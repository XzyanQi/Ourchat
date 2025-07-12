import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:ourchat/models/chat_message.dart';
import 'package:ourchat/providers/authentication_provider_firebase.dart';
import 'package:ourchat/services/database_service.dart';
import 'package:ourchat/services/media_service.dart';
import 'package:ourchat/services/navigation_service.dart';
import 'package:ourchat/services/supabase_storage_service.dart';

class ChatPageProvider extends ChangeNotifier {
  late final DatabaseService _db;
  late final SupabaseStorageService _supabaseStorage;
  late final MediaService _media;
  late final NavigationService _navigation;
  late final StreamSubscription _messageStream;
  late final StreamSubscription _keyboardVisibilityStream;
  late final KeyboardVisibilityController _keyboardVisibilityController;

  final AuthenticationProviderFirebase _auth;
  final ScrollController _messageListViewController;

  final String _chatId;
  List<ChatMessage>? messages;
  String? _message;
  ChatMessage? pinnedMessage;

  String? get message => _message;
  set message(String? value) {
    _message = value;
  }

  bool _isSomeoneTyping = false;
  bool get isSomeoneTyping => _isSomeoneTyping;

  Timer? _typingTimer;

  void setTyping(bool isTyping) {
    if (_isSomeoneTyping != isTyping) {
      _isSomeoneTyping = isTyping;
      notifyListeners();
    }

    if (isTyping) {
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _isSomeoneTyping = false;
        notifyListeners();
      });
    } else {
      _typingTimer?.cancel();
    }
  }

  ChatPageProvider(this._chatId, this._auth, this._messageListViewController) {
    _db = GetIt.instance.get<DatabaseService>();
    _supabaseStorage = GetIt.instance.get<SupabaseStorageService>();
    _media = GetIt.instance.get<MediaService>();
    _navigation = GetIt.instance.get<NavigationService>();
    _keyboardVisibilityController = KeyboardVisibilityController();
    listenToMessages();
    listenToKeyboardChanges();
    getPinnedMessage();
  }

  @override
  void dispose() {
    _messageStream.cancel();
    _keyboardVisibilityStream.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }

  void listenToMessages() {
    try {
      _messageStream = _db.streamMessagesForChat(_chatId).listen((_snapshot) {
        List<ChatMessage> _messages = _snapshot.docs.map((_m) {
          Map<String, dynamic> _messageData = _m.data() as Map<String, dynamic>;
          return ChatMessage.fromJson(_messageData);
        }).toList();
        messages = _messages;
        notifyListeners();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_messageListViewController.hasClients) {
            _messageListViewController.jumpTo(
              _messageListViewController.position.maxScrollExtent,
            );
          }
        });
      });
    } catch (e) {
      debugPrint("Gagal mengambil pesan.");
      debugPrint(e.toString());
    }
  }

  void listenToKeyboardChanges() {
    _keyboardVisibilityStream = _keyboardVisibilityController.onChange.listen((
      event,
    ) {
      _db.updateChatData(_chatId, {'is_activity': event});
    });
  }

  void sendTextMessage() {
    if (_message != null && _message!.trim().isNotEmpty) {
      ChatMessage messageToSend = ChatMessage(
        content: _message!,
        type: MessageType.TEXT,
        senderID: _auth.user!.uid,
        sentTime: DateTime.now(),
      );
      _db.addMessageToChat(_chatId, messageToSend);
      _message = null;
      notifyListeners();
    }
  }

  Future<void> sendImageMessage() async {
    try {
      PlatformFile? file = await _media.pickImageFromLibrary();
      if (file != null) {
        final fileExt = (file.extension ?? '').toLowerCase();
        final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
        if (!allowedExtensions.contains(fileExt)) {
          debugPrint("Hanya file gambar yang diizinkan!");
          _navigation.showSnackBar(
            "Hanya file gambar (jpg, png, gif, webp) yang diizinkan.",
          );
          return;
        }
        String? downloadURL = await _supabaseStorage.uploadChatImage(
          chatId: _chatId,
          userId: _auth.user!.uid,
          file: file,
        );
        if (downloadURL != null) {
          ChatMessage messageToSend = ChatMessage(
            content: downloadURL,
            type: MessageType.IMAGE,
            senderID: _auth.user!.uid,
            sentTime: DateTime.now(),
          );
          _db.addMessageToChat(_chatId, messageToSend);
        } else {
          _navigation.showSnackBar("Gagal mengunggah gambar.");
        }
      }
    } catch (e) {
      debugPrint("Gagal mengirim pesan gambar.");
      debugPrint(e.toString());
      _navigation.showSnackBar("Terjadi kesalahan saat mengirim gambar.");
    }
  }

  // Metode untuk mengirim voice note dari file (mobile)
  Future<void> sendVoiceMessage(File file) async {
    try {
      String fileExt = file.path.split('.').last.toLowerCase();
      final allowedExtensions = ['m4a', 'mp3', 'wav', 'aac', 'ogg', 'webm'];
      if (!allowedExtensions.contains(fileExt)) {
        debugPrint("Hanya file audio yang diizinkan!");
        _navigation.showSnackBar(
          "Hanya file audio (m4a, mp3, wav, aac, ogg, webm) yang diizinkan.",
        );
        return;
      }
      String? downloadURL = await _supabaseStorage.uploadChatVoiceNoteFile(
        chatId: _chatId,
        userId: _auth.user!.uid,
        file: file,
      );
      if (downloadURL != null) {
        ChatMessage messageToSend = ChatMessage(
          content: downloadURL,
          type: MessageType.VOICE,
          senderID: _auth.user!.uid,
          sentTime: DateTime.now(),
        );
        await _db.addMessageToChat(_chatId, messageToSend);
      } else {
        _navigation.showSnackBar("Gagal mengunggah pesan suara.");
      }
    } catch (e) {
      debugPrint("Gagal mengirim pesan suara.");
      debugPrint(e.toString());
      _navigation.showSnackBar("Terjadi kesalahan saat mengirim pesan suara.");
    }
  }

  // Metode untuk mengirim voice note dari bytes (web FilePicker)
  Future<void> sendVoiceMessageFromBytes(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final fileExt = fileName.split('.').last.toLowerCase();
      final allowedExtensions = ['m4a', 'mp3', 'wav', 'aac', 'ogg', 'webm'];
      if (!allowedExtensions.contains(fileExt)) {
        debugPrint("Hanya file audio yang diizinkan untuk diunggah!");
        _navigation.showSnackBar(
          "Hanya file audio (m4a, mp3, wav, aac, ogg, webm) yang diizinkan.",
        );
        return;
      }

      String? downloadURL = await _supabaseStorage.uploadChatVoiceNoteBytes(
        chatId: _chatId,
        userId: _auth.user!.uid,
        bytes: bytes,
        fileName: fileName,
      );
      if (downloadURL != null) {
        ChatMessage messageToSend = ChatMessage(
          content: downloadURL,
          type: MessageType.VOICE,
          senderID: _auth.user!.uid,
          sentTime: DateTime.now(),
        );
        await _db.addMessageToChat(_chatId, messageToSend);
      } else {
        _navigation.showSnackBar("Gagal mengunggah file audio.");
      }
    } catch (e) {
      debugPrint("Gagal mengirim file audio dari bytes.");
      debugPrint(e.toString());
      _navigation.showSnackBar("Terjadi kesalahan saat mengirim file audio.");
    }
  }

  // Metode baru untuk mengirim voice note dari Path (URL Blob di web dari record package)
  Future<void> sendVoiceMessageFromPath(String path) async {
    try {
      if (kIsWeb) {
        final http.Response response = await http.get(Uri.parse(path));
        if (response.statusCode == 200) {
          final Uint8List bytes = response.bodyBytes;
          final String fileName =
              'voice_note_${DateTime.now().millisecondsSinceEpoch}.webm';
          await sendVoiceMessageFromBytes(bytes, fileName);
        } else {
          throw Exception("Failed to fetch audio blob: ${response.statusCode}");
        }
      } else {
        File file = File(path);
        await sendVoiceMessage(file);
      }
    } catch (e) {
      debugPrint("Gagal mengirim voice note dari path: $e");
      debugPrint(e.toString());
      _navigation.showSnackBar(
        "Terjadi kesalahan saat mengirim voice note dari path.",
      );
    }
  }

  void deleteChat() {
    goBack();
    _db.deleteChat(_chatId);
  }

  void goBack() {
    _navigation.goBack();
  }

  Future<void> deleteMessage(ChatMessage message) async {
    try {
      await _db.deleteMessageFromChat(_chatId, message);
      if (pinnedMessage != null &&
          pinnedMessage!.sentTime == message.sentTime &&
          pinnedMessage!.senderID == message.senderID) {
        await unpinMessage();
      }
    } catch (e) {
      debugPrint("Gagal menghapus pesan: $e");
      _navigation.showSnackBar("Gagal menghapus pesan.");
    }
  }

  Future<void> editMessage(BuildContext context, ChatMessage message) async {
    if (message.type != MessageType.TEXT || message.senderID != _auth.user?.uid)
      return;
    TextEditingController controller = TextEditingController(
      text: message.content,
    );
    String? newContent = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Pesan"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Edit pesan..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
    if (newContent != null &&
        newContent.trim().isNotEmpty &&
        newContent != message.content) {
      await _db.updateMessageInChat(_chatId, message, newContent.trim());
      if (pinnedMessage != null &&
          pinnedMessage!.sentTime == message.sentTime &&
          pinnedMessage!.senderID == message.senderID) {
        pinnedMessage = pinnedMessage!.copyWith(content: newContent.trim());
        notifyListeners();
      }
    }
  }

  Future<void> pinMessage(ChatMessage message) async {
    try {
      await _db.setPinnedMessage(_chatId, message);
      pinnedMessage = message;
      notifyListeners();
      _navigation.showSnackBar("Pesan berhasil di-pin!");
    } catch (e) {
      debugPrint("Gagal pin pesan: $e");
      _navigation.showSnackBar("Gagal pin pesan.");
    }
  }

  Future<void> unpinMessage() async {
    try {
      await _db.clearPinnedMessage(_chatId);
      pinnedMessage = null;
      notifyListeners();
      _navigation.showSnackBar("Pesan berhasil di-unpin!");
    } catch (e) {
      debugPrint("Gagal unpin pesan: $e");
      _navigation.showSnackBar("Gagal unpin pesan.");
    }
  }

  Future<void> getPinnedMessage() async {
    try {
      ChatMessage? pinned = await _db.getPinnedMessage(_chatId);
      pinnedMessage = pinned;
      notifyListeners();
    } catch (e) {
      debugPrint("Gagal mengambil pesan pin: $e");
    }
  }
}

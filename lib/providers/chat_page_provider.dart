import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get_it/get_it.dart';
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

  String? get message => _message;

  set message(String? value) {
    _message = value;
  }

  ChatPageProvider(this._chatId, this._auth, this._messageListViewController) {
    _db = GetIt.instance.get<DatabaseService>();
    _supabaseStorage = GetIt.instance.get<SupabaseStorageService>();
    _media = GetIt.instance.get<MediaService>();
    _navigation = GetIt.instance.get<NavigationService>();
    _keyboardVisibilityController = KeyboardVisibilityController();
    listenToMessages();
    listenToKeyboardChanges();
  }

  @override
  void dispose() {
    _messageStream.cancel();
    _keyboardVisibilityStream.cancel();
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
        }
      }
    } catch (e) {
      debugPrint("Gagal mengirim pesan gambar.");
      debugPrint(e.toString());
    }
  }

  void deleteChat() {
    goBack();
    _db.deleteChat(_chatId);
  }

  void goBack() {
    _navigation.goBack();
  }
}

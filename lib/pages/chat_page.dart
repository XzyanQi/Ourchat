import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:ourchat/models/chat.dart';
import 'package:ourchat/models/chat_message.dart';
import 'package:ourchat/models/chat_user.dart';
import 'package:ourchat/providers/authentication_provider_firebase.dart';
import 'package:ourchat/providers/chat_page_provider.dart';
import 'package:ourchat/widgets/custom_list_view_tiles.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

class ChatPage extends StatefulWidget {
  final Chat chat;
  const ChatPage({Key? key, required this.chat}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  late double deviceHeight;
  late double deviceWidth;
  late AuthenticationProviderFirebase auth;
  late GlobalKey<FormState> messageFormKey;
  late ScrollController messagesController;
  late AnimationController sendButtonCtrl;
  late AnimationController imageUploadCtrl;
  late Animation<double> sendButtonAnim;
  late Animation<double> imageUploadAnim;

  bool isImageUploading = false;
  bool isMessageSending = false;
  bool isRecording = false;
  bool isUploadingVoice = false;

  final AudioRecorder _audioRecorder = AudioRecorder();

  @override
  void initState() {
    super.initState();
    messageFormKey = GlobalKey<FormState>();
    messagesController = ScrollController();
    sendButtonCtrl = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    imageUploadCtrl = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    sendButtonAnim = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(parent: sendButtonCtrl, curve: Curves.easeInOut));
    imageUploadAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: imageUploadCtrl, curve: Curves.easeInOut),
    );

    if (!kIsWeb) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Izin mikrofon diperlukan untuk merekam pesan suara.",
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    sendButtonCtrl.dispose();
    imageUploadCtrl.dispose();
    messagesController.dispose();
    _disposeAudioRecorder();
    super.dispose();
  }

  Future<void> _disposeAudioRecorder() async {
    if (await _audioRecorder.isRecording()) {
      await _audioRecorder.stop();
    }
    _audioRecorder.dispose();
  }

  Future<void> handleImageUpload(BuildContext context) async {
    setState(() => isImageUploading = true);
    imageUploadCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1200));
    await Provider.of<ChatPageProvider>(
      context,
      listen: false,
    ).sendImageMessage();
    imageUploadCtrl.reverse();
    setState(() => isImageUploading = false);
  }

  Future<void> handleTextMessage(BuildContext context) async {
    final form = messageFormKey.currentState;
    if (form != null && form.validate()) {
      setState(() => isMessageSending = true);
      sendButtonCtrl.forward().then((_) => sendButtonCtrl.reverse());
      form.save();
      await Future.delayed(const Duration(milliseconds: 250));
      Provider.of<ChatPageProvider>(context, listen: false).sendTextMessage();
      form.reset();
      setState(() => isMessageSending = false);
    }
  }

  Future<void> startVoiceRecording() async {
    try {
      if (!await _audioRecorder.hasPermission()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Izin mikrofon tidak diberikan.")),
        );
        return;
      }

      String outputPath;
      if (!kIsWeb) {
        final Directory tempDir = await getTemporaryDirectory();
        outputPath =
            '${tempDir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
      } else {
        // dummy
        outputPath = 'dummy_path_for_web.webm';
      }

      final AudioEncoder encoder = kIsWeb
          ? AudioEncoder.opus
          : AudioEncoder.aacLc;
      final RecordConfig config = RecordConfig(
        encoder: encoder,
        numChannels: 1,
      );

      await _audioRecorder.start(config, path: outputPath);

      setState(() {
        isRecording = true;
      });
      debugPrint("Recording started. Path: ${outputPath}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Merekam... tekan lagi untuk stop & kirim!"),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error starting recording: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memulai perekaman: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> stopVoiceRecording(BuildContext context) async {
    try {
      final String? path = await _audioRecorder.stop();
      setState(() => isRecording = false);
      debugPrint("Recording stopped. File path: $path");

      if (path != null) {
        setState(() => isUploadingVoice = true);

        await Provider.of<ChatPageProvider>(
          context,
          listen: false,
        ).sendVoiceMessageFromPath(path);

        setState(() {
          isUploadingVoice = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Voice note dikirim!"),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error stopping recording: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal menghentikan perekaman: ${e.toString()}"),
          ),
        );
      }
    }
  }

  // Metode untuk memilih dan mengirim file audio dari web
  Future<void> _pickAndSendAudioWeb(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      PlatformFile file = result.files.first;

      if (file.bytes != null) {
        setState(() => isUploadingVoice = true);
        await Provider.of<ChatPageProvider>(
          context,
          listen: false,
        ).sendVoiceMessageFromBytes(file.bytes!, file.name);
        setState(() => isUploadingVoice = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("File audio dikirim!")));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Gagal membaca file audio.")),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tidak ada file audio yang dipilih.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    auth = Provider.of<AuthenticationProviderFirebase>(context, listen: false);

    return ChangeNotifierProvider<ChatPageProvider>(
      create: (_) =>
          ChatPageProvider(widget.chat.uid, auth, messagesController),
      child: Builder(
        builder: (context) {
          final pageProvider = context.watch<ChatPageProvider>();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (messagesController.hasClients) {
              messagesController.jumpTo(
                messagesController.position.maxScrollExtent,
              );
            }
          });
          return Stack(
            children: [
              Scaffold(
                backgroundColor: const Color(0xFF0A0A0F),
                body: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF1A1A26), Color(0xFF0A0A0F)],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        buildTopBar(context, pageProvider),
                        if (pageProvider.pinnedMessage != null)
                          buildPinnedMessage(
                            pageProvider,
                            pageProvider.pinnedMessage!,
                          ),
                        buildTypingIndicator(pageProvider),
                        Expanded(child: buildMessageList(pageProvider)),
                        if (isUploadingVoice) buildUploadVoiceIndicator(),
                        if (isImageUploading) buildUploadIndicator(),
                        buildSendMessageForm(context),
                      ],
                    ),
                  ),
                ),
              ),
              if (isImageUploading || isUploadingVoice)
                Positioned.fill(
                  child: Container(
                    color: Colors.black38,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6C5CE7),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget buildTopBar(BuildContext context, ChatPageProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26).withOpacity(0.87),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.07), width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF6C5CE7),
              size: 22,
            ),
            onPressed: () => provider.goBack(),
            tooltip: "Kembali",
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.18),
            backgroundImage: widget.chat.imageUrl.isNotEmpty
                ? NetworkImage(widget.chat.imageUrl)
                : null,
            child: widget.chat.imageUrl.isEmpty
                ? Text(
                    widget.chat.title().substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF6C5CE7),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chat.title(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.chat.activity
                      ? "Online"
                      : (widget.chat.members.length == 2
                            ? _getOtherMemberStatus(widget.chat)
                            : "Offline"),
                  style: TextStyle(
                    color: widget.chat.activity
                        ? Colors.green.withOpacity(0.8)
                        : Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
              size: 22,
            ),
            onPressed: () => provider.deleteChat(),
            tooltip: "Hapus chat",
          ),
        ],
      ),
    );
  }

  String _getOtherMemberStatus(Chat chat) {
    if (auth.user == null) return "Offline";

    final otherMember = chat.members.firstWhere(
      (m) => m.uid != auth.user!.uid,
      orElse: () => ChatUser(
        uid: '',
        name: 'N/A',
        email: '',
        imageUrl: '',
        lastActive: DateTime.now().subtract(const Duration(days: 365)),
      ),
    );

    if (otherMember.uid.isEmpty) return "Offline";

    return _formatLastActive(otherMember.lastActive);
  }

  String _formatLastActive(DateTime? lastActive) {
    if (lastActive == null) {
      return "Tidak diketahui";
    }
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inDays > 7) {
      return "${lastActive.day}/${lastActive.month}/${lastActive.year}";
    } else if (difference.inDays > 1) {
      return "${difference.inDays} hari yang lalu";
    } else if (difference.inDays == 1) {
      return "Kemarin";
    } else if (difference.inHours >= 1) {
      return "${difference.inHours} jam yang lalu";
    } else if (difference.inMinutes >= 1) {
      return "${difference.inMinutes} menit yang lalu";
    } else {
      return "Baru saja";
    }
  }

  Widget buildPinnedMessage(ChatPageProvider provider, ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade300, width: 1),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            const Icon(Icons.push_pin_rounded, color: Colors.amber, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.content,
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.amber),
              onPressed: () => provider.unpinMessage(),
              tooltip: "Unpin pesan",
            ),
          ],
        ),
      ),
    );
  }

  Widget buildUploadIndicator() {
    return AnimatedBuilder(
      animation: imageUploadAnim,
      builder: (context, child) {
        if (!isImageUploading) return const SizedBox.shrink();
        return Container(
          height: 54,
          margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 3),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withOpacity(0.17),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Mengunggah gambar...",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.74),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildUploadVoiceIndicator() {
    return Container(
      height: 54,
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 3),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.22),
              borderRadius: BorderRadius.circular(19),
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "Mengunggah voice note...",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTypingIndicator(ChatPageProvider pageProvider) {
    if (pageProvider.isSomeoneTyping == true) {
      return Padding(
        padding: const EdgeInsets.only(left: 18, bottom: 3),
        child: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              "Sedang mengetik...",
              style: TextStyle(color: Colors.green.shade400, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget buildMessageList(ChatPageProvider provider) {
    if (provider.messages == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
      );
    }
    if (provider.messages!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 62,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 14),
            Text(
              "Belum ada pesan",
              style: TextStyle(
                color: Colors.white.withOpacity(0.62),
                fontSize: 16,
              ),
            ),
            Text(
              "Mulai percakapan!",
              style: TextStyle(
                color: Colors.white.withOpacity(0.38),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        controller: messagesController,
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: provider.messages!.length,
        itemBuilder: (context, index) {
          ChatMessage message = provider.messages![index];
          bool isOwnMessage = message.senderID == auth.user!.uid;
          final sender = widget.chat.members.firstWhere(
            (m) => m.uid == message.senderID,
            orElse: () => ChatUser(
              uid: '',
              name: 'Tidak Diketahui',
              email: '',
              imageUrl: '',
              lastActive: DateTime.now(),
            ),
          );
          return AnimatedContainer(
            duration: Duration(milliseconds: 260 + (index * 40)),
            curve: Curves.easeOutBack,
            child: CustomChatListViewTiles(
              deviceHeight: deviceHeight,
              width: deviceWidth * 0.80,
              message: message,
              isOwnMessage: isOwnMessage,
              sender: sender,
            ),
          );
        },
      ),
    );
  }

  Widget buildSendMessageForm(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26).withOpacity(0.88),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 9,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: messageFormKey,
        child: Row(
          children: [
            Expanded(child: buildMessageTextField(context)),
            const SizedBox(width: 7),
            buildImageMessageButton(context),
            const SizedBox(width: 7),
            buildVoiceNoteButton(context),
            const SizedBox(width: 7),
            buildSendMessageButton(context),
          ],
        ),
      ),
    );
  }

  Widget buildMessageTextField(BuildContext context) {
    return TextFormField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "Tulis pesan...",
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.54),
          fontSize: 14,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
      ),
      onSaved: (value) =>
          Provider.of<ChatPageProvider>(context, listen: false).message = value,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return null;
        return RegExp(
              r'^[a-zA-Z0-9\s\p{P}\p{S}\p{M}]+$',
              unicode: true,
            ).hasMatch(value.trim())
            ? null
            : 'Karakter tidak valid';
      },
      textInputAction: TextInputAction.send,
      onFieldSubmitted: (_) => handleTextMessage(context),
      onChanged: (_) {
        Provider.of<ChatPageProvider>(context, listen: false).setTyping(true);
      },
      onEditingComplete: () {
        Provider.of<ChatPageProvider>(context, listen: false).setTyping(false);
      },
    );
  }

  Widget buildImageMessageButton(BuildContext context) {
    return AnimatedBuilder(
      animation: imageUploadAnim,
      builder: (context, child) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C5CE7), Color(0xFF5B4FE0)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C5CE7).withOpacity(0.28),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: isImageUploading ? null : () => handleImageUpload(context),
              child: Icon(
                isImageUploading
                    ? Icons.hourglass_empty_rounded
                    : Icons.photo_camera_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildSendMessageButton(BuildContext context) {
    return AnimatedBuilder(
      animation: sendButtonAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: sendButtonAnim.value,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFF5B4FE0)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C5CE7).withOpacity(0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: isMessageSending
                    ? null
                    : () => handleTextMessage(context),
                child: Icon(
                  isMessageSending
                      ? Icons.hourglass_empty_rounded
                      : Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildVoiceNoteButton(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.20),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            if (kIsWeb) {
              await _pickAndSendAudioWeb(context);
            } else {
              bool currentlyRecording = await _audioRecorder.isRecording();
              if (currentlyRecording) {
                await stopVoiceRecording(context);
              } else {
                await startVoiceRecording();
              }
            }
          },
          child: Icon(
            kIsWeb
                ? Icons.attach_file_rounded
                : (isRecording
                      ? Icons.stop_circle_outlined
                      : Icons.mic_rounded),
            color: Colors.white,
            size: 21,
          ),
        ),
      ),
    );
  }
}

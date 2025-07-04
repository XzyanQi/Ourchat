import 'package:flutter/material.dart';
import 'package:ourchat/models/chat.dart';
import 'package:ourchat/models/chat_message.dart';
import 'package:ourchat/models/chat_user.dart';
import 'package:ourchat/providers/authentication_provider_firebase.dart';
import 'package:ourchat/providers/chat_page_provider.dart';
import 'package:ourchat/widgets/custom_list_view_tiles.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  final Chat chat;

  const ChatPage({Key? key, required this.chat}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  late double _deviceHeight;
  late double _deviceWidth;
  late AuthenticationProviderFirebase _auth;
  late ChatPageProvider _pageProvider;
  late GlobalKey<FormState> _messageFormState;
  late ScrollController _messagesListViewController;
  late AnimationController _sendButtonController;
  late AnimationController _imageUploadController;
  late Animation<double> _sendButtonAnimation;
  late Animation<double> _imageUploadAnimation;

  bool _isImageUploading = false;
  bool _isMessageSending = false;

  @override
  void initState() {
    super.initState();
    _messageFormState = GlobalKey<FormState>();
    _messagesListViewController = ScrollController();

    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _imageUploadController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _sendButtonAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.easeInOut),
    );
    _imageUploadAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _imageUploadController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _sendButtonController.dispose();
    _imageUploadController.dispose();
    super.dispose();
  }

  Future<void> _handleImageUpload() async {
    setState(() {
      _isImageUploading = true;
    });
    _imageUploadController.forward();

    await Future.delayed(const Duration(milliseconds: 1500));

    _pageProvider.sendImageMessage();

    _imageUploadController.reverse();
    setState(() {
      _isImageUploading = false;
    });
  }

  Future<void> _handleTextMessage() async {
    if (_messageFormState.currentState != null &&
        _messageFormState.currentState!.validate()) {
      setState(() {
        _isMessageSending = true;
      });

      _sendButtonController.forward().then((_) {
        _sendButtonController.reverse();
      });

      _messageFormState.currentState!.save();

      await Future.delayed(const Duration(milliseconds: 300));

      _pageProvider.sendTextMessage();
      _messageFormState.currentState!.reset();

      setState(() {
        _isMessageSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _deviceHeight = MediaQuery.of(context).size.height;
    _deviceWidth = MediaQuery.of(context).size.width;
    _auth = Provider.of<AuthenticationProviderFirebase>(context);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ChatPageProvider>(
          create: (_) => ChatPageProvider(
            widget.chat.uid,
            _auth,
            _messagesListViewController,
          ),
        ),
      ],
      child: _buildUI(),
    );
  }

  Widget _buildUI() {
    final isTablet = _deviceWidth > 600;

    return Builder(
      builder: (BuildContext context) {
        _pageProvider = context.watch<ChatPageProvider>();
        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0F),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [const Color(0xFF1A1A26), const Color(0xFF0A0A0F)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildModernTopBar(),
                  Expanded(child: _messageListView()),
                  _buildUploadIndicator(),
                  _sendMessageForm(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26).withOpacity(0.8),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: Color(0xFF6C5CE7),
              size: 22,
            ),
            onPressed: () => _pageProvider.goBack(),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.2),
            child: Text(
              widget.chat.title().substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF6C5CE7),
                fontWeight: FontWeight.bold,
              ),
            ),
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
                  "Online",
                  style: TextStyle(
                    color: Colors.green.withOpacity(0.8),
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
            onPressed: () => _pageProvider.deleteChat(),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadIndicator() {
    return AnimatedBuilder(
      animation: _imageUploadAnimation,
      builder: (context, child) {
        if (!_isImageUploading) return const SizedBox.shrink();

        return Container(
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
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
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _messageListView() {
    if (_pageProvider.messages != null) {
      if (_pageProvider.messages!.isNotEmpty) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: ListView.builder(
            controller: _messagesListViewController,
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: _pageProvider.messages!.length,
            itemBuilder: (BuildContext context, int index) {
              ChatMessage message = _pageProvider.messages![index];
              bool isOwnMessage = message.senderID == _auth.user!.uid;

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
                duration: Duration(milliseconds: 300 + (index * 50)),
                curve: Curves.easeOutBack,
                child: CustomChatListViewTiles(
                  deviceHeight: _deviceHeight,
                  width: _deviceWidth * 0.80,
                  message: message,
                  isOwnMessage: isOwnMessage,
                  sender: sender,
                ),
              );
            },
          ),
        );
      } else {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 64,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                "Belum ada pesan",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                ),
              ),
              Text(
                "Mulai percakapan!",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      }
    } else {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
      );
    }
  }

  Widget _sendMessageForm() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A26).withOpacity(0.8),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _messageFormState,
        child: Row(
          children: [
            Expanded(child: _messageTextField()),
            const SizedBox(width: 8),
            _imageMessageButton(),
            const SizedBox(width: 8),
            _sendMessageButton(),
          ],
        ),
      ),
    );
  }

  Widget _messageTextField() {
    return TextFormField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "Tulis pesan...",
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontSize: 14,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onSaved: (value) => _pageProvider.message = value,
      validator: (value) {
        if (value == null || value.trim().isEmpty) return null;
        return RegExp(
              r'^[a-zA-Z0-9\s\p{P}\p{S}\p{M}]+$',
              unicode: true,
            ).hasMatch(value.trim())
            ? null
            : 'Karakter tidak valid';
      },
    );
  }

  Widget _imageMessageButton() {
    return AnimatedBuilder(
      animation: _imageUploadAnimation,
      builder: (context, child) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF6C5CE7), const Color(0xFF5B4FE0)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C5CE7).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _isImageUploading ? null : _handleImageUpload,
              child: Icon(
                _isImageUploading
                    ? Icons.hourglass_top_rounded
                    : Icons.photo_camera_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sendMessageButton() {
    return AnimatedBuilder(
      animation: _sendButtonAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _sendButtonAnimation.value,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF6C5CE7), const Color(0xFF5B4FE0)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C5CE7).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _isMessageSending ? null : _handleTextMessage,
                child: Icon(
                  _isMessageSending
                      ? Icons.hourglass_top_rounded
                      : Icons.send_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

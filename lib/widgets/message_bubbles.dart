import 'package:flutter/material.dart';
import 'package:ourchat/models/chat_message.dart';
import 'package:ourchat/widgets/our_simple_audio_player.dart';
import 'package:timeago/timeago.dart' as timeago;

class TextMessageBubble extends StatelessWidget {
  final bool isOwnMessage;
  final ChatMessage message;
  final double width;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onPin;

  const TextMessageBubble({
    Key? key,
    required this.isOwnMessage,
    required this.message,
    required this.width,
    this.onDelete,
    this.onEdit,
    this.onPin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Color> _colorScheme = isOwnMessage
        ? [
            const Color.fromRGBO(0, 136, 249, 1.0),
            const Color.fromRGBO(0, 82, 219, 1.0),
          ]
        : [
            const Color.fromRGBO(51, 49, 68, 1.0),
            const Color.fromRGBO(51, 49, 68, 1.0),
          ];
    return GestureDetector(
      onLongPress: () => _showBubbleMenu(context),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: _colorScheme,
            stops: const [0.30, 0.70],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.content, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 4),
            Text(
              timeago.format(message.sentTime),
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  void _showBubbleMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _bubbleActionMenu(context),
    );
  }

  Widget _bubbleActionMenu(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.push_pin, color: Colors.white),
            title: const Text(
              "Pin Pesan",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              if (onPin != null) onPin!();
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.white),
            title: const Text(
              "Edit Pesan",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              if (onEdit != null) onEdit!();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              "Hapus Pesan",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
              if (onDelete != null) onDelete!();
            },
          ),
        ],
      ),
    );
  }
}

class ImageMessageBubble extends StatelessWidget {
  final bool isOwnMessage;
  final ChatMessage message;
  final double width;
  final double maxImageHeight;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onPin;

  const ImageMessageBubble({
    Key? key,
    required this.isOwnMessage,
    required this.message,
    required this.width,
    this.maxImageHeight = 220,
    this.onDelete,
    this.onEdit,
    this.onPin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Color> _colorScheme = isOwnMessage
        ? [
            const Color.fromRGBO(0, 136, 249, 1.0),
            const Color.fromRGBO(0, 82, 219, 1.0),
          ]
        : [
            const Color.fromRGBO(51, 49, 68, 1.0),
            const Color.fromRGBO(51, 49, 68, 1.0),
          ];

    return GestureDetector(
      onTap: () => _showFullImage(context),
      onLongPress: () => _showBubbleMenu(context),
      child: Container(
        width: width,
        padding: EdgeInsets.symmetric(horizontal: width * 0.02, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: _colorScheme,
            stops: const [0.30, 0.70],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                message.content,
                width: width,
                height: maxImageHeight,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: width,
                  height: maxImageHeight,
                  color: Colors.grey[800],
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 40,
                    ),
                  ),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: width,
                    height: maxImageHeight,
                    color: Colors.grey[900],
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Text(
              timeago.format(message.sentTime),
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(message.content, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBubbleMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.push_pin, color: Colors.white),
              title: const Text(
                "Pin Pesan",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                if (onPin != null) onPin!();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text(
                "Edit Pesan",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                if (onEdit != null) onEdit!();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                "Hapus Pesan",
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                if (onDelete != null) onDelete!();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class VoiceMessageBubble extends StatelessWidget {
  final bool isOwnMessage;
  final String audioUrl;
  final double? width;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onPin;

  const VoiceMessageBubble({
    Key? key,
    required this.isOwnMessage,
    required this.audioUrl,
    this.width,
    this.onDelete,
    this.onEdit,
    this.onPin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showBubbleMenu(context),
      child: Container(
        width: width,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isOwnMessage ? Color(0xFF6C5CE7) : Color(0xFF222237),
          borderRadius: BorderRadius.circular(16),
        ),
        child: OurSimpleAudioPlayer(audioUrl: audioUrl),
      ),
    );
  }

  void _showBubbleMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.push_pin, color: Colors.white),
              title: const Text(
                "Pin Pesan",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                if (onPin != null) onPin!();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text(
                "Edit Pesan",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                if (onEdit != null) onEdit!();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                "Hapus Pesan",
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                if (onDelete != null) onDelete!();
              },
            ),
          ],
        ),
      ),
    );
  }
}

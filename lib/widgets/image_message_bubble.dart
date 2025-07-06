import 'package:flutter/material.dart';
import 'package:ourchat/models/chat_message.dart';
import 'package:timeago/timeago.dart' as timeago;

class ImageMessageBubble extends StatelessWidget {
  final bool isOwnMessage;
  final ChatMessage message;
  final double width;
  final double maxImageHeight;
  final Function()? onDelete;
  final Function()? onEdit;
  final Function()? onPin;

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

    return Container(
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
          GestureDetector(
            onTap: () {
              // Fullscreen preview
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  backgroundColor: Colors.black,
                  insetPadding: EdgeInsets.zero,
                  child: Stack(
                    children: [
                      Center(
                        child: InteractiveViewer(
                          child: Image.network(
                            message.content,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 20,
                        right: 20,
                        child: IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            onLongPress: () {
              _showBubbleMenu(context);
            },
            child: ClipRRect(
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
          ),
          const SizedBox(height: 6),
          Text(
            timeago.format(message.sentTime),
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showBubbleMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.push_pin, color: Colors.white),
              title: Text("Pin Pesan", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                if (onPin != null) onPin!();
              },
            ),
            ListTile(
              leading: Icon(Icons.edit, color: Colors.white),
              title: Text("Edit Pesan", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                if (onEdit != null) onEdit!();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text("Hapus Pesan", style: TextStyle(color: Colors.red)),
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

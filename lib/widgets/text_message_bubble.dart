import 'package:flutter/material.dart';
import 'package:ourchat/models/chat_message.dart';
import 'package:timeago/timeago.dart' as timeago;

class TextMessageBubble extends StatelessWidget {
  final bool isOwnMessage;
  final ChatMessage message;
  final double width;
  final Function()? onDelete;
  final Function()? onEdit;
  final Function()? onPin;

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

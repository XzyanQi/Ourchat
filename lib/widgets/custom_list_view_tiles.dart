import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:ourchat/models/chat_message.dart';
import 'package:ourchat/models/chat_user.dart';
import 'package:ourchat/widgets/message_bubbles.dart';
import 'package:ourchat/widgets/rounded_image.dart';

class CustomListViewTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final bool isActive;
  final VoidCallback onTap;
  final bool isSelected;

  const CustomListViewTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.isActive,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: RoundedImageNetworkWithStatusIndicator(
        imagePath: imagePath,
        size: 44,
        isActive: isActive,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: Colors.white)
          : null,
      minVerticalPadding: 0,
      dense: true,
    );
  }
}

class CustomListViewTileWithActivity extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final bool isActive;
  final VoidCallback onTap;

  const CustomListViewTileWithActivity({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: RoundedImageNetworkWithStatusIndicator(
        imagePath: imagePath,
        size: 44,
        isActive: isActive,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: isActive
          ? Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SpinKitThreeBounce(color: Colors.black45, size: 10),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          : Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
      minVerticalPadding: 0,
      dense: true,
    );
  }
}

class CustomChatListViewTiles extends StatelessWidget {
  final double width;
  final double deviceHeight;
  final bool isOwnMessage;
  final ChatMessage message;
  final ChatUser sender;

  const CustomChatListViewTiles({
    super.key,
    required this.width,
    required this.deviceHeight,
    required this.isOwnMessage,
    required this.message,
    required this.sender,
  });

  @override
  Widget build(BuildContext context) {
    final double maxBubbleWidth = width * 0.65;

    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      width: width,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: isOwnMessage
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwnMessage)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: RoundedImageNetwork(imagePath: sender.imageUrl, size: 34),
            ),
          Flexible(
            child: Padding(
              padding: EdgeInsets.only(
                left: isOwnMessage ? 32 : 0,
                right: !isOwnMessage ? 32 : 0,
              ),
              child: message.type == MessageType.TEXT
                  ? TextMessageBubble(
                      isOwnMessage: isOwnMessage,
                      message: message,
                      width: maxBubbleWidth,
                    )
                  : ImageMessageBubble(
                      isOwnMessage: isOwnMessage,
                      message: message,
                      width: maxBubbleWidth,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

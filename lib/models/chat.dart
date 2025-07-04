import 'package:ourchat/models/chat_message.dart';
import 'package:ourchat/models/chat_user.dart';

class Chat {
  final String uid;
  final String currentUserUid;
  final bool activity;
  final bool group;
  final List<ChatUser> members;
  List<ChatMessage> messages;

  Chat({
    required this.uid,
    required this.currentUserUid,
    required this.activity,
    required this.group,
    required this.members,
    required this.messages,
  });

  List<ChatUser> get recipients =>
      members.where((user) => user.uid != currentUserUid).toList();

  String title() {
    return !group
        ? (recipients.isNotEmpty ? recipients.first.name : "")
        : recipients.map((u) => u.name).join(', ');
  }

  String imageURL() {
    return !group
        ? (recipients.isNotEmpty ? recipients.first.imageUrl : "")
        : "https://e7.pngegg.com/pngimages/799/666/png-clipart-computer-icons-avatar-icon-design-avatar-heroes-computer-wallpaper-thumbnail.png";
  }
}

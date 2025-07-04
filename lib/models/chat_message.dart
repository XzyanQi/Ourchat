import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { TEXT, IMAGE, UNKNOWN }

class ChatMessage {
  final String senderID;
  final MessageType type;
  final String content;
  final DateTime sentTime;

  ChatMessage({
    required this.senderID,
    required this.type,
    required this.content,
    required this.sentTime,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    MessageType messageType;
    switch (json["type"]) {
      case "TEXT":
        messageType = MessageType.TEXT;
        break;
      case "IMAGE":
        messageType = MessageType.IMAGE;
        break;
      default:
        messageType = MessageType.UNKNOWN;
    }

    return ChatMessage(
      content: json["content"] ?? "",
      senderID: json["sender_id"] ?? json["senderID"] ?? "",
      sentTime: (json["sent_time"] is Timestamp)
          ? (json["sent_time"] as Timestamp).toDate()
          : DateTime.parse(json["sent_time"].toString()),
      type: messageType,
    );
  }

  Map<String, dynamic> toJson() {
    String messageType;
    switch (type) {
      case MessageType.TEXT:
        messageType = "TEXT";
        break;
      case MessageType.IMAGE:
        messageType = "IMAGE";
        break;
      default:
        messageType = "UNKNOWN";
    }
    return {
      "content": content,
      "type": messageType,
      "sender_id": senderID,
      "sent_time": Timestamp.fromDate(sentTime),
    };
  }
}

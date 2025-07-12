import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum MessageType { TEXT, IMAGE, VOICE, UNKNOWN }

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
      case "VOICE":
        messageType = MessageType.VOICE;
        break;
      default:
        messageType = MessageType.UNKNOWN;
    }

    DateTime parsedSentTime;
    if (json["sent_time"] is Timestamp) {
      parsedSentTime = (json["sent_time"] as Timestamp).toDate();
    } else if (json["sent_time"] is String) {
      try {
        parsedSentTime = DateTime.parse(json["sent_time"]);
      } catch (e) {
        debugPrint(
          "Error parsing sent_time string: ${json["sent_time"]}, Error: $e",
        );
        parsedSentTime = DateTime.now();
      }
    } else {
      parsedSentTime = DateTime.now();
    }

    return ChatMessage(
      content: json["content"] ?? "",
      senderID: json["sender_id"] ?? json["senderID"] ?? "",
      sentTime: parsedSentTime,
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
      case MessageType.VOICE:
        messageType = "VOICE";
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

  ChatMessage copyWith({
    String? senderID,
    MessageType? type,
    String? content,
    DateTime? sentTime,
  }) {
    return ChatMessage(
      senderID: senderID ?? this.senderID,
      type: type ?? this.type,
      content: content ?? this.content,
      sentTime: sentTime ?? this.sentTime,
    );
  }
}

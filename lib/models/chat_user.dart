import 'package:cloud_firestore/cloud_firestore.dart';

class ChatUser {
  final String uid;
  final String name;
  final String email;
  final String imageUrl;
  final DateTime lastActive;

  ChatUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.imageUrl,
    required this.lastActive,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      uid: json['uid'],
      name: json['name'],
      email: json['email'],
      imageUrl: json['imageUrl'],
      lastActive: (json['lastActive'] is Timestamp)
          ? (json['lastActive'] as Timestamp).toDate()
          : DateTime.parse(json['lastActive'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "email": email,
      "name": name,
      "lastActive": lastActive,
      "imageUrl": imageUrl,
    };
  }

  bool wasRecentlyActive({Duration duration = const Duration(minutes: 5)}) {
    return DateTime.now().difference(lastActive) <= duration;
  }
}

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
    final String imageUrl = json['imageUrl'] ?? '';

    DateTime lastActiveDateTime;
    if (json['lastActive'] is Timestamp) {
      lastActiveDateTime = (json['lastActive'] as Timestamp).toDate();
    } else if (json['lastActive'] is String) {
      try {
        lastActiveDateTime = DateTime.parse(json['lastActive']);
      } catch (e) {
        lastActiveDateTime = DateTime.now();
      }
    } else {
      lastActiveDateTime = DateTime.now();
    }

    return ChatUser(
      uid: json['uid'],
      name: json['name'],
      email: json['email'],
      imageUrl: imageUrl,
      lastActive: lastActiveDateTime,
    );
  }

  Map<String, dynamic> toJson() {
    // Mengubah toMap menjadi toJson
    return {
      "uid": uid,
      "email": email,
      "name": name,
      "lastActive": Timestamp.fromDate(lastActive),
      "imageUrl": imageUrl,
    };
  }

  bool wasRecentlyActive({Duration duration = const Duration(minutes: 5)}) {
    return DateTime.now().difference(lastActive) <= duration;
  }

  ChatUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? imageUrl,
    DateTime? lastActive,
  }) {
    return ChatUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      imageUrl: imageUrl ?? this.imageUrl,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ourchat/models/chat_message.dart';

const String USER_COLLECTION = 'users';
const String CHAT_COLLECTION = 'chats';
const String MESSAGE_COLLECTION = 'messages';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DatabaseService();

  Future<void> createUser(
    String uid,
    String name,
    String email,
    String imageUrl,
  ) async {
    try {
      await _db.collection(USER_COLLECTION).doc(uid).set({
        "uid": uid,
        "name": name,
        "email": email,
        "imageUrl": imageUrl,
        "lastActive": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("createUser error: $e");
    }
  }

  Future<DocumentSnapshot> getUser(String uid) {
    return _db.collection(USER_COLLECTION).doc(uid).get();
  }

  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection(USER_COLLECTION).doc(uid).update(data);
    } catch (e) {
      print("updateUserData error: $e");
    }
  }

  Future<QuerySnapshot> getUsers({String? name}) {
    Query _query = _db.collection(USER_COLLECTION);
    if (name != null && name.isNotEmpty) {
      // Prefix search, case sensitive
      _query = _query.orderBy('name').startAt([name]).endAt([name + '\uf8ff']);
    }
    return _query.get();
  }

  Stream<QuerySnapshot> getChatsForUser(String uid) {
    return _db
        .collection(CHAT_COLLECTION)
        .where("members", arrayContains: uid)
        .snapshots();
  }

  Future<QuerySnapshot> getLastMessageForChat(String chatId) {
    return _db
        .collection(CHAT_COLLECTION)
        .doc(chatId)
        .collection(MESSAGE_COLLECTION)
        .orderBy("sent_time", descending: true)
        .limit(2)
        .get();
  }

  Stream<QuerySnapshot> streamMessagesForChat(String chatId) {
    return _db
        .collection(CHAT_COLLECTION)
        .doc(chatId)
        .collection(MESSAGE_COLLECTION)
        .orderBy("sent_time", descending: false)
        .snapshots();
  }

  Future<DocumentReference?> addMessageToChat(
    String chatId,
    ChatMessage message,
  ) async {
    try {
      final json = message.toJson();
      json['sent_time'] = FieldValue.serverTimestamp();
      final docRef = await _db
          .collection(CHAT_COLLECTION)
          .doc(chatId)
          .collection(MESSAGE_COLLECTION)
          .add(json);
      return docRef;
    } catch (e) {
      print("addMessageToChat error: $e");
      return null;
    }
  }

  Future<void> updateUserLastSeenTime(String uid) async {
    try {
      await _db.collection(USER_COLLECTION).doc(uid).update({
        "lastActive": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("updateUserLastSeenTime error: $e");
    }
  }

  Future<void> updateChatData(String chatId, Map<String, dynamic> data) async {
    try {
      await _db.collection(CHAT_COLLECTION).doc(chatId).update(data);
    } catch (e) {
      print("updateChatData error: $e");
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      await _db.collection(CHAT_COLLECTION).doc(chatId).delete();
    } catch (e) {
      print("deleteChat error: $e");
    }
  }

  Future<DocumentReference?> createChat(Map<String, dynamic> data) async {
    try {
      DocumentReference chat = await _db.collection(CHAT_COLLECTION).add(data);
      return chat;
    } catch (e) {
      print("createChat error: $e");
      return null;
    }
  }

  Future<void> deleteMessageFromChat(String chatId, ChatMessage message) async {
    QuerySnapshot snap = await _db
        .collection(CHAT_COLLECTION)
        .doc(chatId)
        .collection(MESSAGE_COLLECTION)
        .where('sent_time', isEqualTo: Timestamp.fromDate(message.sentTime))
        .where('sender_id', isEqualTo: message.senderID)
        .get();

    for (var doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> updateMessageInChat(
    String chatId,
    ChatMessage message,
    String newContent,
  ) async {
    QuerySnapshot snap = await _db
        .collection(CHAT_COLLECTION)
        .doc(chatId)
        .collection(MESSAGE_COLLECTION)
        .where('sent_time', isEqualTo: Timestamp.fromDate(message.sentTime))
        .where('sender_id', isEqualTo: message.senderID)
        .get();

    for (var doc in snap.docs) {
      await doc.reference.update({'content': newContent});
    }
  }

  Future<void> setPinnedMessage(String chatId, ChatMessage message) async {
    await _db
        .collection(CHAT_COLLECTION)
        .doc(chatId)
        .collection('pinned')
        .doc('pinnedMessage')
        .set(message.toJson());
  }

  Future<void> clearPinnedMessage(String chatId) async {
    await _db
        .collection(CHAT_COLLECTION)
        .doc(chatId)
        .collection('pinned')
        .doc('pinnedMessage')
        .delete();
  }

  Future<ChatMessage?> getPinnedMessage(String chatId) async {
    DocumentSnapshot doc = await _db
        .collection(CHAT_COLLECTION)
        .doc(chatId)
        .collection('pinned')
        .doc('pinnedMessage')
        .get();
    if (doc.exists && doc.data() != null) {
      return ChatMessage.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }
}

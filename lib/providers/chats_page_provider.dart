import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:ourchat/models/chat.dart';
import 'package:ourchat/models/chat_message.dart';
import 'package:ourchat/models/chat_user.dart';
import 'package:ourchat/providers/authentication_provider_supabase.dart';
import 'package:ourchat/services/database_service.dart';

class ChatsPageProvider extends ChangeNotifier {
  final AuthenticationProviderSupabase auth;
  late final DatabaseService db;

  List<Chat>? chats;
  StreamSubscription? chatsStream;

  ChatsPageProvider(this.auth) {
    db = GetIt.instance.get<DatabaseService>();
    getChats();
  }

  @override
  void dispose() {
    chatsStream?.cancel();
    super.dispose();
  }

  void getChats() {
    try {
      chatsStream = db.getChatsForUser(auth.user!.uid).listen((snapshot) async {
        final chatList = await Future.wait(
          snapshot.docs.map((d) async {
            final chatData = d.data() as Map<String, dynamic>;

            final List<ChatUser> members = [];
            for (var uid in chatData["members"]) {
              final userSnapshot = await db.getUser(uid);
              final userData = userSnapshot.data() as Map<String, dynamic>;
              userData["uid"] = userSnapshot.id;
              members.add(ChatUser.fromJson(userData));
            }

            final List<ChatMessage> messages = [];
            final chatMessageSnapshot = await db.getLastMessageForChat(d.id);
            if (chatMessageSnapshot.docs.isNotEmpty) {
              final messageData =
                  chatMessageSnapshot.docs.first.data() as Map<String, dynamic>;
              final message = ChatMessage.fromJson(messageData);
              messages.add(message);
            }

            return Chat(
              uid: d.id,
              currentUserUid: auth.user!.uid,
              members: members,
              messages: messages,
              activity: chatData["is_activity"] ?? false,
              group: chatData["is_group"] ?? false,
            );
          }).toList(),
        );
        chats = chatList;
        notifyListeners();
      });
    } catch (e) {
      debugPrint("Gagal mengambil chat: $e");
    }
  }
}

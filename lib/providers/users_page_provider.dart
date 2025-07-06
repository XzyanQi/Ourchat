import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:ourchat/models/chat.dart';
import 'package:ourchat/models/chat_user.dart';
import 'package:ourchat/pages/chat_page.dart';
import 'package:ourchat/providers/authentication_provider_firebase.dart';
import 'package:ourchat/services/database_service.dart';
import 'package:ourchat/services/navigation_service.dart';

class UsersPageProvider extends ChangeNotifier {
  final AuthenticationProviderFirebase _auth;
  late final DatabaseService _database;
  late final NavigationService _navigation;

  List<ChatUser> _users = [];
  List<ChatUser> _selectedUsers = [];
  bool _isLoading = false;
  String? _error;

  List<ChatUser> get users => _users;
  List<ChatUser> get selectedUsers => _selectedUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UsersPageProvider(this._auth) {
    _database = GetIt.instance.get<DatabaseService>();
    _navigation = GetIt.instance.get<NavigationService>();
    _selectedUsers = [];
    getUsers();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> getUsers({String? name}) async {
    _setLoading(true);
    _selectedUsers = [];
    try {
      final snapshot = await _database.getUsers(name: name);
      _users = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data["uid"] = doc.id;
        return ChatUser.fromJson(data);
      }).toList();
      _error = null;
    } catch (e) {
      _users = [];
      _error = "Tidak ada user ditemukan";
      debugPrint(_error!);
      debugPrint(e.toString());
    }
    _setLoading(false);
    notifyListeners();
  }

  void updateSelectedUsers(ChatUser user) {
    if (_selectedUsers.contains(user)) {
      _selectedUsers.remove(user);
    } else {
      _selectedUsers.add(user);
    }
    notifyListeners();
  }

  Future<void> createChat() async {
    if (_selectedUsers.isEmpty) return;
    _setLoading(true);

    try {
      List<String> membersId = _selectedUsers.map((user) => user.uid).toList();
      membersId.add(_auth.user!.uid);
      bool isGroup = _selectedUsers.length > 1;
      DocumentReference? docRef = await _database.createChat({
        "is_group": isGroup,
        "is_activity": false,
        "members": membersId,
      });

      List<ChatUser> members = [];
      for (var uid in membersId) {
        DocumentSnapshot userSnapshot = await _database.getUser(uid);
        Map<String, dynamic> userData =
            userSnapshot.data() as Map<String, dynamic>;
        userData["uid"] = userSnapshot.id;
        members.add(ChatUser.fromJson(userData));
      }

      ChatPage chatPage = ChatPage(
        chat: Chat(
          uid: docRef!.id,
          currentUserUid: _auth.user!.uid,
          members: members,
          messages: [],
          activity: false,
          group: isGroup,
        ),
      );
      clearSelection();
      _navigation.navigateToPage(chatPage);
    } catch (e) {
      _error = "Gagal membuat chat";
      debugPrint(_error!);
      debugPrint(e.toString());
    }
    _setLoading(false);
    notifyListeners();
  }

  void clearSelection() {
    _selectedUsers = [];
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}

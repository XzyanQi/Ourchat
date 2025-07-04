import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:ourchat/models/chat_user.dart';
import 'package:ourchat/services/database_service.dart';
import 'package:ourchat/services/navigation_service.dart';

class AuthenticationProviderFirebase extends ChangeNotifier {
  late final FirebaseAuth _auth;
  late final NavigationService _navigationService;
  late final DatabaseService _databaseService;

  ChatUser? user;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthenticationProviderFirebase() {
    _auth = FirebaseAuth.instance;
    _navigationService = GetIt.instance.get<NavigationService>();
    _databaseService = GetIt.instance.get<DatabaseService>();

    _auth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser != null) {
        try {
          await _databaseService.updateUserLastSeenTime(firebaseUser.uid);
          final snapshot = await _databaseService.getUser(firebaseUser.uid);
          if (snapshot.exists) {
            final userData = snapshot.data() as Map<String, dynamic>;
            user = ChatUser.fromJson({
              "uid": firebaseUser.uid,
              "name": userData["name"],
              "email": userData["email"],
              "imageUrl": userData["imageUrl"],
              "lastActive": userData["lastActive"],
            });

            _clearError();
            notifyListeners();
            _navigationService.removeAndNavigateToRoute("/home");
          }
        } catch (e) {
          debugPrint("Gagal memuat data user: $e");
          _setError("Gagal memuat data user");
        }
      } else {
        user = null;
        _clearError();
        notifyListeners();
        _navigationService.removeAndNavigateToRoute("/login");
      }
    });
  }

  Future<void> loginMenggunakanEmailPassword(
    String email,
    String password,
  ) async {
    try {
      _setLoading(true);
      _clearError();

      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      String errorMsg;
      switch (e.code) {
        case 'user-not-found':
          errorMsg = 'Tidak ada user untuk email tersebut.';
          break;
        case 'wrong-password':
          errorMsg = 'Password salah.';
          break;
        case 'invalid-email':
          errorMsg = 'Email tidak valid.';
          break;
        case 'user-disabled':
          errorMsg = 'Akun user telah dinonaktifkan.';
          break;
        case 'too-many-requests':
          errorMsg = 'Terlalu banyak percobaan, coba lagi nanti.';
          break;
        default:
          errorMsg = e.message ?? 'Login gagal';
      }

      debugPrint("Firebase Auth error: ${e.code} - ${e.message}");
      _setError(errorMsg);
    } catch (e) {
      debugPrint("Error login tidak diketahui: $e");
      _setError("Terjadi kesalahan tak terduga");
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> registerMenggunakanEmailPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      _setLoading(true);
      _clearError();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(name);
      return credential.user?.uid;
    } on FirebaseAuthException catch (e) {
      String errorMsg;
      switch (e.code) {
        case 'weak-password':
          errorMsg = 'Password terlalu lemah.';
          break;
        case 'email-already-in-use':
          errorMsg = 'Akun sudah ada dengan email tersebut.';
          break;
        case 'invalid-email':
          errorMsg = 'Email tidak valid.';
          break;
        default:
          errorMsg = e.message ?? 'Registrasi gagal';
      }

      debugPrint("Firebase registration error: ${e.code} - ${e.message}");
      _setError(errorMsg);
      return null;
    } catch (e) {
      debugPrint("Error registrasi tidak diketahui: $e");
      _setError("Terjadi kesalahan tak terduga");
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> kirimEmailResetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMsg;
      switch (e.code) {
        case 'user-not-found':
          errorMsg = 'Tidak ada user untuk email tersebut.';
          break;
        case 'invalid-email':
          errorMsg = 'Email tidak valid.';
          break;
        default:
          errorMsg = e.message ?? 'Gagal mengirim email reset';
      }

      debugPrint("Reset password error: ${e.code} - ${e.message}");
      _setError(errorMsg);
      return false;
    } catch (e) {
      debugPrint("Error reset password tidak diketahui: $e");
      _setError("Terjadi kesalahan tak terduga");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      _setLoading(true);
      await _auth.signOut();
      user = null;
      _clearError();
    } catch (e) {
      debugPrint("Logout error: $e");
      _setError("Gagal logout");
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}

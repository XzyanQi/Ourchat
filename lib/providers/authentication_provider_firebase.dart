import 'package:cloud_firestore/cloud_firestore.dart';
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
          await _ensureUserDocumentExists(firebaseUser);

          await _databaseService.updateUserLastSeenTime(firebaseUser.uid);

          final snapshot = await _databaseService.getUser(firebaseUser.uid);
          if (snapshot.exists) {
            final userData = snapshot.data() as Map<String, dynamic>?;
            if (userData != null) {
              user = ChatUser.fromJson({
                "uid": firebaseUser.uid,
                "name": _safeGetString(
                  userData,
                  "name",
                  firebaseUser.displayName ?? "Unknown",
                ),
                "email": _safeGetString(
                  userData,
                  "email",
                  firebaseUser.email ?? "",
                ),
                "imageUrl": _safeGetString(userData, "imageUrl", ""),
                "lastActive": _safeGetTimestamp(userData, "lastActive"),
              });

              _clearError();
              notifyListeners();
              _navigationService.removeAndNavigateToRoute("/home");
            } else {
              throw Exception("User data is null");
            }
          } else {
            // Jika dokumen tidak ada, buat dokumen baru
            await _createUserDocument(firebaseUser);
          }
        } catch (e) {
          debugPrint("Gagal memuat data user: $e");
          _setError("Gagal memuat data user: ${e.toString()}");

          await _auth.signOut();
        }
      } else {
        user = null;
        _clearError();
        notifyListeners();
        _navigationService.removeAndNavigateToRoute("/login");
      }
    });
  }

  Future<void> _ensureUserDocumentExists(User firebaseUser) async {
    try {
      final snapshot = await _databaseService.getUser(firebaseUser.uid);
      if (!snapshot.exists) {
        await _createUserDocument(firebaseUser);
      }
    } catch (e) {
      debugPrint("Error checking user document: $e");
    }
  }

  Future<void> _createUserDocument(User firebaseUser) async {
    try {
      await _databaseService.createUser(
        firebaseUser.uid,
        firebaseUser.displayName ?? "Unknown User",
        firebaseUser.email ?? "",
        firebaseUser.photoURL ?? "",
      );
      debugPrint("User document created successfully");
    } catch (e) {
      debugPrint("Error creating user document: $e");
      throw Exception("Failed to create user document");
    }
  }

  Future<void> updateUserProfile({
    String? displayName,
    String? imageUrl,
  }) async {
    if (user == null) {
      debugPrint("User is null, cannot update profile.");
      _setError("User tidak ditemukan.");
      return;
    }

    if (displayName != null && displayName != user!.name) {
      try {
        await _auth.currentUser?.updateDisplayName(displayName);
        user = user!.copyWith(name: displayName);
        notifyListeners();
      } on FirebaseAuthException catch (e) {
        debugPrint("Error updating Firebase Auth display name: ${e.message}");
        _setError("Gagal memperbarui nama pengguna: ${e.message}");
      } catch (e) {
        debugPrint("Error updating display name: $e");
        _setError("Gagal memperbarui nama pengguna.");
      }
    }

    if (imageUrl != null && imageUrl != user!.imageUrl) {
      try {
        await _auth.currentUser?.updatePhotoURL(imageUrl);
        user = user!.copyWith(imageUrl: imageUrl);
        notifyListeners();
      } on FirebaseAuthException catch (e) {
        debugPrint("Error updating Firebase Auth photo URL: ${e.message}");
        _setError("Gagal memperbarui foto profil: ${e.message}");
      } catch (e) {
        debugPrint("Error updating photo URL: $e");
        _setError("Gagal memperbarui foto profil.");
      }
    }
  }

  String _safeGetString(
    Map<String, dynamic> data,
    String key,
    String fallback,
  ) {
    try {
      return data[key]?.toString() ?? fallback;
    } catch (e) {
      debugPrint("Error getting string for key $key: $e");
      return fallback;
    }
  }

  String _safeGetTimestamp(Map<String, dynamic> data, String key) {
    try {
      final value = data[key];
      if (value == null) {
        return DateTime.now().toIso8601String();
      }

      if (value is String) {
        DateTime.parse(value);
        return value;
      }

      if (value is Timestamp) {
        return value.toDate().toIso8601String();
      }

      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value).toIso8601String();
      }
      return DateTime.now().toIso8601String();
    } catch (e) {
      debugPrint("Error parsing timestamp for key $key: $e");
      return DateTime.now().toIso8601String();
    }
  }

  Future<void> loginMenggunakanEmailPassword(
    String email,
    String password,
  ) async {
    try {
      setLoading(true);
      _clearError();

      if (email.isEmpty || password.isEmpty) {
        throw Exception("Email dan password tidak boleh kosong");
      }

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
        case 'network-request-failed':
          errorMsg = 'Periksa koneksi internet Anda.';
          break;
        default:
          errorMsg = e.message ?? 'Login gagal';
      }
      debugPrint("Firebase Auth error: ${e.code} - ${e.message}");
      _setError(errorMsg);
    } catch (e) {
      debugPrint("Error login tidak diketahui: $e");
      _setError("Terjadi kesalahan tak terduga: ${e.toString()}");
    } finally {
      setLoading(false);
    }
  }

  Future<String?> registerMenggunakanEmailPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      setLoading(true);
      _clearError();

      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        throw Exception("Semua field harus diisi");
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName(name);

      if (credential.user != null) {
        await _createUserDocument(credential.user!);
      }

      return credential.user?.uid;
    } on FirebaseAuthException catch (e) {
      String errorMsg;
      switch (e.code) {
        case 'weak-password':
          errorMsg = 'Password terlalu lemah (minimal 6 karakter).';
          break;
        case 'email-already-in-use':
          errorMsg = 'Akun sudah ada dengan email tersebut.';
          break;
        case 'invalid-email':
          errorMsg = 'Email tidak valid.';
          break;
        case 'network-request-failed':
          errorMsg = 'Periksa koneksi internet Anda.';
          break;
        default:
          errorMsg = e.message ?? 'Registrasi gagal';
      }

      debugPrint("Firebase registration error: ${e.code} - ${e.message}");
      _setError(errorMsg);
      return null;
    } catch (e) {
      debugPrint("Error registrasi tidak diketahui: $e");
      _setError("Terjadi kesalahan tak terduga: ${e.toString()}");
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> kirimEmailResetPassword(String email) async {
    try {
      setLoading(true);
      _clearError();

      if (email.isEmpty) {
        throw Exception("Email tidak boleh kosong");
      }

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
        case 'network-request-failed':
          errorMsg = 'Periksa koneksi internet Anda.';
          break;
        default:
          errorMsg = e.message ?? 'Gagal mengirim email reset';
      }

      debugPrint("Reset password error: ${e.code} - ${e.message}");
      _setError(errorMsg);
      return false;
    } catch (e) {
      debugPrint("Error reset password tidak diketahui: $e");
      _setError("Terjadi kesalahan tak terduga: ${e.toString()}");
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      setLoading(true);

      if (user != null) {
        await _databaseService.updateUserLastSeenTime(user!.uid);
      }

      await _auth.signOut();
      user = null;
      _clearError();
    } catch (e) {
      debugPrint("Logout error: $e");
      _setError("Gagal logout: ${e.toString()}");
    } finally {
      setLoading(false);
    }
  }

  void setLoading(bool loading) {
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

  Future<void> retryLoadUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        setLoading(true);
        _clearError();

        await _ensureUserDocumentExists(currentUser);
        await _databaseService.updateUserLastSeenTime(currentUser.uid);

        final snapshot = await _databaseService.getUser(currentUser.uid);
        if (snapshot.exists) {
          final userData = snapshot.data() as Map<String, dynamic>?;
          if (userData != null) {
            user = ChatUser.fromJson({
              "uid": currentUser.uid,
              "name": _safeGetString(
                userData,
                "name",
                currentUser.displayName ?? "Unknown",
              ),
              "email": _safeGetString(
                userData,
                "email",
                currentUser.email ?? "",
              ),
              "imageUrl": _safeGetString(userData, "imageUrl", ""),
              "lastActive": _safeGetTimestamp(userData, "lastActive"),
            });

            notifyListeners();
            _navigationService.removeAndNavigateToRoute("/home");
          }
        }
      } catch (e) {
        debugPrint("Error retry load user: $e");
        _setError("Gagal memuat ulang data user");
      } finally {
        setLoading(false);
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:ourchat/models/chat_user.dart';
import 'package:ourchat/services/database_service.dart';
import 'package:ourchat/services/navigation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthenticationProviderSupabase extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final NavigationService _navigationService;
  late final DatabaseService _databaseService;

  ChatUser? user;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthenticationProviderSupabase() {
    _navigationService = GetIt.instance.get<NavigationService>();
    _databaseService = GetIt.instance.get<DatabaseService>();

    _supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      final userData = session?.user;

      if (userData != null) {
        try {
          await _databaseService.updateUserLastSeenTime(userData.id);
          final userMap = await _databaseService.getUser(userData.id);
          if (userMap != null) {
            user = ChatUser.fromJson({
              "uid": userData.id,
              "name": userMap["name"],
              "email": userMap["email"],
              "imageUrl": userMap["imageUrl"],
              "lastActive": userMap["lastActive"],
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

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login gagal, user tidak ditemukan');
      }
    } on AuthException catch (e) {
      String errorMsg = e.message ?? 'Login gagal';
      if (errorMsg.contains('Invalid login credentials')) {
        errorMsg = 'Email atau password salah.';
      }
      _setError(errorMsg);
      debugPrint("Supabase Auth error: ${e.message}");
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

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      if (response.user == null) {
        throw Exception('Registrasi gagal');
      }
      return response.user!.id;
    } on AuthException catch (e) {
      String errorMsg = e.message ?? 'Registrasi gagal';
      if (errorMsg.contains('Password should be at least')) {
        errorMsg = 'Password terlalu lemah.';
      } else if (errorMsg.contains('already registered')) {
        errorMsg = 'Akun sudah terdaftar dengan email ini.';
      }
      _setError(errorMsg);
      debugPrint("Supabase registration error: ${e.message}");
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

      await _supabase.auth.resetPasswordForEmail(email);
      return true;
    } on AuthException catch (e) {
      String errorMsg = e.message ?? 'Gagal mengirim email reset';
      _setError(errorMsg);
      debugPrint("Reset password error: ${e.message}");
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
      await _supabase.auth.signOut();
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

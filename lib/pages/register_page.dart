import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:ourchat/providers/authentication_provider_firebase.dart';
import 'package:ourchat/services/database_service.dart';
import 'package:ourchat/services/media_service.dart';
import 'package:ourchat/services/navigation_service.dart';
import 'package:ourchat/services/supabase_storage_service.dart';
import 'package:ourchat/widgets/rounded_image.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  late AuthenticationProviderFirebase _auth;
  late DatabaseService _db;
  late SupabaseStorageService _supabaseStorage;
  late NavigationService _navigation;

  String? email;
  String? password;
  String? name;
  PlatformFile? profileImage;
  final GlobalKey<FormState> registerFormKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _loadingController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
        _scaleController.forward();
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email.trim());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isMobile = size.width < 400;

    _auth = Provider.of<AuthenticationProviderFirebase>(context); // BENAR!
    _db = GetIt.instance.get<DatabaseService>();
    _navigation = GetIt.instance.get<NavigationService>();
    _supabaseStorage = GetIt.instance.get<SupabaseStorageService>();

    return _buildUI(isTablet, isMobile);
  }

  Widget _buildUI(bool isTablet, bool isMobile) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667EEA),
              Color(0xFF764BA2),
              Color(0xFF6B73FF),
              Color(0xFF9A4AEF),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 64 : (isMobile ? 16 : 24),
                vertical: 20,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 500 : double.infinity,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeader(isTablet, isMobile),
                          SizedBox(height: isTablet ? 32 : 24),
                          _buildProfileImageField(isTablet, isMobile),
                          SizedBox(height: isTablet ? 32 : 24),
                          _buildRegisterForm(isTablet, isMobile),
                          SizedBox(height: isTablet ? 32 : 24),
                          _buildRegisterButton(isTablet, isMobile),
                          SizedBox(height: isTablet ? 20 : 16),
                          _buildLoginLink(isTablet, isMobile),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet, bool isMobile) {
    return Column(
      children: [
        Hero(
          tag: 'app_logo',
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white,
              size: isTablet ? 48 : (isMobile ? 32 : 40),
            ),
          ),
        ),
        SizedBox(height: isTablet ? 24 : 16),
        Text(
          'Selamat datang di',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: isTablet ? 18 : (isMobile ? 14 : 16),
            fontWeight: FontWeight.w400,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFF8F9FA)],
          ).createShader(bounds),
          child: Text(
            'OurChat',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 42 : (isMobile ? 28 : 36),
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Buat akun untuk mulai ngobrol',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: isTablet ? 16 : (isMobile ? 12 : 14),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImageField(bool isTablet, bool isMobile) {
    final imageSize = isTablet ? 130.0 : (isMobile ? 90.0 : 110.0);

    return Column(
      children: [
        Text(
          'Foto Profil',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: isTablet ? 16 : (isMobile ? 12 : 14),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: isTablet ? 16 : 12),
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return GestureDetector(
              onTap: _isLoading
                  ? null
                  : () async {
                      final file = await GetIt.instance
                          .get<MediaService>()
                          .pickImageFromLibrary();
                      if (file != null) {
                        setState(() {
                          profileImage = file;
                        });
                      }
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: imageSize,
                height: imageSize,
                transform: Matrix4.identity()
                  ..scale(profileImage == null ? _pulseAnimation.value : 1.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: profileImage != null
                      ? null
                      : LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: profileImage != null
                    ? ClipOval(
                        child: RoundedImageFile(
                          key: UniqueKey(),
                          image: profileImage!,
                          size: imageSize,
                        ),
                      )
                    : Icon(
                        Icons.add_a_photo_rounded,
                        color: Colors.white.withOpacity(0.8),
                        size: isTablet ? 36 : (isMobile ? 24 : 30),
                      ),
              ),
            );
          },
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Text(
          profileImage == null
              ? 'Ketuk untuk tambah foto'
              : 'Ketuk untuk ganti foto',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: isTablet ? 14 : (isMobile ? 10 : 12),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm(bool isTablet, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 32 : (isMobile ? 20 : 24)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.15),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: registerFormKey,
        child: Column(
          children: [
            _buildModernTextField(
              hintText: "Nama Lengkap",
              icon: Icons.person_outline_rounded,
              onSaved: (value) => name = value,
              regEx: r'.{3,}',
              isTablet: isTablet,
              isMobile: isMobile,
            ),
            SizedBox(height: isTablet ? 20 : 16),
            _buildModernTextField(
              hintText: "Email",
              icon: Icons.email_outlined,
              onSaved: (value) => email = value,
              regEx: r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$",
              isTablet: isTablet,
              isMobile: isMobile,
            ),
            SizedBox(height: isTablet ? 20 : 16),
            _buildModernTextField(
              hintText: "Password",
              icon: Icons.lock_outline_rounded,
              isPassword: true,
              onSaved: (value) => password = value,
              regEx: r'.{6,}',
              isTablet: isTablet,
              isMobile: isMobile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required String hintText,
    required IconData icon,
    required Function(String?) onSaved,
    required String regEx,
    required bool isTablet,
    required bool isMobile,
    bool isPassword = false,
  }) {
    return TextFormField(
      obscureText: isPassword ? _obscurePassword : false,
      onSaved: onSaved,
      validator: (value) {
        if (value == null || !RegExp(regEx).hasMatch(value)) {
          return 'Mohon masukkan $hintText yang valid';
        }
        return null;
      },
      style: TextStyle(
        color: Colors.white,
        fontSize: isTablet ? 16 : (isMobile ? 12 : 14),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: isTablet ? 16 : (isMobile ? 12 : 14),
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.white.withOpacity(0.8),
          size: isTablet ? 24 : (isMobile ? 18 : 20),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white.withOpacity(0.8),
                  size: isTablet ? 24 : (isMobile ? 18 : 20),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 16,
          vertical: isTablet ? 20 : 16,
        ),
      ),
    );
  }

  Widget _buildRegisterButton(bool isTablet, bool isMobile) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: isTablet ? 56 : (isMobile ? 48 : 52),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF667EEA),
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: isTablet ? 24 : 20,
                width: isTablet ? 24 : 20,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                ),
              )
            : Text(
                'Buat Akun',
                style: TextStyle(
                  fontSize: isTablet ? 18 : (isMobile ? 14 : 16),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginLink(bool isTablet, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Sudah punya akun? ',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: isTablet ? 14 : (isMobile ? 11 : 13),
          ),
        ),
        GestureDetector(
          onTap: () => _navigation.goBack(),
          child: Text(
            'Masuk',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 14 : (isMobile ? 11 : 13),
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRegister() async {
    if (!registerFormKey.currentState!.validate() || profileImage == null) {
      _showError("Mohon lengkapi semua data dan pilih foto profil!");
      return;
    }

    setState(() => _isLoading = true);
    _loadingController.repeat();

    registerFormKey.currentState!.save();

    if (email == null || !isValidEmail(email!)) {
      _showError("Mohon masukkan email yang valid");
      setState(() => _isLoading = false);
      _loadingController.stop();
      return;
    }
    if (password == null || password!.length < 6) {
      _showError("Password minimal 6 karakter");
      setState(() => _isLoading = false);
      _loadingController.stop();
      return;
    }
    if (name == null || name!.length < 3) {
      _showError("Nama minimal 3 karakter");
      setState(() => _isLoading = false);
      _loadingController.stop();
      return;
    }

    try {
      // Daftar akun ke Firebase Auth
      String? uid = await _auth.registerMenggunakanEmailPassword(
        email!,
        password!,
        name!,
      );
      if (uid == null) {
        _showError(
          _auth.errorMessage ??
              "Pendaftaran gagal. Mohon periksa email dan password.",
        );
        setState(() => _isLoading = false);
        _loadingController.stop();
        return;
      }

      // Upload foto ke Supabase Storage
      final fileExt = (profileImage!.extension ?? '').toLowerCase();
      final allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      if (!allowedExtensions.contains(fileExt)) {
        _showError("Hanya file gambar yang diizinkan!");
        setState(() => _isLoading = false);
        _loadingController.stop();
        return;
      }

      final imageUrl = await _supabaseStorage.uploadUserAvatar(
        userId: uid,
        file: profileImage!,
      );
      if (imageUrl == null) {
        _showError("Gagal upload foto. Silakan coba lagi.");
        setState(() => _isLoading = false);
        _loadingController.stop();
        return;
      }

      // Simpan data user ke Firestore
      await _db.createUser(uid, name!, email!, imageUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text("Akun berhasil dibuat!"),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // Delay sebentar agar UX lebih baik
        await Future.delayed(const Duration(milliseconds: 500));
        _navigation.goBack();
      }
    } catch (e, st) {
      print("Error saat registrasi: $e");
      print(st);
      _showError("Terjadi kesalahan saat registrasi. Silakan coba lagi.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _loadingController.stop();
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}

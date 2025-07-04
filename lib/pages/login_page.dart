import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:ourchat/providers/authentication_provider_firebase.dart';
import 'package:ourchat/services/navigation_service.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _loginFormKey = GlobalKey<FormState>();
  String? _email;
  String? _password;

  late AuthenticationProviderFirebase _auth;
  late NavigationService _navigation;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    _navigation = GetIt.instance.get<NavigationService>();

    return Consumer<AuthenticationProviderFirebase>(
      builder: (context, auth, child) {
        _auth = auth;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_auth.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_auth.errorMessage!),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Tutup',
                  textColor: Colors.white,
                  onPressed: () {
                    _auth.clearError();
                  },
                ),
              ),
            );
          }
        });

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F0F23),
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                  Color(0xFF0F3460),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 64 : 24,
                    vertical: 24,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 500 : 400,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildLogo(isTablet),
                            SizedBox(height: isTablet ? 48 : 40),
                            _buildWelcomeText(isTablet),
                            SizedBox(height: isTablet ? 40 : 32),
                            _buildLoginForm(isTablet),
                            SizedBox(height: isTablet ? 32 : 28),
                            _buildLoginButton(isTablet),
                            SizedBox(height: isTablet ? 24 : 20),
                            _buildFooterLinks(isTablet),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo(bool isTablet) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: EdgeInsets.all(isTablet ? 32 : 24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.chat_bubble_rounded,
              size: isTablet ? 48 : 40,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeText(bool isTablet) {
    return Column(
      children: [
        Text(
          'Selamat datang di',
          style: TextStyle(
            color: Colors.white70,
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ).createShader(bounds),
          child: Text(
            'OurChat',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 42 : 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Terhubung dengan orang di seluruh dunia',
          style: TextStyle(
            color: Colors.white60,
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _loginFormKey,
        child: Column(
          children: [
            _buildCustomTextField(
              hintText: "Email",
              icon: Icons.email_outlined,
              isPassword: false,
              onSaved: (value) => _email = value,
              regEx: r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$",
              isTablet: isTablet,
            ),
            SizedBox(height: isTablet ? 20 : 16),
            _buildCustomTextField(
              hintText: "Password",
              icon: Icons.lock_outline,
              isPassword: true,
              onSaved: (value) => _password = value,
              regEx: r'^.{6,}$',
              isTablet: isTablet,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTextField({
    required String hintText,
    required IconData icon,
    required bool isPassword,
    required Function(String?) onSaved,
    required String regEx,
    required bool isTablet,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: TextFormField(
        obscureText: isPassword,
        style: TextStyle(
          color: Colors.white,
          fontSize: isTablet ? 16 : 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.white60,
            fontSize: isTablet ? 16 : 14,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
            ),
            child: Icon(icon, color: Colors.white, size: isTablet ? 20 : 18),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 16,
            vertical: isTablet ? 20 : 16,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$hintText wajib diisi';
          }
          if (!RegExp(regEx).hasMatch(value)) {
            return 'Masukkan $hintText yang valid';
          }
          return null;
        },
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildLoginButton(bool isTablet) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: double.infinity,
            height: isTablet ? 56 : 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _auth.isLoading
                    ? null
                    : () {
                        if (_loginFormKey.currentState!.validate()) {
                          _loginFormKey.currentState!.save();
                          _auth.loginMenggunakanEmailPassword(
                            _email!,
                            _password!,
                          );
                        }
                      },
                child: Center(
                  child: _auth.isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Masuk',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooterLinks(bool isTablet) {
    return Column(
      children: [
        _buildAnimatedLink(
          'Belum punya akun? Daftar',
          onTap: () => _navigation.navigateToRoute('/register'),
          isTablet: isTablet,
        ),
        SizedBox(height: isTablet ? 16 : 12),
        _buildAnimatedLink(
          'Lupa password?',
          onTap: () => _navigation.navigateToRoute('/forget'),
          isTablet: isTablet,
          isUnderlined: true,
        ),
      ],
    );
  }

  Widget _buildAnimatedLink(
    String text, {
    required VoidCallback onTap,
    required bool isTablet,
    bool isUnderlined = false,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween(begin: 1.0, end: 1.0),
      builder: (context, value, child) {
        return GestureDetector(
          onTapDown: (_) {},
          onTapUp: (_) => onTap(),
          onTapCancel: () {},
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 16 : 12,
              vertical: isTablet ? 12 : 8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.transparent,
            ),
            child: Text(
              text,
              style: TextStyle(
                color: const Color(0xFF667EEA),
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w500,
                decoration: isUnderlined ? TextDecoration.underline : null,
                decorationColor: const Color(0xFF667EEA),
              ),
            ),
          ),
        );
      },
    );
  }
}

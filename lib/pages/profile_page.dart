import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:ourchat/models/chat_user.dart';
import 'package:ourchat/providers/authentication_provider_firebase.dart';
import 'package:ourchat/services/database_service.dart';
import 'package:ourchat/services/media_service.dart';
import 'package:ourchat/services/supabase_storage_service.dart';
import 'package:ourchat/widgets/custom_input.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  late AuthenticationProviderFirebase _auth;
  late DatabaseService _databaseService;
  late MediaService _mediaService;
  late SupabaseStorageService _supabaseStorageService;

  final TextEditingController _usernameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _auth = Provider.of<AuthenticationProviderFirebase>(context);
    _databaseService = GetIt.instance.get<DatabaseService>();
    _mediaService = GetIt.instance.get<MediaService>();
    _supabaseStorageService = GetIt.instance.get<SupabaseStorageService>();

    final ChatUser? currentUser = _auth.user;
    if (currentUser != null) {
      // Set teks controller jika berbeda untuk mencegah memicu build terus-menerus
      if (_usernameController.text.isEmpty ||
          _usernameController.text != currentUser.name) {
        _usernameController.text = currentUser.name;
      }
      _profileImageUrl = currentUser.imageUrl;
    }

    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0A12), Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isTablet),
                    const SizedBox(height: 24),
                    Expanded(
                      child: _buildProfileContent(currentUser, isTablet),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E2E), Color(0xFF2A2A3E)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 32 : 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kelola informasi profil Anda',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  _auth.logout();
                },
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(ChatUser? currentUser, bool isTablet) {
    if (currentUser == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildProfilePicture(currentUser, isTablet),
          const SizedBox(height: 24),
          _buildProfileForm(currentUser, isTablet),
          const SizedBox(height: 24),
          _buildSaveButton(isTablet),
        ],
      ),
    );
  }

  Widget _buildProfilePicture(ChatUser currentUser, bool isTablet) {
    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFF6C5CE7).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: isTablet ? 80 : 60,
              backgroundColor: const Color(0xFF667EEA),
              backgroundImage:
                  _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                  ? NetworkImage(_profileImageUrl!)
                  : null,
              child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                  ? Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: isTablet ? 70 : 50,
                    )
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C5CE7),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: _auth.isLoading ? null : _pickAndUploadImage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm(ChatUser currentUser, bool isTablet) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomInput(
            hintText: "Nama Pengguna",
            controller: _usernameController,
            isObscure: false,
            validationRegExp: RegExp(r".{3,}"),
            onSaved: (value) {},
            onChanged: (value) {
              _formKey.currentState?.validate();
            },
            prefixIcon: Icons.person_rounded,
            keyboardType: TextInputType.text,
            label: 'Nama Pengguna',
            autofillHints: const [AutofillHints.username],
          ),
          const SizedBox(height: 16),
          _buildInfoField(
            label: "Email",
            value: currentUser.email,
            icon: Icons.email_rounded,
            isTablet: isTablet,
          ),
          const SizedBox(height: 16),
          _buildInfoField(
            label: "Terakhir Aktif",
            value: _formatLastActive(currentUser.lastActive),
            icon: Icons.access_time_rounded,
            isTablet: isTablet,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    required IconData icon,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 16 : 12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: isTablet ? 24 : 20),
          SizedBox(width: isTablet ? 16 : 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: isTablet ? 14 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(bool isTablet) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _auth.isLoading
              ? null
              : _updateProfile, // Nonaktifkan saat loading
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: isTablet ? 18 : 14),
            child: _auth.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Simpan Perubahan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  String _formatLastActive(DateTime? lastActive) {
    if (lastActive == null) {
      return "Tidak diketahui";
    }
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inDays > 7) {
      return "${lastActive.day}/${lastActive.month}/${lastActive.year}";
    } else if (difference.inDays > 1) {
      return "${difference.inDays} hari yang lalu";
    } else if (difference.inDays == 1) {
      return "Kemarin";
    } else if (difference.inHours >= 1) {
      return "${difference.inHours} jam yang lalu";
    } else if (difference.inMinutes >= 1) {
      return "${difference.inMinutes} menit yang lalu";
    } else {
      return "Baru saja";
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final pickedFile = await _mediaService.pickImageFromLibrary();
      if (pickedFile != null) {
        setState(() {
          _auth.setLoading(true);
        });
        final imageUrl = await _supabaseStorageService.uploadUserAvatar(
          userId: _auth.user!.uid,
          file: pickedFile,
        );
        if (imageUrl != null) {
          await _databaseService.updateUserData(_auth.user!.uid, {
            'imageUrl': imageUrl,
          });
          await _auth.updateUserProfile(imageUrl: imageUrl);
          setState(() {
            _profileImageUrl = imageUrl;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto profil berhasil diperbarui!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal mengunggah foto profil.')),
          );
        }
      }
    } catch (e) {
      debugPrint("Error picking or uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _auth.setLoading(false); // Clear loading state
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      final newUsername = _usernameController.text.trim();
      if (_auth.user != null && newUsername != _auth.user!.name) {
        setState(() {
          _auth.setLoading(true);
        });
        try {
          await _databaseService.updateUserData(_auth.user!.uid, {
            'name': newUsername,
          });
          await _auth.updateUserProfile(displayName: newUsername);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil berhasil diperbarui!')),
          );
        } catch (e) {
          debugPrint("Error updating profile: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memperbarui profil: ${e.toString()}'),
            ),
          );
        } finally {
          setState(() {
            _auth.setLoading(false);
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak ada perubahan nama pengguna untuk disimpan.'),
          ),
        );
      }
    }
  }
}

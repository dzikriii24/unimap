import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicamp/core/services/supabase_service.dart';
import 'package:unicamp/core/theme/app_theme.dart';
import 'package:unicamp/features/auth/presentation/pages/login_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _nimController = TextEditingController();

  // State Variables
  XFile? _rawImage;
  Uint8List? _imageBytes;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedFakultas = '';
  String _selectedJurusan = '';

  // List Fakultas dan Jurusan UIN Sunan Gunung Djati Bandung
  final Map<String, List<String>> _fakultasJurusan = {
    'Fakultas Ushuluddin': [
      'Ilmu Al-Quran dan Tafsir (IAT)',
      'Tafsir Hadis (TH)',
      'Aqidah dan Filsafat Islam (AFI)',
    ],
    'Fakultas Tarbiyah dan Keguruan': [
      'Pendidikan Agama Islam (PAI)',
      'Pendidikan Guru Madrasah Ibtidaiyah (PGMI)',
      'Pendidikan Bahasa Arab (PBA)',
      'Manajemen Pendidikan Islam (MPI)',
      'Pendidikan Islam Anak Usia Dini (PIAUD)',
    ],
    'Fakultas Syariah dan Hukum': [
      'Hukum Keluarga Islam (HKI)',
      'Hukum Ekonomi Syariah (HES)',
      'Hukum Tata Negara (HTN)',
      'Hukum Pidana Islam (HPI)',
    ],
    'Fakultas Dakwah dan Komunikasi': [
      'Komunikasi dan Penyiaran Islam (KPI)',
      'Bimbingan dan Konseling Islam (BKI)',
      'Pengembangan Masyarakat Islam (PMI)',
      'Manajemen Dakwah (MD)',
    ],
    'Fakultas Adab dan Humaniora': [
      'Sejarah dan Peradaban Islam (SPI)',
      'Bahasa dan Sastra Arab (BSA)',
      'Ilmu Perpustakaan dan Informasi Islam (IPII)',
    ],
    'Fakultas Psikologi': [
      'Psikologi',
      'Psikologi Islam',
    ],
    'Fakultas Sains dan Teknologi': [
      'Matematika',
      'Fisika',
      'Kimia',
      'Biologi',
      'Teknik Informatika',
      'Sistem Informasi',
    ],
    'Fakultas Ekonomi dan Bisnis Islam': [
      'Ekonomi Syariah',
      'Perbankan Syariah',
      'Akuntansi Syariah',
      'Manajemen',
    ],
    'Fakultas Kedokteran': [
      'Pendidikan Dokter',
      'Ilmu Keperawatan',
    ],
    'Fakultas Ilmu Sosial dan Ilmu Politik': [
      'Sosiologi',
      'Ilmu Politik',
      'Hubungan Internasional',
    ],
  };

  // List semua jurusan untuk search
  List<String> get _allJurusan {
    List<String> all = [];
    _fakultasJurusan.forEach((key, value) {
      all.addAll(value);
    });
    return all;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _rawImage = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final supabaseClient = Supabase.instance.client;
      final supabaseService = SupabaseService();

      // Cek Username Unik
      final checkUsername = await supabaseClient
          .from('users_001')
          .select('username')
          .eq('username', _usernameController.text.trim())
          .maybeSingle();

      if (checkUsername != null) {
        throw 'Username "${_usernameController.text}" sudah digunakan. Silakan pilih yang lain.';
      }

      // Upload Foto
      String finalFotoUrl;
      String defaultUrl =
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w-150&q=80';

      if (_imageBytes != null && _rawImage != null) {
        final fileExt = _rawImage!.path.split('.').last;
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${_usernameController.text.trim()}.$fileExt';
        final filePath = 'profile_photos/$fileName';

        await supabaseClient.storage.from('avatars').uploadBinary(
              filePath,
              _imageBytes!,
              fileOptions: const FileOptions(
                cacheControl: '3600',
                upsert: false,
                contentType: 'image/jpeg',
              ),
            );

        finalFotoUrl =
            supabaseClient.storage.from('avatars').getPublicUrl(filePath);
      } else {
        finalFotoUrl = defaultUrl;
      }

      // Lakukan Registrasi
      final authResponse = await supabaseService.registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
        jurusan:
            _selectedJurusan.isNotEmpty ? _selectedJurusan : 'Belum dipilih',
        fotoProfile: finalFotoUrl,
      );

      if (mounted) {
        if (authResponse.session != null) {
          // Simpan data tambahan jika ada
          if (_fullNameController.text.isNotEmpty ||
              _nimController.text.isNotEmpty) {
            await supabaseClient.from('user_profiles').insert({
              'user_id': authResponse.user!.id,
              'full_name': _fullNameController.text,
              'nim': _nimController.text,
              'fakultas': _selectedFakultas,
              'created_at': DateTime.now().toIso8601String(),
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '🎉 Pendaftaran Berhasil!',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Selamat datang di UniCamp',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          // Navigasi ke Home
          await Future.delayed(1500.ms);
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        } else {
          _showEmailVerificationDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Terjadi kesalahan';
        String errorDetail = e.toString();

        if (errorDetail.contains('User already registered') ||
            errorDetail.contains('unique constraint')) {
          errorMessage = 'Gagal Mendaftar';
          errorDetail = 'Email atau Username sudah terdaftar.';
        } else if (errorDetail.contains('Storage')) {
          errorMessage = 'Gagal Upload Foto';
          errorDetail = 'Cek koneksi atau ukuran foto.';
        }

        _showErrorDialog(
            errorMessage, errorDetail.replaceAll('Exception:', '').trim());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mark_email_unread_rounded,
                  color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 12),
            Text(
              'Verifikasi Email',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Link verifikasi telah dikirim ke:',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email_outlined,
                      size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _emailController.text,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '📬 Silakan cek inbox atau spam folder email Anda untuk melanjutkan.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Oke, Saya Cek',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Header Gradient
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.9),
                      AppTheme.primaryColor,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    // Logo & Title
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_add_rounded,
                        size: 40,
                        color: AppTheme.primaryColor,
                      ),
                    ).animate().scale(delay: 200.ms),

                    const SizedBox(height: 20),

                    Text(
                      'Bergabung dengan UniCamp',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 300.ms)
                        .slideY(begin: 0.3, end: 0),

                    const SizedBox(height: 8),

                    Text(
                      'Daftarkan diri Anda untuk mulai menjelajahi kampus',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 400.ms),
                  ],
                ),
              ),

              // Form Section
              Transform.translate(
                offset: const Offset(0, -30),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Picture
                        Center(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey.shade100,
                                        border: Border.all(
                                          color: AppTheme.primaryColor,
                                          width: 3,
                                        ),
                                        image: _imageBytes != null
                                            ? DecorationImage(
                                                image:
                                                    MemoryImage(_imageBytes!),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: _imageBytes == null
                                          ? const Icon(
                                              Icons.person_add_rounded,
                                              size: 50,
                                              color: Colors.grey,
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.primaryColor
                                                  .withOpacity(0.3),
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _imageBytes != null
                                    ? 'Foto profil siap'
                                    : 'Upload foto profil',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: _imageBytes != null
                                      ? Colors.green
                                      : AppTheme.textSecondary,
                                  fontWeight: _imageBytes != null
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 500.ms),

                        const SizedBox(height: 32),

                        // Form Title
                        Text(
                          'Informasi Akun',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ).animate().fadeIn(delay: 600.ms),
                        const SizedBox(height: 4),
                        Text(
                          'Lengkapi data diri Anda',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ).animate().fadeIn(delay: 650.ms),

                        const SizedBox(height: 24),

                        // Email Field
                        _buildTextField(
                          label: 'Email',
                          hint: 'contoh@email.com',
                          controller: _emailController,
                          icon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email wajib diisi';
                            }

                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$')
                                .hasMatch(value)) {
                              return 'Format email tidak valid';
                            }

                            return null; // SEMUA email valid
                          },
                          delay: 700,
                        ),

                        const SizedBox(height: 20),

                        // Username Field
                        _buildTextField(
                          label: 'Username',
                          hint: 'minimal 3 karakter',
                          controller: _usernameController,
                          icon: Icons.person_rounded,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Username wajib diisi';
                            if (value.length < 3) return 'Minimal 3 karakter';
                            if (value.contains(' '))
                              return 'Tidak boleh ada spasi';
                            return null;
                          },
                          delay: 750,
                        ),

                        const SizedBox(height: 20),

                        // Fakultas Dropdown
                        _buildLabel('Fakultas', delay: 900),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedFakultas.isEmpty
                                  ? null
                                  : _selectedFakultas,
                              hint: Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Row(
                                  children: [
                                    const Icon(Icons.school_outlined,
                                        size: 20, color: Colors.grey),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Pilih Fakultas',
                                      style: GoogleFonts.inter(
                                          color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: '',
                                  enabled: false,
                                  child: Text('Pilih Fakultas'),
                                ),
                                ..._fakultasJurusan.keys.map((fakultas) {
                                  return DropdownMenuItem<String>(
                                    value: fakultas,
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor
                                                .withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                              Icons.school_rounded,
                                              size: 16,
                                              color: AppTheme.primaryColor),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            fakultas,
                                            style:
                                                GoogleFonts.inter(fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedFakultas = value ?? '';
                                  _selectedJurusan =
                                      ''; // Reset jurusan saat fakultas berubah
                                });
                              },
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down_rounded),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 950.ms)
                            .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 20),

                        // Jurusan Dropdown (hanya muncul jika fakultas dipilih)
                        if (_selectedFakultas.isNotEmpty)
                          _buildLabel('Program Studi', delay: 1000),
                        if (_selectedFakultas.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedJurusan.isEmpty
                                    ? null
                                    : _selectedJurusan,
                                hint: Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.menu_book_outlined,
                                          size: 20, color: Colors.grey),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Pilih Program Studi',
                                        style: GoogleFonts.inter(
                                            color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: '',
                                    enabled: false,
                                    child: Text('Pilih Program Studi'),
                                  ),
                                  ..._fakultasJurusan[_selectedFakultas]!
                                      .map((jurusan) {
                                    return DropdownMenuItem<String>(
                                      value: jurusan,
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.green.withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                                Icons.book_rounded,
                                                size: 16,
                                                color: Colors.green),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              jurusan,
                                              style: GoogleFonts.inter(
                                                  fontSize: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedJurusan = value ?? '';
                                  });
                                },
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down_rounded),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 1050.ms)
                              .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 20),

                        // Password Field
                        _buildTextField(
                          label: 'Password',
                          hint: 'Minimal 6 karakter',
                          controller: _passwordController,
                          icon: Icons.lock_rounded,
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onToggleVisibility: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Password wajib diisi';
                            if (value.length < 6) return 'Minimal 6 karakter';
                            return null;
                          },
                          delay: 1100,
                        ),

                        const SizedBox(height: 20),

                        // Confirm Password Field
                        _buildTextField(
                          label: 'Konfirmasi Password',
                          hint: 'Ketik ulang password',
                          controller: _confirmPasswordController,
                          icon: Icons.lock_reset_rounded,
                          isPassword: true,
                          obscureText: _obscureConfirmPassword,
                          onToggleVisibility: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          validator: (value) {
                            if (value != _passwordController.text)
                              return 'Password tidak cocok';
                            return null;
                          },
                          delay: 1150,
                        ),

                        const SizedBox(height: 28),

                        // Terms and Conditions
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  color: Colors.blue, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dengan mendaftar, Anda menyetujui:',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '• Syarat & Ketentuan layanan\n• Kebijakan Privasi data\n• Kode etik mahasiswa UIN SGD',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 1200.ms),

                        const SizedBox(height: 32),

                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (!_isLoading)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Daftar Sekarang',
                                        style: GoogleFonts.inter(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_rounded,
                                          size: 20),
                                    ],
                                  ),
                                if (_isLoading)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Membuat Akun...',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 1250.ms)
                            .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 24),

                        // Login Link
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Sudah punya akun? ',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const LoginScreen()),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Masuk di sini',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 1300.ms),

                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {int delay = 0}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.2, end: 0);
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Function()? onToggleVisibility,
    String? Function(String?)? validator,
    int delay = 0,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 22,
              ),
            ),
            suffixIcon: isPassword && onToggleVisibility != null
                ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: Colors.grey.shade500,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: validator,
        ),
      ],
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.2, end: 0);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _fullNameController.dispose();
    _nimController.dispose();
    super.dispose();
  }
}

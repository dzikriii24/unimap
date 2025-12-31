import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicamp/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  late TextEditingController _usernameController;
  
  String? _selectedFakultas;
  String? _selectedJurusan;
  
  // Map Fakultas dan Jurusan lengkap UIN SGD Bandung
  final Map<String, List<String>> _fakultasJurusan = {
    'Fakultas Ushuluddin': [
      'Ilmu Al-Quran dan Tafsir (IAT)',
      'Tafsir Hadis (TH)',
      'Aqidah dan Filsafat Islam (AFI)',
      'Belum dipilih',
    ],
    'Fakultas Tarbiyah dan Keguruan': [
      'Pendidikan Agama Islam (PAI)',
      'Pendidikan Guru Madrasah Ibtidaiyah (PGMI)',
      'Pendidikan Bahasa Arab (PBA)',
      'Manajemen Pendidikan Islam (MPI)',
      'Pendidikan Islam Anak Usia Dini (PIAUD)',
      'Belum dipilih',
    ],
    'Fakultas Syariah dan Hukum': [
      'Hukum Keluarga Islam (HKI)',
      'Hukum Ekonomi Syariah (HES)',
      'Hukum Tata Negara (HTN)',
      'Hukum Pidana Islam (HPI)',
      'Belum dipilih',
    ],
    'Fakultas Dakwah dan Komunikasi': [
      'Komunikasi dan Penyiaran Islam (KPI)',
      'Bimbingan dan Konseling Islam (BKI)',
      'Pengembangan Masyarakat Islam (PMI)',
      'Manajemen Dakwah (MD)',
      'Belum dipilih',
    ],
    'Fakultas Adab dan Humaniora': [
      'Sejarah dan Peradaban Islam (SPI)',
      'Bahasa dan Sastra Arab (BSA)',
      'Ilmu Perpustakaan dan Informasi Islam (IPII)',
      'Belum dipilih',
    ],
    'Fakultas Psikologi': [
      'Psikologi',
      'Psikologi Islam',
      'Belum dipilih',
    ],
    'Fakultas Sains dan Teknologi': [
      'Matematika',
      'Fisika',
      'Kimia',
      'Biologi',
      'Teknik Informatika',
      'Sistem Informasi',
      'Belum dipilih',
    ],
    'Fakultas Ekonomi dan Bisnis Islam': [
      'Ekonomi Syariah',
      'Perbankan Syariah',
      'Akuntansi Syariah',
      'Manajemen',
      'Belum dipilih',
    ],
    'Fakultas Kedokteran': [
      'Pendidikan Dokter',
      'Ilmu Keperawatan',
      'Belum dipilih',
    ],
    'Fakultas Ilmu Sosial dan Ilmu Politik': [
      'Sosiologi',
      'Ilmu Politik',
      'Hubungan Internasional',
      'Belum dipilih',
    ],
  };

  XFile? _imageFile;
  Uint8List? _imageBytes; 
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.userData['username']);
    
    // Ekstrak fakultas dan jurusan dari data user
    String currentJurusan = widget.userData['jurusan'] ?? 'Belum dipilih';
    
    // Cari fakultas berdasarkan jurusan yang dipilih
    for (var entry in _fakultasJurusan.entries) {
      if (entry.value.contains(currentJurusan)) {
        _selectedFakultas = entry.key;
        _selectedJurusan = currentJurusan;
        break;
      }
    }
    
    // Jika tidak ditemukan, set default
    if (_selectedFakultas == null || _selectedJurusan == null) {
      _selectedFakultas = 'Fakultas Sains dan Teknologi';
      _selectedJurusan = 'Belum dipilih';
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
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
        _imageFile = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = _supabase.auth.currentUser!.id;
      String photoUrl = widget.userData['foto_profile'] ?? '';

      // 1. Upload Foto
      if (_imageFile != null && _imageBytes != null) {
        final fileExt = _imageFile!.name.split('.').last;
        final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final filePath = 'profile_photos/$fileName';

        await _supabase.storage.from('avatars').uploadBinary(
          filePath,
          _imageBytes!,
          fileOptions: const FileOptions(
            upsert: true, 
            contentType: 'image/jpeg',
            cacheControl: '3600',
          ),
        );

        photoUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);
      }

      // 2. Update Database
      await _supabase.from('users_001').update({
        'username': _usernameController.text.trim(),
        'jurusan': _selectedJurusan,
        'foto_profile': photoUrl,
      }).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Profil diperbarui!',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Perubahan berhasil disimpan',
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
            duration: const Duration(seconds: 2),
          ),
        );
        
        await Future.delayed(1500.ms);
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error Update: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Gagal memperbarui. Coba lagi.',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPhotoUrl = widget.userData['foto_profile'] ?? 
        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80';

    // Image provider logic
    ImageProvider imageProvider;
    if (_imageBytes != null) {
      imageProvider = MemoryImage(_imageBytes!);
    } else {
      imageProvider = NetworkImage(currentPhotoUrl);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.1),
                      Colors.white,
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Edit Profil",
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Form Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Profile Picture Section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Foto Profil",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Stack(
                              children: [
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.primaryColor.withOpacity(0.2),
                                      width: 4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(70),
                                    child: Image(
                                      image: imageProvider,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _pickImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 4,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primaryColor.withOpacity(0.3),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Ketuk ikon kamera untuk mengganti foto",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_imageBytes != null)
                              Text(
                                "✓ Foto baru dipilih",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 32),

                      // Username Section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Username",
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                hintText: "Masukkan username baru",
                                hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(12),
                                  child: const Icon(
                                    Icons.alternate_email_rounded,
                                    color: AppTheme.primaryColor,
                                    size: 22,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryColor,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              style: GoogleFonts.inter(fontSize: 15),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Username tidak boleh kosong";
                                }
                                if (value.length < 3) {
                                  return "Minimal 3 karakter";
                                }
                                if (value.contains(' ')) {
                                  return "Tidak boleh mengandung spasi";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "⚠️ Username ini akan digunakan untuk identitas di UniCamp",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 32),

                      // Jurusan Section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.school_rounded,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Program Studi",
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Fakultas Dropdown
                            _buildLabel("Fakultas"),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedFakultas,
                                  hint: Padding(
                                    padding: const EdgeInsets.only(left: 16),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.school_outlined, size: 20, color: Colors.grey),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Pilih Fakultas',
                                          style: GoogleFonts.inter(color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  items: _fakultasJurusan.keys.map((fakultas) {
                                    return DropdownMenuItem<String>(
                                      value: fakultas,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.school_rounded, size: 18, color: Colors.blue),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                fakultas,
                                                style: GoogleFonts.inter(fontSize: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedFakultas = value;
                                      _selectedJurusan = 'Belum dipilih'; // Reset jurusan
                                    });
                                  },
                                  isExpanded: true,
                                  icon: const Icon(Icons.arrow_drop_down_rounded),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Jurusan Dropdown
                            _buildLabel("Program Studi"),
                            if (_selectedFakultas != null && _selectedFakultas!.isNotEmpty)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedJurusan,
                                    hint: Padding(
                                      padding: const EdgeInsets.only(left: 16),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.menu_book_outlined, size: 20, color: Colors.grey),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Pilih Program Studi',
                                            style: GoogleFonts.inter(color: Colors.grey.shade500),
                                          ),
                                        ],
                                      ),
                                    ),
                                    items: _fakultasJurusan[_selectedFakultas]!.map((jurusan) {
                                      return DropdownMenuItem<String>(
                                        value: jurusan,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.book_rounded, size: 18, color: Colors.green),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  jurusan,
                                                  style: GoogleFonts.inter(fontSize: 14),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedJurusan = value;
                                      });
                                    },
                                    isExpanded: true,
                                    icon: const Icon(Icons.arrow_drop_down_rounded),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 40),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
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
                                    const Icon(Icons.save_rounded, size: 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Simpan Perubahan",
                                      style: GoogleFonts.inter(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
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
                                      "Menyimpan...",
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
                      ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 20),

                      // Info Text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Hanya foto, username, dan program studi yang dapat diubah",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}
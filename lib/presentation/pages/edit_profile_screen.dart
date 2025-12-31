import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unicamp/core/theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _jurusanController;
  
  bool _isLoading = false;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.userData['username']);
    _jurusanController = TextEditingController(text: widget.userData['jurusan']);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;
      String? photoUrl = widget.userData['foto_profile'];

      // 1. Upload Foto Baru (Jika ada)
      if (_imageFile != null) {
        final fileExt = _imageFile!.path.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId.$fileExt';
        final filePath = 'profile_photos/$fileName';
        
        await supabase.storage.from('avatars').upload(filePath, _imageFile!);
        photoUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
      }

      // 2. Update Database
      await supabase.from('users_001').update({
        'username': _usernameController.text.trim(),
        'jurusan': _jurusanController.text.trim(),
        'foto_profile': photoUrl,
      }).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil diperbarui!')));
        Navigator.pop(context, true); // Balik ke profile dan refresh
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profil")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Foto Profil
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _imageFile != null 
                          ? FileImage(_imageFile!) 
                          : NetworkImage(widget.userData['foto_profile'] ?? '') as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.primaryColor,
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _jurusanController,
                decoration: const InputDecoration(labelText: 'Jurusan', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Simpan Perubahan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
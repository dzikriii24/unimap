import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unicamp/core/services/supabase_service.dart';
import 'package:unicamp/core/theme/app_theme.dart';
import 'package:unicamp/features/auth/presentation/pages/register_screen.dart';
import 'package:unicamp/features/auth/presentation/pages/home_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = SupabaseService();
      
      final response = await supabase.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null && mounted) {
        final userId = response.user!.id;
        final profile = await supabase.getUserProfile(userId);

        if (profile == null) {
          await supabase.client.from('users_001').insert({
            'id': userId,
            'email': response.user!.email!,
            'username': response.user!.email!.split('@')[0],
            'jurusan': 'Belum dipilih',
            'foto_profile': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde',
          });
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Login gagal';
        String errorDetail = e.toString();

        if (errorDetail.contains('Invalid login credentials')) {
          errorMessage = 'Email atau password salah';
          errorDetail = 'Periksa kembali data login Anda.';
        } else if (errorDetail.contains('Email not confirmed')) {
          errorMessage = 'Email belum diverifikasi';
          errorDetail = 'Silakan cek inbox email Anda.';
        } else if (errorDetail.contains('429')) {
          errorMessage = 'Terlalu banyak percobaan';
          errorDetail = 'Tunggu beberapa saat sebelum mencoba lagi.';
        } else if (errorDetail.contains('SocketException') || errorDetail.contains('Network')) {
           errorMessage = 'Masalah Koneksi';
           errorDetail = 'Pastikan internet Anda lancar.';
        }

        _showErrorDialog(errorMessage, errorDetail);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
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
            fontSize: 14,
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              'Mengerti',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
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
              // Top section with gradient background
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
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
                    // Logo/Icon
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
                        Icons.lock_open_rounded,
                        size: 40,
                        color: AppTheme.primaryColor,
                      ),
                    ).animate().scale(delay: 200.ms),
                    
                    const SizedBox(height: 24),
                    
                    // Welcome text
                    Text(
                      'Selamat Datang',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Masuk ke akun UniCamp Anda',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w400,
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                    
                    // Stats
                    Container(
                      margin: const EdgeInsets.only(top: 32),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('1,000+', 'Pengguna'),
                          Container(
                            height: 20,
                            width: 1,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          _buildStatItem('50+', 'Fasilitas'),
                          Container(
                            height: 20,
                            width: 1,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          _buildStatItem('24/7', 'Akses'),
                        ],
                      ),
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.5, end: 0),
                  ],
                ),
              ),
              
              // Form Section
              Transform.translate(
                offset: const Offset(0, -30),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
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
                        // Header form
                        Text(
                          'Masuk Sekarang',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ).animate().fadeIn(delay: 600.ms),
                        
                        const SizedBox(height: 4),
                        
                        Text(
                          'Isi data untuk melanjutkan',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ).animate().fadeIn(delay: 700.ms),
                        
                        const SizedBox(height: 24),
                        
                        // Email Field
                        _buildTextField(
                          label: 'Email',
                          hint: 'contoh@email.com',
                          controller: _emailController,
                          icon: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Email wajib diisi';
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                          delay: 800,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Password Field
                        _buildTextField(
                          label: 'Password',
                          hint: 'Masukkan password Anda',
                          controller: _passwordController,
                          icon: Icons.lock_rounded,
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onToggleVisibility: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          suffixAction: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Password wajib diisi';
                            if (value.length < 6) return 'Password minimal 6 karakter';
                            return null;
                          },
                          delay: 900,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Remember me & Forgot password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Remember me
                            Row(
                              children: [
                                Transform.scale(
                                  scale: 0.9,
                                  child: AnimatedContainer(
                                    duration: 200.ms,
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      color: _rememberMe ? AppTheme.primaryColor : Colors.white,
                                      border: Border.all(
                                        color: _rememberMe ? AppTheme.primaryColor : Colors.grey.shade400,
                                        width: 2,
                                      ),
                                    ),
                                    child: _rememberMe
                                        ? const Icon(
                                            Icons.check_rounded,
                                            size: 14,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _rememberMe = !_rememberMe;
                                    });
                                  },
                                  child: Text(
                                    'Ingat saya',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            // Forgot password
                            TextButton(
                              onPressed: () {
                                // TODO: Implement forgot password
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                              ),
                              child: Text(
                                'Lupa Password?',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 1000.ms),
                        
                        const SizedBox(height: 30),
                        
                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (!_isLoading)
                                  Text(
                                    'Masuk ke Akun',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ).animate().fadeIn(),
                                
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
                                        'Memproses...',
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
                        ).animate().fadeIn(delay: 1100.ms).slideY(begin: 0.2, end: 0),
                        
                      ],
                    ),
                  ),
                ),
              ),
              
              // Register Section
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Belum punya akun? ',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Daftar Sekarang',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    bool suffixAction = false,
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
            suffixIcon: isPassword && suffixAction
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
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: validator,
        ),
      ],
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.2, end: 0);
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required Function() onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
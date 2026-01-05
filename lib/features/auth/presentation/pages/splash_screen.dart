import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unicamp/features/auth/presentation/pages/onboarding_screen.dart';
import 'package:unicamp/features/auth/presentation/pages/home_screen.dart';
import 'package:unicamp/core/services/supabase_service.dart';
import 'package:unicamp/core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _navigateToNext();
  }

  void _initAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000), // Durasi sedikit diperpanjang biar smooth
      vsync: this,
    );

    // Animasi Scale (Logo membesar dengan efek bounce)
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Animasi Fade (Teks muncul perlahan)
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    // Animasi Slide (Teks naik sedikit dari bawah)
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));

    final supabase = SupabaseService();
    // Cek session, bukan cuma loggedIn flag (lebih akurat)
    final session = supabase.client.auth.currentSession;
    final isLoggedIn = session != null;

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              isLoggedIn ? const HomeScreen() : const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background Putih Bersih (Kontras Maksimal)
      body: Stack(
        fit: StackFit.expand,
        children: [
          // --- BACKGROUND DECORATION (Lingkaran halus di pojok) ---
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(0.05), // Sangat transparan
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.05), // Aksen biru muda
              ),
            ),
          ),

          // --- MAIN CONTENT ---
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. LOGO ANIMATION
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 180, // Ukuran Logo diperbesar agar dominan
                    height: 180,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08), // Shadow halus
                          blurRadius: 30,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/icons/logouni.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // 2. TEXT ANIMATION
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        // Nama Aplikasi
                        Text(
                          'UNICAMP',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryColor, // Warna Primer (Biru Tua/Ungu)
                            letterSpacing: 4.0, // Jarak antar huruf lebar (Elegan)
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Tagline
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 30, height: 2, color: Colors.redAccent), // Garis Hiasan
                            const SizedBox(width: 10),
                            Text(
                              'EXPLORE EVERY CORNER',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600, // Abu-abu tua
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(width: 30, height: 2, color: Colors.redAccent),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // 3. LOADING INDICATOR (Minimalis)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor.withOpacity(0.5)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- FOOTER COPYRIGHT ---
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Text(
                  'v1.0.0 • © 2025 UniCamp',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 
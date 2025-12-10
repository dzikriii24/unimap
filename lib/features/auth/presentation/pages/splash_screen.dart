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

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));
    
    final supabase = SupabaseService();
    final isLoggedIn = supabase.isLoggedIn;
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => isLoggedIn 
              ? const HomeScreen() 
              : const OnboardingScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo sementara
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.location_on,
                size: 60,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'UniCamp',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore Your Campus',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
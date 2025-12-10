import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unicamp/features/auth/presentation/pages/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Temukan Spot Terbaik',
      description: 'Cari ruang kuliah, kantin, WiFi, dan fasilitas kampus lainnya dengan mudah',
      icon: Icons.explore,
      color: Color(0xFF6366F1),
    ),
    OnboardingPage(
      title: 'Navigasi Mudah',
      description: 'Petunjuk arah ke lokasi yang kamu tuju di dalam kampus',
      icon: Icons.directions,
      color: Color(0xFF8B5CF6),
    ),
    OnboardingPage(
      title: 'Info Real-time',
      description: 'Dapatkan informasi terbaru tentang ketersediaan ruangan dan fasilitas',
      icon: Icons.info,
      color: Color(0xFF10B981),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: Text(
                  'Skip',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
            
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return OnboardingPageWidget(page: _pages[index]);
                },
              ),
            ),
            
            // Dots indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? AppTheme.primaryColor
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    }
                  },
                  child: Text(
                    _currentPage == _pages.length - 1 
                        ? 'Get Started' 
                        : 'Next',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;

  const OnboardingPageWidget({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: page.color,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
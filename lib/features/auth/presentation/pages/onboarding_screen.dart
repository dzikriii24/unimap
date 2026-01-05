import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unicamp/core/theme/app_theme.dart';
import 'package:unicamp/features/auth/presentation/pages/login_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    const OnboardingPage(
      title: 'Temukan Spot',
      description: 'Cari ruang kuliah, kantin, WiFi, dan fasilitas kampus lainnya dengan mudah dan cepat',
      icon: Icons.explore_rounded,
      color: Color(0xFF6366F1),
      gradient: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      image: '📍',
    ),
    const OnboardingPage(
      title: 'Navigasi Mudah',
      description: 'Petunjuk arah langkah demi langkah menuju lokasi yang kamu tuju di dalam kampus',
      icon: Icons.directions_rounded,
      color: Color(0xFF10B981),
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
      image: '🗺️',
    ),
    const OnboardingPage(
      title: 'Info Real-time',
      description: 'Dapatkan informasi terbaru tentang ketersediaan ruangan, fasilitas, dan acara kampus',
      icon: Icons.info_rounded,
      color: Color(0xFFF59E0B),
      gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
      image: '⚡',
    ),
    const OnboardingPage(
      title: 'Mulai Jelajahi',
      description: 'Bergabung dengan komunitas kampus dan nikmati kemudahan navigasi di lingkungan kampus',
      icon: Icons.rocket_launch_rounded,
      color: Color(0xFFEC4899),
      gradient: [Color(0xFFEC4899), Color(0xFFBE185D)],
      image: '🚀',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            AnimatedOpacity(
              opacity: _currentPage == _pages.length - 1 ? 0 : 1,
              duration: 300.ms,
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 16),
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                    ),
                    child: Text(
                      'Lewati',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                ),
              ),
            ),
            
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: 300.ms,
                    width: _currentPage == index ? 32 : 8,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: _currentPage == index
                          ? _pages[index].color
                          : Colors.grey.shade300,
                    ),
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
                  return OnboardingPageWidget(
                    page: _pages[index],
                    pageIndex: index,
                    currentPage: _currentPage,
                  );
                },
              ),
            ),
            
            // Dots indicator with numbers
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...List.generate(
                    _pages.length,
                    (index) => GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: 300.ms,
                          curve: Curves.easeInOut,
                        );
                      },
                      child: AnimatedContainer(
                        duration: 300.ms,
                        width: _currentPage == index ? 36 : 30,
                        height: _currentPage == index ? 36 : 30,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? _pages[index].color
                              : Colors.grey.shade100,
                          border: Border.all(
                            color: _currentPage == index
                                ? _pages[index].color
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.inter(
                              fontSize: _currentPage == index ? 14 : 12,
                              fontWeight: FontWeight.w600,
                              color: _currentPage == index
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().slideY(begin: 0.5, end: 0, delay: 200.ms),
            
            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
              child: AnimatedSwitcher(
                duration: 300.ms,
                child: _currentPage == _pages.length - 1
                    ? SizedBox(
                        key: const ValueKey('get_started'),
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pages[_currentPage].color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            shadowColor: _pages[_currentPage].color.withOpacity(0.3),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Mulai Sekarang',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      )
                    : Row(
                        key: const ValueKey('next'),
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textSecondary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                'Lewati',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _pageController.nextPage(
                                  duration: 300.ms,
                                  curve: Curves.easeInOut,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _pages[_currentPage].color,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Lanjut',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ).animate().slideY(begin: 0.5, end: 0, delay: 200.ms),
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
  final List<Color> gradient;
  final String image;

  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.gradient,
    required this.image,
  });
}

class OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;
  final int pageIndex;
  final int currentPage;

  const OnboardingPageWidget({
    super.key,
    required this.page,
    required this.pageIndex,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentPage = pageIndex == currentPage;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated illustration container
          AnimatedContainer(
            duration: 600.ms,
            curve: Curves.fastEaseInToSlowEaseOut,
            width: isCurrentPage ? 280 : 240,
            height: isCurrentPage ? 280 : 240,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: page.gradient,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: page.color.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 30,
                  right: 30,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                
                // Icon and emoji
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Emoji
                      Text(
                        page.image,
                        style: const TextStyle(fontSize: 64),
                      ).animate(
                        delay: 300.ms,
                      ).scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          page.icon,
                          size: 32,
                          color: Colors.white,
                        ),
                      ).animate(
                        delay: 500.ms,
                      ).fadeIn().scale(
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate(
            delay: 200.ms,
          ).slideY(
            begin: 0.3,
            end: 0,
            duration: 600.ms,
            curve: Curves.easeOutBack,
          ),
          
          const SizedBox(height: 40),
          
          // Title
          AnimatedOpacity(
            duration: 300.ms,
            opacity: isCurrentPage ? 1 : 0.3,
            child: Text(
              page.title,
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: page.color,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ).animate(
              delay: 400.ms,
            ).fadeIn().slideY(
              begin: 0.2,
              end: 0,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Description
          AnimatedOpacity(
            duration: 300.ms,
            opacity: isCurrentPage ? 1 : 0.3,
            child: Text(
              page.description,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppTheme.textSecondary,
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ).animate(
              delay: 500.ms,
            ).fadeIn().slideY(
              begin: 0.2,
              end: 0,
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Decorative elements
          if (isCurrentPage) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: page.color.withOpacity(0.5),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 6,
                  decoration: BoxDecoration(
                    color: page.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: page.color.withOpacity(0.5),
                  ),
                ),
              ],
            ).animate(delay: 600.ms).fadeIn(),
          ],
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unicamp/core/services/supabase_service.dart';
import 'package:unicamp/core/theme/app_theme.dart';
import 'package:unicamp/core/providers/spot_provider.dart';

// ✅ JANGAN LUPA IMPORT HALAMANNYA
import 'package:unicamp/features/auth/presentation/pages/splash_screen.dart';
import 'package:unicamp/features/auth/presentation/pages/home_screen.dart'; 
import 'package:unicamp/features/auth/presentation/pages/login_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SpotProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniCamp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      
      // Halaman awal
      home: const SplashScreen(),

      // ✅ TAMBAHKAN BAGIAN INI (ROUTES)
      // Ini memberitahu Flutter: "Kalau ada yang minta ke '/home', buka HomeScreen ya!"
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        // Tambahkan route lain jika perlu
      },
    );
  }
}
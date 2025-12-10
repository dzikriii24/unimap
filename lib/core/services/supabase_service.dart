import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  // Hardcode credentials (temporary untuk development)
  static const String supabaseUrl = 'https://gyljffqwaahfiagstjzh.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd5bGpmZnF3YWFoZmlhZ3N0anpoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUzNDk3MzYsImV4cCI6MjA4MDkyNTczNn0.qwwRvwNXgA7Oo8wa_6FATMJpFV5KsARCNE3AIlmnss8';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      // Hapus authCallbackUrlHostname karena sudah deprecated
      // Tambah redirectUrl untuk web
      debug: true,
    );
  }

  SupabaseClient get client => Supabase.instance.client;

  User? get currentUser => client.auth.currentUser;

  bool get isLoggedIn => currentUser != null;
}
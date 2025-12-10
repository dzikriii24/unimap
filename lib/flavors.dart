abstract class FlavorConfig {
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  
  static String get supabaseUrl {
    if (isProduction) {
      return const String.fromEnvironment('SUPABASE_URL');
    } else {
      return 'https://YOUR_PROJECT_ID.supabase.co';
    }
  }
  
  static String get supabaseAnonKey {
    if (isProduction) {
      return const String.fromEnvironment('SUPABASE_ANON_KEY');
    } else {
      return 'YOUR_ANON_KEY';
    }
  }
}
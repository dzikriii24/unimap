abstract class FlavorConfig {
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  
  static String get supabaseUrl {
    if (isProduction) {
      return const String.fromEnvironment('https://gyljffqwaahfiagstjzh.supabase.co');
    } else {
      return 'https://gyljffqwaahfiagstjzh.supabase.co';
    }
  }
  
  static String get supabaseAnonKey {
    if (isProduction) {
      return const String.fromEnvironment('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd5bGpmZnF3YWFoZmlhZ3N0anpoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUzNDk3MzYsImV4cCI6MjA4MDkyNTczNn0.qwwRvwNXgA7Oo8wa_6FATMJpFV5KsARCNE3AIlmnss8');
    } else {
      return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd5bGpmZnF3YWFoZmlhZ3N0anpoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUzNDk3MzYsImV4cCI6MjA4MDkyNTczNn0.qwwRvwNXgA7Oo8wa_6FATMJpFV5KsARCNE3AIlmnss8';
    }
  }
}
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://tiolfjznymzmvatsmekp.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRpb2xmanpueW16bXZhdHNtZWtwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkwNTkyNjEsImV4cCI6MjA4NDYzNTI2MX0.C5XPnyWwdNVgl1tcQCPXPg9x2x0Za_Wi5c_zcWW1RBk';

  // Google OAuth - Google Cloud Consoleで取得
  // Web Client ID: Supabaseダッシュボードにも設定が必要
  static const String googleWebClientId = '1023118026968-horqv5f7b6k836n196u00l4bb6q53e8j.apps.googleusercontent.com';
  // iOS Client ID: iOSアプリ用
  static const String googleIosClientId = '1023118026968-2e8i58klhi4d6oq5b8r368jjc6ggte72.apps.googleusercontent.com';
}

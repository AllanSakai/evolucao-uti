import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static var initializationFailed = false;

  static bool get hasKeys => url.isNotEmpty && anonKey.isNotEmpty;

  static bool get isConfigured => hasKeys && !initializationFailed;

  static SupabaseClient? get client =>
      isConfigured ? Supabase.instance.client : null;
}

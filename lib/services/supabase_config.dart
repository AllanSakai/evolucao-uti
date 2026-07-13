import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const adminUsername = 'admin';
  static const adminEmail = String.fromEnvironment(
    'ADMIN_EMAIL',
    defaultValue: 'allansakai@gmail.com',
  );
  static var initializationFailed = false;

  static bool get hasKeys => url.isNotEmpty && anonKey.isNotEmpty;

  static bool get isConfigured => hasKeys && !initializationFailed;

  static SupabaseClient? get client =>
      isConfigured ? Supabase.instance.client : null;

  static bool get isAdminSignedIn {
    final user = client?.auth.currentUser;
    if (user == null) return false;
    final role = user.appMetadata['role'];
    return role == 'admin' ||
        user.email?.toLowerCase() == adminEmail.toLowerCase();
  }
}

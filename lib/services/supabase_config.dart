import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const privilegedEmailsRaw =
      String.fromEnvironment('PRIVILEGED_EMAILS');
  static var initializationFailed = false;

  static bool get hasKeys => url.isNotEmpty && anonKey.isNotEmpty;

  static bool get isConfigured => hasKeys && !initializationFailed;

  static SupabaseClient? get client =>
      isConfigured ? Supabase.instance.client : null;

  static bool get isPrivilegedUser {
    final email = client?.auth.currentUser?.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) return false;
    return privilegedEmails.contains(email);
  }

  static Set<String> get privilegedEmails => privilegedEmailsRaw
      .split(RegExp(r'[,;]'))
      .map((email) => email.trim().toLowerCase())
      .where((email) => email.isNotEmpty)
      .toSet();
}

import 'package:shared_preferences/shared_preferences.dart';

import 'supabase_config.dart';

class WardAccessService {
  const WardAccessService._();

  static const instance = WardAccessService._();

  Future<String?> assumedUnitCode() async {
    final userId = SupabaseConfig.client?.auth.currentUser?.id;
    if (userId == null) return null;
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_key(userId));
  }

  Future<void> assumeUnit(String unitCode) async {
    final userId = SupabaseConfig.client?.auth.currentUser?.id;
    if (userId == null) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key(userId), unitCode);
  }

  Future<void> clearCurrentUser() async {
    final userId = SupabaseConfig.client?.auth.currentUser?.id;
    if (userId == null) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key(userId));
  }

  static String _key(String userId) => 'evolucao_uti_assumed_unit_$userId';
}

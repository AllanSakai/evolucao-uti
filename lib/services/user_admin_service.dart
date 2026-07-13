import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_user.dart';
import 'supabase_config.dart';

class UserAdminService {
  UserAdminService._();

  static final instance = UserAdminService._();

  Future<List<AdminUser>> listUsers() async {
    final data = await _invoke({'action': 'list'});
    final users = (data['users'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(AdminUser.fromJson)
        .toList();
    users.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return users;
  }

  Future<void> createUser({
    required String name,
    required String email,
    required String password,
  }) async {
    await _invoke({
      'action': 'create',
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    });
  }

  Future<void> updateUser({
    required String id,
    required String name,
    required String email,
    String? password,
  }) async {
    await _invoke({
      'action': 'update',
      'id': id,
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      if (password != null && password.isNotEmpty) 'password': password,
    });
  }

  Future<void> deleteUser(String id) async {
    await _invoke({'action': 'delete', 'id': id});
  }

  Future<Map<String, dynamic>> _invoke(Map<String, dynamic> body) async {
    final client = SupabaseConfig.client;
    final token = client?.auth.currentSession?.accessToken;
    if (client == null || token == null) {
      throw const UserAdminException('Sua sessão expirou. Entre novamente.');
    }

    try {
      final response = await client.functions.invoke(
        'manage-users',
        body: body,
        headers: {'Authorization': 'Bearer $token'},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on FunctionException catch (error) {
      final details = error.details;
      final message =
          details is Map ? details['message']?.toString() : details?.toString();
      throw UserAdminException(
        message?.isNotEmpty == true
            ? message!
            : 'Não foi possível concluir a operação.',
      );
    }
  }
}

class UserAdminException implements Exception {
  const UserAdminException(this.message);

  final String message;

  @override
  String toString() => message;
}

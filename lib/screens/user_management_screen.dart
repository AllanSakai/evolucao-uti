import 'package:flutter/material.dart';

import '../models/admin_user.dart';
import '../services/supabase_config.dart';
import '../services/user_admin_service.dart';
import '../widgets/theme_toggle_button.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<AdminUser> _users = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar usuários'),
        actions: const [ThemeToggleButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : () => _openEditor(),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Novo usuário'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }
    if (_users.isEmpty) {
      return const Center(child: Text('Nenhum usuário cadastrado.'));
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 96),
        itemCount: _users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) => _userCard(_users[index]),
      ),
    );
  }

  Widget _userCard(AdminUser user) {
    final colors = Theme.of(context).colorScheme;
    final isCurrentUser =
        SupabaseConfig.client?.auth.currentUser?.id == user.id;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
              child: Text(_initials(user)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name.isEmpty ? 'Nome não informado' : user.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isCurrentUser
                        ? 'Sua conta • acesso total'
                        : 'Criado em ${_formatDate(user.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Editar usuário',
              onPressed: () => _openEditor(user),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: isCurrentUser
                  ? 'A conta conectada não pode ser apagada'
                  : 'Apagar usuário',
              onPressed: isCurrentUser ? null : () => _confirmDelete(user),
              icon: const Icon(Icons.delete_outline),
              color: colors.error,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await UserAdminService.instance.listUsers();
      if (!mounted) return;
      setState(() => _users = users);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditor([AdminUser? user]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UserEditorDialog(user: user),
    );
    if (saved == true) await _loadUsers();
  }

  Future<void> _confirmDelete(AdminUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar usuário?'),
        content: Text(
          'A conta de ${user.name.isEmpty ? user.email : user.name} será '
          'apagada permanentemente, junto com os dados vinculados a ela. '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Apagar'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await UserAdminService.instance.deleteUser(user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário apagado.')),
      );
      await _loadUsers();
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  static String _initials(AdminUser user) {
    final parts = user.name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return user.email.isEmpty ? '?' : user.email[0].toUpperCase();
    }
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class UserEditorDialog extends StatefulWidget {
  const UserEditorDialog({this.user, super.key});

  final AdminUser? user;

  @override
  State<UserEditorDialog> createState() => _UserEditorDialogState();
}

class _UserEditorDialogState extends State<UserEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _saving = false;
  bool _showPassword = false;
  bool _submitted = false;

  bool get _editing => widget.user != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user?.name ?? '');
    _email = TextEditingController(text: widget.user?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editing ? 'Editar usuário' : 'Criar usuário'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: _submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: UserFormValidators.name,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'E-mail *',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: UserFormValidators.email,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: !_showPassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: _editing ? 'Nova senha' : 'Senha *',
                    helperText: _editing
                        ? 'Deixe em branco para manter a senha atual.'
                        : 'Use pelo menos 8 caracteres.',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip:
                          _showPassword ? 'Ocultar senha' : 'Mostrar senha',
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                      icon: Icon(_showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                    ),
                  ),
                  validator: (value) => UserFormValidators.password(
                    value,
                    required: !_editing,
                  ),
                  onChanged: (_) {
                    if (_submitted) _formKey.currentState?.validate();
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmPassword,
                  obscureText: !_showPassword,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText:
                        _editing ? 'Confirmar nova senha' : 'Confirmar senha *',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                  ),
                  validator: (value) => UserFormValidators.confirmPassword(
                    value,
                    password: _password.text,
                    required: !_editing,
                  ),
                  onFieldSubmitted: (_) => _save(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Salvando...' : 'Salvar'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      if (_editing) {
        await UserAdminService.instance.updateUser(
          id: widget.user!.id,
          name: _name.text,
          email: _email.text,
          password: _password.text,
        );
      } else {
        await UserAdminService.instance.createUser(
          name: _name.text,
          email: _email.text,
          password: _password.text,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class UserFormValidators {
  const UserFormValidators._();

  static String? name(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return 'Informe o nome completo.';
    if (normalized.length < 3) {
      return 'O nome deve ter pelo menos 3 caracteres.';
    }
    return null;
  }

  static String? email(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return 'Informe o e-mail.';
    final valid = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized);
    if (!valid) return 'Informe um e-mail válido.';
    return null;
  }

  static String? password(String? value, {required bool required}) {
    final password = value ?? '';
    if (password.isEmpty && !required) return null;
    if (password.isEmpty) return 'Informe a senha.';
    if (password.length < 8) return 'A senha deve ter pelo menos 8 caracteres.';
    return null;
  }

  static String? confirmPassword(
    String? value, {
    required String password,
    required bool required,
  }) {
    final confirmation = value ?? '';
    if (password.isEmpty && confirmation.isEmpty && !required) return null;
    if (confirmation.isEmpty) return 'Confirme a senha.';
    if (confirmation != password) return 'As senhas não são iguais.';
    return null;
  }
}

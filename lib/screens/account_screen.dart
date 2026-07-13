import 'package:flutter/material.dart';

import '../data/icu_units_data.dart';
import '../services/supabase_config.dart';
import '../services/ward_access_service.dart';
import '../widgets/theme_toggle_button.dart';
import 'user_management_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configured = SupabaseConfig.isConfigured;
    final hasKeys = SupabaseConfig.hasKeys;
    final user = SupabaseConfig.client?.auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conta e sincronização'),
        actions: const [ThemeToggleButton()],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          configured
                              ? 'Supabase configurado'
                              : hasKeys
                                  ? 'Supabase com erro de inicialização'
                                  : 'Supabase ainda não configurado',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          configured
                              ? 'Ao entrar, o app carrega e salva automaticamente seus dados do Supabase.'
                              : hasKeys
                                  ? 'As chaves foram recebidas, mas o Supabase não iniciou. Confira as secrets e publique novamente.'
                                  : 'O app continua funcionando localmente. Depois que você criar o projeto no Supabase, rode o app com SUPABASE_URL e SUPABASE_ANON_KEY.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!configured)
                  const _SetupHelp()
                else if (user != null)
                  _SignedIn(email: user.email ?? 'Conta conectada')
                else
                  _loginForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _loginForm() => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loading ? null : _signIn,
                child: Text(_loading ? 'Entrando...' : 'Entrar'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _loading ? null : _signUp,
                child: const Text('Criar conta'),
              ),
            ],
          ),
        ),
      );

  Future<void> _signIn() async {
    await _authAction(() async {
      await SupabaseConfig.client!.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
    }, 'Login realizado.', afterSuccess: _promptAssumedUnit);
  }

  Future<void> _signUp() async {
    await _authAction(() async {
      await SupabaseConfig.client!.auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
        emailRedirectTo: _emailRedirectUrl(),
      );
    }, 'Conta criada. Se o Supabase pedir confirmação, confirme pelo e-mail.');
  }

  String _emailRedirectUrl() {
    final uri = Uri.base;
    var path = uri.path;
    if (!path.endsWith('/')) {
      final lastSlash = path.lastIndexOf('/');
      path = lastSlash < 0 ? '/' : path.substring(0, lastSlash + 1);
    }
    return uri.replace(path: path, query: '', fragment: '').toString();
  }

  Future<void> _authAction(
      Future<void> Function() action, String successMessage,
      {Future<void> Function()? afterSuccess}) async {
    setState(() => _loading = true);
    try {
      await action();
      if (!mounted) return;
      await afterSuccess?.call();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $error')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _promptAssumedUnit() async {
    if (SupabaseConfig.isPrivilegedUser) return;
    final assumed = await WardAccessService.instance.assumedUnitCode();
    if (!mounted || assumed != null) return;
    final selected = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Qual ala você irá assumir?'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final unit in icuUnits)
                ListTile(
                  leading: Icon(
                    assumed == unit.code
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(unit.name),
                  subtitle: Text('${unit.beds.length} boxes'),
                  onTap: () => Navigator.of(context).pop(unit.code),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected == null) return;
    await WardAccessService.instance.assumeUnit(selected);
  }
}

class _SignedIn extends StatelessWidget {
  const _SignedIn({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_done_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text('Conectado como $email')),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Sincronização automática ativa',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            if (SupabaseConfig.isPrivilegedUser) ...[
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Administração',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const UserManagementScreen(),
                  ),
                ),
                icon: const Icon(Icons.manage_accounts_outlined),
                label: const Text('Gerenciar usuários'),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: () async {
                await WardAccessService.instance.clearCurrentUser();
                await SupabaseConfig.client!.auth.signOut();
                if (context.mounted) Navigator.of(context).pop();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sair'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupHelp extends StatelessWidget {
  const _SetupHelp();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Depois que criarmos o projeto no Supabase, você vai copiar a Project URL e a anon public key. Eu deixei o app pronto para receber essas duas informações por dart-define.',
        ),
      ),
    );
  }
}

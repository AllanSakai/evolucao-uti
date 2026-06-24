import 'package:flutter/material.dart';

import '../services/supabase_config.dart';

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
    final user = SupabaseConfig.client?.auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Conta e sincronizacao')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          configured
                              ? 'Supabase configurado'
                              : 'Supabase ainda nao configurado',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          configured
                              ? 'Ao entrar, seus preenchimentos serao sincronizados entre celular e computador.'
                              : 'O app continua funcionando localmente. Depois que voce criar o projeto no Supabase, rode o app com SUPABASE_URL e SUPABASE_ANON_KEY.',
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
          padding: const EdgeInsets.all(16),
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
    }, 'Login realizado.');
  }

  Future<void> _signUp() async {
    await _authAction(() async {
      await SupabaseConfig.client!.auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
      );
    }, 'Conta criada. Se o Supabase pedir confirmacao, confirme pelo e-mail.');
  }

  Future<void> _authAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => _loading = true);
    try {
      await action();
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
}

class _SignedIn extends StatelessWidget {
  const _SignedIn({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Conectado como $email'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
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
          'Depois que criarmos o projeto no Supabase, voce vai copiar a Project URL e a anon public key. Eu deixei o app pronto para receber essas duas informacoes por dart-define.',
        ),
      ),
    );
  }
}

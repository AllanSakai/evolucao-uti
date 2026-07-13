import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_theme.dart';
import 'screens/icu_unit_selection_screen.dart';
import 'screens/login_screen.dart';
import 'services/app_settings_controller.dart';
import 'services/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (SupabaseConfig.hasKeys) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
    } catch (_) {
      SupabaseConfig.initializationFailed = true;
    }
  }
  final settings = await AppSettingsController.load();
  runApp(EvolucaoUtiApp(settings: settings));
}

class EvolucaoUtiApp extends StatelessWidget {
  const EvolucaoUtiApp({required this.settings, super.key});

  final AppSettingsController settings;

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      controller: settings,
      child: AnimatedBuilder(
        animation: settings,
        builder: (context, _) => MaterialApp(
          title: 'AuxiliarUTI',
          debugShowCheckedModeBanner: false,
          theme: PassagemUtiTheme.light,
          darkTheme: PassagemUtiTheme.dark,
          themeMode: settings.themeMode,
          themeAnimationDuration: const Duration(milliseconds: 220),
          home: const _AuthGate(),
        ),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription =
        SupabaseConfig.client?.auth.onAuthStateChange.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isAdminSignedIn) return const LoginScreen();
    return const IcuUnitSelectionScreen();
  }
}

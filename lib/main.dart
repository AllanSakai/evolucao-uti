import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_theme.dart';
import 'screens/icu_unit_selection_screen.dart';
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
  runApp(const EvolucaoUtiApp());
}

class EvolucaoUtiApp extends StatelessWidget {
  const EvolucaoUtiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AuxiliarUTI',
      debugShowCheckedModeBanner: false,
      theme: PassagemUtiTheme.light,
      darkTheme: PassagemUtiTheme.dark,
      themeMode: ThemeMode.system,
      home: const IcuUnitSelectionScreen(),
    );
  }
}

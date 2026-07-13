import 'package:flutter/material.dart';

import '../services/app_settings_controller.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: isDark ? 'Usar tema claro' : 'Usar tema escuro',
      onPressed: () => AppSettingsScope.of(context).toggleTheme(
        Theme.of(context).brightness,
      ),
      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
    );
  }
}

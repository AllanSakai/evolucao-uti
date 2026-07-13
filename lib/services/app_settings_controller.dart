import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController._(this._preferences, this._themeMode);

  static const _themeModeKey = 'app_theme_mode';

  final SharedPreferences _preferences;
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  static Future<AppSettingsController> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedMode = preferences.getString(_themeModeKey);
    final themeMode = switch (savedMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return AppSettingsController._(preferences, themeMode);
  }

  Future<void> toggleTheme(Brightness currentBrightness) async {
    _themeMode =
        currentBrightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    await _preferences.setString(_themeModeKey, _themeMode.name);
  }
}

class AppSettingsScope extends InheritedNotifier<AppSettingsController> {
  const AppSettingsScope({
    required AppSettingsController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppSettingsController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'AppSettingsScope não encontrado.');
    return scope!.notifier!;
  }
}

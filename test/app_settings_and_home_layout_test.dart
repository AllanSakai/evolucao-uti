import 'package:evolucao_uti/main.dart';
import 'package:evolucao_uti/services/app_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('persiste a preferência de tema', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettingsController.load();

    expect(settings.themeMode, ThemeMode.system);
    await settings.toggleTheme(Brightness.light);
    expect(settings.themeMode, ThemeMode.dark);

    final restored = await AppSettingsController.load();
    expect(restored.themeMode, ThemeMode.dark);
  });

  testWidgets('ferramentas ficam compactas no desktop e tema alterna',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = await AppSettingsController.load();
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(EvolucaoUtiApp(settings: settings));
    await tester.pumpAndSettle();

    final toolCard = find.ancestor(
      of: find.text('Atestado'),
      matching: find.byType(Card),
    );
    expect(toolCard, findsOneWidget);
    expect(tester.getSize(toolCard).width, lessThanOrEqualTo(280));

    await tester.tap(find.byTooltip('Usar tema escuro'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Auxiliar UTI'))).brightness,
      Brightness.dark,
    );
  });
}

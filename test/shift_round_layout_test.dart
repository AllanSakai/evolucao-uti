import 'package:evolucao_uti/app_theme.dart';
import 'package:evolucao_uti/models/bed.dart';
import 'package:evolucao_uti/models/icu_unit.dart';
import 'package:evolucao_uti/screens/shift_round_screen.dart';
import 'package:evolucao_uti/services/app_settings_controller.dart';
import 'package:evolucao_uti/services/shift_round_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('resumo não exibe exportação e boxes são compactos no desktop',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpShiftRound(tester);

    expect(find.text('Resumo da ala'), findsOneWidget);
    expect(find.text('Progresso do plantão'), findsOneWidget);
    expect(find.textContaining('Exportar'), findsNothing);

    final firstBedCard = find.ancestor(
      of: find.text('UTI 1 - Leito 1'),
      matching: find.byType(Card),
    );
    expect(firstBedCard, findsOneWidget);
    expect(tester.getSize(firstBedCard).width, lessThan(390));
  });

  testWidgets('boxes ocupam uma coluna em tela pequena', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpShiftRound(tester);

    final firstBedCard = find.ancestor(
      of: find.text('UTI 1 - Leito 1'),
      matching: find.byType(Card),
    );
    expect(firstBedCard, findsOneWidget);
    expect(tester.getSize(firstBedCard).width, greaterThan(330));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpShiftRound(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final settings = await AppSettingsController.load();
  final beds = List.generate(
    6,
    (index) => Bed(
      id: 'bed-${index + 1}',
      unitCode: '1',
      label: '${index + 1}',
      isIsolation: false,
    ),
  );
  final store = InMemoryShiftRoundStore()..startVisit(beds);
  final unit = IcuUnit(code: '1', name: 'UTI 1', beds: beds);

  await tester.pumpWidget(
    AppSettingsScope(
      controller: settings,
      child: MaterialApp(
        theme: PassagemUtiTheme.light,
        home: ShiftRoundScreen(unit: unit, store: store),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

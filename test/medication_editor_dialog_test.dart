import 'package:evolucao_uti/models/medication.dart';
import 'package:evolucao_uti/widgets/medication_editor_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('autocomplete do nome identifica cada variante pela dose',
      (tester) async {
    const base = Medication(
      id: '1',
      name: 'Carvedilol',
      dose: '3,125 mg',
      presentation: MedicationPresentation.tablet,
      useType: MedicationUseType.internal,
      route: 'Via oral',
      administeredQuantity: '1 comprimido',
      frequency: 'Duas vezes ao dia',
      dispensingQuantity: '01 caixa',
    );
    final suggestions = [
      base,
      base.copyWith(id: '2', dose: '6,25 mg'),
      base.copyWith(id: '3', dose: '12,5 mg'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showMedicationEditor(
                context,
                suggestions: suggestions,
              ),
              child: const Text('Adicionar'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    expect(fields, findsWidgets);
    await tester.enterText(fields.first, 'Carv');
    await tester.pumpAndSettle();

    expect(find.text('Carvedilol'), findsNWidgets(3));
    expect(find.text('3,125 mg'), findsOneWidget);
    expect(find.text('6,25 mg'), findsOneWidget);
    expect(find.text('12,5 mg'), findsOneWidget);
  });

  testWidgets(
      'modo prescrição aceita ajustes sem validar duplicidade do cadastro',
      (tester) async {
    const saved = Medication(
      id: 'saved',
      name: 'Carvedilol',
      dose: '3,125 mg',
      presentation: MedicationPresentation.tablet,
      useType: MedicationUseType.internal,
      route: 'Via oral',
      administeredQuantity: '1 comprimido',
      frequency: 'Duas vezes ao dia',
      dispensingQuantity: '',
    );
    Medication? result;
    var selectedFromAutocomplete = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await showMedicationEditor(
                  context,
                  suggestions: const [saved],
                  enforceUniqueRegistration: false,
                  defaultDispensingQuantity: 'Contínuo',
                  onSuggestionSelected: (_) {
                    selectedFromAutocomplete = true;
                  },
                );
              },
              child: const Text('Adicionar'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Carv');
    await tester.pumpAndSettle();
    await tester.tap(find.text('3,125 mg'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(selectedFromAutocomplete, isTrue);
    expect(result, isNotNull);
    expect(result!.dispensingQuantity, 'Contínuo');
  });

  test('quantidades administradas incluem opções inalatórias', () {
    expect(
      inhaledQuantitySuggestions,
      containsAll(['1 puff', '2 puffs', '3 puffs', '4 puffs']),
    );
    expect(inhaledQuantitySuggestions.first, '1 puff');
  });

  testWidgets('editor usa tela cheia rolável em celulares', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showMedicationEditor(context),
              child: const Text('Adicionar'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    final dialog = find.byType(Dialog);
    expect(dialog, findsOneWidget);
    expect(
      find.descendant(of: dialog, matching: find.byType(ListView)),
      findsOneWidget,
    );
    expect(find.text('Adicionar medicamento'), findsOneWidget);
    expect(find.text('Salvar'), findsOneWidget);
    expect(
      find.text('Quantidade para dispensação', skipOffstage: false),
      findsOneWidget,
    );
  });
}

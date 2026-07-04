import 'package:evolucao_uti/models/medication.dart';
import 'package:evolucao_uti/utils/medication_suggestions.dart';
import 'package:evolucao_uti/widgets/medication_editor_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sugere todas as doses cadastradas para o mesmo medicamento', () {
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
    final medications = [
      base,
      base.copyWith(id: '2', dose: '6,25 mg'),
      base.copyWith(id: '3', dose: '12,5 mg'),
      base.copyWith(id: '4', name: 'Outro medicamento', dose: '20 mg'),
    ];

    expect(
      medicationDoseSuggestions(medications, '  CARVEDILOL '),
      ['3,125 mg', '6,25 mg', '12,5 mg'],
    );
    expect(
      medicationDoseSuggestions(medications, 'Carvedilol', query: '6,'),
      ['6,25 mg'],
    );
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

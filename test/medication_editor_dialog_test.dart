import 'package:evolucao_uti/widgets/medication_editor_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

import 'package:evolucao_uti/data/icu_units_data.dart';
import 'package:evolucao_uti/models/evolution_data.dart';
import 'package:evolucao_uti/models/selected_bed.dart';
import 'package:evolucao_uti/services/shift_round_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final unitA = icuUnits.singleWhere((unit) => unit.code == 'A');
  final unitC = icuUnits.singleWhere((unit) => unit.code == 'C');
  final unitE = icuUnits.singleWhere((unit) => unit.code == 'E');

  test('UTI A possui leitos 1 a 11', () {
    expect(unitA.beds.length, 11);
    expect(unitA.beds.first.id, 'A-1');
    expect(unitA.beds.last.id, 'A-11');
  });

  test('UTI C possui leitos 23 a 30 e ISO1 a ISO4', () {
    expect(unitC.beds.length, 12);
    expect(unitC.beds.where((bed) => bed.isIsolation).map((bed) => bed.label),
        ['ISO1', 'ISO2', 'ISO3', 'ISO4']);
  });

  test('leitos repetidos em UTIs diferentes possuem IDs diferentes', () {
    final a1 = unitA.beds.singleWhere((bed) => bed.label == '1');
    final e1 = unitE.beds.singleWhere((bed) => bed.label == '1');
    expect(a1.id, isNot(e1.id));
    expect(a1.id, 'A-1');
    expect(e1.id, 'E-1');
  });

  test('seleciona multiplos leitos', () {
    final store = InMemoryShiftRoundStore();
    store.startVisit(unitA.beds.take(3).toList());
    expect(
        store.beds.map((selected) => selected.bed.id), ['A-1', 'A-2', 'A-3']);
  });

  test('mantem dados separados por leito', () {
    final store = InMemoryShiftRoundStore();
    store.startVisit(unitA.beds.take(2).toList());
    store.saveDraft(
        'A-1',
        const EvolutionData(
          sex: Sex.masculino,
          notes: 'Paciente um',
        ));
    store.saveDraft(
        'A-2',
        const EvolutionData(
          sex: Sex.feminino,
          notes: 'Paciente dois',
        ));
    expect(store.getById('A-1').evolutionData!.notes, 'Paciente um');
    expect(store.getById('A-2').evolutionData!.notes, 'Paciente dois');
  });

  test('atualiza status de pendente para em andamento e concluido', () {
    final store = InMemoryShiftRoundStore();
    store.startVisit([unitA.beds.first]);
    expect(store.getById('A-1').status, BedProgressStatus.pending);

    store.saveDraft('A-1', const EvolutionData(sex: Sex.masculino));
    expect(store.getById('A-1').status, BedProgressStatus.inProgress);

    store.markCompleted('A-1');
    expect(store.getById('A-1').status, BedProgressStatus.completed);
  });

  test('novo dia volta concluido para pendente sem apagar dados', () {
    var now = DateTime(2026, 7, 6, 22);
    final store = InMemoryShiftRoundStore(now: () => now);
    store.startVisit([unitA.beds.first]);
    store.saveDraft(
      'A-1',
      const EvolutionData(sex: Sex.masculino, notes: 'Dados mantidos'),
    );
    store.markCompleted('A-1');
    expect(store.getById('A-1').status, BedProgressStatus.completed);

    now = DateTime(2026, 7, 7, 7);
    store.startVisit([unitA.beds.first]);

    expect(store.getById('A-1').status, BedProgressStatus.pending);
    expect(store.getById('A-1').evolutionData!.notes, 'Dados mantidos');
  });
}

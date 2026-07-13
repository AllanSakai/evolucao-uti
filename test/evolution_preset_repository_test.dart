import 'dart:convert';

import 'package:evolucao_uti/models/evolution_data.dart';
import 'package:evolucao_uti/repositories/evolution_preset_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('salva lista aplica atualizacao e exclui presets locais', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = await LocalEvolutionPresetRepository.load();

    final first = await repository.save(
      name: 'VM padrao',
      data: const EvolutionData(
        sex: Sex.masculino,
        ventilatorySupport: VentilatorySupport.iotVm,
        notes: 'primeiro',
      ),
    );

    expect((await repository.getAll()).single.name, 'VM padrao');
    expect((await repository.getAll()).single.data.notes, 'primeiro');

    await repository.save(
      name: 'VM padrao',
      data: const EvolutionData(
        sex: Sex.feminino,
        ventilatorySupport: VentilatorySupport.tqtVm,
        notes: 'atualizado',
      ),
    );

    final updated = await repository.getAll();
    expect(updated, hasLength(1));
    expect(updated.single.id, first.id);
    expect(updated.single.data.sex, Sex.feminino);
    expect(updated.single.data.notes, 'atualizado');

    await repository.delete(first.id);
    expect(await repository.getAll(), isEmpty);
  });

  test('le presets gravados em SharedPreferences', () async {
    final now = DateTime(2026, 7, 7, 12);
    SharedPreferences.setMockInitialValues({
      'evolution_form_presets': jsonEncode([
        {
          'id': 'preset-1',
          'name': 'Acordado',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'data': const EvolutionData(
            sex: Sex.masculino,
            notes: 'modelo local',
          ).toJson(),
        }
      ]),
    });

    final repository = await LocalEvolutionPresetRepository.load();
    final presets = await repository.getAll();

    expect(presets.single.id, 'preset-1');
    expect(presets.single.data.notes, 'modelo local');
  });
}

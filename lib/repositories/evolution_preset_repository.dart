import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/evolution_data.dart';
import '../models/evolution_form_preset.dart';

abstract interface class EvolutionPresetRepository {
  Future<List<EvolutionFormPreset>> getAll();
  Future<EvolutionFormPreset> save({
    required String name,
    required EvolutionData data,
  });
  Future<void> delete(String id);
}

class LocalEvolutionPresetRepository implements EvolutionPresetRepository {
  LocalEvolutionPresetRepository._(this._preferences);

  static const _key = 'evolution_form_presets';

  final SharedPreferences _preferences;

  static Future<LocalEvolutionPresetRepository> load() async =>
      LocalEvolutionPresetRepository._(
        await SharedPreferences.getInstance(),
      );

  @override
  Future<List<EvolutionFormPreset>> getAll() async => _read()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  @override
  Future<EvolutionFormPreset> save({
    required String name,
    required EvolutionData data,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Informe um nome para o modelo.');
    }
    final presets = _read();
    final now = DateTime.now();
    final existingIndex = presets.indexWhere(
      (preset) => preset.name.toLowerCase() == trimmed.toLowerCase(),
    );
    final preset = existingIndex == -1
        ? EvolutionFormPreset(
            id: 'preset-${now.microsecondsSinceEpoch}',
            name: trimmed,
            createdAt: now,
            updatedAt: now,
            data: data,
          )
        : presets[existingIndex].copyWith(updatedAt: now, data: data);
    if (existingIndex == -1) {
      presets.add(preset);
    } else {
      presets[existingIndex] = preset;
    }
    await _write(presets);
    return preset;
  }

  @override
  Future<void> delete(String id) async {
    final presets = _read()..removeWhere((preset) => preset.id == id);
    await _write(presets);
  }

  List<EvolutionFormPreset> _read() {
    final raw = _preferences.getString(_key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .map((item) => EvolutionFormPreset.fromJson(
              (item as Map).cast<String, dynamic>(),
            ))
        .toList();
  }

  Future<void> _write(List<EvolutionFormPreset> presets) =>
      _preferences.setString(
        _key,
        jsonEncode(presets.map((preset) => preset.toJson()).toList()),
      );
}

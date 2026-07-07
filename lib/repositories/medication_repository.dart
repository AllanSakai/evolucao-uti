import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/common_medications_data.dart';
import '../models/medication.dart';
import '../services/supabase_sync_service.dart';
import '../utils/search_normalizer.dart';

abstract interface class MedicationRepository {
  Future<List<Medication>> getAll();
  Future<void> save(Medication medication);
  Future<void> delete(String id);
  Future<List<Medication>> search(String query);
}

class LocalMedicationRepository implements MedicationRepository {
  LocalMedicationRepository(this._preferences);
  final SharedPreferences _preferences;
  final _sync = SupabaseSyncService.instance;
  bool _syncedRemote = false;
  static const _key = 'medical_discharge_medications';
  static const _catalogVersionKey = 'medical_discharge_catalog_version';
  static const _catalogVersion = 1;

  static Future<LocalMedicationRepository> load() async =>
      LocalMedicationRepository(await SharedPreferences.getInstance());

  Future<List<Medication>> syncNow() async {
    _syncedRemote = false;
    var medications = _readLocal();
    await _mergeCatalog(medications);
    medications = await _syncRemoteOnce(medications, rethrowErrors: true);
    return medications
      ..sort(
        (a, b) => normalizeSearch(a.name).compareTo(normalizeSearch(b.name)),
      );
  }

  @override
  Future<List<Medication>> getAll() async {
    var medications = _readLocal();
    await _mergeCatalog(medications);
    medications = await _syncRemoteOnce(medications);
    return medications
      ..sort(
        (a, b) => normalizeSearch(a.name).compareTo(normalizeSearch(b.name)),
      );
  }

  @override
  Future<void> save(Medication medication) async {
    final medications = await getAll();
    final duplicate = medications.any(
      (item) =>
          item.id != medication.id &&
          normalizeSearch(item.name) == normalizeSearch(medication.name) &&
          normalizeSearch(item.dose) == normalizeSearch(medication.dose),
    );
    if (duplicate) {
      throw const DuplicateMedicationException();
    }
    final index = medications.indexWhere((item) => item.id == medication.id);
    if (index < 0) {
      medications.add(medication);
    } else {
      medications[index] = medication;
    }
    await _write(medications);
    if (_isUserMedication(medication)) {
      try {
        await _sync.upsertMedication(medication);
      } catch (error) {
        debugPrint('Falha ao sincronizar medicamento: $error');
      }
    }
  }

  @override
  Future<void> delete(String id) async {
    final medications = await getAll()
      ..removeWhere((item) => item.id == id);
    await _write(medications);
    try {
      await _sync.deleteMedication(id);
    } catch (error) {
      debugPrint('Falha ao apagar medicamento sincronizado: $error');
    }
  }

  @override
  Future<List<Medication>> search(String query) async {
    final normalizedQuery = normalizeSearch(query);
    final all = await getAll();
    if (normalizedQuery.isEmpty) return all;
    return all
        .where((item) => normalizeSearch(item.name).contains(normalizedQuery))
        .toList();
  }

  Future<void> _write(List<Medication> medications) => _preferences.setString(
        _key,
        jsonEncode(medications.map((item) => item.toJson()).toList()),
      );

  List<Medication> _readLocal() {
    final raw = _preferences.getString(_key);
    if (raw == null) return <Medication>[];
    return (jsonDecode(raw) as List)
        .map(
          (item) => Medication.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList();
  }

  Future<List<Medication>> _syncRemoteOnce(
    List<Medication> medications, {
    bool rethrowErrors = false,
  }) async {
    if (_syncedRemote || !_sync.canSync) return medications;
    _syncedRemote = true;
    try {
      final remote = await _sync.fetchMedications();
      final merged = [...medications];
      for (final medication in remote) {
        final index = merged.indexWhere((item) => item.id == medication.id);
        if (index >= 0) {
          merged[index] = medication;
          continue;
        }
        final sameNameAndDose = merged.any(
          (item) =>
              normalizeSearch(item.name) == normalizeSearch(medication.name) &&
              normalizeSearch(item.dose) == normalizeSearch(medication.dose),
        );
        if (!sameNameAndDose) merged.add(medication);
      }

      for (final medication in merged.where(_isUserMedication)) {
        final alreadyRemote = remote.any(
          (item) =>
              item.id == medication.id ||
              (normalizeSearch(item.name) == normalizeSearch(medication.name) &&
                  normalizeSearch(item.dose) ==
                      normalizeSearch(medication.dose)),
        );
        if (!alreadyRemote) await _sync.upsertMedication(medication);
      }

      await _write(merged);
      return merged;
    } catch (error) {
      debugPrint('Falha ao sincronizar medicamentos: $error');
      if (rethrowErrors) rethrow;
      return medications;
    }
  }

  Future<void> _mergeCatalog(List<Medication> medications) async {
    final installedVersion = _preferences.getInt(_catalogVersionKey) ?? 0;
    if (installedVersion >= _catalogVersion) return;

    for (final candidate in [
      ..._initialMedications,
      ...commonMedicationCatalog,
    ]) {
      final exists = medications.any(
        (medication) =>
            normalizeSearch(medication.name) ==
                normalizeSearch(candidate.name) &&
            normalizeSearch(medication.dose) == normalizeSearch(candidate.dose),
      );
      if (!exists) medications.add(candidate);
    }
    await _write(medications);
    await _preferences.setInt(_catalogVersionKey, _catalogVersion);
  }

  static const _initialMedications = [
    Medication(
      id: 'default-pantoprazol',
      name: 'Pantoprazol',
      dose: '20 mg',
      presentation: MedicationPresentation.tablet,
      useType: MedicationUseType.internal,
      route: 'Via oral',
      administeredQuantity: '1 comprimido',
      frequency: 'Às 6 horas da manhã',
      dispensingQuantity: '01 caixa',
    ),
    Medication(
      id: 'default-dipirona',
      name: 'Dipirona',
      dose: '500 mg',
      presentation: MedicationPresentation.tablet,
      useType: MedicationUseType.internal,
      route: 'Via oral',
      administeredQuantity: '1 comprimido',
      frequency: 'A cada 8 horas, se dor e/ou febre',
      dispensingQuantity: '01 caixa',
    ),
    Medication(
      id: 'default-plasil',
      name: 'Plasil',
      dose: '10 mg',
      presentation: MedicationPresentation.tablet,
      useType: MedicationUseType.internal,
      route: 'Via oral',
      administeredQuantity: '1 comprimido',
      frequency: 'A cada 8 horas, se náuseas e/ou vômitos',
      dispensingQuantity: '01 caixa',
    ),
    Medication(
      id: 'default-dexametasona',
      name: 'Dexametasona',
      dose: '4 mg',
      presentation: MedicationPresentation.tablet,
      useType: MedicationUseType.internal,
      route: 'Via oral',
      administeredQuantity: '1 comprimido',
      frequency: 'Uma vez ao dia',
      dispensingQuantity: '01 caixa',
    ),
  ];

  static bool _isUserMedication(Medication medication) =>
      !medication.id.startsWith('default-') &&
      !medication.id.startsWith('catalog-');
}

class DuplicateMedicationException implements Exception {
  const DuplicateMedicationException();

  @override
  String toString() => 'Já existe um medicamento com este nome e dose.';
}

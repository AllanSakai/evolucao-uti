import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/common_medications_data.dart';
import '../models/medication.dart';
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
  static const _key = 'medical_discharge_medications';
  static const _catalogVersionKey = 'medical_discharge_catalog_version';
  static const _catalogVersion = 1;

  static Future<LocalMedicationRepository> load() async =>
      LocalMedicationRepository(await SharedPreferences.getInstance());

  @override
  Future<List<Medication>> getAll() async {
    final raw = _preferences.getString(_key);
    final medications = raw == null
        ? <Medication>[]
        : (jsonDecode(raw) as List)
            .map(
              (item) =>
                  Medication.fromJson((item as Map).cast<String, dynamic>()),
            )
            .toList();
    await _mergeCatalog(medications);
    return medications..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<void> save(Medication medication) async {
    final medications = await getAll();
    final index = medications.indexWhere((item) => item.id == medication.id);
    if (index < 0) {
      medications.add(medication);
    } else {
      medications[index] = medication;
    }
    await _write(medications);
  }

  @override
  Future<void> delete(String id) async {
    final medications = await getAll()
      ..removeWhere((item) => item.id == id);
    await _write(medications);
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
}

import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bed.dart';
import '../models/evolution_data.dart';
import '../models/selected_bed.dart';
import 'supabase_sync_service.dart';

abstract interface class ShiftRoundStore extends ChangeNotifier {
  List<SelectedBed> get beds;
  void startVisit(List<Bed> selectedBeds);
  SelectedBed getById(String bedId);
  void saveDraft(String bedId, EvolutionData data);
  void markCompleted(String bedId);
  Future<int> syncFromRemote(List<Bed> unitBeds);
  Future<void> clear();
}

class InMemoryShiftRoundStore extends ChangeNotifier
    implements ShiftRoundStore {
  final Map<String, SelectedBed> _beds = {};

  @override
  List<SelectedBed> get beds => List.unmodifiable(_beds.values);

  @override
  void startVisit(List<Bed> selectedBeds) {
    for (final bed in selectedBeds) {
      _beds.putIfAbsent(bed.id, () => SelectedBed(bed: bed));
    }
    _beds.removeWhere((id, _) => !selectedBeds.any((bed) => bed.id == id));
    notifyListeners();
  }

  @override
  SelectedBed getById(String bedId) => _beds[bedId]!;

  @override
  void saveDraft(String bedId, EvolutionData data) {
    final selected = getById(bedId);
    selected.evolutionData = data;
    if (selected.status != BedProgressStatus.completed) {
      selected.status = BedProgressStatus.inProgress;
    }
    notifyListeners();
  }

  @override
  void markCompleted(String bedId) {
    final selected = getById(bedId);
    if (selected.evolutionData == null) return;
    selected.status = BedProgressStatus.completed;
    notifyListeners();
  }

  @override
  Future<int> syncFromRemote(List<Bed> unitBeds) async => 0;

  @override
  Future<void> clear() async {
    _beds.clear();
    notifyListeners();
  }
}

class PersistentShiftRoundStore extends ChangeNotifier
    implements ShiftRoundStore {
  PersistentShiftRoundStore._(this.unitCode, this._preferences);

  final String unitCode;
  final SharedPreferences _preferences;
  final Map<String, SelectedBed> _beds = {};
  final _sync = SupabaseSyncService.instance;

  static Future<PersistentShiftRoundStore> load(String unitCode) async {
    final preferences = await SharedPreferences.getInstance();
    return PersistentShiftRoundStore._(unitCode, preferences);
  }

  static Future<List<String>> savedBedIds(String unitCode) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key(unitCode));
    if (raw == null) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const [];
    return decoded.keys.map((id) => '$id').toList();
  }

  static Future<void> clearUnit(String unitCode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key(unitCode));
  }

  @override
  List<SelectedBed> get beds => List.unmodifiable(_beds.values);

  @override
  void startVisit(List<Bed> selectedBeds) {
    final saved = _readSaved();
    for (final bed in selectedBeds) {
      final savedBed = saved[bed.id];
      _beds[bed.id] = savedBed == null
          ? SelectedBed(bed: bed)
          : SelectedBed(
              bed: bed,
              evolutionData: savedBed.evolutionData,
              status: savedBed.status,
            );
    }
    _beds.removeWhere((id, _) => !selectedBeds.any((bed) => bed.id == id));
    notifyListeners();
  }

  @override
  Future<int> syncFromRemote(List<Bed> unitBeds) async {
    for (final selected in _beds.values) {
      if (selected.evolutionData == null) continue;
      await _sync.upsertBed(
        bed: selected.bed,
        status: selected.status,
        evolutionData: selected.evolutionData,
      );
    }
    final remoteBeds = await _sync.fetchUnit(unitCode);
    if (remoteBeds.isEmpty) return 0;
    final bedsById = {for (final bed in unitBeds) bed.id: bed};
    for (final remote in remoteBeds) {
      final bed = bedsById[remote.bedId];
      if (bed == null) continue;
      _beds[remote.bedId] = SelectedBed(
        bed: bed,
        evolutionData: remote.evolutionData,
        status: remote.status,
      );
    }
    _persist();
    notifyListeners();
    return remoteBeds.length;
  }

  @override
  SelectedBed getById(String bedId) => _beds[bedId]!;

  @override
  void saveDraft(String bedId, EvolutionData data) {
    final selected = getById(bedId);
    selected.evolutionData = data;
    if (selected.status != BedProgressStatus.completed) {
      selected.status = BedProgressStatus.inProgress;
    }
    _persist();
    unawaited(_sync
        .upsertBed(
          bed: selected.bed,
          status: selected.status,
          evolutionData: selected.evolutionData,
        )
        .catchError((error) => debugPrint('Falha ao sincronizar: $error')));
    notifyListeners();
  }

  @override
  void markCompleted(String bedId) {
    final selected = getById(bedId);
    if (selected.evolutionData == null) return;
    selected.status = BedProgressStatus.completed;
    _persist();
    unawaited(_sync
        .upsertBed(
          bed: selected.bed,
          status: selected.status,
          evolutionData: selected.evolutionData,
        )
        .catchError((error) => debugPrint('Falha ao sincronizar: $error')));
    notifyListeners();
  }

  @override
  Future<void> clear() async {
    _beds.clear();
    await _preferences.remove(_key(unitCode));
    await _sync.clearUnit(unitCode);
    notifyListeners();
  }

  Map<String, SelectedBed> _readSaved() {
    final raw = _preferences.getString(_key(unitCode));
    if (raw == null) return {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return {};
    return decoded.map((id, value) {
      final entry = (value as Map).cast<String, dynamic>();
      return MapEntry(
        '$id',
        SelectedBed(
          bed: Bed(
            id: '$id',
            label: entry['label'] as String? ?? '$id',
            unitCode: unitCode,
            isIsolation: entry['isIsolation'] as bool? ?? false,
          ),
          status: _statusFromName(entry['status'] as String?),
          evolutionData: entry['evolutionData'] == null
              ? null
              : EvolutionData.fromJson(
                  (entry['evolutionData'] as Map).cast<String, dynamic>(),
                ),
        ),
      );
    });
  }

  void _persist() {
    final payload = _beds.map((id, selected) => MapEntry(id, {
          'label': selected.bed.label,
          'isIsolation': selected.bed.isIsolation,
          'status': selected.status.name,
          'evolutionData': selected.evolutionData?.toJson(),
        }));
    _preferences.setString(_key(unitCode), jsonEncode(payload));
  }

  static String _key(String unitCode) => 'evolucao_uti_round_$unitCode';

  static BedProgressStatus _statusFromName(String? name) {
    for (final status in BedProgressStatus.values) {
      if (status.name == name) return status;
    }
    return BedProgressStatus.pending;
  }
}

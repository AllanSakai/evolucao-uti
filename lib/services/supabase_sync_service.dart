import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bed.dart';
import '../models/evolution_data.dart';
import '../models/medication.dart';
import '../models/selected_bed.dart';
import 'supabase_config.dart';

class SupabaseSyncService {
  SupabaseSyncService._();

  static final instance = SupabaseSyncService._();

  SupabaseClient? get _client => SupabaseConfig.client;

  bool get canSync =>
      SupabaseConfig.isConfigured && _client?.auth.currentUser != null;

  String? get userEmail => _client?.auth.currentUser?.email;

  Future<List<RemoteSelectedBed>> fetchUnit(String unitCode) async {
    if (!canSync) return const [];
    final response = await _client!
        .from('icu_bed_drafts')
        .select()
        .eq('unit_code', unitCode)
        .order('bed_id');

    return [
      for (final row in response)
        RemoteSelectedBed.fromJson((row as Map).cast<String, dynamic>()),
    ];
  }

  Future<void> upsertBed({
    required Bed bed,
    required BedProgressStatus status,
    required EvolutionData? evolutionData,
  }) async {
    if (!canSync) return;
    final userId = _client!.auth.currentUser!.id;
    await _client!.from('icu_bed_drafts').upsert({
      'user_id': userId,
      'unit_code': bed.unitCode,
      'bed_id': bed.id,
      'label': bed.label,
      'is_isolation': bed.isIsolation,
      'status': status.name,
      'evolution_data': evolutionData?.toJson(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,unit_code,bed_id');
  }

  Future<void> clearUnit(String unitCode) async {
    if (!canSync) return;
    await _client!.from('icu_bed_drafts').delete().eq('unit_code', unitCode);
  }

  Future<List<Medication>> fetchMedications() async {
    if (!canSync) return const [];
    final response = await _client!
        .from('user_medications')
        .select()
        .order('name')
        .order('dose');

    return [
      for (final row in response)
        _medicationFromRemote((row as Map).cast<String, dynamic>()),
    ];
  }

  Future<void> upsertMedication(Medication medication) async {
    if (!canSync) return;
    final userId = _client!.auth.currentUser!.id;
    await _client!.from('user_medications').upsert({
      'user_id': userId,
      'medication_id': medication.id,
      'name': medication.name,
      'dose': medication.dose,
      'presentation': medication.presentation.name,
      'use_type': medication.useType.name,
      'route': medication.route,
      'administered_quantity': medication.administeredQuantity,
      'frequency': medication.frequency,
      'dispensing_quantity': medication.dispensingQuantity,
      'notes': medication.notes,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,medication_id');
  }

  Future<void> deleteMedication(String medicationId) async {
    if (!canSync) return;
    await _client!
        .from('user_medications')
        .delete()
        .eq('medication_id', medicationId);
  }

  Medication _medicationFromRemote(Map<String, dynamic> json) => Medication(
        id: json['medication_id'] as String,
        name: json['name'] as String? ?? '',
        dose: json['dose'] as String? ?? '',
        presentation: MedicationPresentation.values.firstWhere(
          (value) => value.name == json['presentation'],
          orElse: () => MedicationPresentation.other,
        ),
        useType: MedicationUseType.values.firstWhere(
          (value) => value.name == json['use_type'],
          orElse: () => MedicationUseType.internal,
        ),
        route: json['route'] as String? ?? '',
        administeredQuantity: json['administered_quantity'] as String? ?? '',
        frequency: json['frequency'] as String? ?? '',
        dispensingQuantity: json['dispensing_quantity'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
      );
}

class RemoteSelectedBed {
  const RemoteSelectedBed({
    required this.bedId,
    required this.label,
    required this.isIsolation,
    required this.status,
    required this.evolutionData,
    required this.updatedAt,
  });

  factory RemoteSelectedBed.fromJson(Map<String, dynamic> json) {
    final updatedAt = json['updated_at'] as String?;
    return RemoteSelectedBed(
      bedId: json['bed_id'] as String,
      label: json['label'] as String? ?? json['bed_id'] as String,
      isIsolation: json['is_isolation'] as bool? ?? false,
      status: _statusFromName(json['status'] as String?),
      evolutionData: json['evolution_data'] == null
          ? null
          : EvolutionData.fromJson(
              (json['evolution_data'] as Map).cast<String, dynamic>(),
            ),
      updatedAt: updatedAt == null ? null : DateTime.tryParse(updatedAt),
    );
  }

  final String bedId;
  final String label;
  final bool isIsolation;
  final BedProgressStatus status;
  final EvolutionData? evolutionData;
  final DateTime? updatedAt;

  static BedProgressStatus _statusFromName(String? name) {
    for (final status in BedProgressStatus.values) {
      if (status.name == name) return status;
    }
    return BedProgressStatus.pending;
  }
}

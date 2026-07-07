import 'medication.dart';

class PrescriptionProtocol {
  const PrescriptionProtocol({
    required this.id,
    required this.name,
    required this.medications,
    this.usageTips = '',
  });

  final String id;
  final String name;
  final List<Medication> medications;
  final String usageTips;

  PrescriptionProtocol copyWith({
    String? id,
    String? name,
    List<Medication>? medications,
    String? usageTips,
  }) =>
      PrescriptionProtocol(
        id: id ?? this.id,
        name: name ?? this.name,
        medications: medications ?? this.medications,
        usageTips: usageTips ?? this.usageTips,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'medications': medications.map((item) => item.toJson()).toList(),
        'usageTips': usageTips,
      };

  factory PrescriptionProtocol.fromJson(Map<String, dynamic> json) =>
      PrescriptionProtocol(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        usageTips: json['usageTips'] as String? ?? '',
        medications: (json['medications'] as List? ?? const [])
            .map(
              (item) =>
                  Medication.fromJson((item as Map).cast<String, dynamic>()),
            )
            .toList(),
      );
}

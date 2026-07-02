enum MedicationPresentation {
  tablet('Comprimido'),
  capsule('Cápsula'),
  drops('Gotas'),
  ointment('Pomada'),
  cream('Creme'),
  solution('Solução'),
  ampoule('Ampola'),
  sachet('Sachê'),
  spray('Spray'),
  other('Outro');

  const MedicationPresentation(this.label);
  final String label;
}

enum MedicationUseType {
  internal('Uso interno'),
  topical('Uso tópico'),
  inhaled('Uso inalatório'),
  subcutaneous('Uso subcutâneo');

  const MedicationUseType(this.label);
  final String label;
}

class Medication {
  const Medication({
    required this.id,
    required this.name,
    required this.dose,
    required this.presentation,
    required this.useType,
    required this.route,
    required this.administeredQuantity,
    required this.frequency,
    required this.dispensingQuantity,
    this.notes = '',
  });

  final String id;
  final String name;
  final String dose;
  final MedicationPresentation presentation;
  final MedicationUseType useType;
  final String route;
  final String administeredQuantity;
  final String frequency;
  final String dispensingQuantity;
  final String notes;

  Medication copyWith({
    String? id,
    String? name,
    String? dose,
    MedicationPresentation? presentation,
    MedicationUseType? useType,
    String? route,
    String? administeredQuantity,
    String? frequency,
    String? dispensingQuantity,
    String? notes,
  }) =>
      Medication(
        id: id ?? this.id,
        name: name ?? this.name,
        dose: dose ?? this.dose,
        presentation: presentation ?? this.presentation,
        useType: useType ?? this.useType,
        route: route ?? this.route,
        administeredQuantity: administeredQuantity ?? this.administeredQuantity,
        frequency: frequency ?? this.frequency,
        dispensingQuantity: dispensingQuantity ?? this.dispensingQuantity,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dose': dose,
        'presentation': presentation.name,
        'useType': useType.name,
        'route': route,
        'administeredQuantity': administeredQuantity,
        'frequency': frequency,
        'dispensingQuantity': dispensingQuantity,
        'notes': notes,
      };

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        dose: json['dose'] as String? ?? '',
        presentation: MedicationPresentation.values.firstWhere(
          (value) => value.name == json['presentation'],
          orElse: () => MedicationPresentation.other,
        ),
        useType: MedicationUseType.values.firstWhere(
          (value) => value.name == json['useType'],
          orElse: () => MedicationUseType.internal,
        ),
        route: json['route'] as String? ?? '',
        administeredQuantity: json['administeredQuantity'] as String? ?? '',
        frequency: json['frequency'] as String? ?? '',
        dispensingQuantity: json['dispensingQuantity'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
      );
}

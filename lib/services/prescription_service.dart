import '../models/medication.dart';
import '../models/prescription.dart';

class PrescriptionService {
  static const _minimumSeparatorLength = 48;

  String generate(Prescription prescription) {
    final medications = prescription.items.map((item) => item.medication);
    final grouped =
        <MedicationUseType, List<({Medication drug, int number})>>{};
    var nextNumber = 1;
    for (final type in MedicationUseType.values) {
      final group = medications
          .where((item) => item.useType == type)
          .map((drug) => (drug: drug, number: nextNumber++))
          .toList();
      if (group.isNotEmpty) grouped[type] = group;
    }
    final width = grouped.values
        .expand((group) => group)
        .map((entry) => '${entry.number}) ${_description(entry.drug)}'.length)
        .fold<int>(0, (max, length) => length > max ? length : max);
    final buffer = StringBuffer();

    for (final type in MedicationUseType.values) {
      final group = grouped[type];
      if (group == null) continue;
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln(type.label.toUpperCase());
      buffer.writeln();
      for (final entry in group) {
        final medication = entry.drug;
        final left = '${entry.number}) ${_description(medication)}';
        final hyphens =
            width - left.length + PrescriptionService._minimumSeparatorLength;
        buffer.writeln(
          '$left ${'-' * hyphens} ${medication.dispensingQuantity}',
        );
        final instruction = _instruction(medication);
        buffer.writeln(instruction);
        buffer.writeln();
      }
    }
    return buffer.toString().trimRight();
  }

  String _description(Medication medication) {
    final dose = medication.dose.trim();
    return [medication.name.trim(), dose]
        .where((part) => part.isNotEmpty)
        .join(' ');
  }

  String _instruction(Medication medication) {
    final verb = medication.useType == MedicationUseType.topical
        ? 'Aplicar'
        : medication.useType == MedicationUseType.inhaled
            ? 'Administrar'
            : 'Tomar';
    final parts = <String>[
      medication.administeredQuantity.trim(),
      medication.route.trim().toLowerCase(),
      medication.frequency.trim().toLowerCase(),
    ].where((part) => part.isNotEmpty).toList();
    var result = '$verb ${parts.join(', ')}';
    if (medication.notes.trim().isNotEmpty) {
      result += ', ${medication.notes.trim()}';
    }
    return '${result[0].toUpperCase()}${result.substring(1)}.';
  }

  List<Medication> utiTemplate() => [
        _template('pantoprazol', 'Pantoprazol', '20 mg', 'Às 6 horas da manhã'),
        _template('dipirona', 'Dipirona', '500 mg',
            'A cada 8 horas, se dor e/ou febre'),
        _template('plasil', 'Plasil', '10 mg',
            'A cada 8 horas, se náuseas e/ou vômitos'),
      ];

  Medication _template(String id, String name, String dose, String frequency) =>
      Medication(
        id: 'uti-$id',
        name: name,
        dose: dose,
        presentation: MedicationPresentation.tablet,
        useType: MedicationUseType.internal,
        route: 'Via oral',
        administeredQuantity: '1 comprimido',
        frequency: frequency,
        dispensingQuantity: '01 caixa',
      );
}

import '../models/medication.dart';

List<Medication> get commonMedicationCatalog => [
      ..._oral('Carvedilol', ['3,125 mg', '6,25 mg', '12,5 mg', '25 mg']),
      ..._oral('Losartana', ['50 mg']),
      ..._oral('Enalapril', ['5 mg', '10 mg', '20 mg']),
      ..._oral('Captopril', ['25 mg']),
      ..._oral('Anlodipino', ['5 mg', '10 mg']),
      ..._oral('Atenolol', ['25 mg', '50 mg']),
      ..._oral('Propranolol', ['40 mg']),
      ..._oral('Metoprolol', ['25 mg']),
      ..._oral('Hidroclorotiazida', ['12,5 mg', '25 mg']),
      ..._oral('Furosemida', ['40 mg']),
      ..._oral('Espironolactona', ['25 mg', '100 mg']),
      ..._oral('Amiodarona', ['200 mg']),
      ..._oral('Ácido acetilsalicílico', ['100 mg']),
      ..._oral('Clopidogrel', ['75 mg']),
      ..._oral('Sinvastatina', ['10 mg', '20 mg', '40 mg']),
      ..._oral('Metformina', ['500 mg', '500 mg XR', '850 mg']),
      ..._oral('Glibenclamida', ['5 mg']),
      ..._oral('Dapagliflozina', ['10 mg']),
      ..._oral(
        'Omeprazol',
        ['10 mg', '20 mg'],
        presentation: MedicationPresentation.capsule,
      ),
      ..._oral('Pantoprazol', ['20 mg', '40 mg']),
      ..._oral('Metoclopramida', ['10 mg']),
      ..._oral('Ondansetrona', ['4 mg', '8 mg']),
      ..._oral('Paracetamol', ['500 mg']),
      ..._oral('Dipirona', ['500 mg', '1 g']),
      ..._oral('Ibuprofeno', ['400 mg', '600 mg']),
      ..._oral('Prednisona', ['5 mg', '20 mg']),
      ..._oral('Dexametasona', ['4 mg']),
      ..._oral('Levotiroxina', [
        '12,5 mcg',
        '25 mcg',
        '37,5 mcg',
        '50 mcg',
        '100 mcg',
      ]),
      ..._oral('Loratadina', ['10 mg']),
      ..._oral('Dexclorfeniramina', ['2 mg']),
      ..._oral(
        'Amoxicilina',
        ['500 mg'],
        presentation: MedicationPresentation.capsule,
      ),
      ..._oral('Amoxicilina + clavulanato', ['500 mg + 125 mg']),
      ..._oral('Azitromicina', ['500 mg']),
      ..._oral(
        'Cefalexina',
        ['500 mg'],
        presentation: MedicationPresentation.capsule,
      ),
      ..._oral(
        'Nitrofurantoína',
        ['100 mg'],
        presentation: MedicationPresentation.capsule,
      ),
      ..._oral('Metronidazol', ['250 mg', '400 mg']),
      ..._inhaled('Salbutamol', ['100 mcg/dose']),
      ..._inhaled('Beclometasona', [
        '50 mcg/dose',
        '200 mcg/dose',
        '250 mcg/dose',
      ]),
      ..._inhaled('Ipratrópio', ['0,02 mg/dose']),
      ..._inhaled(
        'Ipratrópio',
        ['0,25 mg/mL'],
        presentation: MedicationPresentation.solution,
      ),
      ..._nasal('Budesonida', ['32 mcg/dose', '50 mcg/dose']),
    ];

List<Medication> _oral(
  String name,
  List<String> doses, {
  MedicationPresentation presentation = MedicationPresentation.tablet,
}) =>
    _variants(
      name,
      doses,
      presentation: presentation,
      useType: MedicationUseType.internal,
      route: 'Via oral',
    );

List<Medication> _inhaled(
  String name,
  List<String> doses, {
  MedicationPresentation presentation = MedicationPresentation.spray,
}) =>
    _variants(
      name,
      doses,
      presentation: presentation,
      useType: MedicationUseType.inhaled,
      route: 'Via inalatória',
    );

List<Medication> _nasal(String name, List<String> doses) => _variants(
      name,
      doses,
      presentation: MedicationPresentation.spray,
      useType: MedicationUseType.inhaled,
      route: 'Via nasal',
    );

List<Medication> _variants(
  String name,
  List<String> doses, {
  required MedicationPresentation presentation,
  required MedicationUseType useType,
  required String route,
}) =>
    doses
        .map(
          (dose) => Medication(
            id: 'catalog-${_id(name)}-${_id(dose)}',
            name: name,
            dose: dose,
            presentation: presentation,
            useType: useType,
            route: route,
            administeredQuantity: '',
            frequency: '',
            dispensingQuantity: '',
          ),
        )
        .toList();

String _id(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-|-$'), '');

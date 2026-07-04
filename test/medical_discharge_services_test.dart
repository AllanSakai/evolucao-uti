import 'dart:convert';

import 'package:evolucao_uti/data/common_medications_data.dart';
import 'package:evolucao_uti/models/certificate.dart';
import 'package:evolucao_uti/models/medication.dart';
import 'package:evolucao_uti/models/prescription.dart';
import 'package:evolucao_uti/repositories/medication_repository.dart';
import 'package:evolucao_uti/services/certificate_service.dart';
import 'package:evolucao_uti/services/prescription_service.dart';
import 'package:evolucao_uti/utils/search_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('gera atestado com concordância feminina e datas brasileiras', () {
    final text = CertificateService().generate(Certificate(
      patientName: 'Maria Silva',
      sex: PatientSex.female,
      admissionDate: DateTime(2026, 6, 1),
      dischargeDate: DateTime(2026, 6, 8),
    ));
    expect(text, contains('A PACIENTE MARIA SILVA ESTEVE INTERNADA'));
    expect(text, contains('DO DIA 01/06/2026 ATÉ O DIA 08/06/2026'));
  });

  test('atestado rejeita alta anterior à internação', () {
    expect(
      () => CertificateService().generate(Certificate(
        patientName: 'Maria Silva',
        sex: PatientSex.female,
        admissionDate: DateTime(2026, 6, 8),
        dischargeDate: DateTime(2026, 6, 1),
      )),
      throwsArgumentError,
    );
  });

  test('receita agrupa na ordem obrigatória e alinha dispensação', () {
    final service = PrescriptionService();
    final topical = service.utiTemplate().first.copyWith(
          id: 'topical',
          name: 'Nebacetin',
          dose: '',
          presentation: MedicationPresentation.ointment,
          useType: MedicationUseType.topical,
          route: 'Via tópica',
          administeredQuantity: 'uma camada fina',
          frequency: 'duas vezes ao dia',
        );
    final text = service.generate(Prescription(items: [
      PrescriptionItem(medication: topical),
      PrescriptionItem(medication: service.utiTemplate().first),
    ]));
    expect(text.indexOf('USO INTERNO'), lessThan(text.indexOf('USO TÓPICO')));
    expect(text, contains('Pantoprazol 20 mg'));
    expect(text, isNot(contains('Pantoprazol 20 mg comprimido')));
    final lines =
        text.split('\n').where((line) => RegExp(r'^\d+\)').hasMatch(line));
    expect(lines.first.length, 80);
    expect(lines.map((line) => line.lastIndexOf('01 caixa')).toSet(),
        hasLength(1));
  });

  test('pesquisa normalizada ignora acentos, caixa e espaços extras', () {
    expect(normalizeSearch('  DIPIRÓNA  '), 'dipirona');
    expect(normalizeSearch('Dipi  rona'), 'dipi rona');
  });

  test('banco local inicia com medicamentos úteis para autocomplete', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = await LocalMedicationRepository.load();

    expect(
      (await repository.search(' Pan ')).map((item) => item.dose),
      containsAll(['20 mg', '40 mg']),
    );
    expect(
      (await repository.search('DIP')).map((item) => item.dose),
      containsAll(['500 mg', '1 g']),
    );
    expect((await repository.search('déx')), isNotEmpty);
  });

  test('catálogo comum inclui variantes e preserva cadastros existentes',
      () async {
    const custom = Medication(
      id: 'custom',
      name: 'Meu medicamento',
      dose: '15 mg',
      presentation: MedicationPresentation.tablet,
      useType: MedicationUseType.internal,
      route: 'Via oral',
      administeredQuantity: '1 comprimido',
      frequency: 'Uma vez ao dia',
      dispensingQuantity: '01 caixa',
    );
    SharedPreferences.setMockInitialValues({
      'medical_discharge_medications': jsonEncode([custom.toJson()]),
    });
    final repository = await LocalMedicationRepository.load();
    final all = await repository.getAll();

    expect(all.any((item) => item.id == custom.id), isTrue);
    expect(all.length, greaterThan(50));
    expect(
      all.indexWhere((item) => item.name == 'Ácido acetilsalicílico'),
      lessThan(all.indexWhere((item) => item.name == 'Amiodarona')),
    );
    expect(
      commonMedicationCatalog
          .where((item) => item.name == 'Carvedilol')
          .map((item) => item.dose),
      ['3,125 mg', '6,25 mg', '12,5 mg', '25 mg'],
    );
  });
}

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
    expect(
      RegExp(r'-+').firstMatch(lines.first)!.group(0)!.length,
      greaterThanOrEqualTo(48),
    );
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

    expect((await repository.search(' Pan ')).single.name, 'Pantoprazol');
    expect((await repository.search('DIP')).single.name, 'Dipirona');
    expect((await repository.search('déx')).single.name, 'Dexametasona');
  });
}

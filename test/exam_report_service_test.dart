import 'package:evolucao_uti/models/exam_report.dart';
import 'package:evolucao_uti/services/exam_report_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gera texto configuravel para laudos de exames', () {
    final text = ExamReportService().generate(ExamReport(
      patientName: 'Maria Silva',
      sex: ExamReportSex.female,
      examName: 'Tomografia de cranio',
      reportText: 'Sem evidencia de sangramento intracraniano',
      examDate: DateTime(2026, 6, 9),
    ));

    expect(text, startsWith('A PACIENTE MARIA SILVA APRESENTA LAUDO'));
    expect(text, contains('TOMOGRAFIA DE CRANIO'));
    expect(text, contains('REALIZADO EM 09/06/2026'));
    expect(text, contains('SEM EVIDENCIA DE SANGRAMENTO INTRACRANIANO.'));
  });

  test('exige paciente exame e texto do laudo', () {
    final service = ExamReportService();
    expect(
      () => service.generate(const ExamReport(
        patientName: '',
        sex: ExamReportSex.male,
        examName: 'RX',
        reportText: 'Normal',
      )),
      throwsArgumentError,
    );
    expect(
      () => service.generate(const ExamReport(
        patientName: 'Joao',
        sex: ExamReportSex.male,
        examName: '',
        reportText: 'Normal',
      )),
      throwsArgumentError,
    );
    expect(
      () => service.generate(const ExamReport(
        patientName: 'Joao',
        sex: ExamReportSex.male,
        examName: 'RX',
        reportText: '',
      )),
      throwsArgumentError,
    );
  });
}

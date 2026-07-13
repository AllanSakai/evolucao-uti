import '../models/exam_report.dart';

class ExamReportService {
  String generate(ExamReport report) {
    final patientName = report.patientName.trim();
    final examName = report.examName.trim();
    final reportText = report.reportText.trim();
    if (patientName.isEmpty) {
      throw ArgumentError.value(
        report.patientName,
        'patientName',
        'O nome do paciente e obrigatorio.',
      );
    }
    if (examName.isEmpty) {
      throw ArgumentError.value(
        report.examName,
        'examName',
        'O exame e obrigatorio.',
      );
    }
    if (reportText.isEmpty) {
      throw ArgumentError.value(
        report.reportText,
        'reportText',
        'O laudo do exame e obrigatorio.',
      );
    }

    final female = report.sex == ExamReportSex.female;
    final date = report.examDate == null
        ? ''
        : ', REALIZADO EM ${_date(report.examDate!)}';
    return '${female ? "A PACIENTE" : "O PACIENTE"} '
        '${patientName.toUpperCase()} APRESENTA LAUDO DE '
        '${examName.toUpperCase()}$date, COM A SEGUINTE DESCRICAO:\n\n'
        '${_withFinalPeriod(reportText.toUpperCase())}';
  }

  String _withFinalPeriod(String value) =>
      value.endsWith('.') ? value : '$value.';

  String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}

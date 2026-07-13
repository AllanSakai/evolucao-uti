enum ExamReportSex { male, female }

class ExamReport {
  const ExamReport({
    required this.patientName,
    required this.sex,
    required this.examName,
    required this.reportText,
    this.examDate,
  });

  final String patientName;
  final ExamReportSex sex;
  final String examName;
  final String reportText;
  final DateTime? examDate;
}

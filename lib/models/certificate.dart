enum PatientSex { male, female }

class Certificate {
  const Certificate({
    required this.patientName,
    required this.sex,
    required this.admissionDate,
    required this.dischargeDate,
  });

  final String patientName;
  final PatientSex sex;
  final DateTime admissionDate;
  final DateTime dischargeDate;
}

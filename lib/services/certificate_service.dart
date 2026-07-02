import '../models/certificate.dart';

class CertificateService {
  String generate(Certificate certificate) {
    if (certificate.patientName.trim().isEmpty) {
      throw ArgumentError.value(
        certificate.patientName,
        'patientName',
        'O nome do paciente é obrigatório.',
      );
    }
    if (certificate.dischargeDate.isBefore(certificate.admissionDate)) {
      throw ArgumentError(
        'A data da alta não pode ser anterior à data da internação.',
      );
    }
    final female = certificate.sex == PatientSex.female;
    return 'ATESTO PARA OS DEVIDOS FINS QUE ${female ? "A PACIENTE" : "O PACIENTE"} '
        '${certificate.patientName.trim().toUpperCase()} ESTEVE '
        '${female ? "INTERNADA" : "INTERNADO"} EM UNIDADE DE TRATAMENTO '
        'INTENSIVO, NO HOSPITAL DO CENTRO DE CAMPO LARGO, DO DIA '
        '${_date(certificate.admissionDate)} ATÉ O DIA '
        '${_date(certificate.dischargeDate)}.';
  }

  String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}

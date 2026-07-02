import 'medication.dart';

class PrescriptionItem {
  const PrescriptionItem({required this.medication});
  final Medication medication;
}

class Prescription {
  const Prescription({this.items = const []});
  final List<PrescriptionItem> items;
}

import '../models/medication.dart';
import 'search_normalizer.dart';

List<String> medicationDoseSuggestions(
  Iterable<Medication> medications,
  String medicationName, {
  String query = '',
}) {
  final normalizedName = normalizeSearch(medicationName);
  final normalizedQuery = normalizeSearch(query);
  if (normalizedName.isEmpty) return const [];

  final doses = <String, String>{};
  for (final medication in medications) {
    if (normalizeSearch(medication.name) != normalizedName) continue;
    final dose = medication.dose.trim();
    if (dose.isEmpty || !normalizeSearch(dose).contains(normalizedQuery)) {
      continue;
    }
    doses.putIfAbsent(normalizeSearch(dose), () => dose);
  }

  return doses.values.toList()
    ..sort((first, second) {
      final firstValue = _numericDose(first);
      final secondValue = _numericDose(second);
      if (firstValue != null && secondValue != null) {
        return firstValue.compareTo(secondValue);
      }
      return first.compareTo(second);
    });
}

double? _numericDose(String dose) {
  final match = RegExp(r'\d+(?:[.,]\d+)?').firstMatch(dose);
  return double.tryParse(match?.group(0)?.replaceFirst(',', '.') ?? '');
}

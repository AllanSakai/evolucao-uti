class Bed {
  const Bed({
    required this.id,
    required this.unitCode,
    required this.label,
    required this.isIsolation,
  });

  final String id;
  final String unitCode;
  final String label;
  final bool isIsolation;

  String get displayName =>
      isIsolation ? 'UTI $unitCode - $label' : 'UTI $unitCode - Leito $label';
}

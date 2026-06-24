import '../models/bed.dart';

List<Bed> generateNumericBeds({
  required String unitCode,
  required int start,
  required int end,
}) {
  assert(start <= end);
  return [
    for (var number = start; number <= end; number++)
      Bed(
        id: '$unitCode-$number',
        unitCode: unitCode,
        label: '$number',
        isIsolation: false,
      ),
  ];
}

List<Bed> generateIsolationBeds({
  required String unitCode,
  required List<String> labels,
}) =>
    [
      for (final label in labels)
        Bed(
          id: '$unitCode-$label',
          unitCode: unitCode,
          label: label,
          isIsolation: true,
        ),
    ];

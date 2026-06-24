import '../models/icu_unit.dart';
import '../utils/bed_generators.dart';

final List<IcuUnit> icuUnits = [
  IcuUnit(
      code: 'A',
      name: 'UTI A',
      beds: generateNumericBeds(unitCode: 'A', start: 1, end: 11)),
  IcuUnit(
      code: 'B',
      name: 'UTI B',
      beds: generateNumericBeds(unitCode: 'B', start: 12, end: 22)),
  IcuUnit(
    code: 'C',
    name: 'UTI C',
    beds: [
      ...generateNumericBeds(unitCode: 'C', start: 23, end: 30),
      ...generateIsolationBeds(
          unitCode: 'C', labels: ['ISO1', 'ISO2', 'ISO3', 'ISO4']),
    ],
  ),
  IcuUnit(
    code: 'D',
    name: 'UTI D',
    beds: [
      ...generateNumericBeds(unitCode: 'D', start: 31, end: 42),
      ...generateIsolationBeds(unitCode: 'D', labels: ['ISO5']),
    ],
  ),
  IcuUnit(
    code: 'E',
    name: 'UTI E',
    beds: [
      ...generateNumericBeds(unitCode: 'E', start: 1, end: 12),
      ...generateIsolationBeds(unitCode: 'E', labels: ['ISO1', 'ISO2', 'ISO3']),
    ],
  ),
  IcuUnit(
    code: 'F',
    name: 'UTI F',
    beds: [
      ...generateNumericBeds(unitCode: 'F', start: 13, end: 24),
      ...generateIsolationBeds(unitCode: 'F', labels: ['ISO4']),
    ],
  ),
];

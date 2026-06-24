import 'bed.dart';

class IcuUnit {
  const IcuUnit({
    required this.code,
    required this.name,
    required this.beds,
  });

  final String code;
  final String name;
  final List<Bed> beds;
}

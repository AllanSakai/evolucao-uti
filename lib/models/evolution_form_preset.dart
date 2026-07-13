import 'evolution_data.dart';

class EvolutionFormPreset {
  const EvolutionFormPreset({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.data,
  });

  factory EvolutionFormPreset.fromJson(Map<String, dynamic> json) =>
      EvolutionFormPreset(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        data: EvolutionData.fromJson(
          (json['data'] as Map).cast<String, dynamic>(),
        ),
      );

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final EvolutionData data;

  EvolutionFormPreset copyWith({
    String? name,
    DateTime? updatedAt,
    EvolutionData? data,
  }) =>
      EvolutionFormPreset(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        data: data ?? this.data,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'data': data.toJson(),
      };
}

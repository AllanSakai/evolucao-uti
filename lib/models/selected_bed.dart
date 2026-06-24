import 'bed.dart';
import 'evolution_data.dart';

enum BedProgressStatus { pending, inProgress, completed }

class SelectedBed {
  SelectedBed({
    required this.bed,
    this.evolutionData,
    this.status = BedProgressStatus.pending,
  });

  final Bed bed;
  EvolutionData? evolutionData;
  BedProgressStatus status;
}

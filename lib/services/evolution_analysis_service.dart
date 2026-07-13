import '../models/evolution_data.dart';
import '../models/selected_bed.dart';
import 'evolution_generator.dart';

class BedClinicalChecklist {
  const BedClinicalChecklist({
    required this.pendingItems,
    required this.warnings,
    required this.summaryFlags,
  });

  final List<String> pendingItems;
  final List<String> warnings;
  final List<String> summaryFlags;
}

class UnitClinicalSummary {
  const UnitClinicalSummary({
    required this.total,
    required this.completed,
    required this.pending,
    required this.inProgress,
    required this.mechanicalVentilation,
    required this.vasoactiveSupport,
    required this.febrile,
    required this.lowDiuresis,
    required this.positiveBalance,
    required this.negativeBalance,
    required this.bedsWithPendingItems,
  });

  final int total;
  final int completed;
  final int pending;
  final int inProgress;
  final int mechanicalVentilation;
  final int vasoactiveSupport;
  final int febrile;
  final int lowDiuresis;
  final int positiveBalance;
  final int negativeBalance;
  final int bedsWithPendingItems;
}

class EvolutionAnalysisService {
  const EvolutionAnalysisService();

  BedClinicalChecklist checklist(EvolutionData? data) {
    if (data == null) {
      return const BedClinicalChecklist(
        pendingItems: ['Sem evolucao preenchida'],
        warnings: [],
        summaryFlags: [],
      );
    }

    final pending = <String>[];
    final warnings = <String>[];
    final flags = <String>[];

    if (_blank(data.bloodPressure) &&
        _blank(data.meanArterialPressure) &&
        _blank(data.heartRate)) {
      pending.add('Sinais vitais');
    }
    if (data.ventilatorySupport == null) {
      pending.add('Suporte ventilatorio');
    }
    if (_isMechanicalVentilation(data) &&
        (_blank(data.ventilationMode) ||
            _blank(data.fio2) ||
            _blank(data.peep))) {
      pending.add('Parametros de VM');
    }
    if (data.hemodynamicState == null ||
        data.bloodPressureState == null ||
        data.vasoactiveSupport == null) {
      pending.add('Hemodinamica');
    }
    if (data.diuresisType == null ||
        (data.diuresisType == DiuresisType.svd &&
            _blank(data.diuresisVolume))) {
      pending.add('Diurese');
    }
    if (data.diuresisType != DiuresisType.espontanea &&
        _blank(data.fluidBalance)) {
      pending.add('Balanco hidrico');
    }
    if (_blank(data.generalCondition) ||
        _blank(data.pulmonaryExam) ||
        _blank(data.cardiovascularExam) ||
        _blank(data.abdominalExam) ||
        _blank(data.neurologicalExam)) {
      pending.add('Exame fisico');
    }

    final diuresis = diuresisMlKgHour(data);
    if (diuresis != null && diuresis < 0.5) {
      warnings.add('Diurese baixa (${_formatNumber(diuresis)} mL/kg/h)');
      flags.add('Diurese baixa');
    }
    if (data.temperatureState == TemperatureState.febril) {
      flags.add('Febril');
    }
    if (_isMechanicalVentilation(data)) {
      flags.add('VM');
    }
    if (data.vasoactiveSupport == VasoactiveSupport.comDva) {
      flags.add('DVA');
    }
    final balance = _parseNumber(data.fluidBalance);
    if (balance != null) {
      flags.add(balance >= 0 ? 'BH positivo' : 'BH negativo');
    }

    return BedClinicalChecklist(
      pendingItems: List.unmodifiable(pending),
      warnings: List.unmodifiable(warnings),
      summaryFlags: List.unmodifiable(flags),
    );
  }

  UnitClinicalSummary summarize(List<SelectedBed> beds) {
    var completed = 0;
    var pending = 0;
    var inProgress = 0;
    var mechanicalVentilation = 0;
    var vasoactiveSupport = 0;
    var febrile = 0;
    var lowDiuresis = 0;
    var positiveBalance = 0;
    var negativeBalance = 0;
    var bedsWithPendingItems = 0;

    for (final selected in beds) {
      switch (selected.status) {
        case BedProgressStatus.completed:
          completed++;
        case BedProgressStatus.pending:
          pending++;
        case BedProgressStatus.inProgress:
          inProgress++;
      }

      final data = selected.evolutionData;
      final checklist = this.checklist(data);
      if (checklist.pendingItems.isNotEmpty) bedsWithPendingItems++;
      if (data == null) continue;
      if (_isMechanicalVentilation(data)) mechanicalVentilation++;
      if (data.vasoactiveSupport == VasoactiveSupport.comDva) {
        vasoactiveSupport++;
      }
      if (data.temperatureState == TemperatureState.febril) febrile++;
      final diuresis = diuresisMlKgHour(data);
      if (diuresis != null && diuresis < 0.5) lowDiuresis++;
      final balance = _parseNumber(data.fluidBalance);
      if (balance != null && balance >= 0) positiveBalance++;
      if (balance != null && balance < 0) negativeBalance++;
    }

    return UnitClinicalSummary(
      total: beds.length,
      completed: completed,
      pending: pending,
      inProgress: inProgress,
      mechanicalVentilation: mechanicalVentilation,
      vasoactiveSupport: vasoactiveSupport,
      febrile: febrile,
      lowDiuresis: lowDiuresis,
      positiveBalance: positiveBalance,
      negativeBalance: negativeBalance,
      bedsWithPendingItems: bedsWithPendingItems,
    );
  }

  String exportShift(List<SelectedBed> beds) {
    final generator = EvolutionGenerator();
    final filled = beds.where((selected) => selected.evolutionData != null);
    return filled
        .map((selected) => generator.generateSummary(
              selected.evolutionData!,
              bedLabel: selected.bed.displayName,
            ))
        .join('\n\n---\n\n');
  }

  double? diuresisMlKgHour(EvolutionData data) {
    final volume = _parseNumber(data.diuresisVolume);
    final period = _parseNumber(data.diuresisPeriod);
    final weight = _parseNumber(data.weight);
    if (volume == null ||
        period == null ||
        weight == null ||
        period <= 0 ||
        weight <= 0) {
      return null;
    }
    return volume / period / weight;
  }

  bool _isMechanicalVentilation(EvolutionData data) =>
      data.ventilatorySupport == VentilatorySupport.iotVm ||
      data.ventilatorySupport == VentilatorySupport.tqtVm;

  bool _blank(String? value) => value == null || value.trim().isEmpty;

  double? _parseNumber(String? value) {
    final clean =
        value?.trim().replaceAll(RegExp(r'[^0-9,.-]'), '').replaceAll(',', '.');
    if (clean == null || clean.isEmpty) return null;
    return double.tryParse(clean);
  }

  String _formatNumber(double value) =>
      value.toStringAsFixed(2).replaceAll('.', ',');
}

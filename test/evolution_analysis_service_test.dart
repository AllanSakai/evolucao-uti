import 'package:evolucao_uti/models/bed.dart';
import 'package:evolucao_uti/models/evolution_data.dart';
import 'package:evolucao_uti/models/selected_bed.dart';
import 'package:evolucao_uti/services/evolution_analysis_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = EvolutionAnalysisService();
  const bed = Bed(id: 'A-1', unitCode: 'A', label: '1', isIsolation: false);

  test('checklist leve aponta evolucao vazia', () {
    final checklist = service.checklist(null);

    expect(checklist.pendingItems, ['Sem evolucao preenchida']);
    expect(checklist.warnings, isEmpty);
  });

  test('checklist aponta pendencias em evolucao parcial', () {
    final checklist = service.checklist(const EvolutionData(
      sex: Sex.masculino,
      ventilatorySupport: VentilatorySupport.iotVm,
      ventilationMode: 'PCV',
      fio2: '40',
      diuresisType: DiuresisType.svd,
    ));

    expect(checklist.pendingItems, contains('Sinais vitais'));
    expect(checklist.pendingItems, contains('Parametros de VM'));
    expect(checklist.pendingItems, contains('Diurese'));
    expect(checklist.pendingItems, contains('Balanco hidrico'));
    expect(checklist.summaryFlags, contains('VM'));
  });

  test('diurese espontanea nao exige volume nem balanco hidrico', () {
    final checklist = service.checklist(const EvolutionData(
      sex: Sex.masculino,
      bloodPressure: '120/80',
      heartRate: '82',
      ventilatorySupport: VentilatorySupport.arAmbiente,
      hemodynamicState: HemodynamicState.estavel,
      bloodPressureState: BloodPressureState.normotenso,
      vasoactiveSupport: VasoactiveSupport.semDva,
      diuresisType: DiuresisType.espontanea,
      generalCondition: 'BEG',
      pulmonaryExam: 'MV+',
      cardiovascularExam: 'BCRNF',
      abdominalExam: 'FLACIDO',
      neurologicalExam: 'GCS 15',
    ));

    expect(checklist.pendingItems, isNot(contains('Diurese')));
    expect(checklist.pendingItems, isNot(contains('Balanco hidrico')));
  });

  test('checklist completo fica sem pendencias e sinaliza riscos', () {
    final checklist = service.checklist(const EvolutionData(
      sex: Sex.feminino,
      bloodPressure: '120/80',
      heartRate: '90',
      ventilatorySupport: VentilatorySupport.arAmbiente,
      hemodynamicState: HemodynamicState.estavel,
      bloodPressureState: BloodPressureState.normotenso,
      vasoactiveSupport: VasoactiveSupport.semDva,
      temperatureState: TemperatureState.febril,
      diuresisType: DiuresisType.svd,
      diuresisVolume: '200',
      diuresisPeriod: '12H',
      weight: '70',
      fluidBalance: '-300',
      generalCondition: 'BEG',
      pulmonaryExam: 'MV+',
      cardiovascularExam: 'BCRNF',
      abdominalExam: 'FLACIDO',
      neurologicalExam: 'GCS 15',
    ));

    expect(checklist.pendingItems, isEmpty);
    expect(checklist.warnings.single, contains('Diurese baixa'));
    expect(checklist.summaryFlags, containsAll(['Febril', 'Diurese baixa']));
    expect(checklist.summaryFlags, contains('BH negativo'));
  });

  test('resume indicadores da ala', () {
    final beds = [
      SelectedBed(
        bed: bed,
        status: BedProgressStatus.completed,
        evolutionData: const EvolutionData(
          sex: Sex.masculino,
          ventilatorySupport: VentilatorySupport.iotVm,
          vasoactiveSupport: VasoactiveSupport.comDva,
          temperatureState: TemperatureState.febril,
          diuresisType: DiuresisType.svd,
          diuresisVolume: '200',
          diuresisPeriod: '12H',
          weight: '70',
          fluidBalance: '+500',
        ),
      ),
      SelectedBed(
        bed: const Bed(
          id: 'A-2',
          unitCode: 'A',
          label: '2',
          isIsolation: false,
        ),
        status: BedProgressStatus.pending,
        evolutionData: const EvolutionData(
          sex: Sex.feminino,
          fluidBalance: '-100',
        ),
      ),
    ];

    final summary = service.summarize(beds);

    expect(summary.total, 2);
    expect(summary.completed, 1);
    expect(summary.pending, 1);
    expect(summary.mechanicalVentilation, 1);
    expect(summary.vasoactiveSupport, 1);
    expect(summary.febrile, 1);
    expect(summary.lowDiuresis, 1);
    expect(summary.positiveBalance, 1);
    expect(summary.negativeBalance, 1);
  });

  test('exporta apenas leitos preenchidos', () {
    final text = service.exportShift([
      SelectedBed(
        bed: bed,
        evolutionData: const EvolutionData(sex: Sex.masculino),
      ),
      SelectedBed(
        bed: const Bed(
          id: 'A-2',
          unitCode: 'A',
          label: '2',
          isIsolation: false,
        ),
      ),
    ]);

    expect(text, contains('UTI A - BOX 1'));
    expect(text, isNot(contains('LEITO 2')));
  });

  test('exportacao vazia retorna texto vazio', () {
    expect(service.exportShift([SelectedBed(bed: bed)]), isEmpty);
  });
}

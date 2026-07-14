import 'package:evolucao_uti/models/evolution_data.dart';
import 'package:evolucao_uti/services/evolution_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late EvolutionGenerator generator;

  setUp(() => generator = EvolutionGenerator());

  group('concordancia', () {
    test('usa masculino', () {
      final text = generator.generate(const EvolutionData(
        sex: Sex.masculino,
        neurologicalState: NeurologicalState.acordado,
        bloodPressureState: BloodPressureState.normotenso,
      ));
      expect(text, contains('ACORDADO'));
      expect(text, contains('NORMOTENSO'));
      expect(text, isNot(contains('ACORDADA')));
    });

    test('usa feminino', () {
      final text = generator.generate(const EvolutionData(
        sex: Sex.feminino,
        neurologicalState: NeurologicalState.sedado,
        bloodPressureState: BloodPressureState.hipotenso,
      ));
      expect(text, contains('SEDADA'));
      expect(text, contains('HIPOTENSA'));
    });
  });

  test('modelo de paciente acordado em ar ambiente', () {
    final text = generator.generate(const EvolutionData(
      sex: Sex.masculino,
      template: EvolutionTemplate.acordadoArAmbiente,
      neurologicalState: NeurologicalState.acordado,
      ventilatorySupport: VentilatorySupport.arAmbiente,
      oxygenSaturation: '97',
    ));
    expect(text,
        contains('PACIENTE EM LEITO DE UTI ACORDADO, LUCIDO, COMUNICATIVO.'));
    expect(text, contains('EUPNEICO EM AR AMBIENTE, SPO2 97%.'));
    expect(
        text, contains('AO EXAME: CORADO, HIDRATADO, ACIANOTICO, ANICTERICO.'));
  });

  test('modelo de paciente sedado em IOT e VM inclui parametros informados',
      () {
    final text = generator.generate(const EvolutionData(
      sex: Sex.feminino,
      neurologicalState: NeurologicalState.sedado,
      ventilatorySupport: VentilatorySupport.iotVm,
      ventilationMode: 'PCV',
      respiratoryRate: '18',
      tidalVolume: '420',
      fio2: '40',
      peep: '8',
    ));
    expect(text, contains('SEDADA'));
    expect(
        text,
        contains(
            'EM IOT+VM (MODO PCV, FR 18, VT RESULTANTE 420 ML, FIO2 40%, PEEP 8)'));
    expect(text, contains('MODO PCV'));
    expect(text, contains('FR 18'));
    expect(text, contains('VT RESULTANTE 420 ML'));
    expect(text, contains('FIO2 40%'));
    expect(text, contains('PEEP 8'));
  });

  test('aceita campos faltantes sem criar secoes vazias', () {
    final text = generator.generate(const EvolutionData(sex: Sex.masculino));
    expect(text, startsWith('PACIENTE EM LEITO DE UTI.'));
    expect(text, contains('AO EXAME: CORADO, HIDRATADO'));
    expect(text, isNot(contains('EXAME FISICO')));
  });

  test('nao inventa dados nao informados', () {
    final text = generator.generate(const EvolutionData(
      sex: Sex.masculino,
      ventilatorySupport: VentilatorySupport.iotVm,
      fio2: '35',
    ));
    expect(text, contains('FIO2 35%'));
    expect(text, isNot(contains('PEEP')));
    expect(text, isNot(contains('SPO2')));
    expect(text, isNot(contains('DVA')));
    expect(text, isNot(contains('AFEBRIL')));
    expect(text, isNot(contains('DIETA')));
  });

  test('gera todo o texto em caixa alta', () {
    final text = generator.generate(const EvolutionData(
      sex: Sex.feminino,
      notes: 'Manter vigilancia clinica',
    ));
    expect(text, text.toUpperCase());
  });

  test('gera tendencias de pressao com concordancia neutra', () {
    final hypotension = generator.generate(const EvolutionData(
      sex: Sex.feminino,
      bloodPressureState: BloodPressureState.tendendoHipotensao,
    ));
    final hypertension = generator.generate(const EvolutionData(
      sex: Sex.masculino,
      bloodPressureState: BloodPressureState.tendendoHipertensao,
    ));
    expect(hypotension, contains('TENDENDO A HIPOTENSAO'));
    expect(hypertension, contains('TENDENDO A HIPERTENSAO'));
  });

  test('descreve produtos patologicos nas fezes somente quando informados', () {
    final present = generator.generate(const EvolutionData(
      sex: Sex.masculino,
      bowelMovement: BowelMovement.presentes,
      stoolPathologicalProducts: StoolPathologicalProducts.presentes,
      stoolPathologicalDescription: 'muco e sangue',
    ));
    expect(present, contains('PRODUTOS PATOLOGICOS NAS FEZES: MUCO E SANGUE'));

    final omitted = generator.generate(const EvolutionData(
      sex: Sex.masculino,
      bowelMovement: BowelMovement.presentes,
    ));
    expect(omitted, isNot(contains('PRODUTOS PATOLOGICOS')));
  });

  test('aceita VCV PCV e PSV como modos de ventilacao', () {
    for (final mode in ['VCV', 'PCV', 'PSV']) {
      final text = generator.generate(EvolutionData(
        sex: Sex.masculino,
        ventilatorySupport: VentilatorySupport.iotVm,
        ventilationMode: mode,
      ));
      expect(text, contains('MODO $mode'));
    }
  });

  test('VCV gera somente parametros relevantes do modo', () {
    final text = generator.generate(const EvolutionData(
      sex: Sex.masculino,
      ventilatorySupport: VentilatorySupport.iotVm,
      ventilationMode: 'VCV',
      respiratoryRate: '20',
      tidalVolume: '450',
      inspiratoryFlow: '50',
      controlledPressure: '15',
    ));
    expect(text, contains('VT 450 ML'));
    expect(text, contains('FLUXO INSPIRATORIO 50 L/MIN'));
    expect(text, isNot(contains('PC 15')));
  });

  test('PCV gera pressao e tempo inspiratorio com VT resultante', () {
    final text = generator.generate(const EvolutionData(
      sex: Sex.masculino,
      ventilatorySupport: VentilatorySupport.iotVm,
      ventilationMode: 'PCV',
      controlledPressure: '16',
      inspiratoryTime: '0,9',
      tidalVolume: '380',
    ));
    expect(text, contains('PC 16 CMH2O'));
    expect(text, contains('TI 0,9 S'));
    expect(text, contains('VT RESULTANTE 380 ML'));
  });

  test('PSV gera suporte trigger ciclagem e valores espontaneos', () {
    final text = generator.generate(const EvolutionData(
      sex: Sex.feminino,
      ventilatorySupport: VentilatorySupport.iotVm,
      ventilationMode: 'PSV',
      pressureSupport: '10',
      triggerSensitivity: '2 L/min',
      cyclingCriterion: '25',
      respiratoryRate: '18',
      tidalVolume: '410',
    ));
    expect(text, contains('PS 10 CMH2O'));
    expect(text, contains('TRIGGER 2 L/MIN'));
    expect(text, contains('CICLAGEM 25%'));
    expect(text, contains('FR ESPONTANEA 18'));
    expect(text, contains('VT EXPIRADO 410 ML'));
  });

  test('PSV ignora sincronia com ventilador', () {
    const data = EvolutionData(
      sex: Sex.masculino,
      ventilatorySupport: VentilatorySupport.iotVm,
      ventilationMode: 'PSV',
      ventilatorSynchrony: false,
    );
    expect(generator.generate(data), isNot(contains('ASSINCRONICO')));
    expect(generator.generateSummary(data), isNot(contains('ASSINCRÔNICO')));
  });

  test('aplica unidades de sedacao e DVA', () {
    final text = generator.generate(const EvolutionData(
      sex: Sex.masculino,
      neurologicalState: NeurologicalState.sedado,
      sedoanalgesia: 'midazolam 10',
      vasoactiveSupport: VasoactiveSupport.comDva,
      vasoactiveDrugs: 'noradrenalina 0,1',
    ));
    expect(text, contains('MIDAZOLAM 10 ML/H'));
    expect(text, contains('NORADRENALINA 0,1 MCG/KG/MIN'));
  });

  test('nao afirma sedoanalgesia sem vazao informada', () {
    final text = generator.generate(const EvolutionData(
      sex: Sex.feminino,
      neurologicalState: NeurologicalState.sedado,
    ));
    expect(text, contains('SEDADA'));
    expect(text, isNot(contains('SEDOANALGESIA')));
  });

  test('padroniza periodos para diurese e balanco', () {
    final text = generator.generate(const EvolutionData(
      sex: Sex.masculino,
      diuresisType: DiuresisType.svd,
      diuresisVolume: '500',
      diuresisPeriod: '12H',
      fluidBalance: '+300',
      fluidBalancePeriod: '18H',
    ));
    expect(text, contains('DIURESE POR SVD DE 500 ML NAS ULTIMAS 12H'));
    expect(text, contains('BH POSITIVO EM +300 ML NAS ULTIMAS 18H'));
  });

  test('usa padroes quando diurese espontanea e BH estao em branco', () {
    final text = generator.generate(const EvolutionData(
      sex: Sex.masculino,
      diuresisType: DiuresisType.espontanea,
    ));
    expect(
        text,
        contains(
            'DIURESE ESPONTANEA E EFETIVA, NÃO QUANTIFICADA, SEM QUEIXAS'));
    expect(text, contains('BH NÃO QUANTIFICADO'));
  });

  test('resumo usa a nova estrutura compacta', () {
    final summary = generator.generateSummary(
      const EvolutionData(
        sex: Sex.masculino,
        neurologicalState: NeurologicalState.acordado,
        ventilatorySupport: VentilatorySupport.arAmbiente,
        oxygenSaturation: '97',
        hemodynamicState: HemodynamicState.estavel,
        vasoactiveSupport: VasoactiveSupport.semDva,
        bloodPressureState: BloodPressureState.normotenso,
        diuresisType: DiuresisType.espontanea,
        diuresisPeriod: '18H',
      ),
      bedLabel: 'UTI A - LEITO 3',
    );
    expect(summary, startsWith('RESUMO ESTRUTURADO'));
    expect(summary, contains('IDENTIFICAÇÃO DO LEITO: UTI A - LEITO 3'));
    expect(summary, contains('SEXO: M'));
    expect(summary, contains('ESTADO: ACORDADO'));
    expect(summary, contains('RESP: AR AMBIENTE; SPO2 97%'));
    expect(summary, contains('HEMO: ESTÁVEL; SEM DVA; NORMOTENSO'));
    expect(summary, contains('DIURESE: ESPONTÂNEA; NÃO QUANTIFICADA'));
    expect(summary, contains('PERÍODO AVALIADO: 18H'));
    expect(summary, contains('BH: NÃO QUANTIFICADO'));
    expect(summary, isNot(contains('MODELO A USAR')));
    expect(summary, isNot(contains('FORMATAÇÃO OBRIGATÓRIA')));
  });

  test('resumo identifica sexo e estado sem declarar o modelo', () {
    final female = generator.generateSummary(
      const EvolutionData(
        sex: Sex.feminino,
        neurologicalState: NeurologicalState.acordado,
      ),
    );
    final sedated = generator.generateSummary(
      const EvolutionData(
        sex: Sex.masculino,
        neurologicalState: NeurologicalState.sedado,
      ),
    );
    expect(female, contains('SEXO: F'));
    expect(female, contains('ESTADO: ACORDADA'));
    expect(sedated, contains('SEXO: M'));
    expect(sedated, contains('ESTADO: SEDADO'));
    expect(female, isNot(contains('MODELO')));
    expect(sedated, isNot(contains('MODELO')));
  });

  test('usa modelo de exame fisico quando todo o bloco esta vazio', () {
    final awake = generator.generate(const EvolutionData(
      sex: Sex.feminino,
      neurologicalState: NeurologicalState.acordado,
    ));
    expect(awake, contains('AO EXAME: CORADA, HIDRATADA'));
    expect(awake, contains('AP: MV+ SEM RA BILATERALMENTE'));
    expect(awake, contains('NEURO: GCS 15'));

    final sedated = generator.generate(const EvolutionData(
      sex: Sex.masculino,
      neurologicalState: NeurologicalState.sedado,
    ));
    expect(sedated, contains('NEURO: RASS -5, PIFR'));
  });

  test('gera drogas selecionadas com vazoes e unidades proprias', () {
    final text = generator.generate(const EvolutionData(
      sex: Sex.masculino,
      neurologicalState: NeurologicalState.sedado,
      sedationDrugRates: {
        'Propofol': '12',
        'Fentanila': '8',
      },
      vasoactiveSupport: VasoactiveSupport.comDva,
      vasoactiveDrugRates: {
        'Noradrenalina': '0,1',
        'Vasopressina': '0,03',
      },
    ));
    expect(text, contains('PROPOFOL 12 ML/H'));
    expect(text, contains('FENTANILA 8 ML/H'));
    expect(text, contains('NORADRENALINA 0,1 MCG/KG/MIN'));
    expect(text, contains('VASOPRESSINA 0,03 U/MIN'));
  });

  test('resumo compacto preserva os campos clinicos coletados', () {
    final summary = generator.generateSummary(const EvolutionData(
      sex: Sex.masculino,
      neurologicalState: NeurologicalState.sedado,
      rass: '-4',
      ventilatorySupport: VentilatorySupport.iotVm,
      ventilationMode: 'PCV',
      respiratoryRate: '20',
      controlledPressure: '15',
      fio2: '40',
      peep: '7',
      ventilatorSynchrony: true,
      oxygenSaturation: '89',
      meanArterialPressure: '72',
      weight: '70',
      vasoactiveSupport: VasoactiveSupport.comDva,
      diuresisType: DiuresisType.svd,
      diuresisVolume: '500',
      diuresisPeriod: '18H',
      lowerLimbsExam: 'COM EDEMA ++/4+ EM MID',
      upperLimbsExam: 'SEM EDEMA',
    ));

    expect(summary, contains('PAM PONTUAL: 72 MMHG'));
    expect(summary, contains('PESO: 70 KG'));
    expect(summary, contains('NEURO: RASS -4'));
    expect(
        summary,
        contains('RESP: IOT+VM; MODO PCV; FR 20; PC 15 CMH2O; '
            'FIO2 40%; PEEP 7 CMH2O; SPO2 89%; SINCRÔNICO'));
    expect(summary, contains('MMII: COM EDEMA ++/4+ EM MID'));
    expect(summary, contains('MMSS: SEM EDEMA'));
    expect(summary, contains('DIURESE: SVD; 500 ML'));
    expect(summary, contains('PERÍODO AVALIADO: 18H'));
  });

  test('resumo compacto representa o caso clinico completo', () {
    final summary = generator.generateSummary(
      const EvolutionData(
        sex: Sex.feminino,
        neurologicalState: NeurologicalState.acordado,
        weight: '65',
        ventilatorySupport: VentilatorySupport.arAmbiente,
        oxygenSaturation: '97',
        hemodynamicState: HemodynamicState.estavel,
        vasoactiveSupport: VasoactiveSupport.semDva,
        bloodPressureState: BloodPressureState.tendendoHipotensao,
        bloodPressure: '120/80',
        heartRate: '77',
        temperatureState: TemperatureState.afebril,
        measuredTemperature: '36,6',
        dietRoute: DietRoute.vo,
        vomiting: true,
        gastrointestinalNotes:
            'LEVE DESCONFORTO ABDOMINAL RESPONSIVO À ANALGESIA',
        hgtMinimum: '66',
        hgtMaximum: '73',
        diuresisType: DiuresisType.espontanea,
        diuresisPeriod: '18H',
        bowelMovement: BowelMovement.ausentes,
        daysSinceLastBowelMovement: '5',
        generalCondition: 'BEG; CORADA; HIDRATADA; ACIANÓTICA; ANICTÉRICA',
        pulmonaryExam: 'NORMAL',
        cardiovascularExam:
            'BCRNF SS 2T; TEC<3S; PULSOS PALPÁVEIS; EXTREMIDADES AQUECIDAS',
        abdominalExam: 'PLANO; FLÁCIDO; RH+; INDOLOR; SEM PERITONITE',
        lowerLimbsExam: 'NORMAL',
        upperLimbsExam: 'SEM EDEMA',
        neurologicalExam: 'NORMAL',
      ),
      bedLabel: 'UTI A - LEITO 1',
    );

    expect(summary, contains('IDENTIFICAÇÃO DO LEITO: UTI A - LEITO 1'));
    expect(summary, contains('RESP: AR AMBIENTE; SPO2 97%'));
    expect(summary, contains('HEMO: ESTÁVEL; SEM DVA; TENDENDO À HIPOTENSÃO'));
    expect(summary, contains('PA PONTUAL: 120/80 MMHG'));
    expect(summary, contains('TEMP: AFEBRIL; 36,6 °C'));
    expect(
        summary,
        contains('GI: VÔMITOS; LEVE DESCONFORTO ABDOMINAL '
            'RESPONSIVO À ANALGESIA'));
    expect(summary, contains('HGT: 66 - 73 MG/DL'));
    expect(summary, contains('DIURESE: ESPONTÂNEA; NÃO QUANTIFICADA'));
    expect(summary, contains('PERÍODO AVALIADO: 18H'));
    expect(summary, contains('EVACUAÇÃO: AUSENTE; HÁ 5 DIAS'));
    expect(summary, contains('NEURO: NORMAL'));
  });
}

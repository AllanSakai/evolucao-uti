import '../models/evolution_data.dart';
import '../utils/drug_options.dart';

class EvolutionGenerator {
  String generateSummary(EvolutionData data) {
    final lines = <String>[
      'RESUMO ESTRUTURADO PARA GERAR EVOLUÇÃO MÉDICA DE UTI',
      '',
      'INSTRUÇÃO PARA O GPT:',
      'ESCREVA UMA EVOLUÇÃO MÉDICA DE PLANTÃO EM UTI, EM PORTUGUÊS DO BRASIL, TEXTO CORRIDO, TÉCNICA, OBJETIVA E EM CAIXA ALTA. CORRIJA ORTOGRAFIA E ACENTUAÇÃO DO TEXTO FINAL. USE APENAS OS DADOS ABAIXO. NÃO INVENTE INFORMAÇÕES NÃO INFORMADAS. NÃO PRESCREVA CONDUTAS. SE HOUVER INCONSISTÊNCIAS OU DADOS CLINICAMENTE IMPORTANTES AUSENTES, APONTE ANTES OU DEPOIS DO TEXTO COMO ALERTAS NÃO PRESCRITIVOS.',
      '',
    ];

    void section(String title, List<String> items) {
      final filtered = items.where((item) => item.trim().isNotEmpty).toList();
      if (filtered.isEmpty) return;
      lines
        ..add(title)
        ..addAll(filtered.map((item) => '- $item'))
        ..add('');
    }

    section('IDENTIFICAÇÃO / CONTEXTO', [
      'Sexo: ${data.sex == Sex.feminino ? 'feminino' : 'masculino'}.',
      'Local: ${data.local}.',
      if (_clean(data.weight) != null) 'Peso: ${_clean(data.weight)} kg.',
      if (data.neurologicalState != null)
        'Estado neurológico: ${_neurological(data.neurologicalState!, data.sex == Sex.feminino)}.',
      if (_clean(data.rass) != null) 'RASS: ${_clean(data.rass)}.',
    ]);

    section('DADOS ADICIONAIS COLETADOS / VALIDAÇÕES POSSÍVEIS', [
      if (_clean(data.meanArterialPressure) != null)
        'PAM coletada: ${_clean(data.meanArterialPressure)} mmHg.',
      if (_clean(data.weight) != null)
        'Peso coletado para cálculo de diurese: ${_clean(data.weight)} kg.',
      if (_clean(data.rass) != null) 'RASS coletado: ${_clean(data.rass)}.',
      if (data.ventilatorSynchrony != null)
        'Sincronia com ventilador coletada: ${data.ventilatorSynchrony! ? 'sincrônico' : 'assincrônico'}.',
      if (_clean(data.lowerLimbsExam) != null)
        'Edema/alterações em MMII coletados: ${_clean(data.lowerLimbsExam)}.',
      if (_clean(data.upperLimbsExam) != null)
        'Edema em MMSS coletado: ${_clean(data.upperLimbsExam)}.',
      if (_clean(data.meanArterialPressure) != null &&
          data.vasoactiveSupport == VasoactiveSupport.comDva)
        'Como há DVA e PAM informada, avaliar redação: hemodinamicamente estável às custas de DVA / dependente de DVA mantendo PAM adequada.',
      if (_clean(data.oxygenSaturation) != null)
        'SpO2 disponível para avaliar hipoxemia/saturação limítrofe.',
      if (_clean(data.diuresisVolume) != null &&
          _clean(data.diuresisPeriod) != null &&
          _clean(data.weight) != null)
        'Há dados suficientes para calcular mL/kg/h da diurese.',
    ]);

    section('RESPIRATÓRIO / OXIGENAÇÃO / VM', [
      if (data.ventilatorySupport != null)
        'Suporte ventilatório: ${_support(data.ventilatorySupport!)}.',
      if (_clean(data.ventilationMode) != null)
        'Modo ventilatório: ${_clean(data.ventilationMode)}.',
      if (_clean(data.respiratoryRate) != null)
        'FR: ${_clean(data.respiratoryRate)}.',
      if (_clean(data.tidalVolume) != null)
        'VT/VC: ${_clean(data.tidalVolume)} mL.',
      if (_clean(data.controlledPressure) != null)
        'PC: ${_clean(data.controlledPressure)} cmH2O.',
      if (_clean(data.pressureSupport) != null)
        'PS: ${_clean(data.pressureSupport)} cmH2O.',
      if (_clean(data.fio2) != null) 'FiO2: ${_clean(data.fio2)}%.',
      if (_clean(data.peep) != null) 'PEEP: ${_clean(data.peep)} cmH2O.',
      if (_clean(data.oxygenFlow) != null)
        'Vazão de O2 atual: ${_clean(data.oxygenFlow)} L/min.',
      if (_clean(data.homeOxygenFlow) != null)
        'O2 domiciliar: sim, vazão habitual ${_clean(data.homeOxygenFlow)} L/min.',
      if (_clean(data.oxygenSaturation) != null)
        'SpO2: ${_clean(data.oxygenSaturation)}%.',
      if (data.ventilatorSynchrony != null)
        'Sincronia com ventilador: ${data.ventilatorSynchrony! ? 'sincrônico' : 'assincrônico'}.',
    ]);

    section('HEMODINÂMICA / DVA', [
      if (data.hemodynamicState != null)
        'Hemodinâmica: ${data.hemodynamicState == HemodynamicState.estavel ? 'estável' : 'instável'}.',
      if (data.bloodPressureState != null)
        'Padrão pressórico: ${_bloodPressure(data.bloodPressureState!, data.sex == Sex.feminino)}.',
      if (_clean(data.bloodPressure) != null)
        'PA: ${_clean(data.bloodPressure)} mmHg.',
      if (_clean(data.meanArterialPressure) != null)
        'PAM: ${_clean(data.meanArterialPressure)} mmHg.',
      if (_clean(data.heartRate) != null) 'FC: ${_clean(data.heartRate)} bpm.',
      if (data.vasoactiveSupport != null)
        'DVA: ${data.vasoactiveSupport == VasoactiveSupport.comDva ? 'com DVA' : 'sem DVA'}.',
      if (data.vasoactiveDrugRates.isNotEmpty)
        'Drogas vasoativas: ${_formatDrugRates(data.vasoactiveDrugRates, vasoactiveDrugOptions)}.',
      if (_clean(data.vasoactiveDrugs) != null)
        'Drogas vasoativas livres: ${_clean(data.vasoactiveDrugs)}.',
    ]);

    section('TEMPERATURA', [
      if (data.temperatureState != null)
        'Estado termico: ${switch (data.temperatureState!) {
          TemperatureState.afebril => 'afebril',
          TemperatureState.subfebril => 'subfebril',
          TemperatureState.febril => 'febril',
        }}.',
      if (_clean(data.measuredTemperature) != null)
        'Temperatura medida: ${_clean(data.measuredTemperature)} graus Celsius.',
    ]);

    section('DIETA / GASTROINTESTINAL / GLICEMIA', [
      if (data.dietRoute != null) 'Dieta: ${_diet(data.dietRoute!)}.',
      if (data.nausea) 'Náuseas: sim.',
      if (data.vomiting) 'Vômitos: sim.',
      if (data.gastricStasis) 'Estase: sim.',
      if (!data.nausea && !data.vomiting && !data.gastricStasis)
        'Sintomas gastrointestinais marcados: nenhum.',
      if (_clean(data.hgtMinimum) != null || _clean(data.hgtMaximum) != null)
        'HGT: ${_range(data.hgtMinimum, data.hgtMaximum)} mg/dL.',
    ]);

    final mlKgHour = _diuresisMlKgHour(data);
    section('DIURESE / BALANÇO HÍDRICO', [
      if (data.diuresisType != null)
        'Tipo de diurese: ${_diuresis(data.diuresisType!, false)}.',
      if (_clean(data.diuresisVolume) != null)
        'Volume de diurese: ${_clean(data.diuresisVolume)} mL.',
      if (_clean(data.diuresisPeriod) != null)
        'Período da diurese: últimas ${_clean(data.diuresisPeriod)}.',
      if (mlKgHour != null)
        'Diurese calculada: aproximadamente $mlKgHour mL/kg/h.',
      if (_clean(data.weight) != null)
        'Peso usado para cálculo: ${_clean(data.weight)} kg.',
      if (_clean(data.diuresisAppearance) != null)
        'Aspecto da diurese: ${_clean(data.diuresisAppearance)}.',
      if (_clean(data.fluidBalance) != null)
        'Balanço hídrico: ${_clean(data.fluidBalance)} mL no período ${_clean(data.fluidBalancePeriod) ?? 'não informado'}.',
    ]);

    section('EVACUAÇÃO', [
      if (data.bowelMovement != null)
        'Evacuação: ${_bowel(data.bowelMovement!)}.',
      if (data.bowelMovement != BowelMovement.ausentes &&
          data.stoolPathologicalProducts != null)
        'Produtos patológicos nas fezes: ${data.stoolPathologicalProducts == StoolPathologicalProducts.presentes ? 'presentes' : 'ausentes'}.',
      if (_clean(data.stoolPathologicalDescription) != null)
        'Descrição dos produtos patológicos: ${_clean(data.stoolPathologicalDescription)}.',
    ]);

    section('EXAME FÍSICO DIRIGIDO', [
      if (_clean(data.generalCondition) != null)
        'Estado geral: ${_clean(data.generalCondition)}.',
      if (_clean(data.pulmonaryExam) != null)
        'AP: ${_clean(data.pulmonaryExam)}.',
      if (_clean(data.cardiovascularExam) != null)
        'ACV: ${_clean(data.cardiovascularExam)}.',
      if (_clean(data.abdominalExam) != null)
        'Abdome: ${_clean(data.abdominalExam)}.',
      if (_clean(data.lowerLimbsExam) != null)
        'MMII: ${_clean(data.lowerLimbsExam)}.',
      if (_clean(data.upperLimbsExam) != null)
        'MMSS: ${_clean(data.upperLimbsExam)}.',
      if (_clean(data.neurologicalExam) != null)
        'Neuro: ${_clean(data.neurologicalExam)}.',
    ]);

    section('SEDOANALGESIA / INFUSÕES', [
      if (data.sedationDrugRates.isNotEmpty)
        'Sedação/analgesia: ${_formatDrugRates(data.sedationDrugRates, sedationDrugOptions)}.',
      if (_clean(data.continuousInfusions) != null)
        'BIC/infusões contínuas: ${_clean(data.continuousInfusions)}.',
    ]);

    section('OBSERVAÇÕES LIVRES', [
      if (_clean(data.notes) != null) _clean(data.notes)!,
    ]);

    return lines.join('\n').trim().toUpperCase();
  }

  String generate(EvolutionData data) {
    final sentences = <String>[];
    final female = data.sex == Sex.feminino;
    final standardAwake = data.template == EvolutionTemplate.acordadoArAmbiente;

    sentences.add(_opening(data, female, standardAwake));

    final respiratory = _respiratory(data, female, standardAwake);
    if (respiratory != null) sentences.add(respiratory);

    final vitalSigns = <String>[];
    _addIf(vitalSigns, data.bloodPressure, (v) => 'PA $v');
    _addIf(vitalSigns, data.meanArterialPressure, (v) => 'PAM $v');
    _addIf(vitalSigns, data.heartRate, (v) => 'FC $v');
    _sentence(sentences, vitalSigns);

    final hemodynamics = <String>[];
    if (data.hemodynamicState != null) {
      if (data.hemodynamicState == HemodynamicState.estavel &&
          data.vasoactiveSupport == VasoactiveSupport.comDva) {
        hemodynamics.add('HEMODINAMICAMENTE ESTAVEL AS CUSTAS DE DVA');
      } else {
        hemodynamics.add(data.hemodynamicState == HemodynamicState.estavel
            ? 'HEMODINAMICAMENTE ESTAVEL'
            : 'HEMODINAMICAMENTE INSTAVEL');
      }
    }
    if (data.vasoactiveSupport != null &&
        !(data.hemodynamicState == HemodynamicState.estavel &&
            data.vasoactiveSupport == VasoactiveSupport.comDva)) {
      hemodynamics.add(data.vasoactiveSupport == VasoactiveSupport.semDva
          ? 'SEM DVA'
          : 'COM DVA');
    }
    if (data.vasoactiveDrugRates.isNotEmpty) {
      hemodynamics.add(
          _formatDrugRates(data.vasoactiveDrugRates, vasoactiveDrugOptions));
    } else {
      _addIf(hemodynamics, data.vasoactiveDrugs,
          (v) => _withUnit(v, 'MCG/KG/MIN'));
    }
    if (data.bloodPressureState != null) {
      hemodynamics.add(_bloodPressure(data.bloodPressureState!, female));
    }
    _sentence(sentences, hemodynamics);

    if (data.temperatureState != null) {
      final temperature = _clean(data.measuredTemperature);
      final label = switch (data.temperatureState!) {
        TemperatureState.afebril => 'AFEBRIL',
        TemperatureState.subfebril => 'SUBFEBRIL',
        TemperatureState.febril => 'FEBRIL',
      };
      sentences
          .add('$label${temperature == null ? '' : ' (T $temperature°C)'}.');
    }

    final nutrition = <String>[];
    if (data.dietRoute != null) nutrition.add(_diet(data.dietRoute!));
    final symptoms = <String>[];
    if (data.nausea) symptoms.add('NAUSEAS');
    if (data.vomiting) symptoms.add('VOMITOS');
    if (data.gastricStasis) symptoms.add('ESTASE');
    if (symptoms.isNotEmpty) {
      nutrition.add('APRESENTA ${symptoms.join(' E ')}');
    } else if (standardAwake && data.dietRoute != null) {
      nutrition.add('SEM RELATO DE NAUSEAS OU VOMITOS');
    }
    final hgt = _range(data.hgtMinimum, data.hgtMaximum);
    if (hgt != null) nutrition.add('HGT ENTRE $hgt MG/DL');
    _addIf(nutrition, data.capillaryGlucose, (v) => 'HGT $v');
    _sentence(sentences, nutrition);

    _addIf(sentences, data.continuousInfusions, (v) => 'BIC: $v.');

    final renal = <String>[];
    final volume = _clean(data.diuresisVolume);
    final period = _clean(data.diuresisPeriod);
    if (volume != null) {
      final mlKgHour = _diuresisMlKgHour(data);
      renal.add(
          '${_diuresisPrefix(data.diuresisType)} DE $volume ML${period == null ? '' : ' NAS ULTIMAS $period'}${mlKgHour == null ? '' : ' (≈ $mlKgHour ML/KG/H)'}');
    } else if (data.diuresisType != null) {
      renal.add(_diuresis(data.diuresisType!, standardAwake));
    } else if (standardAwake && data.diuresisType == DiuresisType.espontanea) {
      renal.add('NÃO QUANTIFICADA');
    }
    _addIf(renal, data.diuresisAppearance, (v) => v);
    _addIf(renal, data.fluidBalance, (v) {
      final period = _clean(data.fluidBalancePeriod);
      final signal = v.trim().startsWith('-') ? 'NEGATIVO' : 'POSITIVO';
      final normalized = v.trim().startsWith('+') || v.trim().startsWith('-')
          ? v.trim()
          : '+${v.trim()}';
      return 'BH $signal EM $normalized ML${period == null ? '' : ' NAS ULTIMAS $period'}';
    });
    _sentence(sentences, renal);

    final bowel = <String>[];
    if (data.bowelMovement != null) bowel.add(_bowel(data.bowelMovement!));
    if (data.bowelMovement != BowelMovement.ausentes &&
        data.stoolPathologicalProducts != null) {
      if (data.stoolPathologicalProducts ==
          StoolPathologicalProducts.ausentes) {
        bowel.add('SEM PRODUTOS PATOLOGICOS NAS FEZES');
      } else {
        final description = _clean(data.stoolPathologicalDescription);
        bowel.add(description == null
            ? 'COM PRODUTOS PATOLOGICOS NAS FEZES'
            : 'PRODUTOS PATOLOGICOS NAS FEZES: $description');
      }
    }
    _sentence(sentences, bowel);

    final exam = <String>[];
    final examIsEmpty = [
      data.generalCondition,
      data.pulmonaryExam,
      data.cardiovascularExam,
      data.abdominalExam,
      data.lowerLimbsExam,
      data.upperLimbsExam,
      data.neurologicalExam,
    ].every((value) => _clean(value) == null);
    final defaultGeneral = female
        ? 'CORADA, HIDRATADA, ACIANOTICA, ANICTERICA'
        : 'CORADO, HIDRATADO, ACIANOTICO, ANICTERICO';
    _addIf(exam, data.generalCondition, (v) => 'AO EXAME: $v');
    if (examIsEmpty) {
      exam.add('AO EXAME: $defaultGeneral');
    }
    _addExam(exam, 'AP', data.pulmonaryExam,
        examIsEmpty ? 'MV+ SEM RA BILATERALMENTE' : null);
    _addExam(exam, 'ACV', data.cardiovascularExam,
        examIsEmpty ? 'BCRNF SS 2T, TEC< 3S' : null);
    _addExam(
        exam,
        'ABD',
        data.abdominalExam,
        examIsEmpty
            ? 'PLANO, FLACIDO, RH+, INDOLOR A PALPACAO, SEM SINAIS DE PERITONITE'
            : null);
    _addExam(exam, 'MMII', data.lowerLimbsExam,
        examIsEmpty ? 'SEM EDEMA OU EMPASTAMENTO' : null);
    _addExam(exam, 'MMSS', data.upperLimbsExam, null);
    final defaultNeuro = data.neurologicalState == NeurologicalState.sedado
        ? 'RASS ${_clean(data.rass) ?? '-5'}, PIFR'
        : data.neurologicalState == NeurologicalState.acordado || standardAwake
            ? 'GCS 15 (AO4, RV5, RM6), PIFR, MOBILIDADE E FORCA DE 4 MEMBROS PRESERVADA'
            : null;
    _addExam(exam, 'NEURO', data.neurologicalExam,
        examIsEmpty ? defaultNeuro : null);
    if (exam.isNotEmpty) sentences.add('${exam.join('. ')}.');

    final notes = _clean(data.notes);
    if (notes != null) sentences.add('OBSERVACOES: $notes.');

    return sentences
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toUpperCase();
  }

  String _opening(EvolutionData data, bool female, bool standardAwake) {
    final base = 'PACIENTE EM LEITO DE ${data.local}';
    if (standardAwake) {
      return '$base ${female ? 'ACORDADA, LUCIDA, COMUNICATIVA' : 'ACORDADO, LUCIDO, COMUNICATIVO'}.';
    }
    if (data.neurologicalState == NeurologicalState.sedado) {
      final sedation = data.sedationDrugRates.isNotEmpty
          ? _formatDrugRates(data.sedationDrugRates, sedationDrugOptions)
          : _clean(data.sedoanalgesia);
      final state = female ? 'SEDADA' : 'SEDADO';
      return sedation == null
          ? '$base $state.'
          : '$base $state, SOB SEDOANALGESIA (${_withUnit(sedation, 'ML/H')}).';
    }
    if (data.neurologicalState != null) {
      return '$base ${_neurological(data.neurologicalState!, female)}.';
    }
    return '$base.';
  }

  String? _respiratory(EvolutionData data, bool female, bool standardAwake) {
    if (data.ventilatorySupport == null) return null;
    final values = <String>[];
    final support = data.ventilatorySupport!;
    if (support == VentilatorySupport.iotVm ||
        support == VentilatorySupport.tqtVm) {
      final parameters = <String>[];
      _addIf(parameters, data.ventilationMode, (v) => 'MODO $v');
      switch (data.ventilationMode?.toUpperCase()) {
        case 'VCV':
          _addIf(parameters, data.respiratoryRate, (v) => 'FR $v');
          _addIf(parameters, data.tidalVolume, (v) => 'VT $v ML');
          _addIf(parameters, data.inspiratoryFlow,
              (v) => 'FLUXO INSPIRATORIO $v L/MIN');
        case 'PCV':
          _addIf(parameters, data.respiratoryRate, (v) => 'FR $v');
          _addIf(parameters, data.controlledPressure, (v) => 'PC $v CMH2O');
          _addIf(parameters, data.inspiratoryTime, (v) => 'TI $v S');
          _addIf(parameters, data.tidalVolume, (v) => 'VT RESULTANTE $v ML');
        case 'PSV':
          _addIf(parameters, data.pressureSupport, (v) => 'PS $v CMH2O');
          _addIf(parameters, data.triggerSensitivity, (v) => 'TRIGGER $v');
          _addIf(parameters, data.cyclingCriterion, (v) => 'CICLAGEM $v%');
          _addIf(parameters, data.respiratoryRate, (v) => 'FR ESPONTANEA $v');
          _addIf(parameters, data.tidalVolume, (v) => 'VT EXPIRADO $v ML');
        default:
          _addIf(parameters, data.respiratoryRate, (v) => 'FR $v');
          _addIf(parameters, data.tidalVolume, (v) => 'VT $v ML');
      }
      _addIf(parameters, data.fio2, (v) => 'FIO2 $v%');
      _addIf(parameters, data.peep, (v) => 'PEEP $v');
      final saturation = _clean(data.oxygenSaturation);
      final synchrony = data.ventilatorSynchrony == null
          ? ''
          : data.ventilatorSynchrony!
              ? ', SINCRONICO COM O VENTILADOR'
              : ', ASSINCRONICO COM O VENTILADOR';
      final base = _support(support);
      return '$base${parameters.isEmpty ? '' : ' (${parameters.join(', ')})'}'
          '$synchrony${saturation == null ? '' : ', SPO2 $saturation%'}.';
    }
    if (support == VentilatorySupport.arAmbiente) {
      values.add(standardAwake
          ? '${female ? 'EUPNEICA' : 'EUPNEICO'} EM AR AMBIENTE'
          : 'EM AR AMBIENTE');
    } else {
      values.add(_support(support));
      _addIf(values, data.oxygenFlow, (v) => 'O2 $v L/MIN');
      if (support == VentilatorySupport.cateterNasal) {
        final homeFlow = _clean(data.homeOxygenFlow);
        if (homeFlow != null) {
          values.add('O2 DOMICILIAR $homeFlow L/MIN');
        }
      }
    }
    _addIf(values, data.oxygenSaturation, (v) => 'SPO2 $v%');
    if (standardAwake && _clean(data.oxygenSaturation) == null) {
      values.add('MANTENDO SATURACAO ADEQUADA');
    }
    return '${values.join(', ')}.';
  }

  String _neurological(NeurologicalState state, bool female) => switch (state) {
        NeurologicalState.acordado => female ? 'ACORDADA' : 'ACORDADO',
        NeurologicalState.sedado => female ? 'SEDADA' : 'SEDADO',
        NeurologicalState.sonolento => female ? 'SONOLENTA' : 'SONOLENTO',
        NeurologicalState.confuso => female ? 'CONFUSA' : 'CONFUSO',
      };

  String _support(VentilatorySupport support) => switch (support) {
        VentilatorySupport.arAmbiente => 'EM AR AMBIENTE',
        VentilatorySupport.cateterNasal => 'EM CATETER NASAL',
        VentilatorySupport.mascara => 'EM MASCARA',
        VentilatorySupport.vni => 'EM VNI',
        VentilatorySupport.iotVm => 'EM IOT+VM',
        VentilatorySupport.tqtVm => 'EM TQT+VM',
      };

  String _bloodPressure(BloodPressureState state, bool female) =>
      switch (state) {
        BloodPressureState.normotenso => female ? 'NORMOTENSA' : 'NORMOTENSO',
        BloodPressureState.hipotenso => female ? 'HIPOTENSA' : 'HIPOTENSO',
        BloodPressureState.hipertenso => female ? 'HIPERTENSA' : 'HIPERTENSO',
        BloodPressureState.tendendoHipotensao => 'TENDENDO A HIPOTENSAO',
        BloodPressureState.tendendoHipertensao => 'TENDENDO A HIPERTENSAO',
      };

  String _diet(DietRoute route) => switch (route) {
        DietRoute.vo => 'ACEITANDO DIETA VIA ORAL',
        DietRoute.sne => 'ACEITANDO DIETA VIA SNE',
        DietRoute.sng => 'ACEITANDO DIETA VIA SNG',
        DietRoute.npt => 'EM NUTRICAO PARENTERAL TOTAL',
        DietRoute.zero => 'DIETA ZERO',
      };

  String _diuresis(DiuresisType type, bool standardAwake) => switch (type) {
        DiuresisType.espontanea =>
          standardAwake ? 'DIURESE ESPONTANEA E EFETIVA' : 'DIURESE ESPONTANEA',
        DiuresisType.svd => 'DIURESE EM SVD',
        DiuresisType.ausente => 'DIURESE AUSENTE',
      };

  String _diuresisPrefix(DiuresisType? type) => switch (type) {
        DiuresisType.svd => 'DIURESE POR SVD',
        DiuresisType.ausente => 'DIURESE AUSENTE',
        DiuresisType.espontanea || null => 'DIURESE ESPONTANEA',
      };

  String _bowel(BowelMovement value) => switch (value) {
        BowelMovement.presentes => 'EVACUACOES PRESENTES NO PERIODO',
        BowelMovement.ausentes => 'EVACUACOES AUSENTES NO PERIODO',
        BowelMovement.diarreia => 'DIARREIA NO PERIODO',
      };

  void _sentence(List<String> output, List<String> values) {
    if (values.isNotEmpty) output.add('${values.join(', ')}.');
  }

  void _addExam(
      List<String> output, String label, String? value, String? fallback) {
    final clean = _clean(value) ?? fallback;
    if (clean != null) output.add('$label: $clean');
  }

  void _addIf(
      List<String> output, String? value, String Function(String) text) {
    final clean = _clean(value);
    if (clean != null) output.add(text(clean));
  }

  String? _range(String? min, String? max) {
    final a = _clean(min);
    final b = _clean(max);
    if (a != null && b != null) return '$a - $b';
    if (a != null) return 'MINIMO $a';
    if (b != null) return 'MAXIMO $b';
    return null;
  }

  String? _diuresisMlKgHour(EvolutionData data) {
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
    return (volume / period / weight).toStringAsFixed(2).replaceAll('.', ',');
  }

  double? _parseNumber(String? value) {
    final clean = _clean(value)
        ?.replaceAll(RegExp(r'[^0-9,.-]'), '')
        .replaceAll(',', '.');
    if (clean == null || clean.isEmpty) return null;
    return double.tryParse(clean);
  }

  String? _clean(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }

  String _withUnit(String value, String unit) {
    final upper = value.toUpperCase();
    return upper.contains(unit) ? value : '$value $unit';
  }

  String _formatDrugRates(Map<String, String> rates, List<DrugOption> options) {
    return rates.entries.map((entry) {
      DrugOption? option;
      for (final candidate in options) {
        if (candidate.name == entry.key) option = candidate;
      }
      final rate = _clean(entry.value);
      return rate == null
          ? entry.key
          : '${entry.key} ${_withUnit(rate, option?.unit.toUpperCase() ?? '')}';
    }).join(' + ');
  }
}

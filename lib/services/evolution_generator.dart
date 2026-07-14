import '../models/evolution_data.dart';
import '../utils/drug_options.dart';

class EvolutionGenerator {
  String generateSummary(EvolutionData data, {String? bedLabel}) {
    final lines = <String>[
      'RESUMO ESTRUTURADO PARA GERAR EVOLUÇÃO MÉDICA DE UTI',
      '',
    ];

    void line(String label, String? value) {
      final clean = _clean(value);
      if (clean != null) lines.add('$label: $clean');
    }

    void space() {
      if (lines.isNotEmpty && lines.last.isNotEmpty) lines.add('');
    }

    line('IDENTIFICAÇÃO DO LEITO', bedLabel);
    line('SEXO', data.sex == Sex.feminino ? 'F' : 'M');
    if (data.neurologicalState != null) {
      line('ESTADO',
          _neurological(data.neurologicalState!, data.sex == Sex.feminino));
    }
    line('PESO',
        _clean(data.weight) == null ? null : '${_clean(data.weight)} KG');

    space();
    line('RESP', _summaryRespiratory(data));

    space();
    line('HEMO', _summaryHemodynamics(data));
    line('PA PONTUAL', _withOptionalUnit(data.bloodPressure, 'MMHG'));
    line('PAM PONTUAL', _withOptionalUnit(data.meanArterialPressure, 'MMHG'));
    line('FC', _withOptionalUnit(data.heartRate, 'BPM'));
    if (data.vasoactiveDrugRates.isNotEmpty) {
      line('DVA',
          _formatDrugRates(data.vasoactiveDrugRates, vasoactiveDrugOptions));
    } else {
      line('DVA', data.vasoactiveDrugs);
    }
    if (data.sedationDrugRates.isNotEmpty) {
      line('SEDOANALGESIA',
          _formatDrugRates(data.sedationDrugRates, sedationDrugOptions));
    } else {
      line('SEDOANALGESIA', data.sedoanalgesia);
    }
    line('BIC', data.continuousInfusions);

    space();
    line('TEMP', _summaryTemperature(data));

    space();
    line(
        'DIETA', data.dietRoute == null ? null : _summaryDiet(data.dietRoute!));
    line('GI', _summaryGastrointestinal(data));
    line('HGT', _summaryHgt(data));

    space();
    line('DIURESE', _summaryDiuresis(data));
    final diuresisPeriod = _clean(data.diuresisPeriod);
    final balancePeriod = _clean(data.fluidBalancePeriod);
    if (diuresisPeriod != null &&
        balancePeriod != null &&
        diuresisPeriod != balancePeriod) {
      line('PERÍODO DA DIURESE', diuresisPeriod);
      line('PERÍODO DO BH', balancePeriod);
    } else {
      line('PERÍODO AVALIADO', diuresisPeriod ?? balancePeriod);
    }
    line(
        'BH',
        _clean(data.fluidBalance) == null
            ? 'NÃO QUANTIFICADO'
            : '${_clean(data.fluidBalance)} ML');

    space();
    line('EVACUAÇÃO', _summaryBowelMovement(data));

    space();
    line('GERAL', data.generalCondition);
    line('AP', data.pulmonaryExam);
    line('ACV', data.cardiovascularExam);
    line('ABD', data.abdominalExam);
    line('MMII', data.lowerLimbsExam);
    line('MMSS', data.upperLimbsExam);
    line(
        'NEURO',
        data.neurologicalExam ??
            (_clean(data.rass) == null ? null : 'RASS ${_clean(data.rass)}'));

    space();
    line('OBS', data.notes);

    while (lines.isNotEmpty && lines.last.isEmpty) {
      lines.removeLast();
    }
    return lines.join('\n').toUpperCase();
  }

  String? _summaryRespiratory(EvolutionData data) {
    final support = data.ventilatorySupport;
    final values = <String>[];
    if (support != null) {
      values.add(switch (support) {
        VentilatorySupport.arAmbiente => 'AR AMBIENTE',
        VentilatorySupport.cateterNasal => 'CATETER NASAL',
        VentilatorySupport.mascara => 'MÁSCARA',
        VentilatorySupport.vni => 'VNI',
        VentilatorySupport.iotVm => 'IOT+VM',
        VentilatorySupport.tqtVm => 'TQT+VM',
      });
    }
    _addSummaryValue(values, 'MODO', data.ventilationMode);
    _addSummaryValue(values, 'FR', data.respiratoryRate);
    _addSummaryValue(values, 'VT', data.tidalVolume, unit: 'ML');
    _addSummaryValue(values, 'FLUXO', data.inspiratoryFlow, unit: 'L/MIN');
    _addSummaryValue(values, 'PC', data.controlledPressure, unit: 'CMH2O');
    _addSummaryValue(values, 'TI', data.inspiratoryTime, unit: 'S');
    _addSummaryValue(values, 'PS', data.pressureSupport, unit: 'CMH2O');
    _addSummaryValue(values, 'TRIGGER', data.triggerSensitivity);
    _addSummaryValue(values, 'CICLAGEM', data.cyclingCriterion, unit: '%');
    _addSummaryValue(values, 'FIO2', data.fio2, unit: '%');
    _addSummaryValue(values, 'PEEP', data.peep, unit: 'CMH2O');
    _addSummaryValue(values, 'O2', data.oxygenFlow, unit: 'L/MIN');
    _addSummaryValue(values, 'O2 DOMICILIAR', data.homeOxygenFlow,
        unit: 'L/MIN');
    _addSummaryValue(values, 'SPO2', data.oxygenSaturation, unit: '%');
    if (data.ventilatorSynchrony != null &&
        data.ventilationMode?.toUpperCase() != 'PSV') {
      values.add(data.ventilatorSynchrony! ? 'SINCRÔNICO' : 'ASSINCRÔNICO');
    }
    return values.isEmpty ? null : values.join('; ');
  }

  String? _summaryHemodynamics(EvolutionData data) {
    final values = <String>[];
    if (data.hemodynamicState != null) {
      values.add(data.hemodynamicState == HemodynamicState.estavel
          ? 'ESTÁVEL'
          : 'INSTÁVEL');
    }
    if (data.vasoactiveSupport != null) {
      values.add(data.vasoactiveSupport == VasoactiveSupport.semDva
          ? 'SEM DVA'
          : 'COM DVA');
    }
    if (data.bloodPressureState != null) {
      values.add(switch (data.bloodPressureState!) {
        BloodPressureState.normotenso =>
          data.sex == Sex.feminino ? 'NORMOTENSA' : 'NORMOTENSO',
        BloodPressureState.hipotenso =>
          data.sex == Sex.feminino ? 'HIPOTENSA' : 'HIPOTENSO',
        BloodPressureState.hipertenso =>
          data.sex == Sex.feminino ? 'HIPERTENSA' : 'HIPERTENSO',
        BloodPressureState.tendendoHipotensao => 'TENDENDO À HIPOTENSÃO',
        BloodPressureState.tendendoHipertensao => 'TENDENDO À HIPERTENSÃO',
      });
    }
    return values.isEmpty ? null : values.join('; ');
  }

  String? _summaryTemperature(EvolutionData data) {
    final values = <String>[];
    if (data.temperatureState != null) {
      values.add(switch (data.temperatureState!) {
        TemperatureState.afebril => 'AFEBRIL',
        TemperatureState.subfebril => 'SUBFEBRIL',
        TemperatureState.febril => 'FEBRIL',
      });
    }
    final measured = _clean(data.measuredTemperature);
    if (measured != null) values.add('$measured °C');
    return values.isEmpty ? null : values.join('; ');
  }

  String _summaryDiet(DietRoute route) => switch (route) {
        DietRoute.vo => 'VO',
        DietRoute.sne => 'SNE',
        DietRoute.sng => 'SNG',
        DietRoute.npt => 'NPT',
        DietRoute.zero => 'ZERO',
      };

  String _summaryGastrointestinal(EvolutionData data) {
    final values = <String>[];
    if (data.nausea) values.add('NÁUSEAS');
    if (data.vomiting) values.add('VÔMITOS');
    if (data.gastricStasis) values.add('ESTASE');
    final notes = _clean(data.gastrointestinalNotes);
    if (notes != null) values.add(notes);
    return values.isEmpty
        ? 'SEM NÁUSEAS, VÔMITOS OU ESTASE'
        : values.join('; ');
  }

  String? _summaryHgt(EvolutionData data) {
    final range = _range(data.hgtMinimum, data.hgtMaximum);
    if (range != null) return '$range MG/DL';
    return _withOptionalUnit(data.capillaryGlucose, 'MG/DL');
  }

  String? _summaryDiuresis(EvolutionData data) {
    if (data.diuresisType == null &&
        _clean(data.diuresisVolume) == null &&
        _clean(data.diuresisAppearance) == null) {
      return null;
    }
    final values = <String>[];
    if (data.diuresisType != null) {
      values.add(switch (data.diuresisType!) {
        DiuresisType.espontanea => 'ESPONTÂNEA',
        DiuresisType.svd => 'SVD',
        DiuresisType.ausente => 'AUSENTE',
      });
    }
    final volume = _clean(data.diuresisVolume);
    if (volume != null) {
      values.add('$volume ML');
    } else if (data.diuresisType != DiuresisType.ausente) {
      values.add('NÃO QUANTIFICADA');
    }
    final appearance = _clean(data.diuresisAppearance);
    if (appearance != null) values.add(appearance);
    return values.join('; ');
  }

  String? _summaryBowelMovement(EvolutionData data) {
    if (data.bowelMovement == null) return null;
    final values = <String>[
      switch (data.bowelMovement!) {
        BowelMovement.presentes => 'PRESENTE',
        BowelMovement.ausentes => 'AUSENTE',
        BowelMovement.diarreia => 'DIARREIA',
      }
    ];
    final days = _clean(data.daysSinceLastBowelMovement);
    if (data.bowelMovement == BowelMovement.ausentes && days != null) {
      values.add('HÁ $days DIAS');
    }
    if (data.bowelMovement != BowelMovement.ausentes &&
        data.stoolPathologicalProducts != null) {
      values.add(
          data.stoolPathologicalProducts == StoolPathologicalProducts.presentes
              ? 'COM PRODUTOS PATOLÓGICOS'
              : 'SEM PRODUTOS PATOLÓGICOS');
    }
    final description = _clean(data.stoolPathologicalDescription);
    if (description != null) values.add(description);
    return values.join('; ');
  }

  String? _withOptionalUnit(String? value, String unit) {
    final clean = _clean(value);
    return clean == null ? null : '$clean $unit';
  }

  void _addSummaryValue(List<String> values, String label, String? value,
      {String? unit}) {
    final clean = _clean(value);
    if (clean == null) return;
    final suffix = unit == null
        ? ''
        : unit == '%'
            ? '%'
            : ' $unit';
    values.add('$label $clean$suffix');
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
    _addIf(nutrition, data.gastrointestinalNotes, (v) => v);
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
    } else if (data.diuresisType == DiuresisType.espontanea) {
      renal.add('DIURESE ESPONTANEA E EFETIVA, NÃO QUANTIFICADA, SEM QUEIXAS');
    } else if (data.diuresisType != null) {
      renal.add(_diuresis(data.diuresisType!, standardAwake));
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
    if (_clean(data.fluidBalance) == null) renal.add('BH NÃO QUANTIFICADO');
    _sentence(sentences, renal);

    final bowel = <String>[];
    if (data.bowelMovement != null) bowel.add(_bowel(data.bowelMovement!));
    if (data.bowelMovement == BowelMovement.ausentes) {
      _addIf(bowel, data.daysSinceLastBowelMovement, (v) => 'HA $v DIAS');
    }
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
      final synchrony = data.ventilationMode?.toUpperCase() == 'PSV' ||
              data.ventilatorSynchrony == null
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

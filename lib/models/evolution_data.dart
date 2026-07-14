enum Sex { masculino, feminino }

enum NeurologicalState { acordado, sedado, sonolento, confuso }

enum VentilatorySupport { arAmbiente, cateterNasal, mascara, vni, iotVm, tqtVm }

enum HemodynamicState { estavel, instavel }

enum BloodPressureState {
  normotenso,
  hipotenso,
  hipertenso,
  tendendoHipotensao,
  tendendoHipertensao,
}

enum VasoactiveSupport { semDva, comDva }

enum TemperatureState { afebril, subfebril, febril }

enum DietRoute { vo, sne, sng, npt, zero }

enum DiuresisType { espontanea, svd, ausente }

enum BowelMovement { presentes, ausentes, diarreia }

enum StoolPathologicalProducts { ausentes, presentes }

enum EvolutionTemplate { acordadoArAmbiente, sedadoIotVm }

class EvolutionData {
  const EvolutionData({
    required this.sex,
    this.local = 'UTI',
    this.template,
    this.neurologicalState,
    this.sedoanalgesia,
    this.sedationDrugRates = const {},
    this.ventilatorySupport,
    this.ventilationMode,
    this.respiratoryRate,
    this.tidalVolume,
    this.inspiratoryFlow,
    this.controlledPressure,
    this.inspiratoryTime,
    this.pressureSupport,
    this.triggerSensitivity,
    this.cyclingCriterion,
    this.fio2,
    this.peep,
    this.oxygenFlow,
    this.homeOxygenFlow,
    this.ventilatorSynchrony,
    this.oxygenSaturation,
    this.bloodPressure,
    this.meanArterialPressure,
    this.heartRate,
    this.weight,
    this.measuredTemperature,
    this.capillaryGlucose,
    this.continuousInfusions,
    this.hemodynamicState,
    this.bloodPressureState,
    this.vasoactiveSupport,
    this.vasoactiveDrugs,
    this.vasoactiveDrugRates = const {},
    this.temperatureState,
    this.dietRoute,
    this.nausea = false,
    this.vomiting = false,
    this.gastricStasis = false,
    this.gastrointestinalNotes,
    this.hgtMinimum,
    this.hgtMaximum,
    this.diuresisType,
    this.diuresisVolume,
    this.diuresisPeriod,
    this.diuresisAppearance,
    this.fluidBalance,
    this.fluidBalancePeriod,
    this.bowelMovement,
    this.daysSinceLastBowelMovement,
    this.stoolPathologicalProducts,
    this.stoolPathologicalDescription,
    this.generalCondition,
    this.pulmonaryExam,
    this.cardiovascularExam,
    this.abdominalExam,
    this.lowerLimbsExam,
    this.upperLimbsExam,
    this.neurologicalExam,
    this.rass,
    this.notes,
    this.formState = const {},
  });

  factory EvolutionData.fromJson(Map<String, dynamic> json) => EvolutionData(
        sex: _enumValue(Sex.values, json['sex']) ?? Sex.masculino,
        local: json['local'] as String? ?? 'UTI',
        template: _enumValue(EvolutionTemplate.values, json['template']),
        neurologicalState:
            _enumValue(NeurologicalState.values, json['neurologicalState']),
        sedoanalgesia: json['sedoanalgesia'] as String?,
        sedationDrugRates: _stringMap(json['sedationDrugRates']),
        ventilatorySupport:
            _enumValue(VentilatorySupport.values, json['ventilatorySupport']),
        ventilationMode: (json['ventilationParameters']
            as Map<String, dynamic>?)?['mode'] as String?,
        respiratoryRate: (json['ventilationParameters']
            as Map<String, dynamic>?)?['respiratoryRate'] as String?,
        tidalVolume: (json['ventilationParameters']
            as Map<String, dynamic>?)?['tidalVolume'] as String?,
        inspiratoryFlow: (json['ventilationParameters']
            as Map<String, dynamic>?)?['inspiratoryFlow'] as String?,
        controlledPressure: (json['ventilationParameters']
            as Map<String, dynamic>?)?['controlledPressure'] as String?,
        inspiratoryTime: (json['ventilationParameters']
            as Map<String, dynamic>?)?['inspiratoryTime'] as String?,
        pressureSupport: (json['ventilationParameters']
            as Map<String, dynamic>?)?['pressureSupport'] as String?,
        triggerSensitivity: (json['ventilationParameters']
            as Map<String, dynamic>?)?['triggerSensitivity'] as String?,
        cyclingCriterion: (json['ventilationParameters']
            as Map<String, dynamic>?)?['cyclingCriterion'] as String?,
        fio2: (json['ventilationParameters'] as Map<String, dynamic>?)?['fio2']
            as String?,
        peep: (json['ventilationParameters'] as Map<String, dynamic>?)?['peep']
            as String?,
        oxygenFlow: (json['ventilationParameters']
            as Map<String, dynamic>?)?['oxygenFlow'] as String?,
        homeOxygenFlow: (json['ventilationParameters']
            as Map<String, dynamic>?)?['homeOxygenFlow'] as String?,
        ventilatorSynchrony: (json['ventilationParameters']
            as Map<String, dynamic>?)?['ventilatorSynchrony'] as bool?,
        oxygenSaturation: json['oxygenSaturation'] as String?,
        bloodPressure: json['bloodPressure'] as String?,
        meanArterialPressure: json['meanArterialPressure'] as String?,
        heartRate: json['heartRate'] as String?,
        weight: json['weight'] as String?,
        measuredTemperature: json['measuredTemperature'] as String?,
        capillaryGlucose: json['capillaryGlucose'] as String?,
        continuousInfusions: json['continuousInfusions'] as String?,
        hemodynamicState:
            _enumValue(HemodynamicState.values, json['hemodynamicState']),
        bloodPressureState:
            _enumValue(BloodPressureState.values, json['bloodPressureState']),
        vasoactiveSupport:
            _enumValue(VasoactiveSupport.values, json['vasoactiveSupport']),
        vasoactiveDrugs: json['vasoactiveDrugs'] as String?,
        vasoactiveDrugRates: _stringMap(json['vasoactiveDrugRates']),
        temperatureState:
            _enumValue(TemperatureState.values, json['temperatureState']),
        dietRoute: _enumValue(DietRoute.values, json['dietRoute']),
        nausea: (json['gastrointestinalSymptoms']
                as Map<String, dynamic>?)?['nausea'] as bool? ??
            false,
        vomiting: (json['gastrointestinalSymptoms']
                as Map<String, dynamic>?)?['vomiting'] as bool? ??
            false,
        gastricStasis: (json['gastrointestinalSymptoms']
                as Map<String, dynamic>?)?['gastricStasis'] as bool? ??
            false,
        gastrointestinalNotes: (json['gastrointestinalSymptoms']
            as Map<String, dynamic>?)?['notes'] as String?,
        hgtMinimum: json['hgtMinimum'] as String?,
        hgtMaximum: json['hgtMaximum'] as String?,
        diuresisType: _enumValue(DiuresisType.values,
            (json['diuresis'] as Map<String, dynamic>?)?['type']),
        diuresisVolume:
            (json['diuresis'] as Map<String, dynamic>?)?['volume'] as String?,
        diuresisPeriod:
            (json['diuresis'] as Map<String, dynamic>?)?['period'] as String?,
        diuresisAppearance: (json['diuresis']
            as Map<String, dynamic>?)?['appearance'] as String?,
        fluidBalance: json['fluidBalance'] as String?,
        fluidBalancePeriod: json['fluidBalancePeriod'] as String?,
        bowelMovement: _enumValue(BowelMovement.values, json['bowelMovement']),
        daysSinceLastBowelMovement:
            json['daysSinceLastBowelMovement'] as String?,
        stoolPathologicalProducts: _enumValue(StoolPathologicalProducts.values,
            json['stoolPathologicalProducts']),
        stoolPathologicalDescription:
            json['stoolPathologicalDescription'] as String?,
        generalCondition: (json['physicalExam']
            as Map<String, dynamic>?)?['generalCondition'] as String?,
        pulmonaryExam: (json['physicalExam']
            as Map<String, dynamic>?)?['pulmonary'] as String?,
        cardiovascularExam: (json['physicalExam']
            as Map<String, dynamic>?)?['cardiovascular'] as String?,
        abdominalExam: (json['physicalExam']
            as Map<String, dynamic>?)?['abdomen'] as String?,
        lowerLimbsExam: (json['physicalExam']
            as Map<String, dynamic>?)?['lowerLimbs'] as String?,
        upperLimbsExam: (json['physicalExam']
            as Map<String, dynamic>?)?['upperLimbs'] as String?,
        neurologicalExam: (json['physicalExam']
            as Map<String, dynamic>?)?['neurological'] as String?,
        rass:
            (json['physicalExam'] as Map<String, dynamic>?)?['rass'] as String?,
        notes: json['notes'] as String?,
        formState: (json['formState'] as Map?)?.cast<String, dynamic>() ?? {},
      );

  final Sex sex;
  final String local;
  final EvolutionTemplate? template;
  final NeurologicalState? neurologicalState;
  final String? sedoanalgesia;
  final Map<String, String> sedationDrugRates;
  final VentilatorySupport? ventilatorySupport;
  final String? ventilationMode;
  final String? respiratoryRate;
  final String? tidalVolume;
  final String? inspiratoryFlow;
  final String? controlledPressure;
  final String? inspiratoryTime;
  final String? pressureSupport;
  final String? triggerSensitivity;
  final String? cyclingCriterion;
  final String? fio2;
  final String? peep;
  final String? oxygenFlow;
  final String? homeOxygenFlow;
  final bool? ventilatorSynchrony;
  final String? oxygenSaturation;
  final String? bloodPressure;
  final String? meanArterialPressure;
  final String? heartRate;
  final String? weight;
  final String? measuredTemperature;
  final String? capillaryGlucose;
  final String? continuousInfusions;
  final HemodynamicState? hemodynamicState;
  final BloodPressureState? bloodPressureState;
  final VasoactiveSupport? vasoactiveSupport;
  final String? vasoactiveDrugs;
  final Map<String, String> vasoactiveDrugRates;
  final TemperatureState? temperatureState;
  final DietRoute? dietRoute;
  final bool nausea;
  final bool vomiting;
  final bool gastricStasis;
  final String? gastrointestinalNotes;
  final String? hgtMinimum;
  final String? hgtMaximum;
  final DiuresisType? diuresisType;
  final String? diuresisVolume;
  final String? diuresisPeriod;
  final String? diuresisAppearance;
  final String? fluidBalance;
  final String? fluidBalancePeriod;
  final BowelMovement? bowelMovement;
  final String? daysSinceLastBowelMovement;
  final StoolPathologicalProducts? stoolPathologicalProducts;
  final String? stoolPathologicalDescription;
  final String? generalCondition;
  final String? pulmonaryExam;
  final String? cardiovascularExam;
  final String? abdominalExam;
  final String? lowerLimbsExam;
  final String? upperLimbsExam;
  final String? neurologicalExam;
  final String? rass;
  final String? notes;
  final Map<String, dynamic> formState;

  Map<String, dynamic> toJson() => {
        'sex': sex.name,
        'local': local,
        'template': template?.name,
        'neurologicalState': neurologicalState?.name,
        'sedoanalgesia': sedoanalgesia,
        'sedationDrugRates': sedationDrugRates,
        'ventilatorySupport': ventilatorySupport?.name,
        'ventilationParameters': {
          'mode': ventilationMode,
          'respiratoryRate': respiratoryRate,
          'tidalVolume': tidalVolume,
          'inspiratoryFlow': inspiratoryFlow,
          'controlledPressure': controlledPressure,
          'inspiratoryTime': inspiratoryTime,
          'pressureSupport': pressureSupport,
          'triggerSensitivity': triggerSensitivity,
          'cyclingCriterion': cyclingCriterion,
          'fio2': fio2,
          'peep': peep,
          'oxygenFlow': oxygenFlow,
          'homeOxygenFlow': homeOxygenFlow,
          'ventilatorSynchrony': ventilatorSynchrony,
        },
        'oxygenSaturation': oxygenSaturation,
        'bloodPressure': bloodPressure,
        'meanArterialPressure': meanArterialPressure,
        'heartRate': heartRate,
        'weight': weight,
        'measuredTemperature': measuredTemperature,
        'capillaryGlucose': capillaryGlucose,
        'continuousInfusions': continuousInfusions,
        'hemodynamicState': hemodynamicState?.name,
        'bloodPressureState': bloodPressureState?.name,
        'vasoactiveSupport': vasoactiveSupport?.name,
        'vasoactiveDrugs': vasoactiveDrugs,
        'vasoactiveDrugRates': vasoactiveDrugRates,
        'temperatureState': temperatureState?.name,
        'dietRoute': dietRoute?.name,
        'gastrointestinalSymptoms': {
          'nausea': nausea,
          'vomiting': vomiting,
          'gastricStasis': gastricStasis,
          'notes': gastrointestinalNotes,
        },
        'hgtMinimum': hgtMinimum,
        'hgtMaximum': hgtMaximum,
        'diuresis': {
          'type': diuresisType?.name,
          'volume': diuresisVolume,
          'period': diuresisPeriod,
          'appearance': diuresisAppearance,
        },
        'fluidBalance': fluidBalance,
        'fluidBalancePeriod': fluidBalancePeriod,
        'bowelMovement': bowelMovement?.name,
        'daysSinceLastBowelMovement': daysSinceLastBowelMovement,
        'stoolPathologicalProducts': stoolPathologicalProducts?.name,
        'stoolPathologicalDescription': stoolPathologicalDescription,
        'physicalExam': {
          'generalCondition': generalCondition,
          'pulmonary': pulmonaryExam,
          'cardiovascular': cardiovascularExam,
          'abdomen': abdominalExam,
          'lowerLimbs': lowerLimbsExam,
          'upperLimbs': upperLimbsExam,
          'neurological': neurologicalExam,
          'rass': rass,
        },
        'notes': notes,
        'formState': formState,
      };
}

T? _enumValue<T extends Enum>(List<T> values, Object? name) {
  if (name == null) return null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}

Map<String, String> _stringMap(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, value) => MapEntry('$key', '$value'));
}

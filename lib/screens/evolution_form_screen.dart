import 'package:flutter/material.dart';
import 'dart:async';

import '../models/bed.dart';
import '../models/evolution_data.dart';
import '../utils/drug_options.dart';
import '../widgets/form_section.dart';
import '../widgets/medical_disclaimer.dart';
import 'evolution_preview_screen.dart';

class EvolutionFormScreen extends StatefulWidget {
  const EvolutionFormScreen({
    this.bed,
    this.initialData,
    this.onDraftSaved,
    this.onCompleted,
    super.key,
  });

  final Bed? bed;
  final EvolutionData? initialData;
  final ValueChanged<EvolutionData>? onDraftSaved;
  final VoidCallback? onCompleted;

  @override
  State<EvolutionFormScreen> createState() => _EvolutionFormScreenState();
}

class _EvolutionFormScreenState extends State<EvolutionFormScreen> {
  Sex _sex = Sex.masculino;
  EvolutionTemplate _template = EvolutionTemplate.acordadoArAmbiente;
  NeurologicalState _neurological = NeurologicalState.acordado;
  VentilatorySupport _support = VentilatorySupport.arAmbiente;
  HemodynamicState _hemodynamic = HemodynamicState.estavel;
  BloodPressureState _bloodPressureState = BloodPressureState.normotenso;
  VasoactiveSupport _dvaSupport = VasoactiveSupport.semDva;
  DietRoute _diet = DietRoute.vo;
  DiuresisType _diuresis = DiuresisType.espontanea;
  BowelMovement _bowel = BowelMovement.ausentes;
  StoolPathologicalProducts _stoolProducts = StoolPathologicalProducts.ausentes;
  String _period = '12H';
  String? _ventilationMode;
  bool? _vmSynchrony = true;
  bool _usesHomeOxygen = false;
  bool _nausea = false;
  bool _vomiting = false;
  bool _stasis = false;

  bool? _rightMvPresent = true;
  bool? _leftMvPresent = true;
  final Set<String> _rightPulmonaryFindings = {};
  final Set<String> _leftPulmonaryFindings = {};
  final Set<String> _rightPulmonaryLocations = {};
  final Set<String> _leftPulmonaryLocations = {};

  String _colorStatus = 'CORADO';
  String _hydrationStatus = 'HIDRATADO';
  String _cyanosisStatus = 'ACIANOTICO';
  String _jaundiceStatus = 'ANICTERICO';
  String _respiratoryEffort = 'EUPNEICO';
  String _generalState = 'BEG';

  String _heartRhythm = 'BCRNF';
  String _heartSounds = '2T';
  String _murmur = 'SEM SOPROS';
  String _capillaryRefill = 'TEC<3S';
  String _pulses = 'PULSOS PERIFERICOS PALPAVEIS';
  String _extremitiesTemperature = 'EXTREMIDADES AQUECIDAS';

  String _abdomenShape = 'PLANO';
  String _abdomenConsistency = 'FLACIDO';
  String _bowelSounds = 'RH+';
  String _abdominalPain = 'INDOLOR';
  final Set<String> _abdominalPainLocations = {};
  String _peritonitis = 'SEM SINAIS DE PERITONITE';
  final Set<String> _abdominalOtherFindings = {};

  String _gcsEye = 'AO4';
  String _gcsVerbal = 'RV5';
  String _gcsMotor = 'RM6';
  bool _pifr = true;
  bool _mobilityPreserved = true;
  bool _strengthPreserved = true;

  bool _lowerLimbEdema = false;
  String? _lowerLimbEdemaGrade;
  bool _lowerLimbPitting = false;
  bool _lowerLimbLesion = false;
  bool _lowerLimbAmputation = false;
  final Set<String> _lowerLimbSides = {};
  bool _upperLimbEdema = false;
  String? _upperLimbEdemaGrade;
  Timer? _draftSaveTimer;
  bool _restoringDraft = false;

  final Set<String> _selectedSedationDrugs = {};
  final Set<String> _selectedVasoactiveDrugs = {};
  final Map<String, TextEditingController> _sedationRates = {
    for (final drug in sedationDrugOptions) drug.name: TextEditingController(),
  };
  final Map<String, TextEditingController> _vasoactiveRates = {
    for (final drug in vasoactiveDrugOptions)
      drug.name: TextEditingController(),
  };

  final _fields = <String, TextEditingController>{
    for (final name in [
      'paSystolic',
      'paDiastolic',
      'pam',
      'fc',
      'weight',
      'temp',
      'spo2',
      'oxygenFlow',
      'homeOxygenFlow',
      'hgtMin',
      'hgtMax',
      'bic',
      'fr',
      'vt',
      'pc',
      'ps',
      'fio2',
      'peep',
      'urineVolume',
      'urineAppearance',
      'balance',
      'rass',
      'neuroDeficit',
      'stoolDescription',
      'notes',
    ])
      name: TextEditingController(),
  };

  bool get _isMechanicalVentilation =>
      _support == VentilatorySupport.iotVm ||
      _support == VentilatorySupport.tqtVm;

  bool get _hasArtificialAirway =>
      _support == VentilatorySupport.iotVm ||
      _support == VentilatorySupport.tqtVm;

  bool get _isDeepSedation {
    final rass = _rassValue();
    return rass != null && rass <= -4;
  }

  List<String> get _verbalResponseOptions => [
        'RV5',
        'RV4',
        'RV3',
        'RV2',
        'RV1',
        if (_hasArtificialAirway) 'RVT',
      ];

  @override
  void initState() {
    super.initState();
    for (final controller in [
      ..._fields.values,
      ..._sedationRates.values,
      ..._vasoactiveRates.values,
    ]) {
      controller.addListener(_onFieldChanged);
    }
    final data = widget.initialData;
    if (data == null) return;
    _restoringDraft = true;
    _sex = data.sex;
    _template = data.template ?? _template;
    _neurological = data.neurologicalState ?? _neurological;
    _support = data.ventilatorySupport ?? _support;
    _hemodynamic = data.hemodynamicState ?? _hemodynamic;
    _bloodPressureState = data.bloodPressureState ?? _bloodPressureState;
    _dvaSupport = data.vasoactiveSupport ?? _dvaSupport;
    _diet = data.dietRoute ?? _diet;
    _diuresis = data.diuresisType ?? _diuresis;
    _bowel = data.bowelMovement ?? _bowel;
    _stoolProducts = data.stoolPathologicalProducts ?? _stoolProducts;
    _period = data.diuresisPeriod ?? data.fluidBalancePeriod ?? _period;
    _ventilationMode = data.ventilationMode;
    _vmSynchrony = data.ventilatorSynchrony ?? _vmSynchrony;
    _usesHomeOxygen = data.homeOxygenFlow != null;
    _nausea = data.nausea;
    _vomiting = data.vomiting;
    _stasis = data.gastricStasis;
    _selectedSedationDrugs.addAll(data.sedationDrugRates.keys);
    _selectedVasoactiveDrugs.addAll(data.vasoactiveDrugRates.keys);
    for (final entry in data.sedationDrugRates.entries) {
      _sedationRates[entry.key]?.text = entry.value;
    }
    for (final entry in data.vasoactiveDrugRates.entries) {
      _vasoactiveRates[entry.key]?.text = entry.value;
    }
    _restoreFields(data);
    _restoreFormState(data.formState);
    _restoringDraft = false;
  }

  @override
  void dispose() {
    if (!_restoringDraft && widget.bed != null && widget.onDraftSaved != null) {
      widget.onDraftSaved?.call(_currentData());
    }
    _draftSaveTimer?.cancel();
    for (final controller in [
      ..._fields.values,
      ..._sedationRates.values,
      ..._vasoactiveRates.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.bed?.displayName ?? 'Coleta rapida')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _generate,
          icon: const Icon(Icons.description_outlined),
          label: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Text('Gerar resumo'),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                const MedicalDisclaimer(),
                const SizedBox(height: 12),
                if (widget.bed != null) _bedHeader(context),
                FormSection(title: 'Modelo do paciente', children: [
                  _segmented<Sex>(
                    values: Sex.values,
                    selected: _sex,
                    labelOf: (v) =>
                        v == Sex.masculino ? 'Masculino' : 'Feminino',
                    onChanged: (v) => _update(() => _sex = v),
                  ),
                  _presetButtons(),
                  _chips<NeurologicalState>(
                    title: 'Neuro',
                    values: NeurologicalState.values,
                    selected: _neurological,
                    labelOf: (v) => switch (v) {
                      NeurologicalState.acordado => 'Acordado',
                      NeurologicalState.sedado => 'Sedado',
                      NeurologicalState.sonolento => 'Sonolento',
                      NeurologicalState.confuso => 'Confuso',
                    },
                    onChanged: (v) => _update(() => _neurological = v),
                  ),
                  if (_neurological == NeurologicalState.sedado) ...[
                    _drugChips(
                      options: sedationDrugOptions,
                      selected: _selectedSedationDrugs,
                      controllers: _sedationRates,
                    ),
                  ],
                ]),
                FormSection(title: 'Sinais e respiratorio', children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: _text('paSystolic', 'PAS',
                              hint: '120', number: true)),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(8, 18, 8, 0),
                        child: Text('/'),
                      ),
                      Expanded(
                          child: _text('paDiastolic', 'PAD',
                              hint: '80', number: true)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _text('fc', 'FC', hint: '82', number: true)),
                    ],
                  ),
                  _row(
                    _temperatureField(),
                    _text('spo2', 'Sat %', number: true),
                  ),
                  _row(
                    _text('pam', 'PAM', hint: '65', number: true),
                    _text('weight', 'Peso kg', hint: '70', number: true),
                  ),
                  _row(
                    _text('hgtMin', 'HGT min', number: true),
                    _text('hgtMax', 'HGT max', number: true),
                  ),
                  _chips<VentilatorySupport>(
                    title: 'Suporte',
                    values: const [
                      VentilatorySupport.arAmbiente,
                      VentilatorySupport.cateterNasal,
                      VentilatorySupport.mascara,
                      VentilatorySupport.vni,
                      VentilatorySupport.iotVm,
                      VentilatorySupport.tqtVm,
                    ],
                    selected: _support,
                    labelOf: _supportLabel,
                    onChanged: (v) => _update(() {
                      _support = v;
                      if (!_hasArtificialAirway && _gcsVerbal == 'RVT') {
                        _gcsVerbal = 'RV1';
                      }
                    }),
                  ),
                  if (_support == VentilatorySupport.cateterNasal ||
                      _support == VentilatorySupport.mascara) ...[
                    _text('oxygenFlow', 'Vazao O2 atual (L/min)', number: true),
                    if (_support == VentilatorySupport.cateterNasal) ...[
                      _chips<bool>(
                        title: 'O2 domiciliar?',
                        values: const [false, true],
                        selected: _usesHomeOxygen,
                        labelOf: (v) => v ? 'Sim' : 'Nao',
                        onChanged: (v) => _update(() => _usesHomeOxygen = v),
                      ),
                      if (_usesHomeOxygen)
                        _text('homeOxygenFlow', 'Vazao em casa (L/min)',
                            number: true),
                    ],
                  ],
                  if (_isMechanicalVentilation) ...[
                    _chips<String>(
                      title: 'Modo VM',
                      values: const ['VCV', 'PCV', 'PSV'],
                      selected: _ventilationMode,
                      labelOf: (v) => v,
                      onChanged: (v) => _update(() => _ventilationMode = v),
                    ),
                    _row(_text('fr', 'FR', number: true),
                        _text('fio2', 'FiO2 %', number: true)),
                    _row(_text('peep', 'PEEP', number: true), _vmMainField()),
                    _chips<bool>(
                      title: 'Sincronia com VM',
                      values: const [true, false],
                      selected: _vmSynchrony,
                      labelOf: (v) => v ? 'Sincronico' : 'Assincronico',
                      onChanged: (v) => _update(() => _vmSynchrony = v),
                    ),
                  ],
                ]),
                FormSection(title: 'Hemodinamica', children: [
                  _chips<HemodynamicState>(
                    title: 'Estado',
                    values: HemodynamicState.values,
                    selected: _hemodynamic,
                    labelOf: (v) =>
                        v == HemodynamicState.estavel ? 'Estavel' : 'Instavel',
                    onChanged: (v) => _update(() => _hemodynamic = v),
                  ),
                  _chips<BloodPressureState>(
                    title: 'Pressao',
                    values: BloodPressureState.values,
                    selected: _bloodPressureState,
                    labelOf: (v) => switch (v) {
                      BloodPressureState.normotenso => 'Normo',
                      BloodPressureState.hipotenso => 'Hipo',
                      BloodPressureState.hipertenso => 'Hiper',
                      BloodPressureState.tendendoHipotensao => 'Tend. hipo',
                      BloodPressureState.tendendoHipertensao => 'Tend. hiper',
                    },
                    onChanged: (v) => _update(() => _bloodPressureState = v),
                  ),
                  _chips<VasoactiveSupport>(
                    title: 'DVA',
                    values: VasoactiveSupport.values,
                    selected: _dvaSupport,
                    labelOf: (v) =>
                        v == VasoactiveSupport.semDva ? 'Sem DVA' : 'Com DVA',
                    onChanged: (v) => _update(() => _dvaSupport = v),
                  ),
                  if (_dvaSupport == VasoactiveSupport.comDva)
                    _drugChips(
                      options: vasoactiveDrugOptions,
                      selected: _selectedVasoactiveDrugs,
                      controllers: _vasoactiveRates,
                    ),
                  _text('bic', 'BIC / infusoes continuas',
                      hint: 'Ex.: SG 5%, ATB, sedacao...'),
                ]),
                FormSection(title: 'Dieta e GI', children: [
                  _chips<DietRoute>(
                    title: 'Dieta',
                    values: DietRoute.values,
                    selected: _diet,
                    labelOf: (v) => switch (v) {
                      DietRoute.vo => 'VO',
                      DietRoute.sne => 'SNE',
                      DietRoute.sng => 'SNG',
                      DietRoute.npt => 'NPT',
                      DietRoute.zero => 'Zero',
                    },
                    onChanged: (v) => _update(() => _diet = v),
                  ),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    FilterChip(
                      label: const Text('Nauseas'),
                      selected: _nausea,
                      onSelected: (v) => _update(() => _nausea = v),
                    ),
                    FilterChip(
                      label: const Text('Vomitos'),
                      selected: _vomiting,
                      onSelected: (v) => _update(() => _vomiting = v),
                    ),
                    FilterChip(
                      label: const Text('Estase'),
                      selected: _stasis,
                      onSelected: (v) => _update(() => _stasis = v),
                    ),
                  ]),
                ]),
                FormSection(title: 'Diurese, BH e evacuacao', children: [
                  _chips<String>(
                    title: 'Periodo da diurese e BH',
                    values: const ['12H', '18H'],
                    selected: _period,
                    labelOf: (v) => v,
                    onChanged: (v) => _update(() => _period = v),
                  ),
                  _chips<DiuresisType>(
                    title: 'Diurese',
                    values: DiuresisType.values,
                    selected: _diuresis,
                    labelOf: (v) => switch (v) {
                      DiuresisType.espontanea => 'Espontanea',
                      DiuresisType.svd => 'SVD',
                      DiuresisType.ausente => 'Ausente',
                    },
                    onChanged: (v) => _update(() => _diuresis = v),
                  ),
                  if (_diuresis != DiuresisType.ausente)
                    _row(
                      _text('urineVolume', 'Volume', hint: '250', number: true),
                      _text('urineAppearance', 'Aspecto',
                          hint: 'Clara, concentrada...'),
                    ),
                  _text('balance', 'BH', hint: '+450', number: true),
                  _chips<BowelMovement>(
                    title: 'Evacuacao',
                    values: BowelMovement.values,
                    selected: _bowel,
                    labelOf: (v) => switch (v) {
                      BowelMovement.presentes => 'Presente',
                      BowelMovement.ausentes => 'Ausente',
                      BowelMovement.diarreia => 'Diarreia',
                    },
                    onChanged: (v) => _update(() => _bowel = v),
                  ),
                  _chips<StoolPathologicalProducts>(
                    title: 'Produtos patologicos',
                    values: StoolPathologicalProducts.values,
                    selected: _stoolProducts,
                    labelOf: (v) => v == StoolPathologicalProducts.ausentes
                        ? 'Ausentes'
                        : 'Presentes',
                    onChanged: (v) => _update(() => _stoolProducts = v),
                  ),
                  if (_stoolProducts == StoolPathologicalProducts.presentes)
                    _text('stoolDescription', 'Descrever',
                        hint: 'Sangue, muco, melena...'),
                ]),
                FormSection(title: 'Avaliacao pulmonar', children: [
                  _lungSide(
                    title: 'Pulmao direito',
                    mvPresent: _rightMvPresent,
                    findings: _rightPulmonaryFindings,
                    locations: _rightPulmonaryLocations,
                    onMvChanged: (v) => _update(() => _rightMvPresent = v),
                  ),
                  _lungSide(
                    title: 'Pulmao esquerdo',
                    mvPresent: _leftMvPresent,
                    findings: _leftPulmonaryFindings,
                    locations: _leftPulmonaryLocations,
                    onMvChanged: (v) => _update(() => _leftMvPresent = v),
                  ),
                ]),
                FormSection(title: 'Estado geral', children: [
                  _chips<String>(
                    title: 'Cor',
                    values: const ['CORADO', 'HIPOCORADO', 'DESCORADO'],
                    selected: _colorStatus,
                    labelOf: _generalLabel,
                    onChanged: (v) => _update(() => _colorStatus = v),
                  ),
                  _chips<String>(
                    title: 'Hidratacao',
                    values: const ['HIDRATADO', 'DESIDRATADO'],
                    selected: _hydrationStatus,
                    labelOf: _generalLabel,
                    onChanged: (v) => _update(() => _hydrationStatus = v),
                  ),
                  _chips<String>(
                    title: 'Cianose',
                    values: const ['ACIANOTICO', 'CIANOTICO'],
                    selected: _cyanosisStatus,
                    labelOf: _generalLabel,
                    onChanged: (v) => _update(() => _cyanosisStatus = v),
                  ),
                  _chips<String>(
                    title: 'Ictericia',
                    values: const ['ANICTERICO', 'ICTERICO'],
                    selected: _jaundiceStatus,
                    labelOf: _generalLabel,
                    onChanged: (v) => _update(() => _jaundiceStatus = v),
                  ),
                  _chips<String>(
                    title: 'Padrao respiratorio clinico',
                    values: const ['EUPNEICO', 'DISPNEICO'],
                    selected: _respiratoryEffort,
                    labelOf: _generalLabel,
                    onChanged: (v) => _update(() => _respiratoryEffort = v),
                  ),
                  _chips<String>(
                    title: 'Estado geral',
                    values: const ['BEG', 'REG', 'MEG'],
                    selected: _generalState,
                    labelOf: (v) => switch (v) {
                      'BEG' => 'Bom estado geral',
                      'REG' => 'Regular estado geral',
                      'MEG' => 'Mau estado geral',
                      _ => v,
                    },
                    onChanged: (v) => _update(() => _generalState = v),
                  ),
                ]),
                FormSection(title: 'ACV', children: [
                  _chips<String>(
                    title: 'Ritmo/bulhas',
                    values: const ['BCRNF', 'RITMO IRREGULAR'],
                    selected: _heartRhythm,
                    labelOf: _generalLabel,
                    onChanged: (v) => _update(() => _heartRhythm = v),
                  ),
                  _chips<String>(
                    title: 'Tempos',
                    values: const ['2T', '3T'],
                    selected: _heartSounds,
                    labelOf: _generalLabel,
                    onChanged: (v) => _update(() => _heartSounds = v),
                  ),
                  _chips<String>(
                    title: 'Sopros',
                    values: const [
                      'SEM SOPROS',
                      'SOPRO SISTOLICO',
                      'SOPRO DIASTOLICO'
                    ],
                    selected: _murmur,
                    labelOf: _generalLabel,
                    onChanged: (v) => _update(() => _murmur = v),
                  ),
                  _chips<String>(
                    title: 'TEC',
                    values: const ['TEC<3S', 'TEC>3S'],
                    selected: _capillaryRefill,
                    labelOf: (v) => v == 'TEC<3S' ? 'TEC < 3s' : 'TEC > 3s',
                    onChanged: (v) => _update(() => _capillaryRefill = v),
                  ),
                  _chips<String>(
                    title: 'Pulsos',
                    values: const [
                      'PULSOS PERIFERICOS PALPAVEIS',
                      'PULSOS PERIFERICOS REDUZIDOS',
                    ],
                    selected: _pulses,
                    labelOf: (v) => v == 'PULSOS PERIFERICOS PALPAVEIS'
                        ? 'Pulsos palpaveis'
                        : 'Pulsos reduzidos',
                    onChanged: (v) => _update(() => _pulses = v),
                  ),
                  _chips<String>(
                    title: 'Extremidades',
                    values: const [
                      'EXTREMIDADES AQUECIDAS',
                      'EXTREMIDADES FRIAS'
                    ],
                    selected: _extremitiesTemperature,
                    labelOf: (v) =>
                        v == 'EXTREMIDADES AQUECIDAS' ? 'Aquecidas' : 'Frias',
                    onChanged: (v) =>
                        _update(() => _extremitiesTemperature = v),
                  ),
                ]),
                FormSection(title: 'Abdome', children: [
                  _chips<String>(
                    title: 'Formato',
                    values: const [
                      'PLANO',
                      'GLOBOSO',
                      'DISTENDIDO',
                      'ESCAVADO'
                    ],
                    selected: _abdomenShape,
                    labelOf: _generalLabel,
                    onChanged: (v) => _update(() => _abdomenShape = v),
                  ),
                  _chips<String>(
                    title: 'Consistencia',
                    values: const ['FLACIDO', 'TENSO', 'RIGIDO'],
                    selected: _abdomenConsistency,
                    labelOf: _generalLabel,
                    onChanged: (v) => _update(() => _abdomenConsistency = v),
                  ),
                  _chips<String>(
                    title: 'Ruidos hidroaereos',
                    values: const [
                      'RH+',
                      'RH DIMINUIDOS',
                      'RH AUSENTES',
                      'RH AUMENTADOS'
                    ],
                    selected: _bowelSounds,
                    labelOf: _generalLabel,
                    onChanged: (v) => _update(() => _bowelSounds = v),
                  ),
                  _chips<String>(
                    title: 'Dor',
                    values: const ['INDOLOR', 'DOLOROSO'],
                    selected: _abdominalPain,
                    labelOf: _generalLabel,
                    onChanged: (v) => _update(() => _abdominalPain = v),
                  ),
                  if (_abdominalPain == 'DOLOROSO')
                    _multiChips<String>(
                      title: 'Local da dor',
                      values: const [
                        'DIFUSA',
                        'EPIGASTRIO',
                        'HIPOGASTRIO',
                        'FID',
                        'FIE',
                        'HD',
                        'HE',
                      ],
                      selected: _abdominalPainLocations,
                      labelOf: _generalLabel,
                    ),
                  _chips<String>(
                    title: 'Peritonite',
                    values: const [
                      'SEM SINAIS DE PERITONITE',
                      'DEFESA',
                      'DB+',
                    ],
                    selected: _peritonitis,
                    labelOf: (v) => switch (v) {
                      'SEM SINAIS DE PERITONITE' => 'Sem peritonite',
                      'DEFESA' => 'Defesa',
                      'DB+' => 'DB+',
                      _ => v,
                    },
                    onChanged: (v) => _update(() => _peritonitis = v),
                  ),
                  _multiChips<String>(
                    title: 'Outros achados',
                    values: const ['ASCITE', 'OSTOMIA', 'DRENO ABDOMINAL'],
                    selected: _abdominalOtherFindings,
                    labelOf: _generalLabel,
                  ),
                ]),
                FormSection(title: 'Neuro', children: [
                  FilledButton.tonalIcon(
                    onPressed: _applyNormalNeurological,
                    icon: const Icon(Icons.psychology_alt_outlined),
                    label: const Text('Neurologico normal'),
                  ),
                  _chips<bool>(
                    title: 'Sedacao',
                    values: const [false, true],
                    selected: _neurological == NeurologicalState.sedado,
                    labelOf: (v) => v ? 'Sim' : 'Nao',
                    onChanged: (v) => _update(() {
                      _neurological = v
                          ? NeurologicalState.sedado
                          : NeurologicalState.acordado;
                    }),
                  ),
                  if (_neurological == NeurologicalState.sedado ||
                      _isDeepSedation) ...[
                    _text('rass', 'RASS', hint: '-5', number: true),
                  ] else ...[
                    _gcsSummary(),
                    _chips<String>(
                      title: 'Abertura ocular',
                      values: const ['AO4', 'AO3', 'AO2', 'AO1'],
                      selected: _gcsEye,
                      labelOf: (v) => v,
                      onChanged: (v) => _update(() => _gcsEye = v),
                    ),
                    _chips<String>(
                      title: 'Resposta verbal',
                      values: _verbalResponseOptions,
                      selected: _gcsVerbal,
                      labelOf: (v) => v,
                      onChanged: (v) => _update(() => _gcsVerbal = v),
                    ),
                    _chips<String>(
                      title: 'Resposta motora',
                      values: const ['RM6', 'RM5', 'RM4', 'RM3', 'RM2', 'RM1'],
                      selected: _gcsMotor,
                      labelOf: (v) => v,
                      onChanged: (v) => _update(() => _gcsMotor = v),
                    ),
                    _chips<bool>(
                      title: 'Mobilidade preservada',
                      values: const [true, false],
                      selected: _mobilityPreserved,
                      labelOf: (v) => v ? 'Sim' : 'Nao',
                      onChanged: (v) => _update(() => _mobilityPreserved = v),
                    ),
                    _chips<bool>(
                      title: 'Forca preservada em 4 membros',
                      values: const [true, false],
                      selected: _strengthPreserved,
                      labelOf: (v) => v ? 'Sim' : 'Nao',
                      onChanged: (v) => _update(() => _strengthPreserved = v),
                    ),
                    if (!_mobilityPreserved || !_strengthPreserved)
                      _text('neuroDeficit', 'Paresia/plegia ou deficit motor',
                          hint: 'Ex.: hemiparesia direita, plegia em MIE...'),
                  ],
                  _chips<bool>(
                    title: 'PIFR',
                    values: const [true, false],
                    selected: _pifr,
                    labelOf: (v) => v ? 'Sim' : 'Nao',
                    onChanged: (v) => _update(() => _pifr = v),
                  ),
                ]),
                FormSection(title: 'Membros', children: [
                  Text('MMII', style: Theme.of(context).textTheme.labelLarge),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    FilterChip(
                      label: const Text('Edema'),
                      selected: _lowerLimbEdema,
                      onSelected: (v) => _update(() => _lowerLimbEdema = v),
                    ),
                    FilterChip(
                      label: const Text('Empastamento'),
                      selected: _lowerLimbPitting,
                      onSelected: (v) => _update(() => _lowerLimbPitting = v),
                    ),
                    FilterChip(
                      label: const Text('Lesao'),
                      selected: _lowerLimbLesion,
                      onSelected: (v) => _update(() => _lowerLimbLesion = v),
                    ),
                    FilterChip(
                      label: const Text('Amputacao'),
                      selected: _lowerLimbAmputation,
                      onSelected: (v) =>
                          _update(() => _lowerLimbAmputation = v),
                    ),
                  ]),
                  if (_lowerLimbLesion || _lowerLimbAmputation)
                    _multiChips<String>(
                      title: 'Qual membro inferior?',
                      values: const ['MID', 'MIE'],
                      selected: _lowerLimbSides,
                      labelOf: (v) => v,
                    ),
                  if (_lowerLimbEdema) ...[
                    _chips<String>(
                      title: 'Graduacao do edema MMII',
                      values: const ['+/4+', '++/4+', '+++/4+', '++++/4+'],
                      selected: _lowerLimbEdemaGrade,
                      labelOf: (v) => v,
                      onChanged: (v) => _update(() => _lowerLimbEdemaGrade = v),
                    ),
                    _multiChips<String>(
                      title: 'Localizacao do edema MMII',
                      values: const ['MID', 'MIE'],
                      selected: _lowerLimbSides,
                      labelOf: (v) => v,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _chips<bool>(
                    title: 'MMSS',
                    values: const [false, true],
                    selected: _upperLimbEdema,
                    labelOf: (v) => v ? 'Com edema' : 'Sem edema',
                    onChanged: (v) => _update(() => _upperLimbEdema = v),
                  ),
                  if (_upperLimbEdema)
                    _chips<String>(
                      title: 'Graduacao do edema MMSS',
                      values: const ['+/4+', '++/4+', '+++/4+', '++++/4+'],
                      selected: _upperLimbEdemaGrade,
                      labelOf: (v) => v,
                      onChanged: (v) => _update(() => _upperLimbEdemaGrade = v),
                    ),
                  _text('notes', 'O que precisar escrever a mais', lines: 4),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bedHeader(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.bed_outlined),
              const SizedBox(width: 10),
              Text(widget.bed!.displayName,
                  style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      );

  Widget _presetButtons() => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.tonalIcon(
            onPressed: () => _applyPreset(mechanicalVentilation: false),
            icon: const Icon(Icons.air),
            label: const Text('Padrao acordado'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => _applyPreset(mechanicalVentilation: true),
            icon: const Icon(Icons.monitor_heart_outlined),
            label: const Text('Padrao IOT/VM'),
          ),
        ],
      );

  Widget _temperatureField() => TextField(
        controller: _fields['temp'],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Temperatura',
          hintText: '36,5',
          suffixIcon: Center(
            widthFactor: 1,
            child: _temperatureDot(),
          ),
        ),
      );

  Widget _temperatureDot() {
    final state = _temperatureFromInput();
    final color = switch (state) {
      TemperatureState.febril => Colors.red,
      TemperatureState.subfebril => Colors.orange,
      TemperatureState.afebril => Colors.green,
      null => Theme.of(context).colorScheme.outlineVariant,
    };
    return Container(
      width: 14,
      height: 14,
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
    );
  }

  Widget _lungSide({
    required String title,
    required bool? mvPresent,
    required Set<String> findings,
    required Set<String> locations,
    required ValueChanged<bool?> onMvChanged,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _chips<bool?>(
            title: 'MV',
            values: const [true, false],
            selected: mvPresent,
            labelOf: (v) => v == true ? 'Presente' : 'Ausente',
            onChanged: onMvChanged,
          ),
          _multiChips<String>(
            title: 'Achados',
            values: const [
              'ESTERTORES FINOS',
              'ESTERTORES GROSSOS',
              'SIBILOS',
            ],
            selected: findings,
            labelOf: (v) => switch (v) {
              'ESTERTORES FINOS' => 'Estertores finos',
              'ESTERTORES GROSSOS' => 'Estertores grossos',
              'SIBILOS' => 'Sibilos',
              _ => v,
            },
          ),
          if (findings.isNotEmpty)
            _multiChips<String>(
              title: 'Localizacao dos achados',
              values: const ['BASE', 'CAMPO MEDIO', 'APICE'],
              selected: locations,
              labelOf: (v) => switch (v) {
                'BASE' => 'Base',
                'CAMPO MEDIO' => 'Campo medio',
                'APICE' => 'Apice',
                _ => v,
              },
            ),
          const SizedBox(height: 12),
        ],
      );

  Widget _gcsSummary() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'GCS calculado: ${_gcsText()} ($_gcsEye, $_gcsVerbal, $_gcsMotor)',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      );

  Widget _segmented<T>({
    required List<T> values,
    required T selected,
    required String Function(T) labelOf,
    required ValueChanged<T> onChanged,
  }) =>
      SegmentedButton<T>(
        segments: values
            .map((value) =>
                ButtonSegment<T>(value: value, label: Text(labelOf(value))))
            .toList(),
        selected: {selected},
        onSelectionChanged: (values) => onChanged(values.first),
      );

  Widget _chips<T>({
    required String title,
    required List<T> values,
    required T? selected,
    required String Function(T) labelOf,
    required ValueChanged<T> onChanged,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values
                .map((value) => ChoiceChip(
                      label: Text(labelOf(value)),
                      selected: value == selected,
                      onSelected: (_) => onChanged(value),
                    ))
                .toList(),
          ),
        ],
      );

  Widget _multiChips<T>({
    required String title,
    required List<T> values,
    required Set<T> selected,
    required String Function(T) labelOf,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values
                .map((value) => FilterChip(
                      label: Text(labelOf(value)),
                      selected: selected.contains(value),
                      onSelected: (active) => _update(() => active
                          ? selected.add(value)
                          : selected.remove(value)),
                    ))
                .toList(),
          ),
        ],
      );

  Widget _drugChips({
    required List<DrugOption> options,
    required Set<String> selected,
    required Map<String, TextEditingController> controllers,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options
                .map((drug) => FilterChip(
                      label: Text(drug.name),
                      selected: selected.contains(drug.name),
                      onSelected: (active) => _update(() => active
                          ? selected.add(drug.name)
                          : selected.remove(drug.name)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          for (final drug in options)
            if (selected.contains(drug.name))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: controllers[drug.name],
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      InputDecoration(labelText: '${drug.name} (${drug.unit})'),
                ),
              ),
        ],
      );

  Widget _vmMainField() {
    if (_ventilationMode == 'PCV') {
      return _text('pc', 'PC', number: true);
    }
    if (_ventilationMode == 'PSV') {
      return _text('ps', 'PS', number: true);
    }
    return _text('vt', 'VT', number: true);
  }

  Widget _text(String key, String label,
      {String? hint, bool number = false, int lines = 1}) {
    return TextField(
      controller: _fields[key],
      keyboardType:
          number ? const TextInputType.numberWithOptions(decimal: true) : null,
      maxLines: lines,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  Widget _row(Widget left, Widget right) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 10),
          Expanded(child: right),
        ],
      );

  String _supportLabel(VentilatorySupport support) => switch (support) {
        VentilatorySupport.arAmbiente => 'AA',
        VentilatorySupport.cateterNasal => 'CN',
        VentilatorySupport.mascara => 'Mascara',
        VentilatorySupport.vni => 'VNI',
        VentilatorySupport.iotVm => 'IOT+VM',
        VentilatorySupport.tqtVm => 'TQT+VM',
      };

  String _generalLabel(String value) => value
      .replaceAll('ACIANOTICO', 'Acianotico')
      .replaceAll('ANICTERICO', 'Anicterico')
      .replaceAll('HIPOCORADO', 'Hipocorado')
      .replaceAll('DESCORADO', 'Descorado')
      .replaceAll('CORADO', 'Corado')
      .replaceAll('HIDRATADO', 'Hidratado')
      .replaceAll('DESIDRATADO', 'Desidratado')
      .replaceAll('CIANOTICO', 'Cianotico')
      .replaceAll('ICTERICO', 'Icterico')
      .replaceAll('EUPNEICO', 'Eupneico')
      .replaceAll('DISPNEICO', 'Dispneico')
      .replaceAll('RITMO IRREGULAR', 'Ritmo irregular')
      .replaceAll('SEM SOPROS', 'Sem sopros')
      .replaceAll('SOPRO SISTOLICO', 'Sopro sistolico')
      .replaceAll('SOPRO DIASTOLICO', 'Sopro diastolico')
      .replaceAll('PLANO', 'Plano')
      .replaceAll('GLOBOSO', 'Globoso')
      .replaceAll('DISTENDIDO', 'Distendido')
      .replaceAll('ESCAVADO', 'Escavado')
      .replaceAll('FLACIDO', 'Flacido')
      .replaceAll('TENSO', 'Tenso')
      .replaceAll('RIGIDO', 'Rigido')
      .replaceAll('DIMINUIDOS', 'Diminuídos')
      .replaceAll('AUSENTES', 'Ausentes')
      .replaceAll('AUMENTADOS', 'Aumentados')
      .replaceAll('INDOLOR', 'Indolor')
      .replaceAll('DOLOROSO', 'Doloroso')
      .replaceAll('DIFUSA', 'Difusa')
      .replaceAll('EPIGASTRIO', 'Epigastrio')
      .replaceAll('HIPOGASTRIO', 'Hipogastrio')
      .replaceAll('ASCITE', 'Ascite')
      .replaceAll('OSTOMIA', 'Ostomia')
      .replaceAll('DRENO ABDOMINAL', 'Dreno abdominal');

  String? _value(String key) {
    final value = _fields[key]!.text.trim();
    return value.isEmpty ? null : value;
  }

  int? _rassValue() {
    final raw = _value('rass')?.replaceAll(',', '.');
    if (raw == null) return null;
    return double.tryParse(raw)?.round();
  }

  String? _bloodPressureValue() {
    final systolic = _value('paSystolic');
    final diastolic = _value('paDiastolic');
    if (systolic == null && diastolic == null) return null;
    if (systolic != null && diastolic != null) return '$systolic/$diastolic';
    return systolic ?? diastolic;
  }

  TemperatureState? _temperatureFromInput() {
    final raw = _value('temp')?.replaceAll(',', '.');
    final value = raw == null ? null : double.tryParse(raw);
    if (value == null) return null;
    if (value >= 37.9) return TemperatureState.febril;
    if (value >= 37.5) return TemperatureState.subfebril;
    return TemperatureState.afebril;
  }

  String? _pulmonaryExam() {
    final right = _lungText(
      'DIREITA',
      _rightMvPresent,
      _rightPulmonaryFindings,
      _rightPulmonaryLocations,
    );
    final left = _lungText(
      'ESQUERDA',
      _leftMvPresent,
      _leftPulmonaryFindings,
      _leftPulmonaryLocations,
    );
    final parts = [right, left].whereType<String>().toList();
    if (parts.isEmpty) return null;
    return parts.join('; ');
  }

  String? _lungText(
    String side,
    bool? mvPresent,
    Set<String> findings,
    Set<String> locations,
  ) {
    final values = <String>[];
    if (mvPresent != null) {
      values.add(mvPresent ? 'MV+ $side' : 'MV AUSENTE $side');
    }
    if (findings.isNotEmpty) {
      final locationText =
          locations.isEmpty ? '' : ' EM ${locations.join(' E ')}';
      values.add('${findings.join(' E ')}$locationText $side');
    }
    return values.isEmpty ? null : values.join(', ');
  }

  String? _lowerLimbsExam() {
    final values = <String>[];
    if (_lowerLimbEdema) {
      final grade =
          _lowerLimbEdemaGrade == null ? '' : ' $_lowerLimbEdemaGrade';
      final location =
          _lowerLimbSides.isEmpty ? '' : ' EM ${_lowerLimbSides.join(' E ')}';
      values.add('COM EDEMA$grade$location');
    }
    if (_lowerLimbPitting) values.add('COM EMPASTAMENTO');
    if (_lowerLimbLesion) {
      values.add('COM LESAO${_lowerLimbSidesText()}');
    }
    if (_lowerLimbAmputation) {
      values.add('COM AMPUTACAO${_lowerLimbSidesText()}');
    }
    return values.isEmpty ? null : values.join(', ');
  }

  String _lowerLimbSidesText() =>
      _lowerLimbSides.isEmpty ? '' : ' EM ${_lowerLimbSides.join(' E ')}';

  String? _upperLimbsExam() => _upperLimbEdema
      ? 'COM EDEMA${_upperLimbEdemaGrade == null ? '' : ' $_upperLimbEdemaGrade'}'
      : 'SEM EDEMA';

  String _sexAware(String masculine) {
    if (_sex == Sex.masculino) return masculine;
    return switch (masculine) {
      'CORADO' => 'CORADA',
      'HIPOCORADO' => 'HIPOCORADA',
      'DESCORADO' => 'DESCORADA',
      'HIDRATADO' => 'HIDRATADA',
      'DESIDRATADO' => 'DESIDRATADA',
      'ACIANOTICO' => 'ACIANOTICA',
      'CIANOTICO' => 'CIANOTICA',
      'ANICTERICO' => 'ANICTERICA',
      'ICTERICO' => 'ICTERICA',
      'EUPNEICO' => 'EUPNEICA',
      'DISPNEICO' => 'DISPNEICA',
      _ => masculine,
    };
  }

  String _generalConditionExam() => [
        _generalState,
        _sexAware(_colorStatus),
        _sexAware(_hydrationStatus),
        _sexAware(_cyanosisStatus),
        _sexAware(_jaundiceStatus),
        _sexAware(_respiratoryEffort),
      ].join(', ');

  String _cardiovascularExam() => [
        _heartRhythm,
        _murmur == 'SEM SOPROS' ? 'SS' : _murmur,
        _heartSounds,
        _capillaryRefill,
        _pulses,
        _extremitiesTemperature,
      ].join(', ');

  String _abdominalExam() {
    final pain = _abdominalPain == 'INDOLOR'
        ? 'INDOLOR A PALPACAO'
        : 'DOLOROSO A PALPACAO${_abdominalPainLocations.isEmpty ? '' : ' EM ${_abdominalPainLocations.join(' E ')}'}';
    final findings = [
      _abdomenShape,
      _abdomenConsistency,
      _bowelSounds,
      pain,
      _peritonitis,
      ..._abdominalOtherFindings,
    ];
    return findings.join(', ');
  }

  String _neurologicalExam() {
    final pifrText = _pifr ? 'PIFR' : 'SEM PIFR';
    if (_neurological == NeurologicalState.sedado || _isDeepSedation) {
      final rass = _value('rass') ?? '-5';
      final prefix =
          _neurological == NeurologicalState.sedado ? 'SOB SEDACAO, ' : '';
      return '${prefix}RASS $rass, $pifrText';
    }

    final findings = <String>[
      'GCS ${_gcsText()} ($_gcsEye, $_gcsVerbal, $_gcsMotor)',
      pifrText
    ];
    final deficit = _value('neuroDeficit');
    if (_mobilityPreserved && _strengthPreserved) {
      findings.add('MOBILIDADE E FORCA DE 4 MEMBROS PRESERVADA');
    } else if (deficit != null) {
      findings.add(deficit.toUpperCase());
    } else {
      final altered = <String>[];
      if (!_mobilityPreserved) altered.add('MOBILIDADE NAO PRESERVADA');
      if (!_strengthPreserved) {
        altered.add('FORCA DE 4 MEMBROS NAO PRESERVADA');
      }
      findings.add(altered.join(', '));
    }
    return findings.join(', ');
  }

  String _gcsText() {
    final eye = _componentScore(_gcsEye);
    final motor = _componentScore(_gcsMotor);
    if (_gcsVerbal == 'RVT') return '${eye + motor}T';
    return '${eye + _componentScore(_gcsVerbal) + motor}';
  }

  int _componentScore(String value) => int.parse(value.substring(2));

  void _onFieldChanged() {
    if (_restoringDraft) return;
    setState(() {});
    _saveDraftSoon();
  }

  void _update(VoidCallback changes) {
    setState(changes);
    _saveDraftSoon();
  }

  void _saveDraftSoon() {
    if (widget.bed == null || widget.onDraftSaved == null || _restoringDraft) {
      return;
    }
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(const Duration(milliseconds: 400), () {
      widget.onDraftSaved?.call(_currentData());
    });
  }

  EvolutionData _currentData() => EvolutionData(
        sex: _sex,
        local: widget.bed == null ? 'UTI' : 'UTI ${widget.bed!.unitCode}',
        template: _template,
        neurologicalState: _neurological,
        sedationDrugRates: _neurological == NeurologicalState.sedado
            ? _drugRates(_selectedSedationDrugs, _sedationRates)
            : const {},
        ventilatorySupport: _support,
        ventilationMode: _isMechanicalVentilation ? _ventilationMode : null,
        respiratoryRate: _isMechanicalVentilation ? _value('fr') : null,
        tidalVolume: _ventilationMode == 'VCV' ? _value('vt') : null,
        controlledPressure: _ventilationMode == 'PCV' ? _value('pc') : null,
        pressureSupport: _ventilationMode == 'PSV' ? _value('ps') : null,
        fio2: _isMechanicalVentilation ? _value('fio2') : null,
        peep: _isMechanicalVentilation ? _value('peep') : null,
        oxygenFlow: _support == VentilatorySupport.cateterNasal ||
                _support == VentilatorySupport.mascara
            ? _value('oxygenFlow')
            : null,
        homeOxygenFlow:
            _support == VentilatorySupport.cateterNasal && _usesHomeOxygen
                ? _value('homeOxygenFlow')
                : null,
        ventilatorSynchrony: _isMechanicalVentilation ? _vmSynchrony : null,
        oxygenSaturation: _value('spo2'),
        bloodPressure: _bloodPressureValue(),
        meanArterialPressure: _value('pam'),
        heartRate: _value('fc'),
        weight: _value('weight'),
        measuredTemperature: _value('temp'),
        continuousInfusions: _value('bic'),
        hemodynamicState: _hemodynamic,
        bloodPressureState: _bloodPressureState,
        vasoactiveSupport: _dvaSupport,
        vasoactiveDrugRates: _dvaSupport == VasoactiveSupport.comDva
            ? _drugRates(_selectedVasoactiveDrugs, _vasoactiveRates)
            : const {},
        temperatureState: _temperatureFromInput(),
        dietRoute: _diet,
        nausea: _nausea,
        vomiting: _vomiting,
        gastricStasis: _stasis,
        hgtMinimum: _value('hgtMin'),
        hgtMaximum: _value('hgtMax'),
        diuresisType: _diuresis,
        diuresisVolume:
            _diuresis == DiuresisType.ausente ? null : _value('urineVolume'),
        diuresisPeriod: _diuresis == DiuresisType.ausente ? null : _period,
        diuresisAppearance: _diuresis == DiuresisType.ausente
            ? null
            : _value('urineAppearance'),
        fluidBalance: _value('balance'),
        fluidBalancePeriod: _value('balance') == null ? null : _period,
        bowelMovement: _bowel,
        stoolPathologicalProducts: _stoolProducts,
        stoolPathologicalDescription:
            _stoolProducts == StoolPathologicalProducts.presentes
                ? _value('stoolDescription')
                : null,
        generalCondition: _generalConditionExam(),
        pulmonaryExam: _pulmonaryExam(),
        cardiovascularExam: _cardiovascularExam(),
        abdominalExam: _abdominalExam(),
        neurologicalExam: _neurologicalExam(),
        lowerLimbsExam: _lowerLimbsExam(),
        upperLimbsExam: _upperLimbsExam(),
        rass: _neurological == NeurologicalState.sedado || _isDeepSedation
            ? _value('rass')
            : null,
        notes: _value('notes'),
        formState: _formState(),
      );

  Map<String, dynamic> _formState() => {
        'usesHomeOxygen': _usesHomeOxygen,
        'vmSynchrony': _vmSynchrony,
        'rightMvPresent': _rightMvPresent,
        'leftMvPresent': _leftMvPresent,
        'rightPulmonaryFindings': _rightPulmonaryFindings.toList(),
        'leftPulmonaryFindings': _leftPulmonaryFindings.toList(),
        'rightPulmonaryLocations': _rightPulmonaryLocations.toList(),
        'leftPulmonaryLocations': _leftPulmonaryLocations.toList(),
        'colorStatus': _colorStatus,
        'hydrationStatus': _hydrationStatus,
        'cyanosisStatus': _cyanosisStatus,
        'jaundiceStatus': _jaundiceStatus,
        'respiratoryEffort': _respiratoryEffort,
        'generalState': _generalState,
        'heartRhythm': _heartRhythm,
        'heartSounds': _heartSounds,
        'murmur': _murmur,
        'capillaryRefill': _capillaryRefill,
        'pulses': _pulses,
        'extremitiesTemperature': _extremitiesTemperature,
        'abdomenShape': _abdomenShape,
        'abdomenConsistency': _abdomenConsistency,
        'bowelSounds': _bowelSounds,
        'abdominalPain': _abdominalPain,
        'abdominalPainLocations': _abdominalPainLocations.toList(),
        'peritonitis': _peritonitis,
        'abdominalOtherFindings': _abdominalOtherFindings.toList(),
        'gcsEye': _gcsEye,
        'gcsVerbal': _gcsVerbal,
        'gcsMotor': _gcsMotor,
        'pifr': _pifr,
        'mobilityPreserved': _mobilityPreserved,
        'strengthPreserved': _strengthPreserved,
        'neuroDeficit': _value('neuroDeficit'),
        'lowerLimbEdema': _lowerLimbEdema,
        'lowerLimbEdemaGrade': _lowerLimbEdemaGrade,
        'lowerLimbPitting': _lowerLimbPitting,
        'lowerLimbLesion': _lowerLimbLesion,
        'lowerLimbAmputation': _lowerLimbAmputation,
        'lowerLimbSides': _lowerLimbSides.toList(),
        'upperLimbEdema': _upperLimbEdema,
        'upperLimbEdemaGrade': _upperLimbEdemaGrade,
      };

  void _generate() {
    final data = _currentData();
    widget.onDraftSaved?.call(data);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EvolutionPreviewScreen(
        data: data,
        bed: widget.bed,
        onConfirmed: widget.onCompleted,
      ),
    ));
  }

  void _restoreFields(EvolutionData data) {
    final pressureParts = data.bloodPressure?.split(RegExp(r'[/xX]'));
    if (pressureParts != null && pressureParts.length >= 2) {
      _fields['paSystolic']!.text = pressureParts[0].trim();
      _fields['paDiastolic']!.text = pressureParts[1].trim();
    }
    final values = <String, String?>{
      'fc': data.heartRate,
      'pam': data.meanArterialPressure,
      'weight': data.weight,
      'temp': data.measuredTemperature,
      'spo2': data.oxygenSaturation,
      'oxygenFlow': data.oxygenFlow,
      'homeOxygenFlow': data.homeOxygenFlow,
      'hgtMin': data.hgtMinimum,
      'hgtMax': data.hgtMaximum,
      'bic': data.continuousInfusions,
      'fr': data.respiratoryRate,
      'vt': data.tidalVolume,
      'pc': data.controlledPressure,
      'ps': data.pressureSupport,
      'fio2': data.fio2,
      'peep': data.peep,
      'urineVolume': data.diuresisVolume,
      'urineAppearance': data.diuresisAppearance,
      'balance': data.fluidBalance,
      'rass': data.rass,
      'neuroDeficit': data.formState['neuroDeficit'] as String?,
      'stoolDescription': data.stoolPathologicalDescription,
      'notes': data.notes,
    };
    for (final entry in values.entries) {
      _fields[entry.key]!.text = entry.value ?? '';
    }
  }

  void _restoreFormState(Map<String, dynamic> state) {
    _usesHomeOxygen = state['usesHomeOxygen'] as bool? ?? _usesHomeOxygen;
    _vmSynchrony = state['vmSynchrony'] as bool? ?? _vmSynchrony;
    _rightMvPresent = state['rightMvPresent'] as bool?;
    _leftMvPresent = state['leftMvPresent'] as bool?;
    _restoreStringSet(_rightPulmonaryFindings, state['rightPulmonaryFindings']);
    _restoreStringSet(_leftPulmonaryFindings, state['leftPulmonaryFindings']);
    _restoreStringSet(
        _rightPulmonaryLocations, state['rightPulmonaryLocations']);
    _restoreStringSet(_leftPulmonaryLocations, state['leftPulmonaryLocations']);
    _colorStatus = state['colorStatus'] as String? ?? _colorStatus;
    _hydrationStatus = state['hydrationStatus'] as String? ?? _hydrationStatus;
    _cyanosisStatus = state['cyanosisStatus'] as String? ?? _cyanosisStatus;
    _jaundiceStatus = state['jaundiceStatus'] as String? ?? _jaundiceStatus;
    _respiratoryEffort =
        state['respiratoryEffort'] as String? ?? _respiratoryEffort;
    _generalState = state['generalState'] as String? ?? _generalState;
    _heartRhythm = state['heartRhythm'] as String? ?? _heartRhythm;
    _heartSounds = state['heartSounds'] as String? ?? _heartSounds;
    _murmur = state['murmur'] as String? ?? _murmur;
    _capillaryRefill = state['capillaryRefill'] as String? ?? _capillaryRefill;
    _pulses = state['pulses'] as String? ?? _pulses;
    _extremitiesTemperature =
        state['extremitiesTemperature'] as String? ?? _extremitiesTemperature;
    _abdomenShape = state['abdomenShape'] as String? ?? _abdomenShape;
    _abdomenConsistency =
        state['abdomenConsistency'] as String? ?? _abdomenConsistency;
    _bowelSounds = state['bowelSounds'] as String? ?? _bowelSounds;
    _abdominalPain = state['abdominalPain'] as String? ?? _abdominalPain;
    _restoreStringSet(_abdominalPainLocations, state['abdominalPainLocations']);
    _peritonitis = state['peritonitis'] as String? ?? _peritonitis;
    _restoreStringSet(_abdominalOtherFindings, state['abdominalOtherFindings']);
    _gcsEye = state['gcsEye'] as String? ?? _gcsEye;
    _gcsVerbal = state['gcsVerbal'] as String? ?? _gcsVerbal;
    _gcsMotor = state['gcsMotor'] as String? ?? _gcsMotor;
    _pifr = state['pifr'] as bool? ?? _pifr;
    _mobilityPreserved =
        state['mobilityPreserved'] as bool? ?? _mobilityPreserved;
    _strengthPreserved =
        state['strengthPreserved'] as bool? ?? _strengthPreserved;
    _lowerLimbEdema = state['lowerLimbEdema'] as bool? ?? _lowerLimbEdema;
    _lowerLimbEdemaGrade =
        state['lowerLimbEdemaGrade'] as String? ?? _lowerLimbEdemaGrade;
    _lowerLimbPitting = state['lowerLimbPitting'] as bool? ?? _lowerLimbPitting;
    _lowerLimbLesion = state['lowerLimbLesion'] as bool? ?? _lowerLimbLesion;
    _lowerLimbAmputation =
        state['lowerLimbAmputation'] as bool? ?? _lowerLimbAmputation;
    _restoreStringSet(_lowerLimbSides, state['lowerLimbSides']);
    _upperLimbEdema = state['upperLimbEdema'] as bool? ?? _upperLimbEdema;
    _upperLimbEdemaGrade =
        state['upperLimbEdemaGrade'] as String? ?? _upperLimbEdemaGrade;
  }

  void _restoreStringSet(Set<String> target, Object? raw) {
    target
      ..clear()
      ..addAll(raw is List ? raw.map((value) => '$value') : const []);
  }

  Map<String, String> _drugRates(
    Set<String> selected,
    Map<String, TextEditingController> controllers,
  ) =>
      {
        for (final name in selected)
          if (controllers[name]!.text.trim().isNotEmpty)
            name: controllers[name]!.text.trim(),
      };

  void _applyPreset({required bool mechanicalVentilation}) {
    _update(() {
      _template = mechanicalVentilation
          ? EvolutionTemplate.sedadoIotVm
          : EvolutionTemplate.acordadoArAmbiente;
      _neurological = mechanicalVentilation
          ? NeurologicalState.sedado
          : NeurologicalState.acordado;
      _support = mechanicalVentilation
          ? VentilatorySupport.iotVm
          : VentilatorySupport.arAmbiente;
      _ventilationMode = mechanicalVentilation ? 'PCV' : null;
      _hemodynamic = HemodynamicState.estavel;
      _bloodPressureState = BloodPressureState.normotenso;
      _dvaSupport = VasoactiveSupport.semDva;
      _diet = mechanicalVentilation ? DietRoute.sne : DietRoute.vo;
      _diuresis =
          mechanicalVentilation ? DiuresisType.svd : DiuresisType.espontanea;
      _rightMvPresent = true;
      _leftMvPresent = true;
      _rightPulmonaryFindings.clear();
      _leftPulmonaryFindings.clear();
      _rightPulmonaryLocations.clear();
      _leftPulmonaryLocations.clear();
      _lowerLimbEdema = false;
      _lowerLimbPitting = false;
      _lowerLimbLesion = false;
      _lowerLimbAmputation = false;
      _lowerLimbSides.clear();
      _upperLimbEdema = false;
      _setNormalNeurologicalFields();
    });
  }

  void _applyNormalNeurological() {
    _update(() {
      _neurological = NeurologicalState.acordado;
      _setNormalNeurologicalFields();
      _fields['rass']!.clear();
      _fields['neuroDeficit']!.clear();
    });
  }

  void _setNormalNeurologicalFields() {
    _gcsEye = 'AO4';
    _gcsVerbal = 'RV5';
    _gcsMotor = 'RM6';
    _pifr = true;
    _mobilityPreserved = true;
    _strengthPreserved = true;
  }
}

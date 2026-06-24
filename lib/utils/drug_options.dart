class DrugOption {
  const DrugOption(this.name, this.unit);

  final String name;
  final String unit;
}

const sedationDrugOptions = <DrugOption>[
  DrugOption('Midazolam', 'mL/h'),
  DrugOption('Propofol', 'mL/h'),
  DrugOption('Dexmedetomidina', 'mL/h'),
  DrugOption('Fentanila', 'mL/h'),
  DrugOption('Remifentanila', 'mL/h'),
  DrugOption('Cetamina', 'mL/h'),
];

const vasoactiveDrugOptions = <DrugOption>[
  DrugOption('Noradrenalina', 'mcg/kg/min'),
  DrugOption('Vasopressina', 'U/min'),
  DrugOption('Adrenalina', 'mcg/kg/min'),
  DrugOption('Dobutamina', 'mcg/kg/min'),
  DrugOption('Dopamina', 'mcg/kg/min'),
];

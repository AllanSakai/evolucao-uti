import '../models/evolution_data.dart';

extension SexLabel on Sex {
  String get label => this == Sex.masculino ? 'Masculino' : 'Feminino';
}

extension NeurologicalStateLabel on NeurologicalState {
  String get label => switch (this) {
        NeurologicalState.acordado => 'Acordado',
        NeurologicalState.sedado => 'Sedado',
        NeurologicalState.sonolento => 'Sonolento',
        NeurologicalState.confuso => 'Confuso',
      };
}

extension VentilatorySupportLabel on VentilatorySupport {
  String get label => switch (this) {
        VentilatorySupport.arAmbiente => 'Ar ambiente',
        VentilatorySupport.cateterNasal => 'Cateter nasal',
        VentilatorySupport.mascara => 'Máscara',
        VentilatorySupport.vni => 'VNI',
        VentilatorySupport.iotVm => 'IOT + VM',
        VentilatorySupport.tqtVm => 'TQT + VM',
      };
}

import 'package:flutter/material.dart';

import '../models/medication.dart';
import '../utils/search_normalizer.dart';

const medicationRoutes = [
  'Via oral',
  'Via tópica',
  'Via subcutânea',
  'Via intramuscular',
  'Via endovenosa',
  'Via inalatória',
  'Via por sonda nasoenteral',
  'Via por gastrostomia',
];
const administeredQuantitySuggestions = [
  'Meio comprimido',
  '1 comprimido',
  '2 comprimidos',
  '3 comprimidos',
  '5 gotas',
  '10 gotas',
  '20 gotas',
  '30 gotas',
  '40 gotas',
  '1 cápsula',
  '2 cápsulas',
  '1 ampola',
  '1 sachê',
];
const frequencySuggestions = [
  'Uma vez ao dia',
  'Duas vezes ao dia',
  'Três vezes ao dia',
  'Quatro vezes ao dia',
  'A cada 6 horas',
  'A cada 8 horas',
  'A cada 12 horas',
  'A cada 24 horas',
  'Todas as manhãs',
  'Todas as noites',
  'Às 6 horas da manhã',
  'Às 8 horas',
  'Às 14 horas',
  'Às 18 horas',
  'Se dor',
  'Se dor e/ou febre',
  'Se náuseas e/ou vômitos',
  'Conforme necessidade',
];
const dispensingSuggestions = [
  'Contínuo',
  '01 caixa',
  '02 caixas',
  '03 caixas',
  '04 caixas',
  '05 caixas',
];

Future<Medication?> showMedicationEditor(
  BuildContext context, {
  Medication? initial,
  List<Medication> suggestions = const [],
}) =>
    showDialog<Medication>(
      context: context,
      builder: (_) => _MedicationEditorDialog(
        initial: initial,
        suggestions: suggestions,
      ),
    );

class _MedicationEditorDialog extends StatefulWidget {
  const _MedicationEditorDialog({
    required this.suggestions,
    this.initial,
  });
  final Medication? initial;
  final List<Medication> suggestions;

  @override
  State<_MedicationEditorDialog> createState() =>
      _MedicationEditorDialogState();
}

class _MedicationEditorDialogState extends State<_MedicationEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _dose;
  late final TextEditingController _quantity;
  late final TextEditingController _frequency;
  late final TextEditingController _dispensing;
  late final TextEditingController _notes;
  late MedicationPresentation _presentation;
  late MedicationUseType _useType;
  late String _route;

  @override
  void initState() {
    super.initState();
    final value = widget.initial;
    _name = TextEditingController(text: value?.name);
    _dose = TextEditingController(text: value?.dose);
    _quantity = TextEditingController(text: value?.administeredQuantity);
    _frequency = TextEditingController(text: value?.frequency);
    _dispensing = TextEditingController(text: value?.dispensingQuantity);
    _notes = TextEditingController(text: value?.notes);
    _presentation = value?.presentation ?? MedicationPresentation.tablet;
    _useType = value?.useType ?? MedicationUseType.internal;
    _route =
        value?.route.isNotEmpty == true ? value!.route : medicationRoutes[0];
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _dose,
      _quantity,
      _frequency,
      _dispensing,
      _notes
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.initial == null
            ? 'Adicionar medicamento'
            : 'Editar medicamento'),
        content: SizedBox(
          width: 560,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(children: [
                _nameAutocomplete(),
                _field(_dose, 'Dose'),
                DropdownButtonFormField(
                  initialValue: _presentation,
                  decoration: const InputDecoration(labelText: 'Apresentação'),
                  items: MedicationPresentation.values
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.label),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _presentation = value!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField(
                  initialValue: _useType,
                  decoration: const InputDecoration(labelText: 'Tipo de uso'),
                  items: MedicationUseType.values
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.label),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _useType = value!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField(
                  initialValue: _route,
                  decoration: const InputDecoration(
                    labelText: 'Via de administração',
                  ),
                  items: medicationRoutes
                      .map((value) =>
                          DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) => setState(() => _route = value!),
                ),
                const SizedBox(height: 10),
                _autocomplete(_quantity, 'Quantidade administrada',
                    administeredQuantitySuggestions),
                _autocomplete(_frequency, 'Frequência', frequencySuggestions),
                _autocomplete(_dispensing, 'Quantidade para dispensação',
                    dispensingSuggestions),
                _field(_notes, 'Observações (opcional)', required: false),
              ]),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(onPressed: _save, child: const Text('Salvar')),
        ],
      );

  Widget _nameAutocomplete() => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Autocomplete<Medication>(
          initialValue: _name.value,
          displayStringForOption: (item) => item.name,
          optionsBuilder: (value) {
            final query = normalizeSearch(value.text);
            if (query.isEmpty) return const Iterable<Medication>.empty();
            return widget.suggestions.where(
              (item) => normalizeSearch(item.name).contains(query),
            );
          },
          onSelected: _fillFromMedication,
          fieldViewBuilder: (context, controller, focus, submit) {
            controller.addListener(() => _name.text = controller.text);
            return TextFormField(
              controller: controller,
              focusNode: focus,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Obrigatório' : null,
            );
          },
        ),
      );

  void _fillFromMedication(Medication medication) {
    _name.text = medication.name;
    _dose.text = medication.dose;
    _quantity.text = medication.administeredQuantity;
    _frequency.text = medication.frequency;
    _dispensing.text = medication.dispensingQuantity;
    _notes.text = medication.notes;
    setState(() {
      _presentation = medication.presentation;
      _useType = medication.useType;
      _route = medicationRoutes.contains(medication.route)
          ? medication.route
          : medicationRoutes.first;
    });
  }

  Widget _field(TextEditingController controller, String label,
          {bool required = true}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: controller,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: label),
          validator: required
              ? (value) =>
                  value == null || value.trim().isEmpty ? 'Obrigatório' : null
              : null,
        ),
      );

  Widget _autocomplete(
    TextEditingController controller,
    String label,
    List<String> suggestions,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Autocomplete<String>(
          initialValue: controller.value,
          optionsBuilder: (value) => suggestions.where(
              (item) => item.toLowerCase().contains(value.text.toLowerCase())),
          onSelected: (value) => controller.text = value,
          fieldViewBuilder: (context, fieldController, focus, submit) {
            fieldController
                .addListener(() => controller.text = fieldController.text);
            return TextFormField(
              controller: fieldController,
              focusNode: focus,
              decoration: InputDecoration(labelText: label),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Obrigatório' : null,
            );
          },
        ),
      );

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Medication(
        id: widget.initial?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        name: _name.text.trim(),
        dose: _dose.text.trim(),
        presentation: _presentation,
        useType: _useType,
        route: _route,
        administeredQuantity: _quantity.text.trim(),
        frequency: _frequency.text.trim(),
        dispensingQuantity: _dispensing.text.trim(),
        notes: _notes.text.trim(),
      ),
    );
  }
}

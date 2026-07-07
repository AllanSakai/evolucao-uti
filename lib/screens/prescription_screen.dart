import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/medication.dart';
import '../models/prescription.dart';
import '../repositories/medication_repository.dart';
import '../services/prescription_service.dart';
import '../utils/search_normalizer.dart';
import '../widgets/medication_editor_dialog.dart';
import 'medications_screen.dart';

class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({super.key});
  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  final _service = PrescriptionService();
  final List<Medication> _items = [];
  String get _preview => _service.generate(Prescription(
      items: _items
          .map((medication) => PrescriptionItem(medication: medication))
          .toList()));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Receita médica')),
        body: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              FilledButton.tonalIcon(
                  onPressed: _loadTemplate,
                  icon: const Icon(Icons.bolt_outlined),
                  label: const Text('Modelo UTI')),
              FilledButton.icon(
                  onPressed: _add,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar medicamento')),
              OutlinedButton.icon(
                  onPressed: _addFromDatabase,
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Banco de medicamentos')),
            ]),
            const SizedBox(height: 16),
            if (_items.isEmpty)
              const Card(
                  child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                          'Use o Modelo UTI ou adicione o primeiro medicamento.')))
            else
              ..._items.asMap().entries.map((entry) => Card(
                      child: ListTile(
                    leading: CircleAvatar(child: Text('${entry.key + 1}')),
                    title: Text('${entry.value.name} ${entry.value.dose}'),
                    subtitle: Text(
                        '${entry.value.useType.label} • ${entry.value.administeredQuantity}, ${entry.value.frequency}'),
                    onTap: () => _edit(entry.key),
                    trailing: IconButton(
                        tooltip: 'Remover',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            setState(() => _items.removeAt(entry.key))),
                  ))),
            const SizedBox(height: 16),
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Prévia da receita',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Container(
                            constraints: const BoxConstraints(minHeight: 160),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant)),
                            child: SelectableText(
                                _preview.isEmpty
                                    ? 'A prévia aparecerá automaticamente aqui.'
                                    : _preview,
                                style: const TextStyle(
                                    fontFamily: 'monospace', height: 1.45))),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                            onPressed: _items.isEmpty ? null : _copy,
                            icon: const Icon(Icons.copy),
                            label: const Text('Copiar Receita')),
                      ],
                    ))),
          ]),
        )),
      );

  void _loadTemplate() => setState(() {
        _items
          ..clear()
          ..addAll(_service.utiTemplate());
      });

  Future<void> _add() async {
    final repository = await LocalMedicationRepository.load();
    final suggestions = await repository.getAll();
    if (!mounted) return;
    Medication? selectedFromAutocomplete;
    final medication = await showMedicationEditor(
      context,
      suggestions: suggestions,
      enforceUniqueRegistration: false,
      defaultDispensingQuantity: 'Contínuo',
      onSuggestionSelected: (value) => selectedFromAutocomplete = value,
    );
    if (medication == null) return;
    setState(() => _items.add(medication));
    final matches = await repository.search(medication.name);
    final exists = matches.any((item) =>
        normalizeSearch(item.name) == normalizeSearch(medication.name) &&
        normalizeSearch(item.dose) == normalizeSearch(medication.dose));
    if (!exists && mounted) {
      final base = selectedFromAutocomplete;
      final isNewDose = base != null &&
          normalizeSearch(base.name) == normalizeSearch(medication.name) &&
          normalizeSearch(base.dose) != normalizeSearch(medication.dose);
      final save = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
                  title: Text(
                      isNewDose ? 'Salvar nova dose?' : 'Salvar medicamento?'),
                  content: Text(isNewDose
                      ? 'Deseja salvar ${medication.dose} como nova dose de ${medication.name} para uso futuro?'
                      : 'Deseja salvar este medicamento para uso futuro?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Agora não')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Salvar')),
                  ]));
      if (save == true) {
        try {
          await repository.save(medication);
        } on DuplicateMedicationException {
          // Outro cadastro igual pode ter sido salvo enquanto a receita estava aberta.
        }
      }
    }
  }

  Future<void> _edit(int index) async {
    final repository = await LocalMedicationRepository.load();
    final suggestions = await repository.getAll();
    if (!mounted) return;
    final medication = await showMedicationEditor(
      context,
      initial: _items[index],
      suggestions: suggestions,
      enforceUniqueRegistration: false,
      defaultDispensingQuantity: 'Contínuo',
    );
    if (medication != null) setState(() => _items[index] = medication);
  }

  Future<void> _addFromDatabase() async {
    final medication = await Navigator.of(context).push<Medication>(
        MaterialPageRoute(
            builder: (_) => const MedicationsScreen(selectionMode: true)));
    if (medication != null) {
      setState(
        () => _items.add(
          medication.copyWith(
            id: '${medication.id}-${DateTime.now().microsecondsSinceEpoch}',
            dispensingQuantity: medication.dispensingQuantity.trim().isEmpty
                ? 'Contínuo'
                : medication.dispensingQuantity,
          ),
        ),
      );
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _preview));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Receita copiada.')));
  }
}

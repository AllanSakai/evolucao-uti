import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/medication.dart';
import '../models/prescription.dart';
import '../models/prescription_protocol.dart';
import '../repositories/medication_repository.dart';
import '../repositories/prescription_protocol_repository.dart';
import '../services/prescription_service.dart';
import '../utils/search_normalizer.dart';
import '../widgets/medication_editor_dialog.dart';
import 'medications_screen.dart';
import 'prescription_protocols_screen.dart';

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
              OutlinedButton.icon(
                  onPressed: _applyProtocol,
                  icon: const Icon(Icons.playlist_add_check_outlined),
                  label: const Text('Protocolos')),
              OutlinedButton.icon(
                  onPressed: _items.isEmpty ? null : _saveProtocol,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Salvar protocolo')),
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
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: _items.length,
                onReorderItem: _reorderItem,
                itemBuilder: (_, index) => _prescriptionTile(index),
              ),
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

  Widget _prescriptionTile(int index) {
    final medication = _items[index];
    return Card(
      key: ValueKey(medication.id),
      child: ListTile(
        leading: ReorderableDragStartListener(
          index: index,
          child: CircleAvatar(child: Text('${index + 1}')),
        ),
        title: Text('${medication.name} ${medication.dose}'),
        subtitle: Text(
          '${medication.useType.label} • ${medication.administeredQuantity}, ${medication.frequency}',
        ),
        onTap: () => _edit(index),
        trailing: IconButton(
          tooltip: 'Remover',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => setState(() => _items.removeAt(index)),
        ),
      ),
    );
  }

  void _reorderItem(int oldIndex, int newIndex) {
    setState(() {
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
  }

  void _loadTemplate() => setState(() {
        _items.addAll(_copyForPrescription(_service.utiTemplate()));
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

  Future<void> _applyProtocol() async {
    final protocol = await Navigator.of(context).push<PrescriptionProtocol>(
      MaterialPageRoute(builder: (_) => const PrescriptionProtocolsScreen()),
    );
    if (protocol == null) return;
    setState(() => _items.addAll(_copyForPrescription(protocol.medications)));
  }

  Future<void> _saveProtocol() async {
    final name = await _askProtocolName();
    if (name == null || name.trim().isEmpty) return;
    final repository = await PrescriptionProtocolRepository.load();
    final protocol = PrescriptionProtocol(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      medications: List.unmodifiable(_items),
    );
    await repository.save(protocol);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Protocolo ${protocol.name} salvo.')),
    );
  }

  Future<String?> _askProtocolName() async {
    final controller = TextEditingController();
    try {
      return showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Salvar protocolo'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Nome do protocolo'),
            onSubmitted: (value) => Navigator.pop(context, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Salvar'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  List<Medication> _copyForPrescription(List<Medication> medications) {
    final now = DateTime.now().microsecondsSinceEpoch;
    return [
      for (final entry in medications.asMap().entries)
        entry.value.copyWith(
          id: '${entry.value.id}-$now-${entry.key}',
          dispensingQuantity: entry.value.dispensingQuantity.trim().isEmpty
              ? 'Contínuo'
              : entry.value.dispensingQuantity,
        ),
    ];
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _preview));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Receita copiada.')));
  }
}

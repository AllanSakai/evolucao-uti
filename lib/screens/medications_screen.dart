import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../repositories/medication_repository.dart';
import '../widgets/medication_editor_dialog.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({this.selectionMode = false, super.key});
  final bool selectionMode;
  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  LocalMedicationRepository? _repository;
  List<Medication> _medications = [];
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _repository ??= await LocalMedicationRepository.load();
    _medications = await _repository!.search(_search.text);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(
                widget.selectionMode ? 'Adicionar do banco' : 'Medicamentos')),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _edit(),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar')),
        body: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(children: [
            Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                    controller: _search,
                    onChanged: (_) => _load(),
                    decoration: const InputDecoration(
                        labelText: 'Pesquisar medicamento',
                        prefixIcon: Icon(Icons.search)))),
            Expanded(
                child: _repository == null
                    ? const Center(child: CircularProgressIndicator())
                    : _medications.isEmpty
                        ? const Center(
                            child: Text('Nenhum medicamento encontrado.'))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                            itemCount: _medications.length,
                            itemBuilder: (_, index) =>
                                _tile(_medications[index]))),
          ]),
        )),
      );

  Widget _tile(Medication medication) => Card(
          child: ListTile(
        title: Text('${medication.name} ${medication.dose}'),
        subtitle: Text(
            '${medication.useType.label} • ${medication.route}\n${medication.administeredQuantity}, ${medication.frequency}'),
        isThreeLine: true,
        onTap: widget.selectionMode
            ? () => Navigator.pop(context, medication)
            : () => _edit(medication),
        trailing: widget.selectionMode
            ? const Icon(Icons.add_circle_outline)
            : PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _edit(medication);
                    case 'duplicate':
                      _duplicate(medication);
                    case 'delete':
                      _delete(medication);
                  }
                },
                itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Text('Criar cópia com outra dose'),
                      ),
                      PopupMenuItem(value: 'delete', child: Text('Excluir')),
                    ]),
      ));

  Future<void> _edit([Medication? initial]) async {
    _repository ??= await LocalMedicationRepository.load();
    final suggestions = await _repository!.getAll();
    if (!mounted) return;
    final result = await showMedicationEditor(
      context,
      initial: initial,
      suggestions: suggestions,
    );
    if (result == null) return;
    try {
      await _repository!.save(result);
    } on DuplicateMedicationException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Já existe um medicamento com este nome e dose.'),
        ),
      );
      return;
    }
    await _load();
  }

  Future<void> _duplicate(Medication medication) async {
    _repository ??= await LocalMedicationRepository.load();
    final suggestions = await _repository!.getAll();
    if (!mounted) return;
    final result = await showMedicationEditor(
      context,
      initial: medication,
      duplicate: true,
      suggestions: suggestions,
    );
    if (result == null) return;
    try {
      await _repository!.save(result);
      await _load();
    } on DuplicateMedicationException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Já existe um medicamento com este nome e dose.'),
        ),
      );
    }
  }

  Future<void> _delete(Medication medication) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
                title: const Text('Excluir medicamento?'),
                content:
                    Text('${medication.name} será removido do banco local.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Excluir')),
                ]));
    if (confirmed != true) return;
    await _repository!.delete(medication.id);
    await _load();
  }
}

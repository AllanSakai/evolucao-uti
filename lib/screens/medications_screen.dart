import 'package:flutter/material.dart';
import '../models/medication.dart';
import '../repositories/medication_repository.dart';
import '../services/supabase_sync_service.dart';
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
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load(refreshRemote: true);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool refreshRemote = false}) async {
    if (refreshRemote && mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      _repository ??= await LocalMedicationRepository.load();
      if (refreshRemote && SupabaseSyncService.instance.canSync) {
        await _repository!.syncNow();
      }
      _medications = await _repository!.search(_search.text);
    } catch (error) {
      _loadError = 'Não foi possível atualizar os dados do Supabase.';
      _medications = await _repository?.search(_search.text) ?? [];
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            widget.selectionMode ? 'Adicionar do banco' : 'Medicamentos',
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _edit(),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar')),
        body: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Column(
                children: [
                  TextField(
                    controller: _search,
                    onChanged: (_) => _load(),
                    decoration: const InputDecoration(
                      labelText: 'Pesquisar medicamento',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _dataSourceBanner(),
                  if (_loading) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
            Expanded(
                child: _repository == null && _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _medications.isEmpty
                        ? const Center(
                            child: Text('Nenhum medicamento encontrado.'))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                            itemCount: _medications.length,
                            itemBuilder: (_, index) =>
                                _tile(_medications[index]))),
          ]),
        )),
      );

  Widget _dataSourceBanner() {
    final colors = Theme.of(context).colorScheme;
    final sync = SupabaseSyncService.instance;
    final hasError = _loadError != null;
    final icon = hasError
        ? Icons.cloud_off_outlined
        : sync.canSync
            ? Icons.cloud_done_outlined
            : Icons.storage_outlined;
    final text = hasError
        ? _loadError!
        : sync.canSync
            ? 'Dados atualizados automaticamente pelo Supabase'
            : 'Dados locais — entre na conta para carregar o Supabase';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: hasError
            ? colors.errorContainer.withValues(alpha: .55)
            : colors.surfaceContainerHighest.withValues(alpha: .65),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }

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
                content: Text('${medication.name} será removido do seu banco.'),
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

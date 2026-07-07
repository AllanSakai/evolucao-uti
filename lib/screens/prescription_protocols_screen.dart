import 'package:flutter/material.dart';

import '../models/medication.dart';
import '../models/prescription_protocol.dart';
import '../repositories/medication_repository.dart';
import '../repositories/prescription_protocol_repository.dart';
import '../services/supabase_sync_service.dart';
import '../widgets/medication_editor_dialog.dart';
import 'medications_screen.dart';

class PrescriptionProtocolsScreen extends StatefulWidget {
  const PrescriptionProtocolsScreen({this.selectionMode = false, super.key});

  final bool selectionMode;

  @override
  State<PrescriptionProtocolsScreen> createState() =>
      _PrescriptionProtocolsScreenState();
}

class _PrescriptionProtocolsScreenState
    extends State<PrescriptionProtocolsScreen> {
  PrescriptionProtocolRepository? _repository;
  List<PrescriptionProtocol> _protocols = [];
  final _search = TextEditingController();
  bool _syncing = false;

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
    _repository ??= await PrescriptionProtocolRepository.load();
    _protocols = await _repository!.search(_search.text);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title:
              Text(widget.selectionMode ? 'Adicionar protocolo' : 'Protocolos'),
          actions: [
            IconButton(
              tooltip: 'Sincronizar protocolos',
              onPressed: _syncing ? null : _syncProtocols,
              icon: _syncing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_sync_outlined),
            ),
          ],
        ),
        floatingActionButton: widget.selectionMode
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _edit(),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar'),
              ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => _load(),
                    decoration: const InputDecoration(
                      labelText: 'Pesquisar protocolo',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                Expanded(
                  child: _repository == null
                      ? const Center(child: CircularProgressIndicator())
                      : _protocols.isEmpty
                          ? const Center(
                              child: Text('Nenhum protocolo encontrado.'),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: _protocols.length,
                              itemBuilder: (_, index) =>
                                  _tile(_protocols[index]),
                            ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _tile(PrescriptionProtocol protocol) => Card(
        child: ListTile(
          title: Text(protocol.name),
          subtitle: Text(
            '${protocol.medications.length} medicações\n'
            '${protocol.medications.map((item) => item.name).join(', ')}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          isThreeLine: true,
          onTap: widget.selectionMode
              ? () => Navigator.pop(context, protocol)
              : () => _edit(protocol),
          trailing: widget.selectionMode
              ? const Icon(Icons.add_circle_outline)
              : PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _edit(protocol);
                      case 'delete':
                        _delete(protocol);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Excluir')),
                  ],
                ),
        ),
      );

  Future<void> _edit([PrescriptionProtocol? initial]) async {
    final protocol = await Navigator.of(context).push<PrescriptionProtocol>(
      MaterialPageRoute(
        builder: (_) => _ProtocolEditorScreen(initial: initial),
      ),
    );
    if (protocol == null) return;
    _repository ??= await PrescriptionProtocolRepository.load();
    await _repository!.save(protocol);
    await _load();
  }

  Future<void> _delete(PrescriptionProtocol protocol) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir protocolo?'),
        content: Text('${protocol.name} será removido dos seus protocolos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    _repository ??= await PrescriptionProtocolRepository.load();
    await _repository!.delete(protocol.id);
    await _load();
  }

  Future<void> _syncProtocols() async {
    final sync = SupabaseSyncService.instance;
    if (!sync.canSync) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entre na mesma conta no celular e no computador.'),
        ),
      );
      return;
    }
    setState(() => _syncing = true);
    try {
      _repository ??= await PrescriptionProtocolRepository.load();
      _protocols = await _repository!.syncNow();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Protocolos sincronizados.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao sincronizar protocolos: $error')),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }
}

class _ProtocolEditorScreen extends StatefulWidget {
  const _ProtocolEditorScreen({this.initial});

  final PrescriptionProtocol? initial;

  @override
  State<_ProtocolEditorScreen> createState() => _ProtocolEditorScreenState();
}

class _ProtocolEditorScreenState extends State<_ProtocolEditorScreen> {
  late final TextEditingController _name;
  late final List<Medication> _medications;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?.name);
    _medications = [...?widget.initial?.medications];
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
              widget.initial == null ? 'Novo protocolo' : 'Editar protocolo'),
          actions: [
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Salvar'),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  decoration:
                      const InputDecoration(labelText: 'Nome do protocolo'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _addMedication,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar medicamento'),
                ),
                const SizedBox(height: 12),
                if (_medications.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Adicione as medicações deste protocolo.'),
                    ),
                  )
                else
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: _medications.length,
                    onReorderItem: _reorderItem,
                    itemBuilder: (_, index) => _medicationTile(index),
                  ),
              ],
            ),
          ),
        ),
      );

  Widget _medicationTile(int index) {
    final medication = _medications[index];
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
        onTap: () => _editMedication(index),
        trailing: IconButton(
          tooltip: 'Remover',
          onPressed: () => setState(() => _medications.removeAt(index)),
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }

  void _reorderItem(int oldIndex, int newIndex) {
    setState(() {
      final item = _medications.removeAt(oldIndex);
      _medications.insert(newIndex, item);
    });
  }

  Future<void> _addMedication() async {
    final medication = await Navigator.of(context).push<Medication>(
      MaterialPageRoute(
        builder: (_) => const MedicationsScreen(selectionMode: true),
      ),
    );
    if (medication == null) return;
    setState(() => _medications.add(_copyMedication(medication)));
  }

  Future<void> _editMedication(int index) async {
    final repository = await LocalMedicationRepository.load();
    final suggestions = await repository.getAll();
    if (!mounted) return;
    final medication = await showMedicationEditor(
      context,
      initial: _medications[index],
      suggestions: suggestions,
      enforceUniqueRegistration: false,
      defaultDispensingQuantity: 'Contínuo',
    );
    if (medication == null) return;
    setState(() => _medications[index] = medication);
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome do protocolo.')),
      );
      return;
    }
    if (_medications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione ao menos uma medicação.')),
      );
      return;
    }
    Navigator.pop(
      context,
      PrescriptionProtocol(
        id: widget.initial?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        medications: List.unmodifiable(_medications),
      ),
    );
  }

  Medication _copyMedication(Medication medication) => medication.copyWith(
        id: '${medication.id}-${DateTime.now().microsecondsSinceEpoch}',
        dispensingQuantity: medication.dispensingQuantity.trim().isEmpty
            ? 'Contínuo'
            : medication.dispensingQuantity,
      );
}

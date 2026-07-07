import 'package:flutter/material.dart';

import '../models/prescription_protocol.dart';
import '../repositories/prescription_protocol_repository.dart';
import '../services/supabase_sync_service.dart';

class PrescriptionProtocolsScreen extends StatefulWidget {
  const PrescriptionProtocolsScreen({super.key});

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
          title: const Text('Protocolos'),
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
          onTap: () => Navigator.pop(context, protocol),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') _delete(protocol);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'delete', child: Text('Excluir')),
            ],
          ),
        ),
      );

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

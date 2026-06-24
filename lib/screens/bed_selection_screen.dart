import 'package:flutter/material.dart';

import '../models/bed.dart';
import '../models/icu_unit.dart';
import '../services/shift_round_store.dart';
import '../widgets/medical_disclaimer.dart';
import 'shift_round_screen.dart';

class BedSelectionScreen extends StatefulWidget {
  const BedSelectionScreen({required this.unit, super.key});

  final IcuUnit unit;

  @override
  State<BedSelectionScreen> createState() => _BedSelectionScreenState();
}

class _BedSelectionScreenState extends State<BedSelectionScreen> {
  final Set<String> _selectedIds = {};
  bool _loadingSaved = true;

  @override
  void initState() {
    super.initState();
    _loadSavedBeds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.unit.name)),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: _selectedIds.isEmpty ? null : _startVisit,
          icon: const Icon(Icons.play_arrow),
          label: Text('Iniciar visita (${_selectedIds.length})'),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const MedicalDisclaimer(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _selectedIds
                          ..clear()
                          ..addAll(widget.unit.beds.map((bed) => bed.id))),
                        child: const Text('Selecionar todos'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(_selectedIds.clear),
                        child: const Text('Limpar selecao'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _clearUnit,
                  icon: const Icon(Icons.delete_outline),
                  label: Text('Limpar ${widget.unit.name}'),
                ),
                const SizedBox(height: 16),
                if (_loadingSaved) const LinearProgressIndicator(),
                if (_loadingSaved) const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 150,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.25,
                  ),
                  itemCount: widget.unit.beds.length,
                  itemBuilder: (context, index) =>
                      _bedCard(widget.unit.beds[index]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bedCard(Bed bed) {
    final selected = _selectedIds.contains(bed.id);
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: selected ? colors.primaryContainer : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() {
          selected ? _selectedIds.remove(bed.id) : _selectedIds.add(bed.id);
        }),
        child: Stack(
          children: [
            Center(
              child: Text(bed.label,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            if (bed.isIsolation)
              const Positioned(
                  right: 6, top: 6, child: Chip(label: Text('ISO'))),
            if (selected)
              const Positioned(
                  left: 8, top: 8, child: Icon(Icons.check_circle)),
          ],
        ),
      ),
    );
  }

  void _startVisit() {
    _startVisitAsync();
  }

  Future<void> _startVisitAsync() async {
    final beds =
        widget.unit.beds.where((bed) => _selectedIds.contains(bed.id)).toList();
    final store = await PersistentShiftRoundStore.load(widget.unit.code);
    store.startVisit(beds);
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ShiftRoundScreen(unit: widget.unit, store: store),
    ));
  }

  Future<void> _loadSavedBeds() async {
    final ids = await PersistentShiftRoundStore.savedBedIds(widget.unit.code);
    if (!mounted) return;
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(ids);
      _loadingSaved = false;
    });
  }

  Future<void> _clearUnit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Limpar ${widget.unit.name}?'),
        content: const Text(
          'Isso apaga os preenchimentos salvos desta ala. Os outros setores nao serao alterados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await PersistentShiftRoundStore.clearUnit(widget.unit.code);
    if (!mounted) return;
    setState(_selectedIds.clear);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.unit.name} limpa.')),
    );
  }
}

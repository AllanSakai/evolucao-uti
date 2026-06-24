import 'package:flutter/material.dart';

import '../models/icu_unit.dart';
import '../models/selected_bed.dart';
import '../services/evolution_generator.dart';
import '../services/shift_round_store.dart';
import '../widgets/medical_disclaimer.dart';
import 'evolution_form_screen.dart';
import 'evolution_preview_screen.dart';

class ShiftRoundScreen extends StatefulWidget {
  const ShiftRoundScreen({required this.unit, required this.store, super.key});

  final IcuUnit unit;
  final ShiftRoundStore store;

  @override
  State<ShiftRoundScreen> createState() => _ShiftRoundScreenState();
}

class _ShiftRoundScreenState extends State<ShiftRoundScreen> {
  @override
  void initState() {
    super.initState();
    widget.store.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.store.removeListener(_refresh);
    widget.store.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final completed = widget.store.beds
        .where((bed) => bed.status == BedProgressStatus.completed)
        .length;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.unit.name),
        actions: [
          IconButton(
            tooltip: 'Limpar ala',
            onPressed: _clearUnit,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
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
                      child: Text(
                        '$completed de ${widget.store.beds.length} concluidos',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _clearUnit,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Limpar ala'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...widget.store.beds.map(_bedCard),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bedCard(SelectedBed selected) {
    final status = _status(selected.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(selected.bed.displayName,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Chip(
                  avatar: Icon(status.icon, size: 18),
                  label: Text(status.label),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _annotate(selected),
                  icon: const Icon(Icons.edit_note),
                  label: Text(
                      selected.evolutionData == null ? 'Anotar' : 'Continuar'),
                ),
                if (selected.evolutionData != null)
                  OutlinedButton.icon(
                    onPressed: () => _preview(selected),
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('Ver resumo'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _annotate(SelectedBed selected) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EvolutionFormScreen(
        bed: selected.bed,
        initialData: selected.evolutionData,
        onDraftSaved: (data) => widget.store.saveDraft(selected.bed.id, data),
        onCompleted: () => widget.store.markCompleted(selected.bed.id),
      ),
    ));
  }

  void _preview(SelectedBed selected) {
    final data = selected.evolutionData!;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => EvolutionPreviewScreen(
        data: data,
        bed: selected.bed,
        generatedText: EvolutionGenerator().generateSummary(data),
        onConfirmed: () => widget.store.markCompleted(selected.bed.id),
      ),
    ));
  }

  Future<void> _clearUnit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Limpar ${widget.unit.name}?'),
        content: const Text(
          'Isso apaga todos os preenchimentos salvos desta ala. Os outros setores nao serao alterados.',
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
    await widget.store.clear();
    widget.store.startVisit(widget.unit.beds);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.unit.name} limpa.')),
    );
  }

  ({String label, IconData icon}) _status(BedProgressStatus status) =>
      switch (status) {
        BedProgressStatus.pending => (label: 'Pendente', icon: Icons.schedule),
        BedProgressStatus.inProgress => (
            label: 'Em andamento',
            icon: Icons.edit_outlined
          ),
        BedProgressStatus.completed => (
            label: 'Concluido',
            icon: Icons.check_circle_outline
          ),
      };
}

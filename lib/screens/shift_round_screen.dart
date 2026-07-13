import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/icu_unit.dart';
import '../models/evolution_data.dart';
import '../models/selected_bed.dart';
import '../services/evolution_analysis_service.dart';
import '../services/evolution_generator.dart';
import '../services/shift_round_store.dart';
import '../services/supabase_sync_service.dart';
import 'account_screen.dart';
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
  final _analysis = const EvolutionAnalysisService();
  bool _syncing = false;

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
    final unitSummary = _analysis.summarize(widget.store.beds);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.unit.name),
        actions: [
          IconButton(
            tooltip: 'Sincronizar',
            onPressed: _syncing ? null : _syncNow,
            icon: _syncing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_sync_outlined),
          ),
          IconButton(
            tooltip: 'Conta e sincronização',
            onPressed: _openAccount,
            icon: const Icon(Icons.account_circle_outlined),
          ),
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
            constraints: const BoxConstraints(maxWidth: 920),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 220),
                      child: Text(
                        '$completed de ${widget.store.beds.length} concluídos',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _syncing ? null : _syncNow,
                      icon: const Icon(Icons.cloud_sync_outlined),
                      label: Text(_syncing ? 'Sincronizando' : 'Sincronizar'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _clearUnit,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Limpar ala'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _syncStatusCard(),
                const SizedBox(height: 12),
                _unitSummaryCard(unitSummary),
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
    final checklist = _analysis.checklist(selected.evolutionData);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
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
            if (checklist.summaryFlags.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: checklist.summaryFlags
                    .map((flag) => Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(flag),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
            ],
            if (checklist.pendingItems.isNotEmpty ||
                checklist.warnings.isNotEmpty) ...[
              _checklistBox(checklist),
              const SizedBox(height: 8),
            ],
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

  Widget _checklistBox(BedClinicalChecklist checklist) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = [
      ...checklist.warnings,
      if (checklist.pendingItems.isNotEmpty)
        'Pendencias: ${checklist.pendingItems.join(', ')}',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.fact_check_outlined, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(items.join('\n'))),
        ],
      ),
    );
  }

  Widget _unitSummaryCard(UnitClinicalSummary summary) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Resumo da ala',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  OutlinedButton.icon(
                    onPressed: _showDiuresisAndBalanceSummary,
                    icon: const Icon(Icons.water_drop_outlined),
                    label: const Text('Diurese/BH'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _exportShift,
                    icon: const Icon(Icons.copy_all_outlined),
                    label: const Text('Exportar plantao'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _summaryChip('Concluidos', summary.completed),
                  _summaryChip('Pendentes', summary.pending),
                  _summaryChip('Em andamento', summary.inProgress),
                  if (summary.bedsWithPendingItems > 0)
                    _summaryChip(
                        'Com pendencias', summary.bedsWithPendingItems),
                  if (summary.mechanicalVentilation > 0)
                    _summaryChip('VM', summary.mechanicalVentilation),
                  if (summary.vasoactiveSupport > 0)
                    _summaryChip('DVA', summary.vasoactiveSupport),
                  if (summary.febrile > 0)
                    _summaryChip('Febris', summary.febrile),
                  if (summary.lowDiuresis > 0)
                    _summaryChip('Diurese baixa', summary.lowDiuresis),
                  if (summary.positiveBalance > 0)
                    _summaryChip('BH +', summary.positiveBalance),
                  if (summary.negativeBalance > 0)
                    _summaryChip('BH -', summary.negativeBalance),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _summaryChip(String label, int value) => Chip(
        label: Text('$label: $value'),
        visualDensity: VisualDensity.compact,
      );

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
        generatedText: EvolutionGenerator().generateSummary(
          data,
          bedLabel: selected.bed.displayName,
        ),
        onConfirmed: () => widget.store.markCompleted(selected.bed.id),
      ),
    ));
  }

  void _showDiuresisAndBalanceSummary() {
    final rows = widget.store.beds.map((selected) {
      final data = selected.evolutionData;
      final diuresis = data == null
          ? 'não preenchida'
          : data.diuresisType == DiuresisType.ausente
              ? 'ausente'
              : data.diuresisVolume?.trim().isNotEmpty == true
                  ? '${data.diuresisVolume} mL / ${data.diuresisPeriod ?? "período não informado"}'
                  : data.diuresisType == DiuresisType.espontanea
                      ? 'espontânea, não quantificada'
                      : 'SVD, não quantificada';
      final balance = data?.fluidBalance?.trim().isNotEmpty == true
          ? '${data!.fluidBalance} mL / ${data.fluidBalancePeriod ?? "período não informado"}'
          : 'não quantificado';
      return '${selected.bed.displayName}\nDiurese: $diuresis\nBH: $balance';
    }).join('\n\n');

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Diurese e BH da ala'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(child: SelectableText(rows)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportShift() async {
    final filled =
        widget.store.beds.where((selected) => selected.evolutionData != null);
    if (filled.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum leito preenchido para exportar.')),
      );
      return;
    }
    final text = _analysis.exportShift(widget.store.beds);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Plantao exportado'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(child: SelectableText(text)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plantao copiado.')),
    );
  }

  Widget _syncStatusCard() {
    final sync = SupabaseSyncService.instance;
    final email = sync.userEmail;
    final text = sync.canSync
        ? 'Sincronização ativa: $email'
        : 'Sincronização inativa. Entre na mesma conta no celular e no computador.';
    return Card(
      color: sync.canSync
          ? Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: .35)
          : Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(sync.canSync
                ? Icons.cloud_done_outlined
                : Icons.cloud_off_outlined),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
            if (!sync.canSync) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: _openAccount,
                child: const Text('Entrar'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openAccount() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AccountScreen()),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _syncNow() async {
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
      final count = await widget.store.syncFromRemote(widget.unit.beds);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sincronização concluída ($count registros).')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao sincronizar: $error')),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _clearUnit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Limpar ${widget.unit.name}?'),
        content: const Text(
          'Isso apaga todos os preenchimentos salvos desta ala. Os outros setores não serão alterados.',
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
            label: 'Concluído',
            icon: Icons.check_circle_outline
          ),
      };
}

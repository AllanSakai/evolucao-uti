import 'package:flutter/material.dart';

import '../models/icu_unit.dart';
import '../models/evolution_data.dart';
import '../models/selected_bed.dart';
import '../services/evolution_analysis_service.dart';
import '../services/evolution_generator.dart';
import '../services/shift_round_store.dart';
import '../services/supabase_sync_service.dart';
import '../widgets/theme_toggle_button.dart';
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
  bool _loadingRemote = false;

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
    final unitSummary = _analysis.summarize(widget.store.beds);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.unit.name),
        actions: [
          const ThemeToggleButton(),
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
            constraints: const BoxConstraints(maxWidth: 1180),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                _syncStatusCard(),
                const SizedBox(height: 12),
                _unitSummaryCard(unitSummary),
                const SizedBox(height: 22),
                _bedsSectionHeader(),
                const SizedBox(height: 10),
                _bedsGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bedsSectionHeader() {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text('Boxes da ala', style: theme.textTheme.titleMedium),
        ),
        Text(
          '${widget.store.beds.length} boxes',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _bedsGrid() => LayoutBuilder(
        builder: (context, constraints) {
          const gap = 12.0;
          final columns = constraints.maxWidth >= 1080
              ? 3
              : constraints.maxWidth >= 680
                  ? 2
                  : 1;
          final beds = widget.store.beds;
          if (columns == 1) {
            return Column(
              children: [
                for (var index = 0; index < beds.length; index++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: index < beds.length - 1 ? gap : 0,
                    ),
                    child: _bedCard(beds[index]),
                  ),
              ],
            );
          }
          final rowCount = (beds.length + columns - 1) ~/ columns;
          return Column(
            children: List.generate(
              rowCount,
              (row) => Padding(
                padding: EdgeInsets.only(
                  bottom: row < rowCount - 1 ? gap : 0,
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var column = 0; column < columns; column++) ...[
                        if (column > 0) const SizedBox(width: gap),
                        Expanded(
                          child: row * columns + column < beds.length
                              ? _bedCard(beds[row * columns + column])
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );

  Widget _bedCard(SelectedBed selected) {
    final status = _status(selected.status);
    final checklist = _analysis.checklist(selected.evolutionData);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = _statusColor(selected.status, colorScheme);
    final isCompleted = selected.status == BedProgressStatus.completed;
    return Card(
      margin: EdgeInsets.zero,
      color: isCompleted
          ? Color.lerp(colorScheme.surface, statusColor, isDark ? 0.16 : 0.07)
          : null,
      shape: isCompleted
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: statusColor.withValues(alpha: .5),
                width: 1.4,
              ),
            )
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: statusColor, width: isCompleted ? 5 : 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.bed_outlined,
                    size: 20,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selected.bed.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(
                  avatar: Icon(status.icon, size: 16, color: statusColor),
                  label: Text(status.label),
                  labelStyle: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                  backgroundColor: statusColor.withValues(
                    alpha: isDark ? .2 : .12,
                  ),
                  side: BorderSide(color: statusColor.withValues(alpha: .45)),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
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

  Widget _unitSummaryCard(UnitClinicalSummary summary) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress =
        summary.total == 0 ? 0.0 : summary.completed / summary.total;
    final clinicalIndicators = <({String label, int value, IconData icon})>[
      if (summary.bedsWithPendingItems > 0)
        (
          label: 'Com pendências',
          value: summary.bedsWithPendingItems,
          icon: Icons.fact_check_outlined,
        ),
      if (summary.mechanicalVentilation > 0)
        (
          label: 'VM',
          value: summary.mechanicalVentilation,
          icon: Icons.air,
        ),
      if (summary.vasoactiveSupport > 0)
        (
          label: 'DVA',
          value: summary.vasoactiveSupport,
          icon: Icons.medication_outlined,
        ),
      if (summary.febrile > 0)
        (
          label: 'Febris',
          value: summary.febrile,
          icon: Icons.thermostat_outlined,
        ),
      if (summary.lowDiuresis > 0)
        (
          label: 'Diurese baixa',
          value: summary.lowDiuresis,
          icon: Icons.water_drop_outlined,
        ),
      if (summary.positiveBalance > 0)
        (
          label: 'BH +',
          value: summary.positiveBalance,
          icon: Icons.add_circle_outline,
        ),
      if (summary.negativeBalance > 0)
        (
          label: 'BH -',
          value: summary.negativeBalance,
          icon: Icons.remove_circle_outline,
        ),
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final title = Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.monitor_heart_outlined,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Resumo da ala',
                              style: theme.textTheme.titleMedium),
                          Text(
                            '${summary.total} boxes acompanhados',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
                final action = OutlinedButton.icon(
                  onPressed: _showDiuresisAndBalanceSummary,
                  icon: const Icon(Icons.water_drop_outlined),
                  label: const Text('Diurese e BH'),
                );
                if (constraints.maxWidth < 500) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      title,
                      const SizedBox(height: 12),
                      action,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: 16),
                    action,
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Progresso do plantão',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                Text(
                  '${summary.completed} de ${summary.total}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 8.0;
                final itemWidth = (constraints.maxWidth - gap * 2) / 3;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _summaryMetric(
                        label: 'Concluídos',
                        value: summary.completed,
                        icon: Icons.check_circle_outline,
                        color: colorScheme.primary,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _summaryMetric(
                        label: 'Em andamento',
                        value: summary.inProgress,
                        icon: Icons.edit_outlined,
                        color: colorScheme.tertiary,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _summaryMetric(
                        label: 'Pendentes',
                        value: summary.pending,
                        icon: Icons.schedule,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              },
            ),
            if (clinicalIndicators.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 14),
              Text('Sinais da ala', style: theme.textTheme.titleSmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: clinicalIndicators
                    .map(
                      (indicator) => Chip(
                        avatar: Icon(indicator.icon, size: 17),
                        label: Text('${indicator.label}  ${indicator.value}'),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryMetric({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 84),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$value',
                  style: theme.textTheme.titleLarge?.copyWith(color: color),
                ),
              ),
              Icon(icon, size: 19, color: color),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

  Widget _syncStatusCard() {
    final sync = SupabaseSyncService.instance;
    final email = sync.userEmail;
    final text = _loadingRemote
        ? 'Atualizando dados do Supabase...'
        : sync.canSync
            ? 'Dados atualizados automaticamente • $email'
            : 'Dados locais. Entre na conta para carregar o Supabase.';
    return Card(
      margin: EdgeInsets.zero,
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
            if (_loadingRemote)
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
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
    final sync = SupabaseSyncService.instance;
    if (!sync.canSync) {
      setState(() {});
      return;
    }
    setState(() => _loadingRemote = true);
    try {
      await widget.store.syncFromRemote(widget.unit.beds);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao carregar o Supabase: $error')),
      );
    } finally {
      if (mounted) setState(() => _loadingRemote = false);
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

  Color _statusColor(BedProgressStatus status, ColorScheme colorScheme) =>
      switch (status) {
        BedProgressStatus.pending => colorScheme.onSurfaceVariant,
        BedProgressStatus.inProgress => colorScheme.tertiary,
        BedProgressStatus.completed => colorScheme.primary,
      };
}

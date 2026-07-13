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
  const ShiftRoundScreen({
    required this.unit,
    required this.store,
    this.readOnly = false,
    super.key,
  });

  final IcuUnit unit;
  final ShiftRoundStore store;
  final bool readOnly;

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
            onPressed: widget.readOnly ? null : _clearUnit,
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
                if (widget.readOnly) ...[
                  const SizedBox(height: 12),
                  _readOnlyAccessCard(),
                ],
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
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = _statusColor(selected.status, colorScheme);
    final canPreview = selected.evolutionData != null;
    return Card(
      margin: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: statusColor, width: 4)),
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
                if (widget.readOnly)
                  FilledButton.tonalIcon(
                    onPressed: canPreview ? () => _preview(selected) : null,
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Visualizar'),
                  )
                else
                  FilledButton.tonalIcon(
                    onPressed: () => _annotate(selected),
                    icon: const Icon(Icons.edit_note),
                    label: Text(selected.evolutionData == null
                        ? 'Anotar'
                        : 'Continuar'),
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
        readOnly: widget.readOnly,
        generatedText: EvolutionGenerator().generateSummary(
          data,
          bedLabel: selected.bed.displayName,
        ),
        onConfirmed: widget.readOnly
            ? null
            : () => widget.store.markCompleted(selected.bed.id),
      ),
    ));
  }

  void _showDiuresisAndBalanceSummary() {
    final reports = widget.store.beds.map(_diuresisBalanceReport).toList();
    final filled = reports.where((report) => report.hasData).length;
    final quantifiedDiuresis =
        reports.where((report) => report.diuresisVolume != null).length;
    final lowDiuresis = reports.where((report) => report.lowDiuresis).length;
    final positiveBalance =
        reports.where((report) => (report.balanceValue ?? 0) > 0).length;
    final negativeBalance =
        reports.where((report) => (report.balanceValue ?? 0) < 0).length;
    final missingBalance = reports
        .where((report) => report.hasData && report.balanceValue == null)
        .length;
    final rows = reports.map((report) => report.asText()).join('\n\n');
    final summary =
        'Leitos preenchidos: $filled/${reports.length} | Diurese quantificada: $quantifiedDiuresis | Diurese baixa: $lowDiuresis | BH +: $positiveBalance | BH -: $negativeBalance | BH pendente: $missingBalance';

    showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return AlertDialog(
          title: const Text('Diurese e BH da ala'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _summaryPill('Preenchidos', '$filled/${reports.length}'),
                      _summaryPill('Diurese quant.', '$quantifiedDiuresis'),
                      if (lowDiuresis > 0)
                        _summaryPill('Diurese baixa', '$lowDiuresis'),
                      if (positiveBalance > 0)
                        _summaryPill('BH +', '$positiveBalance'),
                      if (negativeBalance > 0)
                        _summaryPill('BH -', '$negativeBalance'),
                      if (missingBalance > 0)
                        _summaryPill('BH pendente', '$missingBalance'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: .45),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        '$summary\n\n$rows',
                        style:
                            theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  _DiuresisBalanceReport _diuresisBalanceReport(SelectedBed selected) {
    final data = selected.evolutionData;
    if (data == null) {
      return _DiuresisBalanceReport(
        bedLabel: selected.bed.displayName,
        diuresis: 'não preenchida',
        balance: 'não preenchido',
        status: 'pendente',
      );
    }

    final diuresisVolume = _parseNumber(data.diuresisVolume);
    final diuresisPeriod = _parseNumber(data.diuresisPeriod);
    final weight = _parseNumber(data.weight);
    final mlKgHour = diuresisVolume != null &&
            diuresisPeriod != null &&
            diuresisPeriod > 0 &&
            weight != null &&
            weight > 0
        ? diuresisVolume / diuresisPeriod / weight
        : null;
    final lowDiuresis = mlKgHour != null && mlKgHour < 0.5;
    final balanceValue = _parseNumber(data.fluidBalance);
    final balanceStatus = balanceValue == null
        ? 'BH pendente'
        : balanceValue > 0
            ? 'BH positivo'
            : balanceValue < 0
                ? 'BH negativo'
                : 'BH neutro';
    final diuresisStatus = data.diuresisType == DiuresisType.ausente
        ? 'diurese ausente'
        : lowDiuresis
            ? 'diurese baixa'
            : diuresisVolume != null
                ? 'diurese quantificada'
                : 'diurese não quantificada';

    return _DiuresisBalanceReport(
      bedLabel: selected.bed.displayName,
      diuresis: _formatDiuresis(data, mlKgHour),
      balance: _formatBalance(data),
      status: '$diuresisStatus; $balanceStatus',
      diuresisVolume: diuresisVolume,
      balanceValue: balanceValue,
      lowDiuresis: lowDiuresis,
    );
  }

  String _formatDiuresis(EvolutionData data, double? mlKgHour) {
    final period = data.diuresisPeriod?.trim().isNotEmpty == true
        ? data.diuresisPeriod!.trim()
        : 'período não informado';
    final appearance = data.diuresisAppearance?.trim().isNotEmpty == true
        ? ' | aspecto: ${data.diuresisAppearance!.trim()}'
        : '';
    final rate = mlKgHour == null
        ? ''
        : ' | ${mlKgHour.toStringAsFixed(2).replaceAll('.', ',')} mL/kg/h';

    if (data.diuresisType == DiuresisType.ausente) return 'ausente$appearance';
    if (data.diuresisVolume?.trim().isNotEmpty == true) {
      final route =
          data.diuresisType == DiuresisType.svd ? 'SVD' : 'espontânea';
      return '$route: ${data.diuresisVolume!.trim()} mL / $period$rate$appearance';
    }
    if (data.diuresisType == DiuresisType.espontanea) {
      return 'espontânea, não quantificada$appearance';
    }
    if (data.diuresisType == DiuresisType.svd) {
      return 'SVD, não quantificada$appearance';
    }
    return 'não informada$appearance';
  }

  String _formatBalance(EvolutionData data) {
    final balance = data.fluidBalance?.trim();
    if (balance == null || balance.isEmpty) return 'não quantificado';
    final period = data.fluidBalancePeriod?.trim().isNotEmpty == true
        ? data.fluidBalancePeriod!.trim()
        : 'período não informado';
    final value = _signedVolume(balance);
    final parsed = _parseNumber(balance);
    final trend = parsed == null
        ? ''
        : parsed > 0
            ? ' | retenção líquida'
            : parsed < 0
                ? ' | balanço negativo'
                : ' | neutro';
    return '$value mL / $period$trend';
  }

  Widget _summaryPill(String label, String value) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text('$label: $value'),
    );
  }

  double? _parseNumber(String? value) {
    final clean =
        value?.trim().replaceAll(RegExp(r'[^0-9,.-]'), '').replaceAll(',', '.');
    if (clean == null || clean.isEmpty) return null;
    return double.tryParse(clean);
  }

  String _signedVolume(String value) {
    final clean = value.trim();
    if (clean.startsWith('+') || clean.startsWith('-')) return clean;
    final parsed = _parseNumber(clean);
    if (parsed == null || parsed == 0) return clean;
    return '+$clean';
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

  Widget _readOnlyAccessCard() {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerHighest.withValues(alpha: .45),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: colors.onSurfaceVariant),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Você pode consultar esta ala, mas edição e limpeza ficam bloqueadas porque ela não é a ala assumida no plantão.',
              ),
            ),
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

class _DiuresisBalanceReport {
  const _DiuresisBalanceReport({
    required this.bedLabel,
    required this.diuresis,
    required this.balance,
    required this.status,
    this.diuresisVolume,
    this.balanceValue,
    this.lowDiuresis = false,
  });

  final String bedLabel;
  final String diuresis;
  final String balance;
  final String status;
  final double? diuresisVolume;
  final double? balanceValue;
  final bool lowDiuresis;

  bool get hasData => status != 'pendente';

  String asText() {
    return '$bedLabel\n'
        'Diurese: $diuresis\n'
        'BH: $balance\n'
        'Status: $status';
  }
}

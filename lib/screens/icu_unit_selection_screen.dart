import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/icu_units_data.dart';
import '../models/icu_unit.dart';
import '../services/shift_round_store.dart';
import '../services/supabase_config.dart';
import '../services/supabase_sync_service.dart';
import '../services/ward_access_service.dart';
import '../widgets/theme_toggle_button.dart';
import 'account_screen.dart';
import 'certificate_screen.dart';
import 'medications_screen.dart';
import 'prescription_screen.dart';
import 'prescription_protocols_screen.dart';
import 'shift_round_screen.dart';

class IcuUnitSelectionScreen extends StatefulWidget {
  const IcuUnitSelectionScreen({super.key});

  @override
  State<IcuUnitSelectionScreen> createState() => _IcuUnitSelectionScreenState();
}

class _IcuUnitSelectionScreenState extends State<IcuUnitSelectionScreen> {
  StreamSubscription<AuthState>? _authSubscription;
  String? _assumedUnitCode;
  bool _checkingAccess = false;
  bool _promptOpen = false;

  @override
  void initState() {
    super.initState();
    _loadAssumedUnit();
    _authSubscription =
        SupabaseConfig.client?.auth.onAuthStateChange.listen((_) {
      if (!mounted) return;
      _loadAssumedUnit(promptIfMissing: false);
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auxiliar UTI'),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            tooltip: 'Conta e sincronização',
            onPressed: _openAccount,
            icon: Badge(
              isLabelVisible: SupabaseSyncService.instance.canSync,
              smallSize: 8,
              child: const Icon(Icons.account_circle_outlined),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                _pageHeader(context),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) => GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 300,
                      mainAxisExtent: 112,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: icuUnits.length,
                    itemBuilder: (context, index) => _UnitCard(
                      unit: icuUnits[index],
                      assumedUnitCode: _assumedUnitCode,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text('Ferramentas clínicas',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 960
                        ? 4
                        : constraints.maxWidth >= 560
                            ? 2
                            : 1;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisExtent: 104,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: _tools.length,
                      itemBuilder: (context, index) => _tools[index],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _tools = [
    _ToolTile(
      icon: Icons.badge_outlined,
      title: 'Atestado',
      subtitle: 'Gere o atestado de internacao.',
      screen: CertificateScreen(),
    ),
    _ToolTile(
      icon: Icons.medication_outlined,
      title: 'Receita',
      subtitle: 'Monte e copie uma receita rapidamente.',
      screen: PrescriptionScreen(),
    ),
    _ToolTile(
      icon: Icons.inventory_2_outlined,
      title: 'Medicamentos',
      subtitle: 'Pesquise e gerencie o banco local.',
      screen: MedicationsScreen(),
    ),
    _ToolTile(
      icon: Icons.playlist_add_check_outlined,
      title: 'Protocolos',
      subtitle: 'Crie atalhos com sequencias de medicacoes.',
      screen: PrescriptionProtocolsScreen(),
    ),
  ];

  Widget _pageHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final sync = SupabaseSyncService.instance;
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Selecione a UTI do plantão',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: sync.canSync
                ? colors.primaryContainer.withValues(alpha: .55)
                : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                sync.canSync
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                size: 18,
                color: sync.canSync ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 7),
              Text(
                sync.canSync ? 'Supabase conectado' : 'Dados locais',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openAccount() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AccountScreen()),
    );
    if (mounted) _loadAssumedUnit(promptIfMissing: true);
  }

  Future<void> _loadAssumedUnit({bool promptIfMissing = true}) async {
    if (_checkingAccess) return;
    _checkingAccess = true;
    final assumed = await WardAccessService.instance.assumedUnitCode();
    if (!mounted) return;
    setState(() => _assumedUnitCode = assumed);
    _checkingAccess = false;
    if (promptIfMissing &&
        SupabaseSyncService.instance.canSync &&
        !SupabaseConfig.isPrivilegedUser &&
        assumed == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _promptAssumedUnit();
      });
    }
  }

  Future<void> _promptAssumedUnit() async {
    if (_promptOpen) return;
    _promptOpen = true;
    final selected = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Qual ala você irá assumir?'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final unit in icuUnits)
                ListTile(
                  leading: Icon(
                    _assumedUnitCode == unit.code
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(unit.name),
                  subtitle: Text('${unit.beds.length} boxes'),
                  onTap: () => Navigator.of(context).pop(unit.code),
                ),
            ],
          ),
        ),
      ),
    );
    _promptOpen = false;
    if (selected == null) return;
    await _setAssumedUnit(selected);
  }

  Future<void> _setAssumedUnit(String unitCode) async {
    await WardAccessService.instance.assumeUnit(unitCode);
    if (!mounted) return;
    setState(() => _assumedUnitCode = unitCode);
  }
}

class _UnitCard extends StatefulWidget {
  const _UnitCard({
    required this.unit,
    required this.assumedUnitCode,
  });

  final IcuUnit unit;
  final String? assumedUnitCode;

  @override
  State<_UnitCard> createState() => _UnitCardState();
}

class _UnitCardState extends State<_UnitCard> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final signedIn = SupabaseSyncService.instance.canSync;
    final privileged = SupabaseConfig.isPrivilegedUser;
    final isAssumed = widget.assumedUnitCode == widget.unit.code;
    final readOnly =
        signedIn && !privileged && widget.assumedUnitCode != null && !isAssumed;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _loading ? null : _openUnit,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.local_hospital_outlined,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.unit.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      readOnly
                          ? '${widget.unit.beds.length} leitos - somente leitura'
                          : privileged
                              ? '${widget.unit.beds.length} leitos - acesso total'
                              : isAssumed
                                  ? '${widget.unit.beds.length} leitos - ala assumida'
                                  : '${widget.unit.beds.length} leitos',
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              if (_loading)
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  readOnly ? Icons.visibility_outlined : Icons.chevron_right,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUnit() async {
    setState(() => _loading = true);
    final store = await PersistentShiftRoundStore.load(widget.unit.code);
    store.startVisit(widget.unit.beds);
    try {
      await store.syncFromRemote(widget.unit.beds);
    } catch (_) {
      // O armazenamento local continua disponível quando a rede falha.
    }
    if (!mounted) {
      store.dispose();
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ShiftRoundScreen(
        unit: widget.unit,
        store: store,
        readOnly: SupabaseSyncService.instance.canSync &&
            !SupabaseConfig.isPrivilegedUser &&
            widget.assumedUnitCode != null &&
            widget.assumedUnitCode != widget.unit.code,
      ),
    ));
    if (mounted) setState(() => _loading = false);
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.screen,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget screen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => screen),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 22, color: colors.onSecondaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right,
                  size: 20, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

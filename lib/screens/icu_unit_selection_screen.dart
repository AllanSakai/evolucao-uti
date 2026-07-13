import 'package:flutter/material.dart';

import '../data/icu_units_data.dart';
import '../models/icu_unit.dart';
import '../services/shift_round_store.dart';
import 'account_screen.dart';
import 'certificate_screen.dart';
import 'medications_screen.dart';
import 'prescription_screen.dart';
import 'prescription_protocols_screen.dart';
import 'shift_round_screen.dart';

class IcuUnitSelectionScreen extends StatelessWidget {
  const IcuUnitSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AuxiliarUTI'),
        actions: [
          IconButton(
            tooltip: 'Conta e sincronização',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AccountScreen()),
            ),
            icon: const Icon(Icons.account_circle_outlined),
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
                Text('Selecione a UTI do plantão',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 760 ? 3 : 2;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: constraints.maxWidth < 460 ? 1.45 : 2,
                      ),
                      itemCount: icuUnits.length,
                      itemBuilder: (context, index) =>
                          _UnitCard(unit: icuUnits[index]),
                    );
                  },
                ),
                const SizedBox(height: 28),
                Text('Ferramentas clinicas',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) => GridView.count(
                    crossAxisCount: constraints.maxWidth >= 760 ? 2 : 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: constraints.maxWidth >= 760 ? 3.6 : 4.2,
                    children: const [
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({required this.unit});

  final IcuUnit unit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openUnit(context),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.local_hospital_outlined,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unit.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${unit.beds.length} leitos',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUnit(BuildContext context) async {
    final store = await PersistentShiftRoundStore.load(unit.code);
    store.startVisit(unit.beds);
    await store.syncFromRemote(unit.beds);
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ShiftRoundScreen(unit: unit, store: store),
    ));
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
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => screen),
          ),
          child: ListTile(
            leading: Icon(icon, size: 28),
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
          ),
        ),
      );
}

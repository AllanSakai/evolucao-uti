import 'package:flutter/material.dart';

import '../data/icu_units_data.dart';
import '../models/icu_unit.dart';
import '../services/shift_round_store.dart';
import '../widgets/medical_disclaimer.dart';
import 'account_screen.dart';
import 'shift_round_screen.dart';

class IcuUnitSelectionScreen extends StatelessWidget {
  const IcuUnitSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EvoluçãoUTI'),
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
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const MedicalDisclaimer(),
                const SizedBox(height: 20),
                Text('Selecione a UTI do plantão',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2,
                  ),
                  itemCount: icuUnits.length,
                  itemBuilder: (context, index) =>
                      _UnitCard(unit: icuUnits[index]),
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openUnit(context),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(unit.name, style: Theme.of(context).textTheme.titleLarge),
              Text('${unit.beds.length} leitos'),
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

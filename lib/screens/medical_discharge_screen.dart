import 'package:flutter/material.dart';

import 'certificate_screen.dart';
import 'medications_screen.dart';
import 'prescription_screen.dart';
import 'prescription_protocols_screen.dart';

class MedicalDischargeScreen extends StatelessWidget {
  const MedicalDischargeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Alta Médica')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Documentos para copiar',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Gere textos padronizados e cole diretamente no sistema do hospital.',
                ),
                const SizedBox(height: 20),
                const _Tile(
                  icon: Icons.badge_outlined,
                  title: 'Atestado de internação',
                  subtitle: 'Informe paciente e período da internação.',
                  screen: CertificateScreen(),
                ),
                const _Tile(
                  icon: Icons.medication_outlined,
                  title: 'Receita médica',
                  subtitle: 'Monte e copie uma receita em menos de um minuto.',
                  screen: PrescriptionScreen(),
                ),
                const _Tile(
                  icon: Icons.inventory_2_outlined,
                  title: 'Medicamentos',
                  subtitle: 'Pesquise e gerencie o banco local.',
                  screen: MedicationsScreen(),
                ),
                const _Tile(
                  icon: Icons.playlist_add_check_outlined,
                  title: 'Protocolos',
                  subtitle: 'Crie atalhos com sequências de medicações.',
                  screen: PrescriptionProtocolsScreen(),
                ),
              ],
            ),
          ),
        ),
      );
}

class _Tile extends StatelessWidget {
  const _Tile({
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
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Icon(icon, size: 32),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => screen)),
        ),
      );
}

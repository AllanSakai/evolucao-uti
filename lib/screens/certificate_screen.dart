import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/certificate.dart';
import '../services/certificate_service.dart';
import '../widgets/form_section.dart';

class CertificateScreen extends StatefulWidget {
  const CertificateScreen({super.key});

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  final _name = TextEditingController();
  final _service = CertificateService();
  PatientSex _sex = PatientSex.male;
  DateTime? _admission;
  DateTime? _discharge = DateUtils.dateOnly(DateTime.now());

  String get _text {
    if (_name.text.trim().isEmpty || _admission == null || _discharge == null) {
      return 'Preencha o nome e as datas para visualizar o atestado.';
    }
    return _service.generate(Certificate(
      patientName: _name.text,
      sex: _sex,
      admissionDate: _admission!,
      dischargeDate: _discharge!,
    ));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Atestado de internação')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FormSection(title: 'Paciente', children: [
                  TextField(
                    controller: _name,
                    onChanged: (_) => setState(() {}),
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nome do paciente',
                    ),
                  ),
                  SegmentedButton<PatientSex>(
                    segments: const [
                      ButtonSegment(
                        value: PatientSex.male,
                        label: Text('Masculino'),
                      ),
                      ButtonSegment(
                        value: PatientSex.female,
                        label: Text('Feminino'),
                      ),
                    ],
                    selected: {_sex},
                    onSelectionChanged: (value) =>
                        setState(() => _sex = value.first),
                  ),
                  _DateButton(
                    label: 'Data da internação',
                    value: _admission,
                    onSelected: (value) => setState(() {
                      _admission = value;
                      if (_discharge?.isBefore(value) ?? false) {
                        _discharge = null;
                      }
                    }),
                  ),
                  _DateButton(
                    label: 'Data da alta',
                    value: _discharge,
                    firstDate: _admission,
                    onSelected: (value) => setState(() => _discharge = value),
                  ),
                ]),
                FormSection(title: 'Prévia', children: [
                  SelectableText(_text),
                  FilledButton.icon(
                    onPressed: _name.text.trim().isEmpty ||
                            _admission == null ||
                            _discharge == null
                        ? null
                        : _copy,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar Atestado'),
                  ),
                ]),
              ],
            ),
          ),
        ),
      );

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Atestado copiado.')),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onSelected,
    this.firstDate,
  });
  final String label;
  final DateTime? value;
  final DateTime? firstDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        icon: const Icon(Icons.calendar_month_outlined),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(value == null
              ? label
              : '$label: ${value!.day.toString().padLeft(2, '0')}/'
                  '${value!.month.toString().padLeft(2, '0')}/${value!.year}'),
        ),
        onPressed: () async {
          final now = DateTime.now();
          final selected = await showDatePicker(
            context: context,
            initialDate: value ?? firstDate ?? now,
            firstDate: firstDate ?? DateTime(2000),
            lastDate: DateTime(now.year + 2),
          );
          if (selected != null) onSelected(selected);
        },
      );
}

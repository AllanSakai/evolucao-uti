import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/exam_report.dart';
import '../services/exam_report_service.dart';
import '../widgets/form_section.dart';

class ExamReportScreen extends StatefulWidget {
  const ExamReportScreen({super.key});

  @override
  State<ExamReportScreen> createState() => _ExamReportScreenState();
}

class _ExamReportScreenState extends State<ExamReportScreen> {
  final _name = TextEditingController();
  final _exam = TextEditingController();
  final _report = TextEditingController();
  final _service = ExamReportService();
  ExamReportSex _sex = ExamReportSex.male;
  DateTime? _examDate = DateUtils.dateOnly(DateTime.now());

  bool get _canGenerate =>
      _name.text.trim().isNotEmpty &&
      _exam.text.trim().isNotEmpty &&
      _report.text.trim().isNotEmpty;

  String get _text {
    if (!_canGenerate) {
      return 'Preencha paciente, exame e laudo para visualizar o texto.';
    }
    return _service.generate(ExamReport(
      patientName: _name.text,
      sex: _sex,
      examName: _exam.text,
      reportText: _report.text,
      examDate: _examDate,
    ));
  }

  @override
  void dispose() {
    _name.dispose();
    _exam.dispose();
    _report.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Laudos de exames')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
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
                  SegmentedButton<ExamReportSex>(
                    segments: const [
                      ButtonSegment(
                        value: ExamReportSex.male,
                        label: Text('Masculino'),
                      ),
                      ButtonSegment(
                        value: ExamReportSex.female,
                        label: Text('Feminino'),
                      ),
                    ],
                    selected: {_sex},
                    onSelectionChanged: (value) =>
                        setState(() => _sex = value.first),
                  ),
                ]),
                FormSection(title: 'Exame', children: [
                  TextField(
                    controller: _exam,
                    onChanged: (_) => setState(() {}),
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Nome do exame',
                      hintText: 'Ex.: TOMOGRAFIA DE CRANIO',
                    ),
                  ),
                  _DateButton(
                    label: 'Data do exame',
                    value: _examDate,
                    onSelected: (value) => setState(() => _examDate = value),
                    onClear: () => setState(() => _examDate = null),
                  ),
                  TextField(
                    controller: _report,
                    onChanged: (_) => setState(() {}),
                    minLines: 5,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Texto do laudo',
                      alignLabelWithHint: true,
                    ),
                  ),
                ]),
                FormSection(title: 'Previa', children: [
                  SelectableText(_text),
                  FilledButton.icon(
                    onPressed: _canGenerate ? _copy : null,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar laudo'),
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
      const SnackBar(content: Text('Laudo copiado.')),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onSelected,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onSelected;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
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
                  initialDate: value ?? now,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(now.year + 2),
                );
                if (selected != null) onSelected(selected);
              },
            ),
          ),
          IconButton(
            tooltip: 'Remover data',
            onPressed: value == null ? null : onClear,
            icon: const Icon(Icons.close),
          ),
        ],
      );
}

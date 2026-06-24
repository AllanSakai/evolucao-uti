import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/bed.dart';
import '../models/evolution_data.dart';
import '../services/evolution_generator.dart';
import '../widgets/medical_disclaimer.dart';

class EvolutionPreviewScreen extends StatefulWidget {
  const EvolutionPreviewScreen({
    required this.data,
    this.bed,
    this.generatedText,
    this.onConfirmed,
    super.key,
  });

  final EvolutionData data;
  final Bed? bed;
  final String? generatedText;
  final VoidCallback? onConfirmed;

  @override
  State<EvolutionPreviewScreen> createState() => _EvolutionPreviewScreenState();
}

class _EvolutionPreviewScreenState extends State<EvolutionPreviewScreen> {
  late final TextEditingController _controller;
  bool _editing = false;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.generatedText ??
          EvolutionGenerator().generateSummary(widget.data),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.bed?.displayName ?? 'Resumo')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const MedicalDisclaimer(),
                if (widget.bed != null) ...[
                  const SizedBox(height: 12),
                  Text(widget.bed!.displayName,
                      style: Theme.of(context).textTheme.titleLarge),
                ],
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _controller,
                      readOnly: !_editing,
                      minLines: 14,
                      maxLines: null,
                      decoration: InputDecoration(
                        labelText:
                            _editing ? 'Edicao manual' : 'Resumo para GPT',
                        border: _editing
                            ? const OutlineInputBorder()
                            : InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _copy,
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('Copiar resumo'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _editing = !_editing),
                      icon: Icon(_editing ? Icons.check : Icons.edit_outlined),
                      label: Text(
                          _editing ? 'Concluir edicao' : 'Editar manualmente'),
                    ),
                    FilledButton.icon(
                      onPressed: _confirmed ? null : _confirmEvolution,
                      icon: const Icon(Icons.check_circle_outline),
                      label:
                          Text(_confirmed ? 'Resumo confirmado' : 'Confirmar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _controller.text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resumo copiado.')),
      );
    }
  }

  void _confirmEvolution() {
    widget.onConfirmed?.call();
    setState(() => _confirmed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Leito marcado como concluido.')),
    );
  }
}

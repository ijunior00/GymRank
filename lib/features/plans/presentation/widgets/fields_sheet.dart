import 'package:flutter/material.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';

/// Um campo do formulário genérico de edição em bottom sheet.
class FieldSpec {
  const FieldSpec(
    this.label, {
    this.initial,
    this.keyboardType = TextInputType.text,
    this.multiline = false,
    this.required = false,
  });

  final String label;
  final String? initial;
  final TextInputType keyboardType;
  final bool multiline;
  final bool required;
}

/// Resultado do sheet: `null` se cancelado; `deleted` se pediu exclusão.
class FieldsResult {
  const FieldsResult({required this.values, this.deleted = false});

  final List<String> values;
  final bool deleted;

  String? at(int i) {
    final v = values[i].trim();
    return v.isEmpty ? null : v;
  }

  int? intAt(int i) => int.tryParse(values[i].trim());

  double? numAt(int i) =>
      double.tryParse(values[i].trim().replaceAll(',', '.'));
}

/// Formulário genérico em bottom sheet, respeitando o teclado. É o único
/// padrão de edição da revisão: toda linha (ejercicio, alimento, meta)
/// abre este sheet em vez de campos inline apertados.
Future<FieldsResult?> showFieldsSheet(
  BuildContext context, {
  required String title,
  required List<FieldSpec> fields,
  bool allowDelete = false,
}) {
  return showModalBottomSheet<FieldsResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _FieldsSheet(
      title: title,
      fields: fields,
      allowDelete: allowDelete,
    ),
  );
}

class _FieldsSheet extends StatefulWidget {
  const _FieldsSheet({
    required this.title,
    required this.fields,
    required this.allowDelete,
  });

  final String title;
  final List<FieldSpec> fields;
  final bool allowDelete;

  @override
  State<_FieldsSheet> createState() => _FieldsSheetState();
}

class _FieldsSheetState extends State<_FieldsSheet> {
  late final List<TextEditingController> _controllers = [
    for (final f in widget.fields) TextEditingController(text: f.initial ?? ''),
  ];
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      FieldsResult(values: [for (final c in _controllers) c.text]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: AppTextStyles.headline),
              const SizedBox(height: 14),
              for (var i = 0; i < widget.fields.length; i++) ...[
                TextFormField(
                  controller: _controllers[i],
                  keyboardType: widget.fields[i].multiline
                      ? TextInputType.multiline
                      : widget.fields[i].keyboardType,
                  minLines: 1,
                  maxLines: widget.fields[i].multiline ? 4 : 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: widget.fields[i].label),
                  validator: widget.fields[i].required
                      ? (v) => (v == null || v.trim().isEmpty)
                          ? 'Obligatorio'
                          : null
                      : null,
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 6),
              ElevatedButton(onPressed: _save, child: const Text('Guardar')),
              if (widget.allowDelete)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(
                    const FieldsResult(values: [], deleted: true),
                  ),
                  style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  child: const Text('Eliminar'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

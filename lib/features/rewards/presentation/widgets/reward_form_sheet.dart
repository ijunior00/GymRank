import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/core/l10n/labels_es.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/rewards/domain/entities/reward_entity.dart';
import 'package:gymrank/features/rewards/presentation/controllers/reward_providers.dart';
import 'package:image_picker/image_picker.dart';

/// Abre a folha de criar/editar prêmio e devolve o prêmio salvo (ou
/// `null` se a pessoa fechou sem salvar).
Future<RewardEntity?> showRewardFormSheet(
  BuildContext context, {
  RewardEntity? initial,
}) {
  return showModalBottomSheet<RewardEntity>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => RewardFormSheet(initial: initial),
  );
}

class RewardFormSheet extends ConsumerStatefulWidget {
  const RewardFormSheet({super.key, this.initial});

  final RewardEntity? initial;

  @override
  ConsumerState<RewardFormSheet> createState() => _RewardFormSheetState();
}

class _RewardFormSheetState extends ConsumerState<RewardFormSheet> {
  static const int maxStock = 1000;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _stock;
  late RewardType _type;
  Uint8List? _imageBytes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    _name = TextEditingController(text: r?.name ?? '');
    _stock = TextEditingController(text: (r?.stock ?? 1).toString());
    _type = r?.type ?? RewardType.vestuario;
  }

  @override
  void dispose() {
    _name.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _imageBytes = bytes);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final coachId = ref.read(currentUserProvider).valueOrNull?.coachId;
    if (coachId == null) return;

    final reward = RewardEntity(
      id: widget.initial?.id ?? '',
      coachId: widget.initial?.coachId ?? coachId,
      name: _name.text.trim(),
      imageUrl: widget.initial?.imageUrl,
      type: _type,
      stock: int.parse(_stock.text.trim()),
    );

    setState(() => _saving = true);
    final result = await ref
        .read(rewardRepositoryProvider)
        .save(reward, imageBytes: _imageBytes);
    if (!mounted) return;
    setState(() => _saving = false);

    final failure = result.failureOrNull;
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el premio: ${failure.labelEs}')),
      );
      return;
    }
    Navigator.of(context).pop(result.dataOrNull);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    final existingImage = widget.initial?.imageUrl;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(isEdit ? 'Editar premio' : 'Nuevo premio',
                  style: AppTextStyles.headline),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej. Playera oficial del método',
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Ponle un nombre al premio.' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<RewardType>(
                // ignore: deprecated_member_use
                value: _type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: [
                  for (final t in RewardType.values)
                    DropdownMenuItem(value: t, child: Text(t.labelEs)),
                ],
                onChanged: (t) => setState(() => _type = t ?? _type),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stock,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '¿Cuántos tienes?',
                  helperText: 'Baja solo cada vez que alguien lo gana.',
                ),
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null || n < 0) return 'Escribe un número (0 o más).';
                  if (n > maxStock) return 'Máximo $maxStock.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      image: _imageBytes != null
                          ? DecorationImage(
                              image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                          : existingImage != null
                              ? DecorationImage(
                                  image: NetworkImage(existingImage),
                                  fit: BoxFit.cover)
                              : null,
                    ),
                    child: _imageBytes == null && existingImage == null
                        ? const Icon(Icons.card_giftcard,
                            color: AppColors.textSecondary)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _pickImage,
                      icon: const Icon(Icons.photo_outlined),
                      label: Text(
                        _imageBytes != null || existingImage != null
                            ? 'Cambiar foto'
                            : 'Agregar foto (opcional)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? 'Guardar' : 'Crear premio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

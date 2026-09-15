import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/core/l10n/labels_es.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/checkin/domain/entities/checkin_location.dart';
import 'package:gymrank/features/checkin/presentation/controllers/checkin_providers.dart';

Future<CheckInLocation?> showLocationFormSheet(
  BuildContext context, {
  CheckInLocation? initial,
}) {
  return showModalBottomSheet<CheckInLocation>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => LocationFormSheet(initial: initial),
  );
}

/// Cadastro de uma academia. A posição vem do GPS do celular da coach
/// (estando lá) ou digitada; sem posição não dá para conferir a distância.
class LocationFormSheet extends ConsumerStatefulWidget {
  const LocationFormSheet({super.key, this.initial});

  final CheckInLocation? initial;

  @override
  ConsumerState<LocationFormSheet> createState() => _LocationFormSheetState();
}

class _LocationFormSheetState extends ConsumerState<LocationFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  late double _radius;
  double? _accuracy;
  bool _locating = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final l = widget.initial;
    _name = TextEditingController(text: l?.name ?? '');
    _address = TextEditingController(text: l?.address ?? '');
    _lat = TextEditingController(text: l == null ? '' : l.lat.toStringAsFixed(6));
    _lng = TextEditingController(text: l == null ? '' : l.lng.toStringAsFixed(6));
    _radius = l?.radiusM ?? CheckInLocation.defaultRadiusM;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  Future<void> _useMyPosition() async {
    setState(() => _locating = true);
    final result = await ref.read(positionSourceProvider).current();
    if (!mounted) return;
    setState(() => _locating = false);
    final failure = result.failureOrNull;
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.labelEs), duration: const Duration(seconds: 6)),
      );
      return;
    }
    final p = result.dataOrNull!;
    setState(() {
      _lat.text = p.lat.toStringAsFixed(6);
      _lng.text = p.lng.toStringAsFixed(6);
      _accuracy = p.accuracyM;
    });
  }

  String? _coordError(String? raw, double limit) {
    final v = double.tryParse((raw ?? '').trim().replaceAll(',', '.'));
    if (v == null) return 'Usa "Mi ubicación" o escribe el número.';
    if (v.abs() > limit) return 'Fuera de rango.';
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final coachId = ref.read(currentUserProvider).valueOrNull?.coachId;
    if (coachId == null) return;

    final initial = widget.initial;
    final location = CheckInLocation(
      id: initial?.id ?? '',
      coachId: initial?.coachId ?? coachId,
      name: _name.text.trim(),
      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      lat: double.parse(_lat.text.trim().replaceAll(',', '.')),
      lng: double.parse(_lng.text.trim().replaceAll(',', '.')),
      radiusM: _radius,
      qrVersion: initial?.qrVersion ?? 1,
      active: initial?.active ?? true,
      createdAt: initial?.createdAt ?? DateTime.now(),
    );

    setState(() => _saving = true);
    final result = await ref.read(checkInRepositoryProvider).saveLocation(location);
    if (!mounted) return;
    setState(() => _saving = false);

    final failure = result.failureOrNull;
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: ${failure.labelEs}')),
      );
      return;
    }
    Navigator.of(context).pop(result.dataOrNull);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
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
              Text(isEdit ? 'Editar academia' : 'Nueva academia',
                  style: AppTextStyles.headline),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej. Smart Fit Polanco',
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Ponle nombre a la academia.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Dirección (opcional)',
                ),
              ),
              const SizedBox(height: 8),
              const Text('Ubicación', style: AppTextStyles.title),
              const SizedBox(height: 4),
              const Text(
                'Lo más fácil: toca el botón estando en la academia.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _locating || _saving ? null : _useMyPosition,
                icon: _locating
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(_locating ? 'Buscando…' : 'Usar mi ubicación actual'),
              ),
              if (_accuracy != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Precisión: ±${_accuracy!.round()} m'
                    '${_accuracy! > 50 ? ' · mejor repetir cerca de una ventana' : ''}',
                    style: AppTextStyles.caption.copyWith(
                      color: _accuracy! > 50 ? AppColors.warning : AppColors.success,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _lat,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      decoration: const InputDecoration(labelText: 'Latitud'),
                      validator: (v) => _coordError(v, 90),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lng,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      decoration: const InputDecoration(labelText: 'Longitud'),
                      validator: (v) => _coordError(v, 180),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Radio aceptado: ${_radius.round()} m', style: AppTextStyles.title),
              Slider(
                value: _radius,
                min: CheckInLocation.minRadiusM,
                max: CheckInLocation.maxRadiusM,
                divisions: 19,
                label: '${_radius.round()} m',
                onChanged: (v) => setState(() => _radius = v),
              ),
              const Text(
                '150 m cubre el gimnasio y el estacionamiento. Sube el radio si '
                'el GPS falla adentro (edificios grandes, sótanos).',
                style: AppTextStyles.caption,
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
                    : Text(isEdit ? 'Guardar' : 'Registrar academia'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

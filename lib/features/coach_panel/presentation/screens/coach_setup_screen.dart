import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/coach_panel/domain/entities/coach_entity.dart';
import 'package:gymrank/features/coach_panel/presentation/controllers/coach_panel_providers.dart';
import 'package:gymrank/features/sharing/presentation/controllers/share_providers.dart';

/// Primeiro acesso da treinadora: dá nome à marca/método e gera o código
/// de convite. Só aparece para quem já tem o papel `coach` (atribuído
/// fora do app) e ainda não tem `coachId`.
class CoachSetupScreen extends ConsumerStatefulWidget {
  const CoachSetupScreen({super.key});

  @override
  ConsumerState<CoachSetupScreen> createState() => _CoachSetupScreenState();
}

class _CoachSetupScreenState extends ConsumerState<CoachSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _tagline = TextEditingController();
  final _city = TextEditingController();
  final _instagram = TextEditingController();
  bool _saving = false;

  /// Cor da marca: aparece nas imagens que os alunos compartilham.
  String _brandColorHex = _brandColors.first.$2;

  static const List<(String, String)> _brandColors = [
    ('Violeta', '#A855F7'),
    ('Fucsia', '#D946EF'),
    ('Índigo', '#6366F1'),
    ('Rosa', '#F43F5E'),
    ('Esmeralda', '#10B981'),
    ('Ámbar', '#F59E0B'),
  ];

  static const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const _secretAlphabet =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user != null) _city.text = user.city;
  }

  @override
  void dispose() {
    _name.dispose();
    _tagline.dispose();
    _city.dispose();
    _instagram.dispose();
    super.dispose();
  }

  String _random(int length, String alphabet) {
    final rnd = Random.secure();
    return List.generate(length, (_) => alphabet[rnd.nextInt(alphabet.length)])
        .join();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    setState(() => _saving = true);
    final coach = CoachEntity(
      id: '',
      ownerUserId: user.id,
      name: _name.text.trim(),
      tagline: _tagline.text.trim().isEmpty ? null : _tagline.text.trim(),
      city: _city.text.trim(),
      country: 'MX',
      logoUrl: null,
      brandColorHex: _brandColorHex,
      instagramHandle: _instagram.text.trim().isEmpty
          ? null
          : _instagram.text.trim().replaceFirst('@', ''),
      inviteCode: _random(6, _codeAlphabet),
      qrCodeSecret: _random(40, _secretAlphabet),
      plan: SubscriptionPlan.free,
      studentCount: 0,
      activeChallengeCount: 0,
      createdAt: DateTime.now(),
    );

    final result =
        await ref.read(coachPanelRepositoryProvider).createCoach(coach);
    if (!mounted) return;
    setState(() => _saving = false);

    final failure = result.failureOrNull;
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo crear tu perfil: $failure')),
      );
      return;
    }
    context.go('/coach');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tu perfil de coach')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('¿Cómo se llama tu método?', style: AppTextStyles.headline),
              const SizedBox(height: 6),
              const Text(
                'Es el nombre que tus alumnos verán en todo el app.',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la marca o método',
                  hintText: 'Ej. Método AF',
                ),
                validator: (v) =>
                    (v == null || v.trim().length < 2) ? 'Escribe un nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tagline,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Frase corta (opcional)',
                  hintText: 'Ej. Fuerza, constancia y comunidad',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _city,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Ciudad'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _instagram,
                decoration: const InputDecoration(
                  labelText: 'Instagram (opcional)',
                  prefixText: '@',
                ),
              ),
              const SizedBox(height: 20),
              const Text('Color de tu marca', style: AppTextStyles.caption),
              const SizedBox(height: 4),
              const Text(
                'Es el color de las imágenes que tus alumnos comparten.',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final (name, hex) in _brandColors)
                    _ColorSwatch(
                      name: name,
                      hex: hex,
                      selected: _brandColorHex == hex,
                      onTap: () => setState(() => _brandColorHex = hex),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Crear perfil y generar código'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Amostra de cor da marca, com estado selecionado visível sem depender
/// só da cor (borda + check), para quem enxerga cor de forma diferente.
class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.name,
    required this.hex,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String hex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = parseBrandColor(hex) ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Semantics(
        selected: selected,
        label: name,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? AppColors.textPrimary : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 22)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(name, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

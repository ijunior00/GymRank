import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/core/l10n/labels_es.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/core/utils/date_formatter.dart';
import 'package:gymrank/core/utils/load_error_text.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/challenges/domain/challenge_form_rules.dart';
import 'package:gymrank/features/challenges/domain/entities/challenge_entity.dart';
import 'package:gymrank/features/challenges/presentation/controllers/challenge_providers.dart';
import 'package:gymrank/features/rewards/presentation/controllers/reward_providers.dart';
import 'package:gymrank/features/rewards/presentation/widgets/reward_form_sheet.dart';

/// Criar ou editar um reto. Sem [challengeId] é um reto novo.
class ChallengeFormScreen extends ConsumerWidget {
  const ChallengeFormScreen({super.key, this.challengeId});

  final String? challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = challengeId;
    if (id == null) return const _ChallengeForm(initial: null);

    final challenge = ref.watch(challengeByIdProvider(id));
    return challenge.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Editar reto')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Editar reto')),
        body: Center(child: Text(describeLoadError(e))),
      ),
      data: (c) => c == null
          ? Scaffold(
              appBar: AppBar(title: const Text('Editar reto')),
              body: const Center(child: Text('Este reto ya no existe.')),
            )
          : _ChallengeForm(key: ValueKey(c.id), initial: c),
    );
  }
}

enum _PeriodChoice { semana, mes, fechas }

class _ChallengeForm extends ConsumerStatefulWidget {
  const _ChallengeForm({super.key, required this.initial});

  final ChallengeEntity? initial;

  @override
  ConsumerState<_ChallengeForm> createState() => _ChallengeFormState();
}

class _ChallengeFormState extends ConsumerState<_ChallengeForm> {
  static const _noReward = '__none__';
  static const _newReward = '__new__';
  static const _xpPresets = [50, 100, 250, 500, 1000];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _target;
  late ChallengeMetric _metric;
  late DateTime _startsAt;
  late DateTime _endsAt;
  late _PeriodChoice _periodChoice;
  late int _xp;
  String? _rewardId;
  bool _saving = false;
  String? _datesError;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    _title = TextEditingController(text: c?.title ?? '');
    _description = TextEditingController(text: c?.description ?? '');
    _target = TextEditingController(
      text: c == null ? '' : c.targetValue.toInt().toString(),
    );
    _metric = c != null && ChallengeFormRules.availableMetrics.contains(c.metric)
        ? c.metric
        : ChallengeMetric.diasTreinados;
    final today = DateUtils.dateOnly(DateTime.now());
    _startsAt = c?.startsAt ?? today;
    _endsAt = c?.endsAt ?? today.add(const Duration(days: 7));
    _periodChoice = c == null ? _PeriodChoice.semana : _PeriodChoice.fechas;
    _xp = c?.xpReward ?? 100;
    _rewardId = c?.rewardId;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _target.dispose();
    super.dispose();
  }

  void _choosePeriod(_PeriodChoice choice) {
    setState(() {
      _periodChoice = choice;
      final start = DateUtils.dateOnly(DateTime.now());
      switch (choice) {
        case _PeriodChoice.semana:
          _startsAt = start;
          _endsAt = start.add(const Duration(days: 7));
        case _PeriodChoice.mes:
          _startsAt = start;
          _endsAt = start.add(const Duration(days: 30));
        case _PeriodChoice.fechas:
          break;
      }
      _datesError = null;
    });
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialDateRange: DateTimeRange(start: _startsAt, end: _endsAt),
      helpText: 'Inicio y fin del reto',
      saveText: 'Listo',
    );
    if (range == null) return;
    setState(() {
      _periodChoice = _PeriodChoice.fechas;
      _startsAt = range.start;
      // O fim vale o dia inteiro: até as 23:59 daquela data.
      _endsAt = DateUtils.dateOnly(range.end)
          .add(const Duration(days: 1))
          .subtract(const Duration(minutes: 1));
      _datesError = null;
    });
  }

  Future<void> _onRewardChanged(String? value) async {
    if (value == _newReward) {
      final created = await showRewardFormSheet(context);
      if (!mounted) return;
      setState(() => _rewardId = created?.id ?? _rewardId);
      return;
    }
    setState(() => _rewardId = value == _noReward ? null : value);
  }

  Future<void> _save() async {
    final datesError = ChallengeFormRules.datesError(_startsAt, _endsAt);
    setState(() => _datesError = datesError);
    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk || datesError != null) return;

    final me = ref.read(currentUserProvider).valueOrNull;
    final coachId = me?.coachId;
    if (coachId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero configura tu comunidad.')),
      );
      return;
    }

    final initial = widget.initial;
    final now = DateTime.now();
    final challenge = ChallengeEntity(
      id: initial?.id ?? '',
      coachId: coachId,
      title: _title.text.trim(),
      description: _description.text.trim(),
      scope: initial?.scope ?? ChallengeScope.comunidad,
      period: ChallengeFormRules.periodFor(_startsAt, _endsAt),
      metric: _metric,
      targetValue: int.parse(_target.text.trim()).toDouble(),
      startsAt: _startsAt,
      endsAt: _endsAt,
      xpReward: _xp,
      rewardId: _rewardId,
      participantCount: initial?.participantCount ?? 0,
      isActive: initial?.isActive ?? true,
      createdAt: initial?.createdAt ?? now,
    );

    setState(() => _saving = true);
    final result = await ref.read(challengeRepositoryProvider).save(challenge);
    if (!mounted) return;
    setState(() => _saving = false);

    final failure = result.failureOrNull;
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: ${failure.labelEs}')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEdit
              ? 'Cambios guardados.'
              : '¡Reto publicado! Ya aparece en la pestaña Retos de tus alumnas.',
        ),
      ),
    );
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/coach/challenges');
    }
  }

  @override
  Widget build(BuildContext context) {
    final rewards = ref.watch(coachRewardsProvider).valueOrNull ?? const [];
    final rewardIds = rewards.map((r) => r.id).toSet();
    final selectedReward =
        _rewardId != null && rewardIds.contains(_rewardId) ? _rewardId! : _noReward;
    final xpError = ChallengeFormRules.xpError(_xp);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Editar reto' : 'Nuevo reto')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              maxLength: ChallengeFormRules.maxTitle,
              decoration: const InputDecoration(
                labelText: 'Nombre del reto',
                hintText: 'Ej. Semana imparable',
              ),
              validator: (v) => ChallengeFormRules.titleError(v ?? ''),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              maxLength: ChallengeFormRules.maxDescription,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                hintText: 'Qué hay que lograr y por qué vale la pena',
              ),
              validator: (v) => ChallengeFormRules.descriptionError(v ?? ''),
            ),
            const SizedBox(height: 20),
            const Text('¿Qué cuenta?', style: AppTextStyles.title),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in ChallengeFormRules.availableMetrics)
                  ChoiceChip(
                    avatar: Icon(
                      m == ChallengeMetric.checkIns
                          ? Icons.qr_code_scanner
                          : Icons.fitness_center,
                      size: 18,
                    ),
                    label: Text(m.labelEs),
                    selected: _metric == m,
                    onSelected: (_) => setState(() => _metric = m),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _metric == ChallengeMetric.checkIns
                  ? 'Cada check-in con QR en la academia suma 1.'
                  : 'Cada día con entrenamiento registrado o sesión completada suma 1.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _target,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _metric == ChallengeMetric.checkIns
                    ? '¿Cuántos check-ins?'
                    : '¿Cuántos días?',
                hintText: 'Ej. 5',
              ),
              validator: (v) => ChallengeFormRules.targetError(v ?? ''),
            ),
            const SizedBox(height: 20),
            const Text('¿Cuánto dura?', style: AppTextStyles.title),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Una semana'),
                  selected: _periodChoice == _PeriodChoice.semana,
                  onSelected: (_) => _choosePeriod(_PeriodChoice.semana),
                ),
                ChoiceChip(
                  label: const Text('Un mes'),
                  selected: _periodChoice == _PeriodChoice.mes,
                  onSelected: (_) => _choosePeriod(_PeriodChoice.mes),
                ),
                ChoiceChip(
                  label: const Text('Elegir fechas'),
                  selected: _periodChoice == _PeriodChoice.fechas,
                  onSelected: (_) => _pickDates(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDates,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Del ${DateFormatter.shortDate(_startsAt)} al '
                        '${DateFormatter.shortDate(_endsAt)}',
                        style: AppTextStyles.bodyMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_datesError != null)
              Text(
                _datesError!,
                style: AppTextStyles.caption.copyWith(color: AppColors.warning),
              ),
            const SizedBox(height: 20),
            Text('Recompensa: +$_xp XP', style: AppTextStyles.title),
            const SizedBox(height: 4),
            Slider(
              value: _xp.toDouble(),
              min: ChallengeFormRules.minXp.toDouble(),
              max: ChallengeFormRules.maxXp.toDouble(),
              divisions:
                  (ChallengeFormRules.maxXp - ChallengeFormRules.minXp) ~/ 10,
              label: '+$_xp XP',
              onChanged: (v) => setState(() => _xp = v.round()),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final preset in _xpPresets)
                  ChoiceChip(
                    label: Text('$preset'),
                    selected: _xp == preset,
                    onSelected: (_) => setState(() => _xp = preset),
                  ),
              ],
            ),
            Text(
              xpError ??
                  'Como referencia: un entrenamiento vale 50 XP y un check-in 20.',
              style: AppTextStyles.caption
                  .copyWith(color: xpError == null ? null : AppColors.warning),
            ),
            const SizedBox(height: 20),
            const Text('Premio (opcional)', style: AppTextStyles.title),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: selectedReward,
              isExpanded: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.card_giftcard),
              ),
              items: [
                const DropdownMenuItem(value: _noReward, child: Text('Sin premio')),
                for (final r in rewards)
                  DropdownMenuItem(
                    value: r.id,
                    child: Text(
                      '${r.name} · ${r.stock} disponibles',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const DropdownMenuItem(
                  value: _newReward,
                  child: Text('＋ Crear premio nuevo…'),
                ),
              ],
              onChanged: _saving ? null : _onRewardChanged,
            ),
            const SizedBox(height: 6),
            const Text(
              'Quien complete el reto recibe el premio automáticamente, '
              'mientras haya disponibles.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEdit ? 'Guardar cambios' : 'Publicar reto'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Visible para toda tu comunidad en la pestaña Retos.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}

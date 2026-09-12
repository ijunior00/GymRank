import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymrank/core/l10n/labels_es.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/core/utils/share_text.dart';
import 'package:gymrank/core/widgets/entrance.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/coach_panel/domain/entities/client_entity.dart';
import 'package:gymrank/features/coach_panel/domain/entities/coach_entity.dart';
import 'package:gymrank/features/coach_panel/presentation/controllers/coach_panel_providers.dart';
import 'package:gymrank/core/utils/date_formatter.dart';
import 'package:gymrank/features/coach_panel/presentation/widgets/student_activity_chip.dart';
import 'package:gymrank/features/sharing/domain/entities/share_card.dart';
import 'package:gymrank/features/sharing/presentation/controllers/share_providers.dart';

enum _Filter { todos, alDia, enRiesgo, sinActividad, pausados }

/// Painel da treinadora: código de convite, indicadores da comunidade e a
/// lista de alunos com busca e filtro por situação. Os indicadores vêm da
/// Cloud Function `recalculateCoachDashboard`; a situação de cada aluno é
/// derivada no cliente a partir dos últimos registros.
class CoachDashboardScreen extends ConsumerStatefulWidget {
  const CoachDashboardScreen({super.key});

  @override
  ConsumerState<CoachDashboardScreen> createState() =>
      _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends ConsumerState<CoachDashboardScreen> {
  final _searchController = TextEditingController();
  _Filter _filter = _Filter.todos;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _passesFilter(CoachStudentView s) {
    return switch (_filter) {
      _Filter.todos => true,
      _Filter.alDia =>
        s.status == ClientStatus.activo && s.activity == StudentActivity.alDia,
      _Filter.enRiesgo => s.status == ClientStatus.activo &&
          s.activity == StudentActivity.enRiesgo,
      _Filter.sinActividad => s.status == ClientStatus.activo &&
          (s.activity == StudentActivity.sinActividad ||
              s.activity == StudentActivity.sinRegistros),
      _Filter.pausados => s.status != ClientStatus.activo,
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final coach = ref.watch(currentCoachProvider);
    final stats = ref.watch(coachDashboardStatsProvider).valueOrNull;
    final students = ref.watch(coachStudentsProvider);

    if (user != null && user.isCoach && user.coachId == null) {
      return const _SetupPrompt();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(coach.valueOrNull?.name ?? 'Panel de coach'),
      ),
      // Ação principal na zona do polegar: 80% do uso é no celular.
      floatingActionButton: coach.valueOrNull == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showInviteSheet(context, coach.valueOrNull!),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Invitar'),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          if (coach.valueOrNull != null)
            Entrance(child: _InviteCard(coach: coach.valueOrNull!)),
          const SizedBox(height: 16),
          Entrance(
            delay: const Duration(milliseconds: 80),
            child: _StatsGrid(
              stats: stats,
              fallbackStudents: students.valueOrNull,
              onFilter: (f) => setState(() => _filter = f),
            ),
          ),
          const SizedBox(height: 16),
          Entrance(
            delay: const Duration(milliseconds: 110),
            child: _MarketingCard(students: students.valueOrNull ?? const []),
          ),
          const SizedBox(height: 24),
          const Entrance(
            delay: Duration(milliseconds: 140),
            child: Text('Alumnos', style: AppTextStyles.headline),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o usuario',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in _Filter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_filterLabel(f)),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          students.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => _Message(text: 'Error: $e'),
            data: (all) {
              final query = _searchController.text;
              final visible = all
                  .where((s) => s.matches(query) && _passesFilter(s))
                  .toList();
              if (all.isEmpty) {
                return const _Message(
                  icon: Icons.group_add_outlined,
                  text:
                      'Aún no tienes alumnos. Comparte tu código de invitación '
                      'para que se unan desde su perfil.',
                );
              }
              if (visible.isEmpty) {
                return const _Message(
                  icon: Icons.filter_alt_off_outlined,
                  text: 'Ningún alumno coincide con la búsqueda o el filtro.',
                );
              }
              return EntranceList(
                step: const Duration(milliseconds: 40),
                children: [
                  for (final s in visible)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _StudentTile(
                        student: s,
                        onTap: () =>
                            context.push('/coach/clients/${s.user.id}'),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _filterLabel(_Filter f) => switch (f) {
        _Filter.todos => 'Todos',
        _Filter.alDia => 'Al día',
        _Filter.enRiesgo => 'En riesgo',
        _Filter.sinActividad => 'Sin actividad',
        _Filter.pausados => 'En pausa',
      };

  void _showInviteSheet(BuildContext context, CoachEntity coach) {
    // As ações fecham a folha antes de agir: um SnackBar disparado com a
    // folha aberta fica escondido atrás dela e a treinadora acha que nada
    // aconteceu. Por isso usam o `context` da tela, não o da folha.
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Tu código de invitación', style: AppTextStyles.headline),
            const SizedBox(height: 8),
            Text(
              'Tus alumnos lo escriben al crear su cuenta o en Perfil → '
              '"Unirme a mi coach". Así quedan vinculados a ${coach.name}.',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 20),
            _InviteCodeBox(code: coach.inviteCode),
            const SizedBox(height: 16),
            // Mandar por WhatsApp é como ela vai usar isto de verdade; copiar
            // fica como segunda opção.
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                shareText(
                  context,
                  'Únete a mi comunidad ${coach.name} en AnahiFitness 💪\n\n'
                  'Descarga la app, crea tu cuenta y usa el código '
                  '${coach.inviteCode} para entrenar conmigo.',
                );
              },
              icon: const Icon(Icons.ios_share),
              label: const Text('Compartir invitación'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _copyCode(context, coach.inviteCode);
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copiar solo el código'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _copyCode(BuildContext context, String code) async {
  await Clipboard.setData(ClipboardData(text: code));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Código copiado.')),
  );
}

class _SetupPrompt extends StatelessWidget {
  const _SetupPrompt();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de coach')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.storefront_outlined,
                size: 56, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Configura tu marca',
              textAlign: TextAlign.center,
              style: AppTextStyles.headline,
            ),
            const SizedBox(height: 8),
            const Text(
              'Antes de recibir alumnos, dale nombre a tu método y genera tu '
              'código de invitación. Toma menos de un minuto.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/coach/setup'),
              child: const Text('Crear mi perfil de coach'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.coach});

  final CoachEntity coach;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.heroGradient,
        ),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CÓDIGO DE INVITACIÓN',
                  style: AppTextStyles.caption.copyWith(letterSpacing: 1.2),
                ),
                const SizedBox(height: 6),
                Text(
                  coach.inviteCode,
                  style: AppTextStyles.displayLarge.copyWith(
                    fontSize: 30,
                    letterSpacing: 4,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  coach.tagline ?? '${coach.studentCount} alumnos en tu comunidad',
                  style: AppTextStyles.bodyMuted,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Copiar código',
            onPressed: () => _copyCode(context, coach.inviteCode),
            icon: const Icon(Icons.copy),
          ),
        ],
      ),
    );
  }
}

class _InviteCodeBox extends StatelessWidget {
  const _InviteCodeBox({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Center(
        child: Text(
          code,
          style: AppTextStyles.displayLarge.copyWith(
            fontSize: 36,
            letterSpacing: 6,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.stats,
    required this.fallbackStudents,
    required this.onFilter,
  });

  final CoachDashboardStats? stats;
  final List<CoachStudentView>? fallbackStudents;

  /// Os indicadores que correspondem a um filtro da lista viram atalho:
  /// tocar em "En riesgo" já mostra quem está em risco.
  final ValueChanged<_Filter> onFilter;

  @override
  Widget build(BuildContext context) {
    // Enquanto a function ainda não materializou `stats/current`, mostra
    // o que dá para derivar da lista de alunos já carregada.
    final derived = fallbackStudents ?? const <CoachStudentView>[];
    final active =
        derived.where((s) => s.status == ClientStatus.activo).toList();
    final atRisk = active
        .where((s) =>
            s.activity == StudentActivity.enRiesgo ||
            s.activity == StudentActivity.sinActividad)
        .length;

    final items = <(String, String, _Filter?)>[
      ('Alumnos activos', '${stats?.activeStudents ?? active.length}', _Filter.alDia),
      ('En riesgo', '${stats?.inactiveStudents7d ?? atRisk}', _Filter.enRiesgo),
      ('Entrenaron hoy', stats == null ? '—' : '${stats!.workoutsToday}', null),
      ('Entrenos (7 días)', stats == null ? '—' : '${stats!.workoutsThisWeek}', null),
      ('Nuevos este mes', stats == null ? '—' : '${stats!.newStudentsThisMonth}', null),
      (
        'Retención',
        stats == null ? '—' : '${(stats!.retentionRate * 100).toStringAsFixed(0)}%',
        null,
      ),
    ];

    // Duas colunas: em telas de 360 px cada tile fica com ~165 px, o que
    // cabe número grande + rótulo em uma linha sem espremer.
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.9,
      children: [
        for (final (label, value, filter) in items)
          Card(
            child: InkWell(
              onTap: filter == null ? null : () => onFilter(filter),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(value,
                              style: AppTextStyles.displayLarge
                                  .copyWith(fontSize: 24)),
                          const SizedBox(height: 2),
                          Text(
                            label,
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (filter != null)
                      const Icon(Icons.chevron_right,
                          size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// O que a comunidade está espalhando: cards compartilhados na semana e
/// os alunos que mais trouxeram gente (embaixadores).
class _MarketingCard extends ConsumerWidget {
  const _MarketingCard({required this.students});

  final List<CoachStudentView> students;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shares = ref.watch(communitySharesProvider).valueOrNull ?? const [];
    final ambassadors = [
      for (final s in students)
        if (s.user.referralCount > 0) s,
    ]..sort((a, b) => b.user.referralCount.compareTo(a.user.referralCount));

    if (shares.isEmpty && ambassadors.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Difusión', style: AppTextStyles.title),
              SizedBox(height: 4),
              Text(
                'Cuando tus alumnos compartan sus récords y rachas, verás '
                'aquí qué está circulando y quién trae más gente.',
                style: AppTextStyles.bodyMuted,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Difusión', style: AppTextStyles.title),
            if (shares.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Compartido hace poco', style: AppTextStyles.caption),
              for (final s in shares.take(4))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      const Icon(Icons.ios_share,
                          size: 15, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${s.userName} · ${_shareLabel(s.kind)}',
                          style: AppTextStyles.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(DateFormatter.relative(s.sharedAt),
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),
            ],
            if (ambassadors.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Embajadores', style: AppTextStyles.caption),
              for (final a in ambassadors.take(3))
                InkWell(
                  onTap: () => context.push('/coach/clients/${a.user.id}'),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        const Icon(Icons.volunteer_activism,
                            size: 15, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(a.user.name,
                              style: AppTextStyles.body,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text(
                          a.user.referralCount == 1
                              ? '1 invitado'
                              : '${a.user.referralCount} invitados',
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right,
                            size: 16, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  static String _shareLabel(ShareCardKind kind) => switch (kind) {
        ShareCardKind.record => 'récord',
        ShareCardKind.racha => 'racha',
        ShareCardKind.nivel => 'nivel',
        ShareCardKind.entrenamiento => 'entrenamiento',
        ShareCardKind.ranking => 'ranking',
      };
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.student, required this.onTap});

  final CoachStudentView student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final user = student.user;
    final days = student.daysSinceActivity;
    final lastActivity = switch (days) {
      null => 'sin registros',
      0 => 'entrenó hoy',
      1 => 'entrenó ayer',
      _ => 'hace $days días',
    };

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.surfaceElevated,
                backgroundImage:
                    user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                child: user.photoUrl == null
                    ? Text(
                        _initials(user.name),
                        style: AppTextStyles.title
                            .copyWith(color: AppColors.primary),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.name, style: AppTextStyles.title),
                    const SizedBox(height: 2),
                    Text(
                      'Nivel ${user.level} · racha ${user.currentStreakDays} d · $lastActivity',
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (student.client?.planName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        student.client!.planName!,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textPrimary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (student.status != ClientStatus.activo)
                StudentStatusChip(label: student.status.labelEs)
              else
                StudentActivityChip(activity: student.activity),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 32, color: AppColors.textSecondary),
              const SizedBox(height: 8),
            ],
            Text(text,
                textAlign: TextAlign.center, style: AppTextStyles.bodyMuted),
          ],
        ),
      ),
    );
  }
}

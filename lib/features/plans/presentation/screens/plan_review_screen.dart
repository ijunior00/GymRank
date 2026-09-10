import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymrank/core/l10n/labels_es.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/coach_panel/presentation/controllers/coach_panel_providers.dart';
import 'package:gymrank/features/plans/domain/entities/plan_content.dart';
import 'package:gymrank/features/plans/domain/entities/plan_entity.dart';
import 'package:gymrank/features/plans/presentation/controllers/plan_providers.dart';
import 'package:gymrank/features/plans/presentation/widgets/fields_sheet.dart';
import 'package:gymrank/features/plans/presentation/widgets/plan_content_view.dart';
import 'package:url_launcher/url_launcher.dart';

/// Revisão e publicação de um plano pela treinadora. Três origens:
/// - [documentId]: resultado do parser de um PDF/Word/foto (`listo`);
/// - [planId]: editar e republicar um plano já vigente (nova versão);
/// - [userId] + [kind] sem os anteriores: captura manual do zero.
///
/// Nada chega ao aluno até ela tocar em "Publicar".
class PlanReviewScreen extends ConsumerStatefulWidget {
  const PlanReviewScreen({
    this.documentId,
    this.planId,
    this.userId,
    this.kind,
    super.key,
  }) : assert(documentId != null || planId != null || (userId != null && kind != null));

  final String? documentId;
  final String? planId;
  final String? userId;
  final PlanKind? kind;

  @override
  ConsumerState<PlanReviewScreen> createState() => _PlanReviewScreenState();
}

class _PlanReviewScreenState extends ConsumerState<PlanReviewScreen> {
  PlanContent? _draft;
  String? _targetUserId;
  String? _sourceDocumentId;
  String? _downloadUrl;
  String? _fileName;
  bool _publishing = false;
  bool _preview = false;

  final _title = TextEditingController();
  final _summary = TextEditingController();
  final _notes = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.documentId == null && widget.planId == null) {
      _load(PlanContent.empty(widget.kind!), userId: widget.userId!);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _load(
    PlanContent content, {
    required String userId,
    String? sourceDocumentId,
    String? downloadUrl,
    String? fileName,
  }) {
    _draft = content;
    _targetUserId = userId;
    _sourceDocumentId = sourceDocumentId;
    _downloadUrl = downloadUrl;
    _fileName = fileName;
    _title.text = content.title;
    _summary.text = content.summary ?? '';
    _notes.text = content.generalNotes ?? '';
  }

  @override
  Widget build(BuildContext context) {
    // Carrega a origem uma única vez; depois a tela vive do rascunho local.
    if (_draft == null) {
      if (widget.documentId != null) {
        final doc = ref.watch(planDocumentProvider(widget.documentId!));
        return doc.when(
          loading: () => const _Loading(),
          error: (e, _) => _Message('Error: $e'),
          data: (d) {
            if (d == null) return const _Message('Documento no encontrado.');
            if (d.parsedPlan == null) {
              return _Message(
                d.status == PlanDocumentStatus.error
                    ? 'La lectura falló: ${d.errorMessage ?? 'error desconocido'}.'
                    : 'El documento todavía se está leyendo. Vuelve en un momento.',
              );
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _draft != null) return;
              setState(() => _load(
                    PlanContent.fromMap(d.kind, d.parsedPlan!),
                    userId: d.userId,
                    sourceDocumentId: d.id,
                    downloadUrl: d.downloadUrl,
                    fileName: d.fileName,
                  ));
            });
            return const _Loading();
          },
        );
      }
      final plan = ref.watch(planByIdProvider(widget.planId!));
      return plan.when(
        loading: () => const _Loading(),
        error: (e, _) => _Message('Error: $e'),
        data: (p) {
          if (p == null) return const _Message('Plan no encontrado.');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _draft != null) return;
            setState(() => _load(
                  PlanContent.fromMap(p.kind, p.content),
                  userId: p.userId,
                  sourceDocumentId: p.sourceDocumentId,
                ));
          });
          return const _Loading();
        },
      );
    }

    final draft = _draft!;
    final student = ref.watch(studentUserProvider(_targetUserId!)).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text('Revisar: ${draft.kind.labelEs}'),
        actions: [
          IconButton(
            tooltip: _preview ? 'Editar' : 'Vista del alumno',
            icon: Icon(_preview ? Icons.edit_outlined : Icons.visibility_outlined),
            onPressed: () => setState(() {
              _syncTextFields();
              _preview = !_preview;
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _publishing ? null : _confirmPublish,
        icon: _publishing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.send),
        label: Text(_publishing ? 'Publicando…' : 'Publicar'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _SourceCard(
            studentName: student?.name,
            fileName: _fileName,
            downloadUrl: _downloadUrl,
            isRepublish: widget.planId != null,
          ),
          const SizedBox(height: 12),
          if (_sourceDocumentId != null && !_preview) ...[
            ParserWarningsBanner(content: draft),
            const SizedBox(height: 16),
          ],
          if (_preview) ...[
            Text(_title.text, style: AppTextStyles.headline),
            const SizedBox(height: 8),
            PlanContentView(content: draft),
          ] else ...[
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Título del plan'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _summary,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Resumen (opcional)'),
            ),
            const SizedBox(height: 20),
            ...switch (draft) {
              WorkoutPlanContent c => _workoutEditor(c),
              DietPlanContent c => _dietEditor(c),
              MacrosPlanContent c => _macrosEditor(c),
              EvaluationContent c => _evaluationEditor(c),
              GenericContent c => _genericEditor(c),
              _ => const <Widget>[],
            },
            const SizedBox(height: 16),
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration:
                  const InputDecoration(labelText: 'Notas generales (opcional)'),
            ),
          ],
        ],
      ),
    );
  }

  void _syncTextFields() {
    final d = _draft!;
    d.title = _title.text.trim();
    d.summary = _summary.text.trim().isEmpty ? null : _summary.text.trim();
    d.generalNotes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
  }

  // --- publicar --------------------------------------------------------------

  Future<void> _confirmPublish() async {
    _syncTextFields();
    final draft = _draft!;
    if (draft.title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ponle un título al plan.')),
      );
      return;
    }
    final student = ref.read(studentUserProvider(_targetUserId!)).valueOrNull;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Publicar este plan?'),
        content: Text(
          '${student?.name ?? 'El alumno'} lo verá de inmediato en "Mis planes" '
          'y recibirá una notificación. La versión anterior queda en el historial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final coachId = ref.read(currentCoachIdProvider);
    final uid = ref.read(authStateProvider).valueOrNull;
    if (coachId == null || uid == null) return;

    setState(() => _publishing = true);
    final result = await ref.read(planRepositoryProvider).publish(
          coachId: coachId,
          userId: _targetUserId!,
          kind: draft.kind,
          title: draft.title,
          content: draft.toMap(),
          publishedBy: uid,
          sourceDocumentId: _sourceDocumentId,
        );
    if (!mounted) return;
    setState(() => _publishing = false);

    result.when(
      success: (plan) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Plan publicado (versión ${plan.currentVersion}).')),
        );
        context.pop();
      },
      failure: (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo publicar: $f')),
      ),
    );
  }

  // --- editores por tipo -----------------------------------------------------

  List<Widget> _workoutEditor(WorkoutPlanContent c) => [
        _EditorHeader(
          title: 'Sesiones',
          trailing: TextButton.icon(
            onPressed: () async {
              final r = await showFieldsSheet(context,
                  title: 'Nueva sesión',
                  fields: const [
                    FieldSpec('Nombre (ej. Día 1 · Pierna)', required: true),
                    FieldSpec('Enfoque (opcional)'),
                  ]);
              if (r == null) return;
              setState(() => c.days.add(WorkoutDay(name: r.at(0)!, focus: r.at(1))));
            },
            icon: const Icon(Icons.add),
            label: const Text('Sesión'),
          ),
        ),
        for (final day in c.days)
          _GroupCard(
            title: day.name,
            subtitle: day.focus,
            onEdit: () async {
              final r = await showFieldsSheet(context,
                  title: 'Sesión',
                  allowDelete: true,
                  fields: [
                    FieldSpec('Nombre', initial: day.name, required: true),
                    FieldSpec('Enfoque', initial: day.focus),
                    FieldSpec('Notas de la sesión', initial: day.notes, multiline: true),
                  ]);
              if (r == null) return;
              setState(() {
                if (r.deleted) {
                  c.days.remove(day);
                } else {
                  day
                    ..name = r.at(0)!
                    ..focus = r.at(1)
                    ..notes = r.at(2);
                }
              });
            },
            onAdd: () => _editExercise(day, null),
            addLabel: 'Ejercicio',
            children: [
              for (final ex in day.exercises)
                _Row(
                  title: ex.name,
                  subtitle: [
                    if (ex.prescription.isNotEmpty) ex.prescription,
                    if (ex.technique != null) ex.technique!,
                  ].join(' · '),
                  onTap: () => _editExercise(day, ex),
                ),
            ],
          ),
      ];

  Future<void> _editExercise(WorkoutDay day, WorkoutExercise? ex) async {
    final r = await showFieldsSheet(context,
        title: ex == null ? 'Nuevo ejercicio' : 'Ejercicio',
        allowDelete: ex != null,
        fields: [
          FieldSpec('Ejercicio', initial: ex?.name, required: true),
          FieldSpec('Series', initial: ex?.sets?.toString(), keyboardType: TextInputType.number),
          FieldSpec('Repeticiones (ej. 10-12)', initial: ex?.reps),
          FieldSpec('Carga (ej. 40 kg, RPE 8)', initial: ex?.load),
          FieldSpec('Descanso (segundos)', initial: ex?.restSeconds?.toString(), keyboardType: TextInputType.number),
          FieldSpec('Técnica (drop set, superserie…)', initial: ex?.technique),
          FieldSpec('Notas', initial: ex?.notes, multiline: true),
        ]);
    if (r == null) return;
    setState(() {
      if (r.deleted) {
        day.exercises.remove(ex);
        return;
      }
      final target = ex ?? WorkoutExercise(name: '');
      target
        ..name = r.at(0)!
        ..sets = r.intAt(1)
        ..reps = r.at(2)
        ..load = r.at(3)
        ..restSeconds = r.intAt(4)
        ..technique = r.at(5)
        ..notes = r.at(6);
      if (ex == null) day.exercises.add(target);
    });
  }

  List<Widget> _dietEditor(DietPlanContent c) => [
        _EditorHeader(
          title: 'Comidas',
          trailing: TextButton.icon(
            onPressed: () async {
              final r = await showFieldsSheet(context,
                  title: 'Nueva comida',
                  fields: const [
                    FieldSpec('Nombre (ej. Desayuno)', required: true),
                    FieldSpec('Hora (opcional)'),
                  ]);
              if (r == null) return;
              setState(() => c.meals.add(Meal(name: r.at(0)!, time: r.at(1))));
            },
            icon: const Icon(Icons.add),
            label: const Text('Comida'),
          ),
        ),
        for (final meal in c.meals)
          _GroupCard(
            title: meal.name,
            subtitle: meal.time,
            onEdit: () async {
              final r = await showFieldsSheet(context,
                  title: 'Comida',
                  allowDelete: true,
                  fields: [
                    FieldSpec('Nombre', initial: meal.name, required: true),
                    FieldSpec('Hora', initial: meal.time),
                    FieldSpec('Notas', initial: meal.notes, multiline: true),
                  ]);
              if (r == null) return;
              setState(() {
                if (r.deleted) {
                  c.meals.remove(meal);
                } else {
                  meal
                    ..name = r.at(0)!
                    ..time = r.at(1)
                    ..notes = r.at(2);
                }
              });
            },
            onAdd: () => _editMealItem(meal, null),
            addLabel: 'Alimento',
            children: [
              for (final item in meal.items)
                _Row(
                  title: item.food,
                  subtitle: [
                    if (item.quantity != null) item.quantity!,
                    if (item.notes != null) item.notes!,
                  ].join(' · '),
                  onTap: () => _editMealItem(meal, item),
                ),
            ],
          ),
        _GroupCard(
          title: 'Equivalencias',
          subtitle: 'Intercambios permitidos',
          onAdd: () => _editSubstitution(c, null),
          addLabel: 'Equivalencia',
          children: [
            for (var i = 0; i < c.substitutions.length; i++)
              _Row(
                title: c.substitutions[i],
                subtitle: '',
                onTap: () => _editSubstitution(c, i),
              ),
          ],
        ),
      ];

  Future<void> _editMealItem(Meal meal, MealItem? item) async {
    final r = await showFieldsSheet(context,
        title: item == null ? 'Nuevo alimento' : 'Alimento',
        allowDelete: item != null,
        fields: [
          FieldSpec('Alimento', initial: item?.food, required: true),
          FieldSpec('Cantidad (ej. 120 g, 1 taza)', initial: item?.quantity),
          FieldSpec('Notas', initial: item?.notes, multiline: true),
        ]);
    if (r == null) return;
    setState(() {
      if (r.deleted) {
        meal.items.remove(item);
        return;
      }
      final target = item ?? MealItem(food: '');
      target
        ..food = r.at(0)!
        ..quantity = r.at(1)
        ..notes = r.at(2);
      if (item == null) meal.items.add(target);
    });
  }

  Future<void> _editSubstitution(DietPlanContent c, int? index) async {
    final r = await showFieldsSheet(context,
        title: index == null ? 'Nueva equivalencia' : 'Equivalencia',
        allowDelete: index != null,
        fields: [
          FieldSpec('Texto', initial: index == null ? null : c.substitutions[index], required: true, multiline: true),
        ]);
    if (r == null) return;
    setState(() {
      if (r.deleted) {
        c.substitutions.removeAt(index!);
      } else if (index == null) {
        c.substitutions.add(r.at(0)!);
      } else {
        c.substitutions[index] = r.at(0)!;
      }
    });
  }

  List<Widget> _macrosEditor(MacrosPlanContent c) => [
        _GroupCard(
          title: 'Metas de macros',
          subtitle: 'Por tipo de día',
          onAdd: () => _editTarget(c, null),
          addLabel: 'Meta',
          children: [
            for (final t in c.targets)
              _Row(
                title: t.label,
                subtitle: [
                  if (t.kcal != null) '${_n(t.kcal!)} kcal',
                  if (t.proteinG != null) 'P ${_n(t.proteinG!)} g',
                  if (t.carbsG != null) 'C ${_n(t.carbsG!)} g',
                  if (t.fatG != null) 'G ${_n(t.fatG!)} g',
                ].join(' · '),
                onTap: () => _editTarget(c, t),
              ),
          ],
        ),
      ];

  Future<void> _editTarget(MacrosPlanContent c, MacroTarget? t) async {
    const num = TextInputType.numberWithOptions(decimal: true);
    final r = await showFieldsSheet(context,
        title: t == null ? 'Nueva meta' : 'Meta',
        allowDelete: t != null,
        fields: [
          FieldSpec('Etiqueta (ej. Día de entrenamiento)', initial: t?.label, required: true),
          FieldSpec('kcal', initial: t?.kcal?.toString(), keyboardType: num),
          FieldSpec('Proteína (g)', initial: t?.proteinG?.toString(), keyboardType: num),
          FieldSpec('Carbohidratos (g)', initial: t?.carbsG?.toString(), keyboardType: num),
          FieldSpec('Grasa (g)', initial: t?.fatG?.toString(), keyboardType: num),
          FieldSpec('Fibra (g)', initial: t?.fiberG?.toString(), keyboardType: num),
          FieldSpec('Agua (ml)', initial: t?.waterMl?.toString(), keyboardType: num),
        ]);
    if (r == null) return;
    setState(() {
      if (r.deleted) {
        c.targets.remove(t);
        return;
      }
      final target = t ?? MacroTarget(label: '');
      target
        ..label = r.at(0)!
        ..kcal = r.numAt(1)
        ..proteinG = r.numAt(2)
        ..carbsG = r.numAt(3)
        ..fatG = r.numAt(4)
        ..fiberG = r.numAt(5)
        ..waterMl = r.numAt(6);
      if (t == null) c.targets.add(target);
    });
  }

  List<Widget> _evaluationEditor(EvaluationContent c) => [
        _GroupCard(
          title: 'Mediciones',
          subtitle: c.recordedAt ?? 'Sin fecha',
          onEdit: () async {
            final r = await showFieldsSheet(context,
                title: 'Fecha de la evaluación',
                fields: [FieldSpec('Fecha', initial: c.recordedAt)]);
            if (r == null) return;
            setState(() => c.recordedAt = r.at(0));
          },
          onAdd: () => _editMetric(c, null),
          addLabel: 'Medición',
          children: [
            for (final m in c.metrics)
              _Row(
                title: m.label,
                subtitle: '${m.value}${m.unit == null ? '' : ' ${m.unit}'}',
                onTap: () => _editMetric(c, m),
              ),
          ],
        ),
      ];

  Future<void> _editMetric(EvaluationContent c, EvaluationMetric? m) async {
    final r = await showFieldsSheet(context,
        title: m == null ? 'Nueva medición' : 'Medición',
        allowDelete: m != null,
        fields: [
          FieldSpec('Medición (ej. Cintura)', initial: m?.label, required: true),
          FieldSpec('Valor', initial: m?.value, required: true),
          FieldSpec('Unidad (ej. cm, kg, %)', initial: m?.unit),
        ]);
    if (r == null) return;
    setState(() {
      if (r.deleted) {
        c.metrics.remove(m);
        return;
      }
      final target = m ?? EvaluationMetric(label: '', value: '');
      target
        ..label = r.at(0)!
        ..value = r.at(1)!
        ..unit = r.at(2);
      if (m == null) c.metrics.add(target);
    });
  }

  List<Widget> _genericEditor(GenericContent c) => [
        _GroupCard(
          title: 'Secciones',
          onAdd: () => _editSection(c, null),
          addLabel: 'Sección',
          children: [
            for (final s in c.sections)
              _Row(title: s.heading, subtitle: s.content, onTap: () => _editSection(c, s)),
          ],
        ),
      ];

  Future<void> _editSection(GenericContent c, GenericSection? s) async {
    final r = await showFieldsSheet(context,
        title: s == null ? 'Nueva sección' : 'Sección',
        allowDelete: s != null,
        fields: [
          FieldSpec('Encabezado', initial: s?.heading, required: true),
          FieldSpec('Contenido', initial: s?.content, required: true, multiline: true),
        ]);
    if (r == null) return;
    setState(() {
      if (r.deleted) {
        c.sections.remove(s);
        return;
      }
      final target = s ?? GenericSection(heading: '', content: '');
      target
        ..heading = r.at(0)!
        ..content = r.at(1)!;
      if (s == null) c.sections.add(target);
    });
  }

  static String _n(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

// --- widgets auxiliares -------------------------------------------------------

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.studentName,
    required this.fileName,
    required this.downloadUrl,
    required this.isRepublish,
  });

  final String? studentName;
  final String? fileName;
  final String? downloadUrl;
  final bool isRepublish;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.person_outline, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Para ${studentName ?? '…'}', style: AppTextStyles.title),
                  Text(
                    isRepublish
                        ? 'Editando el plan vigente · se publicará como nueva versión'
                        : fileName == null
                            ? 'Captura manual'
                            : 'Leído de $fileName',
                    style: AppTextStyles.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (downloadUrl != null)
              TextButton(
                onPressed: () => launchUrl(
                  Uri.parse(downloadUrl!),
                  mode: LaunchMode.externalApplication,
                ),
                child: const Text('Ver original'),
              ),
          ],
        ),
      ),
    );
  }
}

class _EditorHeader extends StatelessWidget {
  const _EditorHeader({required this.title, required this.trailing});

  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTextStyles.headline)),
          trailing,
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.title,
    required this.children,
    required this.onAdd,
    required this.addLabel,
    this.subtitle,
    this.onEdit,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final VoidCallback onAdd;
  final String addLabel;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.title),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Text(subtitle!, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: onEdit,
                  ),
              ],
            ),
            if (children.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Sin elementos todavía.', style: AppTextStyles.caption),
              )
            else
              ...children,
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: Text(addLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.title, required this.subtitle, required this.onTap});

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body),
                  if (subtitle.isNotEmpty)
                    Text(subtitle,
                        style: AppTextStyles.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revisar plan')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revisar plan')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(text, textAlign: TextAlign.center, style: AppTextStyles.bodyMuted),
        ),
      ),
    );
  }
}

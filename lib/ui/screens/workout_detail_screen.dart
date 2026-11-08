import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../data/daily_library.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/lift_names.dart';
import '../../models/training.dart';
import '../../services/training_store.dart';
import '../../utils/format.dart';
import '../widgets/ds.dart';
import '../widgets/training_widgets.dart';
import 'training_home.dart';

/// Texto de una serie: "80 kg × 3 @8".
String setText(WorkSet s, String unit) =>
    '${fmtWeight(s.weight)} $unit × ${s.reps}${s.rpe != null ? ' @${fmtWeight(s.rpe!)}' : ''}';

/// Lista de ejercicios y series de un entrenamiento (también la usa el coach).
class WorkoutSummaryList extends StatelessWidget {
  const WorkoutSummaryList({super.key, required this.workout, required this.store});

  final Workout workout;
  final TrainingStore store;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final u = workout.unit.label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final e in workout.exercises)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      liftIconFor(store.storage, e.lift, size: 32),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(liftDisplayName(e.lift), style: theme.textTheme.titleMedium),
                      ),
                      if (sessionFor(workout, e.lift, workout.unit) case final s?)
                        Text(
                          loc.e1rmShort(fmtWeight(s.best1Rm, maxDecimals: 1), u),
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (var i = 0; i < e.sets.length; i++)
                    Text('${i + 1}.  ${setText(e.sets[i], u)}'),
                ],
              ),
            ),
          ),
        if (workout.notes.isNotEmpty)
          Card(
            child: Padding(padding: const EdgeInsets.all(12), child: Text(workout.notes)),
          ),
      ],
    );
  }
}

/// Detalle de un entrenamiento terminado: resultado, duración, movimientos
/// del WOD y series de cada ejercicio.
class WorkoutDetailScreen extends StatelessWidget {
  const WorkoutDetailScreen({
    super.key,
    required this.store,
    required this.workoutId,
    this.justFinished = false,
  });

  final TrainingStore store;
  final String workoutId;

  /// Recién terminado: el trofeo entra con un pequeño rebote y vibra.
  final bool justFinished;

  Future<void> _delete(BuildContext context, Workout w) async {
    final loc = AppLocalizations.of(context);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(loc.workoutDeleteTitle, textAlign: TextAlign.center, style: Ds.title(ctx)),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE5484D),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(loc.delete),
              ),
              const SizedBox(height: 8),
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(loc.cancel),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return;
    await store.deleteWorkout(w.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final w = store.workouts.where((x) => x.id == workoutId).firstOrNull;
    if (w == null) return Scaffold(appBar: AppBar());
    final u = w.unit.label;
    final style = TrainingStyle.parse(w.style);
    final locale = Localizations.localeOf(context).toString();
    final date = DateFormat.MMMMEEEEd(locale).add_Hm().format(w.date.toLocal());
    final sets = w.doneSets.length;
    final volume = w.doneSets.fold<double>(0, (a, s) => a + s.weight * s.reps);

    final stats = <(String, String)>[
      if (w.durationSec > 0) (fmtDuration(w.durationSec), loc.detailDuration),
      if (sets > 0) ('$sets', loc.planSets),
      if (volume > 0) ('${fmtWeight(volume, maxDecimals: 0)} $u', loc.metricVolume),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(w.title.isEmpty ? loc.workoutFree : w.title),
        actions: [
          PopupMenuButton<String>(
            tooltip: loc.edit,
            icon: const Icon(Icons.more_horiz),
            onSelected: (_) => _delete(context, w),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline, color: Color(0xFFE5484D)),
                    const SizedBox(width: 10),
                    Text(loc.delete, style: const TextStyle(color: Color(0xFFE5484D))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // ── Encabezado ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(Ds.gutter, 4, Ds.gutter, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (style != null)
                      DsPill(styleName(loc, style).toUpperCase(), color: styleColor(style)),
                    if (w.format?.isNotEmpty == true) DsPill(w.format!, color: Ds.muted(context)),
                  ],
                ),
                if (style != null || w.format?.isNotEmpty == true) const SizedBox(height: 12),
                Text(w.title.isEmpty ? loc.workoutFree : w.title, style: Ds.display(context)),
                const SizedBox(height: 4),
                Text(date, style: Ds.secondary(context)),
              ],
            ),
          ),

          // ── Resultado ──────────────────────────────────────────────────
          if (w.score?.isNotEmpty == true) ...[
            const SizedBox(height: 20),
            DsBlock(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.detailResult.toUpperCase(), style: Ds.label(context)),
                        const SizedBox(height: 6),
                        Text(w.score!, style: Ds.display(context).copyWith(fontSize: 44)),
                      ],
                    ),
                  ),
                  _Trophy(animate: justFinished),
                ],
              ),
            ),
          ],

          // ── Números ────────────────────────────────────────────────────
          if (stats.isNotEmpty) ...[
            const SizedBox(height: 12),
            DsBlock(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: DsStatStrip(stats: stats),
            ),
          ],

          // ── Movimientos del WOD ───────────────────────────────────────
          if (w.wodLines.isNotEmpty) ...[
            DsSection(loc.detailMovements),
            DsBlock(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < w.wodLines.length; i++)
                    _LineRow(line: w.wodLines[i], first: i == 0),
                ],
              ),
            ),
          ],

          // ── Ejercicios con series ─────────────────────────────────────
          if (w.exercises.isNotEmpty) DsSection(loc.detailExercises),
          for (final e in w.exercises) ...[
            _ExerciseBlock(workout: w, log: e),
            const SizedBox(height: 12),
          ],

          // ── Notas ──────────────────────────────────────────────────────
          if (w.notes.isNotEmpty) ...[
            DsSection(loc.workoutNotes),
            DsBlock(child: Text(w.notes, style: Ds.body(context))),
          ],
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line, required this.first});

  final WodLine line;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: Ds.hairline(context))),
      ),
      child: Row(
        children: [
          if (line.reps.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 64),
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  line.reps,
                  style: Ds.body(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800, fontFeatures: Ds.tabular),
                ),
              ),
            ),
          Expanded(child: Text(liftDisplayName(line.lift), style: Ds.body(context))),
          if (line.load != null)
            Text(
              line.load!,
              style: Ds.body(
                context,
              ).copyWith(fontWeight: FontWeight.w700, fontFeatures: Ds.tabular),
            ),
        ],
      ),
    );
  }
}

/// Un ejercicio con sus series; la serie más pesada va marcada.
class _ExerciseBlock extends StatelessWidget {
  const _ExerciseBlock({required this.workout, required this.log});

  final Workout workout;
  final ExerciseLog log;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final u = workout.unit.label;
    final best = sessionFor(workout, log.lift, workout.unit);
    final heaviest = log.sets.isEmpty
        ? null
        : log.sets.reduce((a, b) => b.weight > a.weight ? b : a);

    return DsBlock(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(liftDisplayName(log.lift), style: Ds.title(context))),
              if (best != null && best.best1Rm > 0)
                DsPill(loc.e1rmShort(fmtWeight(best.best1Rm, maxDecimals: 1), u)),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < log.sets.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Ds.hairline(context))),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${i + 1}',
                      style: Ds.secondary(context).copyWith(fontFeatures: Ds.tabular),
                    ),
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: log.sets[i].weight > 0 ? fmtWeight(log.sets[i].weight) : '—',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(
                            text: log.sets[i].weight > 0 ? ' $u' : '',
                            style: Ds.secondary(context),
                          ),
                          TextSpan(text: '  ×  ${log.sets[i].reps}'),
                        ],
                      ),
                      style: Ds.body(context).copyWith(fontFeatures: Ds.tabular),
                    ),
                  ),
                  if (log.sets[i].rpe != null)
                    Text('RPE ${fmtWeight(log.sets[i].rpe!)}', style: Ds.secondary(context)),
                  if (identical(log.sets[i], heaviest) && log.sets.length > 1) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFB020)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Trofeo del resultado. Si [animate], entra con rebote y una vibración.
class _Trophy extends StatefulWidget {
  const _Trophy({required this.animate});

  final bool animate;

  @override
  State<_Trophy> createState() => _TrophyState();
}

class _TrophyState extends State<_Trophy> {
  @override
  void initState() {
    super.initState();
    if (widget.animate) HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    const icon = Icon(Icons.emoji_events_rounded, color: Color(0xFFFFB020), size: 40);
    if (!widget.animate || MediaQuery.disableAnimationsOf(context)) return icon;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (_, t, c) => Transform.scale(scale: 0.4 + 0.6 * t, child: c),
      child: icon,
    );
  }
}

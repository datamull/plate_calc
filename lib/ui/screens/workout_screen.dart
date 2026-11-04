import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/lift_names.dart';
import '../../models/training.dart';
import '../../services/plate_calculator.dart';
import '../../services/training_store.dart';
import '../../utils/format.dart';
import '../widgets/result_sheet.dart';
import '../widgets/share_code.dart';
import '../widgets/training_widgets.dart';

/// Registro de un entrenamiento en curso: series, pesos, repeticiones,
/// descanso entre series y calculadora de discos por serie.
class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key, required this.store, required this.workout});

  final TrainingStore store;
  final Workout workout;

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  TrainingStore get _store => widget.store;
  Workout get _w => widget.workout;

  Timer? _ticker;
  int _elapsed = 0;

  /// Segundos de descanso que quedan (null = sin descanso activo).
  int? _rest;

  @override
  void initState() {
    super.initState();
    _elapsed = DateTime.now().difference(_w.date).inSeconds.clamp(0, 1 << 30);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _store.saveDraft(_w);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      _elapsed = DateTime.now().difference(_w.date).inSeconds;
      if (_rest != null) {
        _rest = _rest! - 1;
        if (_rest! <= 0) {
          _rest = null;
          HapticFeedback.heavyImpact();
          SystemSound.play(SystemSoundType.alert);
        }
      }
    });
  }

  void _changed() {
    setState(() {});
    _store.saveDraft(_w);
  }

  void _toggleDone(WorkSet s) {
    s.done = !s.done;
    if (s.done) {
      HapticFeedback.lightImpact();
      _rest = _store.restSeconds;
    }
    _changed();
  }

  Future<void> _addExercise() async {
    final lift = await pickExercise(context, _store);
    if (lift == null || lift.trim().isEmpty) return;
    _w.exercises.add(ExerciseLog(lift: lift.trim(), sets: [WorkSet(reps: 5)]));
    _changed();
  }

  void _showPlates(WorkSet s) {
    final loc = AppLocalizations.of(context);
    final settings = _store.storage.settings(_w.unit);
    final result = computePlates(
      target: s.weight,
      barWeight: settings.barWeight,
      collarsWeight: settings.collarsWeight,
      plates: settings.plates,
    );
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.errorTargetTooLow)));
      return;
    }
    showResultSheet(context, result: result, unit: _w.unit);
  }

  Future<void> _pickRest() async {
    final loc = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(loc.restDefault, style: Theme.of(ctx).textTheme.titleMedium),
            for (final s in const [30, 60, 90, 120, 180, 240, 300])
              ListTile(
                title: Text(fmtDuration(s)),
                trailing: s == _store.restSeconds ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(ctx).pop(s),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await _store.setRestSeconds(picked);
      setState(() => _rest = _rest == null ? null : picked);
    }
  }

  Future<void> _finish() async {
    final loc = AppLocalizations.of(context);
    if (_w.doneSets.isEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(loc.workoutNoSetsTitle),
          content: Text(loc.workoutNoSetsBody),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.cancel)),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.workoutDiscard)),
          ],
        ),
      );
      if (ok == true) await _discard(confirm: false);
      return;
    }
    // Solo se guardan las series hechas.
    for (final e in _w.exercises) {
      e.sets.removeWhere((s) => !s.done);
    }
    _w.exercises.removeWhere((e) => e.sets.isEmpty);
    _w.durationSec = _elapsed;
    final prs = await _store.finish(_w);
    if (!mounted) return;
    await showWorkoutSummary(context, store: _store, workout: _w, records: prs);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _discard({bool confirm = true}) async {
    final loc = AppLocalizations.of(context);
    if (confirm) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(loc.workoutDiscardTitle),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.cancel)),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.workoutDiscard)),
          ],
        ),
      );
      if (ok != true) return;
    }
    await _store.saveDraft(null);
    if (mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final title = _w.title.isEmpty ? loc.workoutFree : _w.title;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, overflow: TextOverflow.ellipsis),
            Text(
              '⏱ ${fmtDuration(_elapsed)}${_w.planName != null ? '  ·  ${_w.planName}' : ''}',
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'rest') _pickRest();
              if (v == 'discard') _discard();
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'rest', child: Text(loc.restDefault)),
              PopupMenuItem(value: 'discard', child: Text(loc.workoutDiscard)),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 120),
        children: [
          for (final e in _w.exercises)
            _ExerciseCard(
              key: ObjectKey(e),
              log: e,
              store: _store,
              unitLabel: _w.unit.label,
              onChanged: _changed,
              onToggle: _toggleDone,
              onPlates: _store.isBarbell(e.lift) ? _showPlates : null,
              onRemove: () {
                _w.exercises.remove(e);
                _changed();
              },
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: Text(loc.workoutAddExercise),
            onPressed: _addExercise,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _w.notes,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: loc.workoutNotes,
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) {
              _w.notes = v;
              _store.saveDraft(_w);
            },
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.flag),
            label: Text(loc.workoutFinish),
            onPressed: _finish,
          ),
        ],
      ),
      bottomNavigationBar: _rest == null
          ? null
          : SafeArea(
              child: Material(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${loc.restLabel} ${fmtDuration(_rest!)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      TextButton(
                        style: _compact,
                        onPressed: () => setState(() => _rest = (_rest! - 15).clamp(1, 3600)),
                        child: const Text('−15'),
                      ),
                      TextButton(
                        style: _compact,
                        onPressed: () => setState(() => _rest = _rest! + 15),
                        child: const Text('+15'),
                      ),
                      IconButton(
                        tooltip: loc.restSkip,
                        icon: const Icon(Icons.skip_next),
                        onPressed: () => setState(() => _rest = null),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

final _compact = TextButton.styleFrom(
  minimumSize: const Size(44, 40),
  padding: const EdgeInsets.symmetric(horizontal: 8),
  visualDensity: VisualDensity.compact,
);

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    super.key,
    required this.log,
    required this.store,
    required this.unitLabel,
    required this.onChanged,
    required this.onToggle,
    required this.onPlates,
    required this.onRemove,
  });

  final ExerciseLog log;
  final TrainingStore store;
  final String unitLabel;
  final VoidCallback onChanged;
  final void Function(WorkSet) onToggle;
  final void Function(WorkSet)? onPlates;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                liftIconFor(store.storage, log.lift, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(liftDisplayName(log.lift), style: theme.textTheme.titleMedium),
                      if (log.percent != null)
                        Text(loc.workoutPercentOfRm(fmtWeight(log.percent!)), style: muted),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: loc.workoutRemoveExercise,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onRemove,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 8),
              child: Row(
                children: [
                  SizedBox(width: 28, child: Text('#', style: muted)),
                  Expanded(flex: 3, child: Text(unitLabel, style: muted)),
                  Expanded(flex: 2, child: Text(loc.workoutReps, style: muted)),
                  Expanded(flex: 2, child: Text('RPE', style: muted)),
                  const SizedBox(width: 88),
                ],
              ),
            ),
            for (var i = 0; i < log.sets.length; i++)
              _SetRow(
                key: ObjectKey(log.sets[i]),
                index: i + 1,
                set: log.sets[i],
                onChanged: onChanged,
                onToggle: () => onToggle(log.sets[i]),
                onPlates: onPlates == null ? null : () => onPlates!(log.sets[i]),
                onRemove: log.sets.length > 1
                    ? () {
                        log.sets.removeAt(i);
                        onChanged();
                      }
                    : null,
              ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: Text(loc.workoutAddSet),
              onPressed: () {
                final last = log.sets.isEmpty ? WorkSet(reps: 5) : log.sets.last;
                log.sets.add(WorkSet(reps: last.reps, weight: last.weight));
                onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    super.key,
    required this.index,
    required this.set,
    required this.onChanged,
    required this.onToggle,
    required this.onPlates,
    required this.onRemove,
  });

  final int index;
  final WorkSet set;
  final VoidCallback onChanged;
  final VoidCallback onToggle;
  final VoidCallback? onPlates;
  final VoidCallback? onRemove;

  InputDecoration get _dec => const InputDecoration(
    isDense: true,
    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    border: OutlineInputBorder(),
  );

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('$index')),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: TextFormField(
                initialValue: set.weight > 0 ? fmtWeight(set.weight) : '',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _dec,
                onChanged: (v) {
                  set.weight = parseNumber(v) ?? 0;
                  onChanged();
                },
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: TextFormField(
                initialValue: set.reps > 0 ? '${set.reps}' : '',
                keyboardType: TextInputType.number,
                decoration: _dec,
                onChanged: (v) {
                  set.reps = int.tryParse(v.trim()) ?? 0;
                  onChanged();
                },
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: set.rpe != null ? fmtWeight(set.rpe!) : '',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _dec,
              onChanged: (v) {
                final r = parseNumber(v);
                set.rpe = (r != null && r > 0 && r <= 10) ? r : null;
                onChanged();
              },
            ),
          ),
          SizedBox(
            width: 44,
            child: onPlates == null
                ? null
                : IconButton(
                    tooltip: loc.workoutPlates,
                    icon: const Icon(Icons.fitness_center, size: 20),
                    onPressed: onPlates,
                  ),
          ),
          SizedBox(
            width: 44,
            child: IconButton(
              tooltip: loc.workoutSetDone,
              icon: Icon(
                set.done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: set.done ? Colors.green : scheme.onSurfaceVariant,
              ),
              onPressed: onToggle,
            ),
          ),
        ],
      ),
    );
    if (onRemove == null) return row;
    return Dismissible(
      key: ObjectKey(set),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: scheme.errorContainer,
        child: const Icon(Icons.delete_outline),
      ),
      onDismissed: (_) => onRemove!(),
      child: row,
    );
  }
}

/// Resumen al terminar: récords nuevos y, si el plan vino de un coach,
/// opción de enviarle el resultado.
Future<void> showWorkoutSummary(
  BuildContext context, {
  required TrainingStore store,
  required Workout workout,
  required List<PersonalRecord> records,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final loc = AppLocalizations.of(ctx);
      final sets = workout.doneSets.length;
      final volume = workout.doneSets.fold<double>(0, (a, s) => a + s.weight * s.reps);
      return AlertDialog(
        title: Text(records.isEmpty ? loc.summaryTitle : loc.summaryTitlePr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.summaryStats(sets, fmtWeight(volume, maxDecimals: 0), workout.unit.label)),
            Text('⏱ ${fmtDuration(workout.durationSec)}'),
            for (final r in records) ...[
              const SizedBox(height: 8),
              Text(
                '🏆 ${liftDisplayName(r.lift)}: ${r.kind == RecordKind.heaviest ? loc.prHeaviest(fmtWeight(r.value), r.unit.label) : loc.prEstimated(fmtWeight(r.value, maxDecimals: 1), r.unit.label)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
        actions: [
          if (workout.coach != null)
            TextButton.icon(
              icon: const Icon(Icons.send),
              label: Text(loc.sendToCoach),
              onPressed: () => shareResultWithCoach(ctx, store, workout),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.ok)),
        ],
      );
    },
  );
}

/// Pide el nombre del alumno (una vez) y muestra el código del resultado.
Future<void> shareResultWithCoach(BuildContext context, TrainingStore store, Workout w) async {
  final loc = AppLocalizations.of(context);
  var name = store.athleteName;
  if (name.isEmpty) {
    final ctrl = TextEditingController();
    final entered = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.athleteNameTitle),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: loc.athleteNameHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: Text(loc.ok)),
        ],
      ),
    );
    if (entered == null || entered.trim().isEmpty) return;
    name = entered.trim();
    await store.setAthleteName(name);
  }
  if (!context.mounted) return;
  await showShareCodeSheet(
    context,
    title: loc.resultShareTitle,
    subtitle: loc.resultShareSubtitle(w.coach ?? ''),
    code: ShareCode.encodeResult(name, w),
  );
}

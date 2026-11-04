import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/lift_names.dart';
import '../../models/training.dart';
import '../../services/training_store.dart';
import '../../utils/format.dart';
import '../widgets/training_widgets.dart';

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

class WorkoutDetailScreen extends StatelessWidget {
  const WorkoutDetailScreen({super.key, required this.store, required this.workoutId});

  final TrainingStore store;
  final String workoutId;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final w = store.workouts.where((x) => x.id == workoutId).firstOrNull;
    if (w == null) return Scaffold(appBar: AppBar());
    return Scaffold(
      appBar: AppBar(
        title: Text(w.title.isEmpty ? loc.workoutFree : w.title),
        actions: [
          IconButton(
            tooltip: loc.delete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(loc.workoutDeleteTitle),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.cancel)),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.delete)),
                  ],
                ),
              );
              if (ok != true) return;
              await store.deleteWorkout(w.id);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(
            '${fmtDateTime(w.date)}${w.durationSec > 0 ? '  ·  ⏱ ${fmtDuration(w.durationSec)}' : ''}'
            '${w.planName != null ? '\n${w.planName}' : ''}',
          ),
          const SizedBox(height: 8),
          WorkoutSummaryList(workout: w, store: store),
        ],
      ),
    );
  }
}

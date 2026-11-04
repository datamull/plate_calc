import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/lift_names.dart';
import '../../models/weight_unit.dart';
import '../../services/training_store.dart';
import '../../utils/format.dart';
import '../theme/app_theme.dart';
import '../widgets/training_widgets.dart';
import 'workout_detail_screen.dart';

/// Pestaña Progreso: racha, calendario, RM estimado y récords por ejercicio.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, required this.store, this.onGoTrain});

  final TrainingStore store;

  /// Lleva a la pestaña Entrenar (se muestra si aún no hay entrenamientos).
  final VoidCallback? onGoTrain;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  final _calcWeight = TextEditingController();
  final _calcReps = TextEditingController();

  @override
  void dispose() {
    _calcWeight.dispose();
    _calcReps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final store = widget.store;
    final unit = store.storage.listUnit;
    final workouts = store.workouts;
    final now = DateTime.now();
    final thisMonth = workouts
        .where((w) => w.date.toLocal().year == now.year && w.date.toLocal().month == now.month)
        .length;
    final lifts = trainedLifts(workouts);

    final w = parseNumber(_calcWeight.text) ?? 0;
    final r = int.tryParse(_calcReps.text.trim()) ?? 0;
    final est = estimate1Rm(w, r);

    Widget section(String title, String help) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(
            help,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(loc.tabProgress)),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
        children: [
          if (workouts.isEmpty)
            Card(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.show_chart),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            loc.progressIntroTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(loc.progressIntroBody),
                    if (widget.onGoTrain != null) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        icon: const Icon(Icons.fitness_center),
                        label: Text(loc.progressGoTrain),
                        onPressed: widget.onGoTrain,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          section(loc.progressConsistencyTitle, loc.progressConsistencyHelp),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: StatTile(
                    icon: Icons.local_fire_department,
                    value: '${weekStreak(workouts)}',
                    label: loc.statStreak,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatTile(
                    icon: Icons.calendar_month,
                    value: '$thisMonth',
                    label: loc.statThisMonth,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatTile(
                    icon: Icons.fitness_center,
                    value: '${workouts.length}',
                    label: loc.statTotal,
                  ),
                ),
              ],
            ),
          ),
          section(loc.progressCalendarTitle, loc.progressCalendarHelp),
          _Calendar(
            month: _month,
            trained: trainedDays(workouts),
            onMonth: (m) => setState(() => _month = m),
            onDay: (day) {
              final match = workouts.where((x) {
                final d = x.date.toLocal();
                return d.year == day.year && d.month == day.month && d.day == day.day;
              });
              if (match.isEmpty) return;
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => WorkoutDetailScreen(store: store, workoutId: match.first.id),
                ),
              );
            },
          ),
          section(loc.recordsTitle, loc.progressRecordsHelp),
          if (lifts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(loc.recordsEmpty),
            ),
          for (final lift in lifts)
            Builder(
              builder: (context) {
                final hist = liftHistory(workouts, lift, unit);
                final heavy = hist.map((s) => s.heaviest).fold(0.0, math.max);
                final best = hist.map((s) => s.best1Rm).fold(0.0, math.max);
                return Card(
                  child: ListTile(
                    leading: liftIconFor(store.storage, lift, size: 36),
                    title: Text(liftDisplayName(lift)),
                    subtitle: Text(
                      '${loc.recordHeaviest(fmtWeight(heavy), unit.label)} · '
                      '${loc.e1rmShort(fmtWeight(best, maxDecimals: 1), unit.label)}',
                    ),
                    trailing: const Icon(Icons.show_chart),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LiftProgressScreen(store: store, lift: lift, unit: unit),
                      ),
                    ),
                  ),
                );
              },
            ),
          section(loc.e1rmCalcTitle, loc.e1rmCalcHelp),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _calcWeight,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: loc.e1rmWeight,
                            suffixText: unit.label,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _calcReps,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: loc.workoutReps,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    est > 0
                        ? loc.e1rmResult(fmtWeight(est, maxDecimals: 1), unit.label)
                        : loc.e1rmExample(
                            unit == WeightUnit.kg ? '100 kg' : '225 lb',
                            unit == WeightUnit.kg ? '117 kg' : '263 lb',
                          ),
                    style: est > 0
                        ? theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)
                        : theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.month,
    required this.trained,
    required this.onMonth,
    required this.onDay,
  });

  final DateTime month;
  final Set<DateTime> trained;
  final ValueChanged<DateTime> onMonth;
  final ValueChanged<DateTime> onDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ml = MaterialLocalizations.of(context);
    final first = DateTime(month.year, month.month);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final offset = first.weekday - 1; // lunes = 0
    // narrowWeekdays empieza en domingo; se rota para empezar en lunes.
    final names = [...ml.narrowWeekdays.skip(1), ml.narrowWeekdays.first];
    final today = DateTime.now();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => onMonth(DateTime(month.year, month.month - 1)),
                ),
                Expanded(
                  child: Text(
                    ml.formatMonthYear(first),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => onMonth(DateTime(month.year, month.month + 1)),
                ),
              ],
            ),
            Row(
              children: [
                for (final n in names)
                  Expanded(
                    child: Text(n, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            for (var week = 0; week * 7 < offset + days; week++)
              Row(
                children: [
                  for (var c = 0; c < 7; c++)
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final n = week * 7 + c - offset + 1;
                          if (n < 1 || n > days) return const SizedBox(height: 38);
                          final date = DateTime(month.year, month.month, n);
                          final on = trained.contains(date);
                          final isToday =
                              date.year == today.year &&
                              date.month == today.month &&
                              date.day == today.day;
                          return InkWell(
                            customBorder: const CircleBorder(),
                            onTap: on ? () => onDay(date) : null,
                            child: Container(
                              height: 38,
                              margin: const EdgeInsets.all(2),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: on ? AppColors.brandGradient : null,
                                border: isToday
                                    ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                                    : null,
                              ),
                              child: Text(
                                '$n',
                                style: TextStyle(
                                  color: on ? Colors.white : null,
                                  fontWeight: on ? FontWeight.w700 : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

enum _Metric { estimated, heaviest, volume }

/// Progreso de un ejercicio: gráfico y sesiones.
class LiftProgressScreen extends StatefulWidget {
  const LiftProgressScreen({
    super.key,
    required this.store,
    required this.lift,
    required this.unit,
  });

  final TrainingStore store;
  final String lift;
  final WeightUnit unit;

  @override
  State<LiftProgressScreen> createState() => _LiftProgressScreenState();
}

class _LiftProgressScreenState extends State<LiftProgressScreen> {
  _Metric _metric = _Metric.estimated;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final u = widget.unit.label;
    final hist = liftHistory(widget.store.workouts, widget.lift, widget.unit);
    final values = [
      for (final s in hist)
        switch (_metric) {
          _Metric.estimated => s.best1Rm,
          _Metric.heaviest => s.heaviest,
          _Metric.volume => s.volume,
        },
    ];
    final rm = widget.store.storage.lastRm(widget.lift, widget.unit);

    return Scaffold(
      appBar: AppBar(title: Text(liftDisplayName(widget.lift))),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (rm != null) Text(loc.currentRm(fmtWeight(rm), u), style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          SegmentedButton<_Metric>(
            segments: [
              ButtonSegment(value: _Metric.estimated, label: Text(loc.metricE1rm)),
              ButtonSegment(value: _Metric.heaviest, label: Text(loc.metricHeaviest)),
              ButtonSegment(value: _Metric.volume, label: Text(loc.metricVolume)),
            ],
            selected: {_metric},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _metric = s.first),
          ),
          const SizedBox(height: 16),
          if (values.length < 2)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(loc.chartNeedsMore, textAlign: TextAlign.center),
            )
          else
            SimpleLineChart(
              values: values,
              labels: [for (final s in hist) shortDate(s.date)],
              color: _metric == _Metric.volume ? AppColors.purple : AppColors.blue,
            ),
          const SizedBox(height: 16),
          for (final s in hist.reversed)
            ListTile(
              dense: true,
              title: Text(fmtDateTime(s.date)),
              subtitle: Text(
                '${loc.recordHeaviest(fmtWeight(s.heaviest), u)} · '
                '${loc.e1rmShort(fmtWeight(s.best1Rm, maxDecimals: 1), u)} · '
                '${loc.metricVolume}: ${fmtWeight(s.volume, maxDecimals: 0)} $u',
              ),
            ),
        ],
      ),
    );
  }
}

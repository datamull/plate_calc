import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/daily_library.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/lift_names.dart';
import '../../models/training.dart';
import '../../models/weight_unit.dart';
import '../../services/training_store.dart';
import '../../utils/format.dart';
import '../theme/app_theme.dart';
import '../widgets/ds.dart';
import 'training_home.dart';
import 'workout_detail_screen.dart';

/// Progreso: constancia (12 semanas), un gráfico por ejercicio y récords.
/// Poco texto: números grandes y gráficos con ejes legibles.
class ProgressView extends StatefulWidget {
  const ProgressView({super.key, required this.store});

  final TrainingStore store;

  @override
  State<ProgressView> createState() => _ProgressViewState();
}

enum _Metric { estimated, heaviest }

class _ProgressViewState extends State<ProgressView> {
  String? _lift;
  _Metric _metric = _Metric.estimated;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final store = widget.store;
    final unit = store.storage.listUnit;
    final workouts = store.workouts;

    if (workouts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insights, size: 48, color: Ds.muted(context)),
              const SizedBox(height: 12),
              Text(loc.progressEmpty, textAlign: TextAlign.center, style: Ds.secondary(context)),
            ],
          ),
        ),
      );
    }

    final lifts = trainedLifts(workouts);
    final lift = lifts.contains(_lift) ? _lift : lifts.firstOrNull;
    final wods = workouts.where((w) => w.score?.isNotEmpty == true).take(5).toList();

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      children: [
        DsFadeIn(child: _ConsistencyCard(workouts: workouts)),
        if (lift != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final l in lifts)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: DsChip(
                      label: liftDisplayName(l),
                      selected: l == lift,
                      onTap: () => setState(() => _lift = l),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          DsFadeIn(
            index: 1,
            child: _LiftChartCard(
              history: liftHistory(workouts, lift, unit),
              unit: unit,
              metric: _metric,
              onMetric: (m) => setState(() => _metric = m),
            ),
          ),
        ],
        if (lifts.isNotEmpty) ...[
          DsSection(loc.recordsTitle),
          DsBlock(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Column(
              children: [
                for (final l in lifts)
                  _RecordRow(
                    lift: l,
                    history: liftHistory(workouts, l, unit),
                    unit: unit,
                    last: l == lifts.last,
                  ),
              ],
            ),
          ),
        ],
        if (wods.isNotEmpty) ...[
          DsSection(loc.wodResultsTitle),
          DsBlock(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Column(
              children: [
                for (final w in wods)
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => WorkoutDetailScreen(store: store, workoutId: w.id),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: w == wods.last
                            ? null
                            : Border(bottom: BorderSide(color: Ds.hairline(context))),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: styleColor(
                                TrainingStyle.parse(w.style) ?? TrainingStyle.crossfit,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              w.title,
                              style: Ds.body(context).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            w.score!,
                            style: Ds.body(
                              context,
                            ).copyWith(fontWeight: FontWeight.w800, fontFeatures: Ds.tabular),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Racha + barras de entrenamientos por semana (últimas 12).
class _ConsistencyCard extends StatelessWidget {
  const _ConsistencyCard({required this.workouts});

  final List<Workout> workouts;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final counts = List<int>.filled(12, 0);
    for (final w in workouts) {
      final d = w.date.toLocal();
      final day = DateTime(d.year, d.month, d.day);
      final weeksAgo =
          (DateTime.utc(monday.year, monday.month, monday.day)
                      .difference(DateTime.utc(day.year, day.month, day.day - (day.weekday - 1)))
                      .inDays /
                  7)
              .round();
      if (weeksAgo >= 0 && weeksAgo < 12) counts[11 - weeksAgo]++;
    }
    final maxY = math.max(3, counts.reduce(math.max)).toDouble();
    final streak = weekStreak(workouts);
    final thisWeek = counts.last;

    return DsBlock(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _BigNumber(
                  value: '$streak',
                  label: loc.statStreak,
                  icon: Icons.local_fire_department,
                  color: const Color(0xFFFF7A3D),
                ),
              ),
              Expanded(
                child: _BigNumber(
                  value: '$thisWeek',
                  label: loc.statThisWeek,
                  icon: Icons.bolt,
                  color: AppColors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 96,
            child: BarChart(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceBetween,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF2A303B),
                    getTooltipItem: (g, _, rod, _) => BarTooltipItem(
                      '${rod.toY.toInt()}',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(),
                  rightTitles: AxisTitles(),
                  topTitles: AxisTitles(),
                  bottomTitles: AxisTitles(),
                ),
                barGroups: [
                  for (var i = 0; i < 12; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: counts[i] == 0 ? 0.12 : counts[i].toDouble(),
                          width: 16,
                          borderRadius: BorderRadius.circular(6),
                          color: counts[i] == 0
                              ? Ds.hairline(context)
                              : (i == 11 ? AppColors.blue : AppColors.blue.withValues(alpha: 0.32)),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: Ds.hairline(context).withValues(alpha: 0.04),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  loc.chartWeeksAgo(11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Ds.secondary(context).copyWith(fontSize: 12),
                ),
              ),
              Expanded(
                child: Text(
                  loc.chartThisWeek,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: Ds.secondary(context).copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BigNumber extends StatelessWidget {
  const _BigNumber({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(value, style: Ds.display(context).copyWith(fontSize: 44, letterSpacing: -1.5)),
            const SizedBox(width: 6),
            Icon(icon, color: color, size: 22),
          ],
        ),
        Text(label, style: Ds.secondary(context)),
      ],
    );
  }
}

/// Gráfico de un ejercicio: número grande arriba, cambio y línea con fechas.
class _LiftChartCard extends StatelessWidget {
  const _LiftChartCard({
    required this.history,
    required this.unit,
    required this.metric,
    required this.onMetric,
  });

  final List<LiftSession> history;
  final WeightUnit unit;
  final _Metric metric;
  final ValueChanged<_Metric> onMetric;

  double _v(LiftSession s) => metric == _Metric.estimated ? s.best1Rm : s.heaviest;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final values = [for (final s in history) _v(s)];
    final best = values.isEmpty ? 0.0 : values.reduce(math.max);
    final change = values.length < 2 ? null : values.last - values.first;

    return DsBlock(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric == _Metric.estimated ? loc.metricE1rmLong : loc.metricHeaviestLong,
                      style: Ds.secondary(context),
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: fmtWeight(best, maxDecimals: 1),
                            style: Ds.display(context),
                          ),
                          TextSpan(text: ' ${unit.label}', style: Ds.secondary(context)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (change != null)
                DsPill(
                  '${change >= 0 ? '+' : ''}${fmtWeight(change, maxDecimals: 1)} ${unit.label}',
                  color: change >= 0 ? Ds.done : const Color(0xFFE5484D),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (history.length < 2)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  loc.chartNeedsMore,
                  textAlign: TextAlign.center,
                  style: Ds.secondary(context),
                ),
              ),
            )
          else
            SizedBox(height: 210, child: _line(context, values, locale)),
          const SizedBox(height: 12),
          Row(
            children: [
              _MetricChip(
                label: loc.metricE1rm,
                on: metric == _Metric.estimated,
                onTap: () => onMetric(_Metric.estimated),
              ),
              const SizedBox(width: 8),
              _MetricChip(
                label: loc.metricHeaviest,
                on: metric == _Metric.heaviest,
                onTap: () => onMetric(_Metric.heaviest),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, List<double> values, String locale) {
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    final pad = math.max((hi - lo) * 0.25, unit == WeightUnit.kg ? 2.5 : 5);
    final minY = (lo - pad).floorToDouble();
    final maxY = (hi + pad).ceilToDouble();
    final step = ((maxY - minY) / 3).ceilToDouble();
    final n = values.length;
    final labelEvery = math.max(1, (n / 3).ceil());
    final dateFmt = DateFormat.MMMd(locale);
    final gridColor = Ds.hairline(context);

    return LineChart(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      LineChartData(
        minY: minY,
        maxY: maxY,
        minX: 0,
        maxX: (n - 1).toDouble(),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: step,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: gridColor, strokeWidth: 1, dashArray: const [3, 4]),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: step,
              getTitlesWidget: (v, meta) {
                if (v == meta.max || v == meta.min) return const SizedBox();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    fmtWeight(v, maxDecimals: 0),
                    style: Ds.secondary(context).copyWith(fontSize: 12, fontFeatures: Ds.tabular),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (v != i || (i % labelEvery != 0 && i != n - 1)) return const SizedBox();
                if (i != n - 1 && n - 1 - i < labelEvery) return const SizedBox();
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    dateFmt.format(history[i].date.toLocal()),
                    style: Ds.secondary(context).copyWith(fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF2A303B),
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${fmtWeight(s.y, maxDecimals: 1)} ${unit.label}\n',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                  children: [
                    TextSpan(
                      text: dateFmt.format(history[s.x.toInt()].date.toLocal()),
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < n; i++) FlSpot(i.toDouble(), values[i])],
            isCurved: true,
            preventCurveOverShooting: true,
            color: AppColors.blue,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              checkToShowDot: (spot, _) => spot.x == n - 1 || n <= 8,
              getDotPainter: (spot, _, _, i) => FlDotCirclePainter(
                radius: i == n - 1 ? 5 : 2.5,
                color: AppColors.blue,
                strokeWidth: i == n - 1 ? 3 : 0,
                strokeColor: DsBlock.color(context),
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.blue.withValues(alpha: 0.22),
                  AppColors.blue.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.on, required this.onTap});

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DsChip(
    label: label,
    selected: on,
    onTap: onTap,
    color: Theme.of(context).colorScheme.onSurface,
  );
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.lift,
    required this.history,
    required this.unit,
    required this.last,
  });

  final String lift;
  final List<LiftSession> history;
  final WeightUnit unit;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final best = history.reduce((a, b) => b.heaviest > a.heaviest ? b : a);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: Ds.hairline(context))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  liftDisplayName(lift),
                  style: Ds.body(context).copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  DateFormat.yMMMd(locale).format(best.date.toLocal()),
                  style: Ds.secondary(context),
                ),
              ],
            ),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: fmtWeight(best.heaviest),
                  style: Ds.title(context).copyWith(fontFeatures: Ds.tabular),
                ),
                TextSpan(text: ' ${unit.label}', style: Ds.secondary(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

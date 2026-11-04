import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/daily_library.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/lift_names.dart';
import '../../models/training.dart';
import '../../models/weight_unit.dart';
import '../../services/training_store.dart';
import '../../utils/format.dart';
import '../theme/app_theme.dart';
import '../widgets/ds.dart';
import 'board_scan.dart';
import 'progress_screen.dart';
import 'wod_screen.dart';
import 'workout_detail_screen.dart';
import 'workout_screen.dart';

/// Color de cada estilo (solo en etiquetas y puntos).
Color styleColor(TrainingStyle s) => switch (s) {
  TrainingStyle.crossfit => const Color(0xFFFF7A3D),
  TrainingStyle.haltero => AppColors.blue,
  TrainingStyle.gym => AppColors.purple,
};

String styleName(AppLocalizations loc, TrainingStyle s) => switch (s) {
  TrainingStyle.crossfit => loc.styleCrossfit,
  TrainingStyle.haltero => loc.styleHaltero,
  TrainingStyle.gym => loc.styleGym,
};

/// Pestaña Entrenar: Hoy · Historial · Progreso.
class TrainingHome extends StatefulWidget {
  const TrainingHome({super.key, required this.store});

  final TrainingStore store;

  @override
  State<TrainingHome> createState() => _TrainingHomeState();
}

class _TrainingHomeState extends State<TrainingHome> {
  int _view = 0;
  int _version = 0;

  void _refresh() => setState(() => _version++);

  Future<void> _editStyles() async {
    await showStylesSheet(context, widget.store);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final key = ValueKey('$_view-$_version');
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DsLargeHeader(
              title: loc.tabTrain,
              trailing: IconButton(
                tooltip: loc.stylesTitle,
                icon: const Icon(Icons.tune),
                onPressed: _editStyles,
              ),
            ),
            const SizedBox(height: 4),
            DsSegmented(
              labels: [loc.tabToday, loc.historyTitle, loc.tabProgress],
              selected: _view,
              onChanged: (i) => setState(() {
                _view = i;
                _version++;
              }),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: switch (_view) {
                1 => HistoryView(key: key, store: widget.store),
                2 => ProgressView(key: key, store: widget.store),
                _ => TodayView(key: key, store: widget.store, onEditStyles: _editStyles),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Elegir qué estilos se muestran (CrossFit, Halterofilia, Gym).
Future<void> showStylesSheet(BuildContext context, TrainingStore store) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _StylesSheet(store: store),
  );
}

class _StylesSheet extends StatefulWidget {
  const _StylesSheet({required this.store});

  final TrainingStore store;

  @override
  State<_StylesSheet> createState() => _StylesSheetState();
}

class _StylesSheetState extends State<_StylesSheet> {
  late final Set<TrainingStyle> _on = {...widget.store.styles};

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Ds.gutter),
              child: Text(loc.stylesTitle, style: Ds.title(context)),
            ),
            const SizedBox(height: 12),
            for (final s in TrainingStyle.values)
              _StyleToggle(
                style: s,
                on: _on.contains(s),
                onTap: () => setState(() => _on.contains(s) ? _on.remove(s) : _on.add(s)),
              ),
            const SizedBox(height: 16),
            DsPrimaryButton(
              label: loc.keyboardDone,
              icon: Icons.check,
              onPressed: _on.isEmpty
                  ? null
                  : () async {
                      await widget.store.setStyles(_on.toList());
                      if (context.mounted) Navigator.of(context).pop();
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _StyleToggle extends StatelessWidget {
  const _StyleToggle({required this.style, required this.on, required this.onTap});

  final TrainingStyle style;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final color = styleColor(style);
    final desc = switch (style) {
      TrainingStyle.crossfit => loc.styleCrossfitDesc,
      TrainingStyle.haltero => loc.styleHalteroDesc,
      TrainingStyle.gym => loc.styleGymDesc,
    };
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Ds.gutter, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    styleName(loc, style),
                    style: Ds.body(context).copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(desc, style: Ds.secondary(context)),
                ],
              ),
            ),
            Switch.adaptive(value: on, onChanged: (_) => onTap()),
          ],
        ),
      ),
    );
  }
}

// ── Hoy ─────────────────────────────────────────────────────────────────────

class TodayView extends StatefulWidget {
  const TodayView({super.key, required this.store, required this.onEditStyles});

  final TrainingStore store;
  final VoidCallback onEditStyles;

  @override
  State<TodayView> createState() => _TodayViewState();
}

class _TodayViewState extends State<TodayView> {
  TrainingStore get _store => widget.store;
  TrainingStyle? _style;

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) setState(() {});
  }

  void _start(DailyWorkout d) {
    final unit = _store.storage.listUnit;
    final timed = d.style == TrainingStyle.crossfit && d.format != WodFormat.sets;
    if (timed) {
      _open(WodScreen(store: _store, wod: d));
    } else {
      _open(WorkoutScreen(store: _store, workout: _store.startDaily(d, unit)));
    }
  }

  void _startFree() {
    _open(
      WorkoutScreen(
        store: _store,
        workout:
            _store.draft ??
            Workout(id: newId(), date: DateTime.now(), unit: _store.storage.listUnit),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final styles = _store.styles;
    final draft = _store.draft;

    // Primera vez: elegir qué entrena.
    if (styles.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(top: 24, bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Ds.gutter),
            child: Text(loc.stylesFirstTitle, style: Ds.title(context)),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Ds.gutter),
            child: Text(loc.stylesFirstBody, style: Ds.secondary(context)),
          ),
          const SizedBox(height: 20),
          DsPrimaryButton(
            label: loc.stylesChoose,
            icon: Icons.tune,
            onPressed: widget.onEditStyles,
          ),
        ],
      );
    }

    final style = styles.contains(_style) ? _style! : styles.first;
    final today = DateTime.now();
    final offset = _store.dailyOffset(style, today);
    final wod = dailyFor(style, today, offset: offset);
    final done = _store.dailyDone(wod, today);

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      children: [
        if (draft != null) ...[
          _ResumeBanner(workout: draft, onTap: _startFree),
          const SizedBox(height: 12),
        ],
        if (styles.length > 1) ...[
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final s in styles)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(styleName(loc, s)),
                      selected: s == style,
                      showCheckmark: false,
                      selectedColor: styleColor(s).withValues(alpha: 0.18),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: s == style ? styleColor(s) : Ds.muted(context),
                      ),
                      side: BorderSide.none,
                      shape: const StadiumBorder(),
                      onSelected: (_) => setState(() => _style = s),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        WodCard(
          store: _store,
          wod: wod,
          done: done,
          onStart: () => _start(wod),
          onOther: () async {
            await _store.setDailyOffset(style, today, offset + 1);
            if (mounted) setState(() {});
          },
          onOpenDone: done == null
              ? null
              : () => _open(WorkoutDetailScreen(store: _store, workoutId: done.id)),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              side: BorderSide(color: Ds.hairline(context)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(loc.scanButton),
            onPressed: () async {
              await scanBoard(context, _store);
              if (mounted) setState(() {});
            },
          ),
        ),
        if (style == TrainingStyle.crossfit) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(loc.crossfitOfficialWod),
              onPressed: () => launchUrl(
                Uri.parse('https://www.crossfit.com/wod'),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: _startFree,
            child: Text(loc.todayFreeWorkout, style: TextStyle(color: Ds.muted(context))),
          ),
        ),
      ],
    );
  }
}

class _ResumeBanner extends StatelessWidget {
  const _ResumeBanner({required this.workout, required this.onTap});

  final Workout workout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: AppColors.blue,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${loc.todayInProgress} · ${workout.title.isEmpty ? loc.workoutFree : workout.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  loc.todayResume,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// El entrenamiento del día como pizarra.
class WodCard extends StatelessWidget {
  const WodCard({
    super.key,
    required this.store,
    required this.wod,
    required this.onStart,
    this.done,
    this.onOpenDone,
    this.onOther,
    this.showDate = true,
  });

  final TrainingStore store;
  final DailyWorkout wod;
  final Workout? done;
  final VoidCallback onStart;
  final VoidCallback? onOpenDone;

  /// Cambiar por otro entrenamiento (botón "Otro").
  final VoidCallback? onOther;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final unit = store.storage.listUnit;
    final color = styleColor(wod.style);
    final date = DateFormat.MMMEd(
      Localizations.localeOf(context).toString(),
    ).format(DateTime.now());

    return DsBlock(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              DsPill(styleName(loc, wod.style).toUpperCase(), color: color),
              if (wod.formatLabel.isNotEmpty) DsPill(wod.formatLabel, color: Ds.muted(context)),
            ],
          ),
          const SizedBox(height: 14),
          Text(wod.name, style: Ds.display(context)),
          if (showDate) ...[const SizedBox(height: 2), Text(date, style: Ds.secondary(context))],
          const SizedBox(height: 10),
          for (final item in wod.items) WodItemRow(item: item, store: store, unit: unit),
          const SizedBox(height: 18),
          if (done != null)
            Material(
              color: Ds.done.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onOpenDone,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Ds.done),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          done!.score?.isNotEmpty == true
                              ? '${loc.todayDone} · ${done!.score}'
                              : loc.todayDone,
                          style: const TextStyle(
                            color: Ds.done,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Ds.done),
                    ],
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(loc.todayStart),
                    onPressed: onStart,
                  ),
                ),
                if (onOther != null) ...[
                  const SizedBox(width: 10),
                  Tooltip(
                    message: loc.todayOther,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(56, 56),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: Ds.hairline(context)),
                      ),
                      onPressed: onOther,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shuffle_rounded, size: 20),
                          const SizedBox(width: 6),
                          Text(loc.todayOther, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class WodItemRow extends StatelessWidget {
  const WodItemRow({super.key, required this.item, required this.store, required this.unit});

  final DailyItem item;
  final TrainingStore store;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final w = store.dailyWeight(item, unit);
    final right = w != null
        ? '${fmtWeight(w)} ${unit.label}'
        : item.percent != null
        ? '${fmtWeight(item.percent!)}% RM'
        : item.rx(unit);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Ds.hairline(context))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (item.reps.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 56),
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  item.reps,
                  style: Ds.body(
                    context,
                  ).copyWith(fontWeight: FontWeight.w800, fontFeatures: Ds.tabular),
                ),
              ),
            ),
          Expanded(child: Text(liftDisplayName(item.lift), style: Ds.body(context))),
          if (right != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: w != null
                    ? Ds.body(
                        context,
                      ).copyWith(fontWeight: FontWeight.w800, fontFeatures: Ds.tabular)
                    : Ds.secondary(context),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Historial ───────────────────────────────────────────────────────────────

class HistoryView extends StatefulWidget {
  const HistoryView({super.key, required this.store});

  final TrainingStore store;

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final list = widget.store.workouts;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            loc.historyWorkoutsEmpty,
            textAlign: TextAlign.center,
            style: Ds.secondary(context),
          ),
        ),
      );
    }
    final children = <Widget>[];
    String? month;
    for (final w in list) {
      final m = DateFormat.yMMMM(locale).format(w.date.toLocal());
      if (m != month) {
        month = m;
        children.add(DsSection(m));
      }
      children.add(
        HistoryRow(
          workout: w,
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => WorkoutDetailScreen(store: widget.store, workoutId: w.id),
              ),
            );
            if (mounted) setState(() {});
          },
        ),
      );
    }
    return ListView(padding: const EdgeInsets.only(bottom: 32), children: children);
  }
}

class HistoryRow extends StatelessWidget {
  const HistoryRow({super.key, required this.workout, required this.onTap});

  final Workout workout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final w = workout;
    final locale = Localizations.localeOf(context).toString();
    final style = TrainingStyle.parse(w.style);
    final lifts = w.exercises.map((e) => liftDisplayName(e.lift)).join(' · ');
    return DsRow(
      leading: SizedBox(
        width: 44,
        child: Column(
          children: [
            Text(
              '${w.date.toLocal().day}',
              style: Ds.title(context).copyWith(fontFeatures: Ds.tabular),
            ),
            Text(
              DateFormat.E(locale).format(w.date.toLocal()).replaceAll('.', '').toUpperCase(),
              style: Ds.label(context),
            ),
          ],
        ),
      ),
      title: w.title.isEmpty ? loc.workoutFree : w.title,
      subtitle: w.score?.isNotEmpty == true ? w.score : (lifts.isEmpty ? null : lifts),
      trailing: style == null
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: styleColor(style), shape: BoxShape.circle),
            ),
      onTap: onTap,
    );
  }
}

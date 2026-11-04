import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/programs.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/lift_names.dart';
import '../../models/training.dart';
import '../../models/weight_unit.dart';
import '../../services/training_store.dart';
import '../../utils/format.dart';
import '../theme/app_theme.dart';
import '../widgets/ds.dart';
import '../widgets/share_code.dart';
import 'plan_editor_screen.dart';
import 'plan_screen.dart';
import 'workout_detail_screen.dart';
import 'workout_screen.dart';

/// Pestaña Hoy: la "pizarra" del día (como SugarWOD) con la próxima sesión y
/// tus pesos ya calculados, la semana, tus planes y lo último que hiciste.
class TrainScreen extends StatefulWidget {
  const TrainScreen({super.key, required this.store, this.onOpenSettings});

  final TrainingStore store;
  final VoidCallback? onOpenSettings;

  @override
  State<TrainScreen> createState() => _TrainScreenState();
}

class _TrainScreenState extends State<TrainScreen> {
  TrainingStore get _store => widget.store;

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) setState(() {});
  }

  void _startFree() {
    final draft = _store.draft;
    _open(
      WorkoutScreen(
        store: _store,
        workout: draft ?? Workout(id: newId(), date: DateTime.now(), unit: _store.storage.listUnit),
      ),
    );
  }

  Future<void> _startPlanDay(Plan plan, int day) async {
    final w = _store.startFromPlan(plan, day, _store.storage.listUnit);
    await _open(WorkoutScreen(store: _store, workout: w));
  }

  Future<void> _importPlan() async {
    final loc = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final code = await askForCode(context, title: loc.importPlanTitle);
    if (code == null || code.trim().isEmpty) return;
    final plan = ShareCode.decodePlan(code);
    if (plan == null) {
      messenger.showSnackBar(SnackBar(content: Text(loc.importInvalid)));
      return;
    }
    await _store.savePlan(plan);
    messenger.showSnackBar(SnackBar(content: Text(loc.importPlanDone(plan.name))));
    if (mounted) await _open(PlanScreen(store: _store, planId: plan.id));
  }

  Future<void> _newPlan() async {
    final loc = AppLocalizations.of(context);
    final plan = Plan(
      id: newId(),
      name: '',
      days: [PlanDay(name: loc.planDayDefault(1))],
    );
    await _open(PlanEditorScreen(store: _store, plan: plan));
  }

  Future<void> _useTemplate(Plan tpl) async {
    if (!_store.plans.any((p) => p.id == tpl.id)) await _store.savePlan(tpl);
    if (mounted) await _open(PlanScreen(store: _store, planId: tpl.id));
  }

  /// Plan activo: el último que se entrenó (o el primero) con días pendientes.
  (Plan, int)? _nextSession(List<Plan> plans, List<Workout> history) {
    DateTime last(Plan p) =>
        history.where((w) => w.planId == p.id).firstOrNull?.date ?? DateTime(2000);
    final sorted = [...plans]..sort((a, b) => last(b).compareTo(last(a)));
    for (final p in sorted) {
      final done = _store.doneDays(p.id);
      for (var i = 0; i < p.days.length; i++) {
        if (!done.contains(i)) return (p, i);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final ml = MaterialLocalizations.of(context);
    final draft = _store.draft;
    final plans = _store.plans;
    final history = _store.workouts;
    final templates = builtInPlans(loc).where((t) => !plans.any((p) => p.id == t.id)).toList();
    final next = _nextSession(plans, history);
    final unit = _store.storage.listUnit;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            DsLargeHeader(
              eyebrow: ml.formatFullDate(DateTime.now()),
              title: loc.tabToday,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: loc.importPlanTitle,
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: _importPlan,
                  ),
                  if (widget.onOpenSettings != null)
                    IconButton(
                      tooltip: loc.settingsTooltip,
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: widget.onOpenSettings,
                    ),
                ],
              ),
            ),
            _WeekStrip(trained: trainedDays(history)),

            // ── En curso ─────────────────────────────────────────────────────
            if (draft != null) ...[
              DsSection(loc.todayInProgress),
              DsRow(
                leading: const Icon(Icons.timer_outlined, color: AppColors.blue),
                title: draft.title.isEmpty ? loc.workoutFree : draft.title,
                subtitle: loc.setsCount(draft.doneSets.length),
                trailing: FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  onPressed: _startFree,
                  child: Text(loc.todayResume),
                ),
              ),
            ]
            // ── Próxima sesión (pizarra) ─────────────────────────────────────
            else if (next != null) ...[
              DsSection(loc.todayNext, help: next.$1.name),
              _Whiteboard(
                store: _store,
                plan: next.$1,
                day: next.$2,
                unit: unit,
                onStart: () => _startPlanDay(next.$1, next.$2),
                onOpenPlan: () => _open(PlanScreen(store: _store, planId: next.$1.id)),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(onPressed: _startFree, child: Text(loc.todayFreeWorkout)),
              ),
            ] else ...[
              DsSection(loc.todayNext),
              Padding(
                padding: const EdgeInsets.fromLTRB(Ds.gutter, 0, Ds.gutter, 16),
                child: Text(loc.todayNoPlanBody, style: Ds.secondary(context)),
              ),
              DsPrimaryButton(label: loc.workoutStartFree, icon: Icons.add, onPressed: _startFree),
            ],

            // ── Planes ───────────────────────────────────────────────────────
            DsSection(loc.myPlans),
            for (final p in plans)
              DsRow(
                leading: Icon(
                  p.fromCoach ? Icons.groups_outlined : Icons.view_list_outlined,
                  color: Ds.muted(context),
                ),
                title: p.name.isEmpty ? loc.planUntitled : p.name,
                subtitle: p.fromCoach
                    ? ((p.box ?? '').isEmpty
                          ? loc.planFromCoach(p.coach!)
                          : '${loc.planFromCoach(p.coach!)} · ${p.box}')
                    : null,
                trailing: Text(
                  '${_store.doneDays(p.id).length}/${p.days.length}',
                  style: Ds.secondary(context).copyWith(fontFeatures: Ds.tabular),
                ),
                onTap: () => _open(PlanScreen(store: _store, planId: p.id)),
              ),
            DsRow(
              leading: const Icon(Icons.add, color: AppColors.blue),
              title: loc.planCreate,
              onTap: _newPlan,
            ),
            DsRow(
              leading: const Icon(Icons.qr_code_scanner, color: AppColors.blue),
              title: loc.importPlanTitle,
              onTap: _importPlan,
              divider: false,
            ),

            // ── Programas por porcentaje ─────────────────────────────────────
            if (templates.isNotEmpty) DsSection(loc.templatesTitle),
            for (final t in templates)
              DsRow(
                title: t.name,
                subtitle: t.notes,
                onTap: () => _useTemplate(t),
                divider: t != templates.last,
              ),

            // ── Recientes ────────────────────────────────────────────────────
            DsSection(
              loc.todayRecent,
              action: history.length > 3 ? loc.seeAll : null,
              onAction: () => _open(HistoryScreen(store: _store)),
            ),
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Ds.gutter),
                child: Text(loc.historyWorkoutsEmpty, style: Ds.secondary(context)),
              ),
            for (final w in history.take(3))
              _WorkoutRow(
                workout: w,
                onTap: () => _open(WorkoutDetailScreen(store: _store, workoutId: w.id)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Lunes a domingo de esta semana; los días entrenados llevan un punto.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.trained});

  final Set<DateTime> trained;

  @override
  Widget build(BuildContext context) {
    final ml = MaterialLocalizations.of(context);
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final names = [...ml.narrowWeekdays.skip(1), ml.narrowWeekdays.first];
    return Padding(
      padding: const EdgeInsets.fromLTRB(Ds.gutter - 6, 8, Ds.gutter - 6, 0),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Builder(
                builder: (context) {
                  final d = DateTime(monday.year, monday.month, monday.day + i);
                  final isToday = d.day == now.day && d.month == now.month;
                  final on = trained.contains(d);
                  return Column(
                    children: [
                      Text(names[i], style: Ds.label(context)),
                      const SizedBox(height: 6),
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isToday ? AppColors.blue : null,
                        ),
                        child: Text(
                          '${d.day}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                            color: isToday ? Colors.white : null,
                            fontFeatures: Ds.tabular,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: on ? Ds.done : Colors.transparent,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// La sesión del día como pizarra: ejercicios a la izquierda y tu peso
/// calculado con tu RM a la derecha, en grande.
class _Whiteboard extends StatelessWidget {
  const _Whiteboard({
    required this.store,
    required this.plan,
    required this.day,
    required this.unit,
    required this.onStart,
    required this.onOpenPlan,
  });

  final TrainingStore store;
  final Plan plan;
  final int day;
  final WeightUnit unit;
  final VoidCallback onStart;
  final VoidCallback onOpenPlan;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final d = plan.days[day];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onOpenPlan,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Ds.gutter, 0, Ds.gutter, 12),
            child: Text(d.name, style: Ds.title(context)),
          ),
        ),
        for (final item in d.items)
          Container(
            margin: const EdgeInsets.only(left: Ds.gutter),
            padding: const EdgeInsets.fromLTRB(0, 12, Ds.gutter, 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Ds.hairline(context))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        liftDisplayName(item.lift),
                        style: Ds.body(context).copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.percent != null
                            ? '${item.sets} × ${item.reps} · ${fmtWeight(item.percent!)}%'
                            : '${item.sets} × ${item.reps}',
                        style: Ds.secondary(context).copyWith(fontFeatures: Ds.tabular),
                      ),
                    ],
                  ),
                ),
                Builder(
                  builder: (context) {
                    final w = store.targetWeight(item, unit);
                    if (w == null) {
                      return Text(
                        item.percent != null ? loc.planNoRm : '—',
                        style: Ds.secondary(context),
                      );
                    }
                    return Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: fmtWeight(w),
                            style: Ds.title(context).copyWith(fontFeatures: Ds.tabular),
                          ),
                          TextSpan(text: ' ${unit.label}', style: Ds.secondary(context)),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        Container(height: 1, color: Ds.hairline(context)),
        const SizedBox(height: 16),
        DsPrimaryButton(label: loc.planStartNext(d.name), onPressed: onStart),
      ],
    );
  }
}

class _WorkoutRow extends StatelessWidget {
  const _WorkoutRow({required this.workout, required this.onTap});

  final Workout workout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final w = workout;
    final lifts = w.exercises.map((e) => liftDisplayName(e.lift)).join(' · ');
    return DsRow(
      leading: SizedBox(
        width: 40,
        child: Column(
          children: [
            Text(
              '${w.date.toLocal().day}',
              style: Ds.title(context).copyWith(fontFeatures: Ds.tabular),
            ),
            Text(
              DateFormat.MMM(
                Localizations.localeOf(context).toString(),
              ).format(w.date.toLocal()).replaceAll('.', '').toUpperCase(),
              style: Ds.label(context),
            ),
          ],
        ),
      ),
      title: w.title.isEmpty ? loc.workoutFree : w.title,
      subtitle: lifts.isEmpty ? loc.setsCount(w.doneSets.length) : lifts,
      onTap: onTap,
    );
  }
}

/// Todos los entrenamientos, del más nuevo al más antiguo.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.store});

  final TrainingStore store;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final list = store.workouts;
    return Scaffold(
      appBar: AppBar(title: Text(loc.historyTitle)),
      body: ListView(
        children: [
          for (final w in list)
            _WorkoutRow(
              workout: w,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => WorkoutDetailScreen(store: store, workoutId: w.id),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../data/programs.dart';
import '../../l10n/app_localizations.dart';
import '../../models/training.dart';
import '../../services/training_store.dart';
import '../widgets/share_code.dart';
import '../widgets/training_widgets.dart';
import 'plan_editor_screen.dart';
import 'plan_screen.dart';
import 'workout_detail_screen.dart';
import 'workout_screen.dart';

/// Pestaña Entrenar: empezar un entrenamiento, planes y historial.
class TrainScreen extends StatefulWidget {
  const TrainScreen({super.key, required this.store});

  final TrainingStore store;

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
    if (draft != null) {
      _open(WorkoutScreen(store: _store, workout: draft));
      return;
    }
    _open(
      WorkoutScreen(
        store: _store,
        workout: Workout(id: newId(), date: DateTime.now(), unit: _store.storage.listUnit),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final draft = _store.draft;
    final plans = _store.plans;
    final templates = builtInPlans(loc).where((t) => !plans.any((p) => p.id == t.id)).toList();
    final history = _store.workouts;

    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(text, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.tabTrain),
        actions: [
          IconButton(
            tooltip: loc.importPlanTitle,
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _importPlan,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
        children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            icon: Icon(draft != null ? Icons.play_arrow : Icons.add),
            label: Text(draft != null ? loc.workoutResume : loc.workoutStartFree),
            onPressed: _startFree,
          ),
          header(loc.myPlans),
          if (plans.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(loc.myPlansEmpty, style: theme.textTheme.bodyMedium),
            ),
          for (final p in plans)
            _PlanTile(
              plan: p,
              done: _store.doneDays(p.id).length,
              onTap: () => _open(PlanScreen(store: _store, planId: p.id)),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_note),
                label: Text(loc.planCreate),
                onPressed: _newPlan,
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(loc.importPlanShort),
                onPressed: _importPlan,
              ),
            ],
          ),
          if (templates.isNotEmpty) header(loc.templatesTitle),
          for (final t in templates)
            Card(
              child: ListTile(
                leading: const Icon(Icons.auto_graph),
                title: Text(t.name),
                subtitle: Text(t.notes),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _useTemplate(t),
              ),
            ),
          header(loc.historyTitle),
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(loc.historyWorkoutsEmpty),
            ),
          for (final w in history.take(30))
            Card(
              child: ListTile(
                title: Text(w.title.isEmpty ? loc.workoutFree : w.title),
                subtitle: Text(
                  '${shortDate(w.date)} · ${loc.setsCount(w.doneSets.length)}'
                  '${w.planName != null ? ' · ${w.planName}' : ''}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(WorkoutDetailScreen(store: _store, workoutId: w.id)),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan, required this.done, required this.onTap});

  final Plan plan;
  final int done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final total = plan.days.length;
    return Card(
      child: ListTile(
        leading: Icon(plan.fromCoach ? Icons.sports : Icons.list_alt),
        title: Text(plan.name.isEmpty ? loc.planUntitled : plan.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plan.fromCoach)
              Text(
                (plan.box ?? '').isEmpty
                    ? loc.planFromCoach(plan.coach!)
                    : '${loc.planFromCoach(plan.coach!)} · ${plan.box}',
              ),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: total == 0 ? 0 : done / total),
            const SizedBox(height: 2),
            Text(loc.planProgress(done, total)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

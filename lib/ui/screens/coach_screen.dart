import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/lift_names.dart';
import '../../models/training.dart';
import '../../services/training_store.dart';
import '../../utils/format.dart';
import '../widgets/share_code.dart';
import '../widgets/training_widgets.dart';
import 'plan_editor_screen.dart';
import 'plan_screen.dart';
import 'workout_detail_screen.dart';

/// Pestaña Coach: el coach arma planes para su box, los comparte por QR o
/// código, y recibe los resultados de sus alumnos de la misma forma.
class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key, required this.store});

  final TrainingStore store;

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  TrainingStore get _store => widget.store;

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) setState(() {});
  }

  Future<void> _editProfile() async {
    final loc = AppLocalizations.of(context);
    final name = TextEditingController(text: _store.coachName);
    final box = TextEditingController(text: _store.coachBox);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.coachProfile),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: loc.coachNameLabel),
            ),
            TextField(
              controller: box,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: loc.coachBoxLabel),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.save)),
        ],
      ),
    );
    if (ok == true) {
      await _store.setCoach(name.text, box.text);
      setState(() {});
    }
  }

  Future<void> _newPlan() async {
    final loc = AppLocalizations.of(context);
    if (_store.coachName.isEmpty) await _editProfile();
    if (!mounted) return;
    await _open(
      PlanEditorScreen(
        store: _store,
        plan: Plan(
          id: newId(),
          name: '',
          days: [PlanDay(name: loc.planDayDefault(1))],
        ),
      ),
    );
  }

  Future<void> _importResult() async {
    final loc = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final code = await askForCode(context, title: loc.importResultTitle);
    if (code == null || code.trim().isEmpty) return;
    final r = ShareCode.decodeResult(code);
    if (r == null) {
      messenger.showSnackBar(SnackBar(content: Text(loc.importInvalid)));
      return;
    }
    final added = await _store.addResult(r);
    messenger.showSnackBar(
      SnackBar(content: Text(added ? loc.importResultDone(r.athlete) : loc.importResultDuplicate)),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final myPlans = _store.plans.where((p) => !p.fromCoach && !p.id.startsWith('tpl_')).toList();
    final results = _store.results;
    final athletes = _store.athletes;

    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(text, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
    );

    return Scaffold(
      appBar: AppBar(title: Text(loc.tabCoach)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.sports)),
              title: Text(_store.coachName.isEmpty ? loc.coachSetupTitle : _store.coachName),
              subtitle: Text(_store.coachBox.isEmpty ? loc.coachSetupSubtitle : _store.coachBox),
              trailing: const Icon(Icons.edit),
              onTap: _editProfile,
            ),
          ),
          Card(
            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
            child: Padding(padding: const EdgeInsets.all(12), child: Text(loc.coachHowItWorks)),
          ),
          header(loc.coachPlansTitle),
          for (final p in myPlans)
            Card(
              child: ListTile(
                leading: const Icon(Icons.list_alt),
                title: Text(p.name),
                subtitle: Text(loc.planDaysCount(p.days.length)),
                trailing: IconButton(
                  tooltip: loc.planShare,
                  icon: const Icon(Icons.qr_code),
                  onPressed: () => showShareCodeSheet(
                    context,
                    title: loc.planShareTitle(p.name),
                    subtitle: loc.planShareSubtitle,
                    code: ShareCode.encodePlan(
                      Plan(
                        id: p.id,
                        name: p.name,
                        days: p.days,
                        notes: p.notes,
                        coach: _store.coachName.isEmpty ? loc.coachDefaultName : _store.coachName,
                        box: _store.coachBox.isEmpty ? null : _store.coachBox,
                      ),
                    ),
                  ),
                ),
                onTap: () => _open(PlanScreen(store: _store, planId: p.id)),
              ),
            ),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.add),
            label: Text(loc.coachCreatePlan),
            onPressed: _newPlan,
          ),
          header(loc.coachAthletesTitle),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(loc.importResultTitle),
            onPressed: _importResult,
          ),
          const SizedBox(height: 8),
          if (athletes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(loc.coachAthletesEmpty),
            ),
          for (final a in athletes)
            Builder(
              builder: (context) {
                final mine = results.where((r) => r.athlete == a).toList();
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(a.characters.first.toUpperCase())),
                    title: Text(a),
                    subtitle: Text(
                      '${loc.resultsCount(mine.length)} · ${loc.lastWorkout(shortDate(mine.first.workout.date))}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(AthleteScreen(store: _store, athlete: a)),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Resultados de un alumno: mejores marcas y entrenamientos recibidos.
class AthleteScreen extends StatelessWidget {
  const AthleteScreen({super.key, required this.store, required this.athlete});

  final TrainingStore store;
  final String athlete;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final results = store.results.where((r) => r.athlete == athlete).toList();
    final workouts = [for (final r in results) r.workout];
    final unit = store.storage.listUnit;
    final lifts = trainedLifts(workouts);

    return Scaffold(
      appBar: AppBar(
        title: Text(athlete),
        actions: [
          IconButton(
            tooltip: loc.delete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(loc.athleteDeleteTitle(athlete)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.cancel)),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.delete)),
                  ],
                ),
              );
              if (ok != true) return;
              await store.deleteAthlete(athlete);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(loc.recordsTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          for (final lift in lifts)
            Builder(
              builder: (context) {
                final hist = liftHistory(workouts, lift, unit);
                final heavy = hist.map((s) => s.heaviest).fold(0.0, math.max);
                final best = hist.map((s) => s.best1Rm).fold(0.0, math.max);
                return ListTile(
                  dense: true,
                  leading: liftIconFor(store.storage, lift, size: 32),
                  title: Text(liftDisplayName(lift)),
                  subtitle: Text(
                    '${loc.recordHeaviest(fmtWeight(heavy), unit.label)} · '
                    '${loc.e1rmShort(fmtWeight(best, maxDecimals: 1), unit.label)}',
                  ),
                );
              },
            ),
          const SizedBox(height: 12),
          Text(loc.historyTitle, style: theme.textTheme.titleMedium),
          for (final r in results)
            Card(
              child: ExpansionTile(
                title: Text(r.workout.title.isEmpty ? loc.workoutFree : r.workout.title),
                subtitle: Text(
                  '${fmtDateTime(r.workout.date)}${r.workout.planName != null ? ' · ${r.workout.planName}' : ''}',
                ),
                childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                children: [WorkoutSummaryList(workout: r.workout, store: store)],
              ),
            ),
        ],
      ),
    );
  }
}

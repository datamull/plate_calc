import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/lift_names.dart';
import '../../models/training.dart';
import '../../services/training_store.dart';
import '../../utils/format.dart';
import '../theme/app_theme.dart';
import '../widgets/ds.dart';
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
    final myPlans = _store.plans.where((p) => !p.fromCoach && !p.id.startsWith('tpl_')).toList();
    final results = _store.results;
    final athletes = _store.athletes;

    Plan signed(Plan p) => Plan(
      id: p.id,
      name: p.name,
      days: p.days,
      notes: p.notes,
      coach: _store.coachName.isEmpty ? loc.coachDefaultName : _store.coachName,
      box: _store.coachBox.isEmpty ? null : _store.coachBox,
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            DsLargeHeader(
              eyebrow: _store.coachBox.isEmpty ? null : _store.coachBox,
              title: loc.tabBox,
            ),
            DsRow(
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.blue.withValues(alpha: 0.15),
                child: const Icon(Icons.sports, color: AppColors.blue),
              ),
              title: _store.coachName.isEmpty ? loc.coachSetupTitle : _store.coachName,
              subtitle: _store.coachBox.isEmpty ? loc.coachSetupSubtitle : loc.coachProfile,
              trailing: Icon(Icons.edit_outlined, color: Ds.muted(context), size: 20),
              onTap: _editProfile,
              divider: false,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Ds.gutter, 8, Ds.gutter, 0),
              child: Text(loc.coachHowItWorks, style: Ds.secondary(context)),
            ),

            DsSection(loc.coachPlansTitle),
            for (final p in myPlans)
              DsRow(
                title: p.name,
                subtitle: loc.planDaysCount(p.days.length),
                trailing: IconButton(
                  tooltip: loc.planShare,
                  icon: const Icon(Icons.qr_code, color: AppColors.blue),
                  onPressed: () => showShareCodeSheet(
                    context,
                    title: loc.planShareTitle(p.name),
                    subtitle: loc.planShareSubtitle,
                    code: ShareCode.encodePlan(signed(p)),
                  ),
                ),
                onTap: () => _open(PlanScreen(store: _store, planId: p.id)),
              ),
            DsRow(
              leading: const Icon(Icons.add, color: AppColors.blue),
              title: loc.coachCreatePlan,
              onTap: _newPlan,
              divider: false,
            ),

            DsSection(loc.coachAthletesTitle),
            DsRow(
              leading: const Icon(Icons.qr_code_scanner, color: AppColors.blue),
              title: loc.importResultTitle,
              onTap: _importResult,
            ),
            if (athletes.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(Ds.gutter, 12, Ds.gutter, 0),
                child: Text(loc.coachAthletesEmpty, style: Ds.secondary(context)),
              ),
            for (final a in athletes)
              Builder(
                builder: (context) {
                  final mine = results.where((r) => r.athlete == a).toList();
                  return DsRow(
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: Ds.hairline(context),
                      child: Text(
                        a.characters.first.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    title: a,
                    subtitle:
                        '${loc.resultsCount(mine.length)} · ${loc.lastWorkout(shortDate(mine.first.workout.date))}',
                    divider: a != athletes.last,
                    onTap: () => _open(AthleteScreen(store: _store, athlete: a)),
                  );
                },
              ),
          ],
        ),
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

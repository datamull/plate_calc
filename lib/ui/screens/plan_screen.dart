import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/lift_names.dart';
import '../../models/training.dart';
import '../../models/weight_unit.dart';
import '../../services/training_store.dart';
import '../../utils/format.dart';
import '../widgets/share_code.dart';
import 'plan_editor_screen.dart';
import 'workout_screen.dart';
import '../widgets/app_icons.dart';

/// Texto de un ejercicio del plan: "Snatch 5×2 · 70% (70 kg)".
String planItemText(AppLocalizations loc, TrainingStore store, PlanItem i, WeightUnit unit) {
  final base = '${liftDisplayName(i.lift)} ${i.sets}×${i.reps}';
  if (i.percent != null) {
    final w = store.targetWeight(i, unit);
    final pct = '${fmtWeight(i.percent!)}%';
    return w == null
        ? '$base · $pct (${loc.planNoRm})'
        : '$base · $pct (${fmtWeight(w)} ${unit.label})';
  }
  if (i.weight != null) return '$base · ${fmtWeight(i.weight!)} ${unit.label}';
  return base;
}

/// Detalle de un plan: días, pesos calculados con el RM y botón para empezar.
class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key, required this.store, required this.planId});

  final TrainingStore store;
  final String planId;

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  TrainingStore get _store => widget.store;

  Plan? get _plan => _store.plans.where((p) => p.id == widget.planId).firstOrNull;

  Future<void> _start(Plan plan, int day) async {
    final loc = AppLocalizations.of(context);
    if (_store.draft != null) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(loc.draftReplaceTitle),
          content: Text(loc.draftReplaceBody),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.cancel)),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.ok)),
          ],
        ),
      );
      if (ok != true) return;
    }
    final w = _store.startFromPlan(plan, day, _store.storage.listUnit);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WorkoutScreen(store: _store, workout: w),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _delete(Plan plan) async {
    final loc = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.planDeleteTitle(plan.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.delete)),
        ],
      ),
    );
    if (ok != true) return;
    await _store.deletePlan(plan.id);
    if (mounted) Navigator.of(context).pop();
  }

  void _share(Plan plan) {
    final loc = AppLocalizations.of(context);
    // Si es propio, se firma con el nombre del coach (si lo configuró).
    final toShare = plan.fromCoach
        ? plan
        : Plan(
            id: plan.id,
            name: plan.name,
            days: plan.days,
            notes: plan.notes,
            coach: _store.coachName.isEmpty ? loc.coachDefaultName : _store.coachName,
            box: _store.coachBox.isEmpty ? null : _store.coachBox,
          );
    showShareCodeSheet(
      context,
      title: loc.planShareTitle(plan.name),
      subtitle: loc.planShareSubtitle,
      code: ShareCode.encodePlan(toShare),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final plan = _plan;
    if (plan == null) return Scaffold(appBar: AppBar());
    final unit = _store.storage.listUnit;
    final done = _store.doneDays(plan.id);
    final next = List.generate(
      plan.days.length,
      (i) => i,
    ).where((i) => !done.contains(i)).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(plan.name.isEmpty ? loc.planUntitled : plan.name),
        actions: [
          IconButton(
            tooltip: loc.planShare,
            icon: const Icon(AppIcons.qr),
            onPressed: () => _share(plan),
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'edit') {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PlanEditorScreen(store: _store, plan: plan),
                  ),
                );
                if (mounted) setState(() {});
              }
              if (v == 'delete') await _delete(plan);
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text(loc.edit)),
              PopupMenuItem(value: 'delete', child: Text(loc.delete)),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
        children: [
          if (plan.fromCoach)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(AppIcons.whistle, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    (plan.box ?? '').isEmpty
                        ? loc.planFromCoach(plan.coach!)
                        : '${loc.planFromCoach(plan.coach!)} · ${plan.box}',
                  ),
                ],
              ),
            ),
          if (plan.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(plan.notes, style: theme.textTheme.bodyMedium),
            ),
          if (next != null)
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              icon: const Icon(AppIcons.play),
              label: Text(loc.planStartNext(plan.days[next].name)),
              onPressed: () => _start(plan, next),
            ),
          const SizedBox(height: 8),
          for (var d = 0; d < plan.days.length; d++)
            Card(
              child: ExpansionTile(
                initiallyExpanded: d == next,
                leading: Icon(
                  done.contains(d) ? AppIcons.checkCircle : AppIcons.circle,
                  color: done.contains(d) ? Colors.green : null,
                ),
                title: Text(plan.days[d].name),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final i in plan.days[d].items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('• ${planItemText(loc, _store, i, unit)}'),
                    ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      icon: const Icon(AppIcons.play),
                      label: Text(loc.planStartDay),
                      onPressed: () => _start(plan, d),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

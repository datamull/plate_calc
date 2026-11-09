import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/training.dart';
import '../../models/week_plan.dart';
import '../../services/plan_ai.dart';
import '../../services/training_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/ds.dart';
import 'board_scan.dart';
import 'training_home.dart';
import 'workout_detail_screen.dart';

/// Plan semanal: se sube el PDF que manda el coach, la IA lo lee y cada día
/// queda listo para entrenar. La semana siguiente se sube el nuevo y
/// reemplaza al anterior.
class PlanView extends StatefulWidget {
  const PlanView({super.key, required this.store});

  final TrainingStore store;

  @override
  State<PlanView> createState() => _PlanViewState();
}

class _PlanViewState extends State<PlanView> {
  TrainingStore get _store => widget.store;
  int? _day;
  bool _busy = false;

  Future<void> _upload({required bool replacing}) async {
    final loc = AppLocalizations.of(context);
    if (!PlanAi.enabled) return _snack(loc.planAiOff);

    if (replacing) {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Ds.gutter, 0, Ds.gutter, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(loc.planReplaceTitle, style: Ds.title(ctx)),
                const SizedBox(height: 6),
                Text(loc.planReplaceBody, style: Ds.secondary(ctx)),
                const SizedBox(height: 20),
                DsButton(
                  icon: AppIcons.pdf,
                  label: loc.planReplaceConfirm,
                  onPressed: () => Navigator.pop(ctx, true),
                ),
                const SizedBox(height: 4),
                DsButton(
                  kind: DsButtonKind.ghost,
                  label: MaterialLocalizations.of(ctx).cancelButtonLabel,
                  onPressed: () => Navigator.pop(ctx, false),
                ),
              ],
            ),
          ),
        ),
      );
      if (ok != true || !mounted) return;
    }

    // Apple (5.1.2(i)): permiso antes de enviar datos a una IA de terceros.
    var consent = _store.storage.aiConsent;
    if (consent == null) {
      consent = await askAiConsent(context);
      if (consent == null || !mounted) return;
      await _store.storage.setAiConsent(consent);
    }
    if (!consent) return _snack(loc.planAiDeclined);

    final PlatformFile? file;
    try {
      file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['pdf']);
    } catch (_) {
      return _snack(loc.planErrorOffline);
    }
    if (file == null || !mounted) return;

    setState(() => _busy = true);
    final bytes = await file.readAsBytes();
    final (json, error) = await PlanAi.read(bytes);
    if (!mounted) return;
    if (json == null) {
      setState(() => _busy = false);
      return _snack(switch (error) {
        PlanReadError.tooLarge => loc.planErrorTooLarge,
        PlanReadError.unreadable => loc.planErrorUnreadable,
        _ => loc.planErrorOffline,
      });
    }
    await _store.saveWeekPlan(WeekPlan.envelope(json, now: DateTime.now(), fileName: file.name));
    if (!mounted) return;
    unawaited(HapticFeedback.mediumImpact());
    setState(() {
      _busy = false;
      _day = null;
    });
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _start(PlanBlock b) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ScanReviewScreen(store: _store, wod: b.wod, byAi: true),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openDone(Workout w) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WorkoutDetailScreen(store: _store, workoutId: w.id),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (_busy) return _Reading(text: loc.planReading);
    final plan = _store.weekPlan(fallbackName: loc.scanDefaultName);
    if (plan == null) return _Empty(onUpload: () => _upload(replacing: false));

    final today = DateTime.now();
    final inWeek =
        !today.isBefore(plan.weekStart) &&
        today.isBefore(plan.weekStart.add(const Duration(days: 7)));
    final day =
        _day ??
        (inWeek && plan.days.containsKey(today.weekday)
            ? today.weekday
            : (inWeek ? today.weekday : plan.days.keys.reduce((a, b) => a < b ? a : b)));
    final blocks = plan.days[day] ?? const <PlanBlock>[];
    final locale = Localizations.localeOf(context).toString();

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // Encabezado: semana y reemplazo del PDF.
        Padding(
          padding: const EdgeInsets.fromLTRB(Ds.gutter, 4, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.planWeekOf(DateFormat.MMMd(locale).format(plan.weekStart)).toUpperCase(),
                      style: Ds.label(context),
                    ),
                    if (plan.title != null || plan.fileName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        plan.title ?? plan.fileName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Ds.body(context).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
              DsButton(
                kind: DsButtonKind.ghost,
                expand: false,
                height: 40,
                icon: AppIcons.refresh,
                label: loc.planReplace,
                onPressed: () => _upload(replacing: true),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _DayStrip(
          plan: plan,
          selected: day,
          today: inWeek ? today.weekday : null,
          isDone: (wd) {
            final b = plan.days[wd];
            return b != null && b.every((x) => _store.planDone(x.wod) != null);
          },
          onSelect: (wd) => setState(() => _day = wd),
        ),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Ds.gutter),
          child: Text(
            DateFormat.MMMMEEEEd(locale).format(plan.dateOf(day)),
            style: Ds.display(context).copyWith(fontSize: 30),
          ),
        ),
        const SizedBox(height: 8),
        if (blocks.isEmpty)
          _RestDay(title: loc.planRestDay, body: loc.planRestBody)
        else
          for (var i = 0; i < blocks.length; i++)
            DsFadeIn(
              key: ValueKey('${plan.id}-$day-$i'),
              index: i,
              child: _BlockView(
                store: _store,
                block: blocks[i],
                first: i == 0,
                done: _store.planDone(blocks[i].wod),
                onStart: () => _start(blocks[i]),
                onOpenDone: _openDone,
              ),
            ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Ds.gutter),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(AppIcons.sparkle, size: 14, color: Ds.muted(context)),
              const SizedBox(width: 8),
              Expanded(child: Text(loc.planReadByAi, style: Ds.secondary(context))),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sin plan: qué hace la sección y una sola acción.
class _Empty extends StatelessWidget {
  const _Empty({required this.onUpload});

  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(Ds.gutter, 28, Ds.gutter, 32),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(Ds.radiusBlock),
              border: Border.all(color: AppColors.steelLine),
            ),
            child: Icon(AppIcons.pdf, size: 26, color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
        const SizedBox(height: 22),
        Text(loc.planEmptyTitle, style: Ds.display(context).copyWith(fontSize: 34)),
        const SizedBox(height: 10),
        Text(loc.planEmptyBody, style: Ds.body(context).copyWith(color: Ds.muted(context))),
        const SizedBox(height: 28),
        DsButton(icon: AppIcons.pdf, label: loc.planUpload, onPressed: onUpload),
        const SizedBox(height: 14),
        Text(loc.planReplaceHint, style: Ds.secondary(context)),
      ],
    );
  }
}

/// Mientras la IA lee el PDF.
class _Reading extends StatelessWidget {
  const _Reading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 18),
            Text(text, textAlign: TextAlign.center, style: Ds.secondary(context)),
          ],
        ),
      ),
    );
  }
}

/// Los 7 días de la semana del plan.
class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.plan,
    required this.selected,
    required this.today,
    required this.isDone,
    required this.onSelect,
  });

  final WeekPlan plan;
  final int selected;
  final int? today;
  final bool Function(int weekday) isDone;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final on = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Ds.gutter - 4),
      child: Row(
        children: [
          for (var wd = 1; wd <= 7; wd++)
            Expanded(
              child: Builder(
                builder: (context) {
                  final date = plan.dateOf(wd);
                  final has = plan.days.containsKey(wd);
                  final sel = wd == selected;
                  final done = has && isDone(wd);
                  final letter = DateFormat.E(locale).format(date).replaceAll('.', '');
                  return Semantics(
                    button: true,
                    selected: sel,
                    label: DateFormat.MMMMEEEEd(locale).format(date),
                    excludeSemantics: true,
                    child: DsPressable(
                      scale: 0.94,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (!sel) HapticFeedback.selectionClick();
                          onSelect(wd);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.surfaceHigh : Colors.transparent,
                            borderRadius: BorderRadius.circular(Ds.radiusButton),
                            border: Border.all(
                              color: sel ? AppColors.steelLine : Colors.transparent,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                letter.length > 3 ? letter.substring(0, 3) : letter,
                                style: Ds.label(
                                  context,
                                ).copyWith(fontSize: 10.5, color: sel ? on : null),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${date.day}',
                                style: Ds.display(context).copyWith(
                                  fontSize: 22,
                                  color: has || sel ? on : Ds.muted(context).withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: !has
                                      ? Colors.transparent
                                      : (done ? Ds.done : AppColors.blue),
                                ),
                              ),
                              if (wd == today) ...[
                                const SizedBox(height: 3),
                                Container(width: 12, height: 1.5, color: on.withValues(alpha: 0.5)),
                              ] else
                                const SizedBox(height: 4.5),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Un bloque del día: encabezado, movimientos y su acción.
class _BlockView extends StatelessWidget {
  const _BlockView({
    required this.store,
    required this.block,
    required this.first,
    required this.done,
    required this.onStart,
    required this.onOpenDone,
  });

  final TrainingStore store;
  final PlanBlock block;
  final bool first;
  final Workout? done;
  final VoidCallback onStart;
  final ValueChanged<Workout> onOpenDone;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final wod = block.wod;
    final color = styleColor(wod.style);
    final header = [
      if (block.title != null) block.title!.toUpperCase(),
      if (wod.formatLabel.isNotEmpty) wod.formatLabel.toUpperCase(),
    ].join('  ·  ');
    final showName = wod.name.trim().toLowerCase() != (block.title ?? '').trim().toLowerCase();

    return Container(
      margin: const EdgeInsets.fromLTRB(Ds.gutter, 16, Ds.gutter, 0),
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: Ds.hairline(context))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  header.isEmpty ? styleName(loc, wod.style).toUpperCase() : header,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Ds.label(context).copyWith(color: color),
                ),
              ),
            ],
          ),
          if (showName) ...[
            const SizedBox(height: 8),
            Text(wod.name, style: Ds.display(context).copyWith(fontSize: 28)),
          ],
          const SizedBox(height: 8),
          for (var i = 0; i < wod.items.length; i++)
            WodItemRow(
              item: wod.items[i],
              store: store,
              unit: store.storage.listUnit,
              first: i == 0,
            ),
          if (block.notes != null) ...[
            const SizedBox(height: 6),
            Text(block.notes!, style: Ds.secondary(context).copyWith(fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 14),
          if (done != null)
            DsPressable(
              child: Material(
                color: Ds.done.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Ds.radiusButton),
                child: InkWell(
                  borderRadius: BorderRadius.circular(Ds.radiusButton),
                  splashFactory: NoSplash.splashFactory,
                  onTap: () => onOpenDone(done!),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        const Icon(AppIcons.checkCircle, color: Ds.done, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            done!.score?.isNotEmpty == true
                                ? '${loc.todayDone} · ${done!.score}'
                                : loc.todayDone,
                            style: const TextStyle(
                              color: Ds.done,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Icon(AppIcons.chevron, color: Ds.done, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            DsButton(
              kind: first ? DsButtonKind.primary : DsButtonKind.outline,
              height: 48,
              icon: AppIcons.play,
              label: loc.todayStart,
              onPressed: onStart,
            ),
        ],
      ),
    );
  }
}

/// Día sin entrenamiento en el plan.
class _RestDay extends StatelessWidget {
  const _RestDay({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Ds.gutter, 12, Ds.gutter, 0),
      child: Row(
        children: [
          Icon(AppIcons.rest, size: 22, color: Ds.muted(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Ds.body(context).copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(body, style: Ds.secondary(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

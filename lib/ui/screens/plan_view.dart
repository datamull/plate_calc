import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/training.dart';
import '../../models/week_plan.dart';
import '../../services/plan_ai.dart';
import '../../services/plan_reminders.dart';
import '../../services/training_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/ds.dart';
import 'board_scan.dart';
import 'training_home.dart';
import 'workout_detail_screen.dart';

/// Plan semanal: se sube el PDF que manda el coach, la IA lo lee y cada día
/// queda listo para entrenar. Cada PDF queda guardado con su semana y se
/// recorren con las flechas.
class PlanView extends StatefulWidget {
  const PlanView({super.key, required this.store});

  final TrainingStore store;

  @override
  State<PlanView> createState() => _PlanViewState();
}

class _PlanViewState extends State<PlanView> {
  TrainingStore get _store => widget.store;

  /// Plan elegido con las flechas (null = el de esta semana).
  String? _planId;
  int? _day;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncReminders());
  }

  Future<void> _syncReminders() async {
    if (!mounted) return;
    final loc = AppLocalizations.of(context);
    await PlanReminders.sync(
      _store,
      title: loc.reminderTitle,
      body: loc.reminderBody,
      fallbackName: loc.scanDefaultName,
    );
  }

  Future<void> _upload() async {
    final loc = AppLocalizations.of(context);
    if (!PlanAi.enabled) return _snack(loc.planAiOff);

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
    setState(() => _busy = false);
    if (json == null) {
      return _snack(switch (error) {
        PlanReadError.tooLarge => loc.planErrorTooLarge,
        PlanReadError.unreadable => loc.planErrorUnreadable,
        _ => loc.planErrorOffline,
      });
    }

    // Se elige la semana antes de guardar (el PDF suele llegar el fin de
    // semana anterior).
    final now = DateTime.now();
    final pick = await _pickWeek(
      initial: WeekPlan.suggestedWeek(json, now),
      title: loc.planWeekPickTitle,
      body: loc.planWeekPickBody,
      confirm: loc.planWeekSave,
    );
    if (pick?.week == null || !mounted) return;
    final env = WeekPlan.envelope(json, now: now, fileName: file.name, weekStart: pick!.week);
    await _store.saveWeekPlan(env);
    if (!mounted) return;
    unawaited(HapticFeedback.mediumImpact());
    setState(() {
      _planId = '${env['id']}';
      _day = null;
    });
    if (_store.planRemindersOn) await PlanReminders.requestPermission();
    await _syncReminders();
  }

  Future<({DateTime? week, bool delete})?> _pickWeek({
    required DateTime initial,
    required String title,
    String? body,
    required String confirm,
    String? exceptId,
    bool canDelete = false,
  }) => showModalBottomSheet<({DateTime? week, bool delete})>(
    context: context,
    showDragHandle: true,
    builder: (_) => _WeekSheet(
      store: _store,
      initial: initial,
      title: title,
      body: body,
      confirm: confirm,
      exceptId: exceptId,
      canDelete: canDelete,
    ),
  );

  /// Tocar la fecha: cambiar la semana del plan o eliminarlo.
  Future<void> _editWeek(WeekPlan plan) async {
    final loc = AppLocalizations.of(context);
    final pick = await _pickWeek(
      initial: plan.weekStart,
      title: loc.planMoveTitle,
      confirm: loc.planMoveSave,
      exceptId: plan.id,
      canDelete: true,
    );
    if (pick == null || !mounted) return;
    if (pick.delete) {
      await _store.deleteWeekPlan(plan.id);
      _planId = null;
    } else if (pick.week != null) {
      await _store.moveWeekPlan(plan.id, pick.week!);
      _planId = plan.id;
    }
    if (!mounted) return;
    setState(() => _day = null);
    await _syncReminders();
  }

  Future<void> _markDayDone(WeekPlan plan, int day, List<PlanBlock> blocks) async {
    final loc = AppLocalizations.of(context);
    await _store.markPlanDone(
      [for (final b in blocks) b.wod],
      _store.storage.listUnit,
      plan.dateOf(day),
    );
    if (!mounted) return;
    unawaited(HapticFeedback.mediumImpact());
    setState(() {});
    _snack(loc.planMarkedDone);
    await _syncReminders();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _start(PlanBlock b, DateTime day) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ScanReviewScreen(store: _store, wod: b.wod, byAi: true),
      ),
    );
    if (!mounted) return;
    setState(() {});
    await _syncReminders();
  }

  Future<void> _openDone(Workout w) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WorkoutDetailScreen(store: _store, workoutId: w.id),
      ),
    );
    if (!mounted) return;
    setState(() {});
    await _syncReminders();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (_busy) return _Reading(text: loc.planReading);
    final plans = _store.weekPlans(fallbackName: loc.scanDefaultName);
    if (plans.isEmpty) return _Empty(onUpload: _upload);

    final plan =
        plans.where((p) => p.id == _planId).firstOrNull ??
        _store.weekPlan(fallbackName: loc.scanDefaultName)!;
    final index = plans.indexOf(plan);
    final today = DateTime.now();
    final inWeek = plan.contains(today);
    final day = _day ?? (inWeek ? today.weekday : plan.days.keys.reduce((a, b) => a < b ? a : b));
    final blocks = plan.days[day] ?? const <PlanBlock>[];
    final pending = blocks.where((b) => _store.planDone(b.wod) == null).toList();
    final locale = Localizations.localeOf(context).toString();

    void go(int i) {
      HapticFeedback.selectionClick();
      setState(() {
        _planId = plans[i].id;
        _day = null;
      });
    }

    // Entrenó sin registrar en la app: botón fijo abajo para dejar todo el
    // día como hecho (no se muestra en días futuros ni si ya está hecho).
    final canMark = pending.isNotEmpty && !plan.dateOf(day).isAfter(today);

    final list = ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // Encabezado: semana (tocar para cambiarla) y flechas entre planes.
        Padding(
          padding: const EdgeInsets.fromLTRB(Ds.gutter, 4, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _editWeek(plan),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                loc
                                    .planWeekOf(DateFormat.MMMd(locale).format(plan.weekStart))
                                    .toUpperCase(),
                                style: Ds.label(context),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(AppIcons.edit, size: 13, color: Ds.muted(context)),
                          ],
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
                ),
              ),
              _ArrowButton(
                left: true,
                label: loc.planPrevWeek,
                onTap: index > 0 ? () => go(index - 1) : null,
              ),
              _ArrowButton(
                left: false,
                label: loc.planNextWeekA11y,
                onTap: index < plans.length - 1 ? () => go(index + 1) : null,
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
                onStart: () => _start(blocks[i], plan.dateOf(day)),
                onOpenDone: _openDone,
              ),
            ),
        const SizedBox(height: 18),
        DsBlock(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            children: [
              DsRow(
                leading: Icon(AppIcons.pdf, size: 20, color: Ds.muted(context)),
                title: loc.planReplace,
                onTap: _upload,
                divider: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
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

    return Column(
      children: [
        Expanded(child: list),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: canMark
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: const Border(top: BorderSide(color: AppColors.steelLine)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(Ds.gutter, 12, Ds.gutter, 12),
                    child: DsButton(
                      kind: DsButtonKind.secondary,
                      icon: AppIcons.checkCircle,
                      label: loc.planMarkDone,
                      onPressed: () => _markDayDone(plan, day, pending),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Flecha para pasar a la semana anterior o siguiente.
class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.left, required this.label, required this.onTap});

  final bool left;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final on = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: DsPressable(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Transform.flip(
                flipX: left,
                child: Icon(
                  AppIcons.chevron,
                  size: 18,
                  color: onTap == null ? Ds.muted(context).withValues(alpha: 0.35) : on,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Elegir la semana de un plan: ‹ semana del 16 nov. ›
class _WeekSheet extends StatefulWidget {
  const _WeekSheet({
    required this.store,
    required this.initial,
    required this.title,
    required this.confirm,
    this.body,
    this.exceptId,
    this.canDelete = false,
  });

  final TrainingStore store;
  final DateTime initial;
  final String title;
  final String? body;
  final String confirm;
  final String? exceptId;
  final bool canDelete;

  @override
  State<_WeekSheet> createState() => _WeekSheetState();
}

class _WeekSheetState extends State<_WeekSheet> {
  late DateTime _week = WeekPlan.mondayOf(widget.initial);

  void _shift(int weeks) {
    HapticFeedback.selectionClick();
    setState(() => _week = DateTime(_week.year, _week.month, _week.day + 7 * weeks));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final thisMonday = WeekPlan.mondayOf(DateTime.now());
    final diff = (_week.difference(thisMonday).inHours / (24 * 7)).round();
    final relative = switch (diff) {
      0 => loc.planThisWeek,
      1 => loc.planNextWeek,
      -1 => loc.planLastWeek,
      _ => null,
    };
    final end = DateTime(_week.year, _week.month, _week.day + 6);
    final taken = widget.store.hasPlanFor(_week, exceptId: widget.exceptId);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Ds.gutter, 0, Ds.gutter, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: Ds.title(context)),
            if (widget.body != null) ...[
              const SizedBox(height: 6),
              Text(widget.body!, style: Ds.secondary(context)),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                _ArrowButton(left: true, label: loc.planPrevWeek, onTap: () => _shift(-1)),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${DateFormat.MMMd(locale).format(_week)} – '
                        '${DateFormat.MMMd(locale).format(end)}',
                        textAlign: TextAlign.center,
                        style: Ds.display(context).copyWith(fontSize: 28),
                      ),
                      const SizedBox(height: 4),
                      Text((relative ?? '${_week.year}').toUpperCase(), style: Ds.label(context)),
                    ],
                  ),
                ),
                _ArrowButton(left: false, label: loc.planNextWeekA11y, onTap: () => _shift(1)),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: taken ? 1 : 0,
              child: Text(
                loc.planWeekTaken,
                textAlign: TextAlign.center,
                style: Ds.secondary(context),
              ),
            ),
            const SizedBox(height: 16),
            DsButton(
              icon: AppIcons.check,
              label: widget.confirm,
              onPressed: () => Navigator.pop(context, (week: _week, delete: false)),
            ),
            if (widget.canDelete) ...[
              const SizedBox(height: 4),
              DsButton(
                kind: DsButtonKind.ghost,
                icon: AppIcons.trash,
                label: loc.planDelete,
                onPressed: () => Navigator.pop(context, (week: null, delete: true)),
              ),
            ],
          ],
        ),
      ),
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
    // Sin nombre propio (p. ej. "AMRAP 1′" generado): no repetir lo que ya dice
    // la línea de arriba.
    final n = wod.name.trim().toLowerCase();
    final showName =
        n.isNotEmpty &&
        n != (block.title ?? '').trim().toLowerCase() &&
        !wod.formatLabel.toLowerCase().startsWith(n);

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

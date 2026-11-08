import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/training.dart';
import '../../services/training_store.dart';
import '../../utils/format.dart';
import '../widgets/training_widgets.dart';
import 'plan_screen.dart';
import '../widgets/app_icons.dart';

/// Crear o editar una rutina / programa (también lo usa el coach).
class PlanEditorScreen extends StatefulWidget {
  const PlanEditorScreen({super.key, required this.store, required this.plan});

  final TrainingStore store;
  final Plan plan;

  @override
  State<PlanEditorScreen> createState() => _PlanEditorScreenState();
}

class _PlanEditorScreenState extends State<PlanEditorScreen> {
  // Se edita una copia; solo se guarda al tocar Guardar.
  late final Plan _plan = Plan.fromJson(widget.plan.toJson())!;
  late final _name = TextEditingController(text: _plan.name);
  late final _notes = TextEditingController(text: _plan.notes);

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context);
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.planNameRequired)));
      return;
    }
    _plan
      ..name = _name.text.trim()
      ..notes = _notes.text.trim();
    _plan.days.removeWhere((d) => d.items.isEmpty);
    if (_plan.days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.planNeedsExercise)));
      _plan.days.add(PlanDay(name: loc.planDayDefault(1)));
      setState(() {});
      return;
    }
    await widget.store.savePlan(_plan);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _addItem(PlanDay day) async {
    final lift = await pickExercise(context, widget.store);
    if (lift == null || lift.trim().isEmpty || !mounted) return;
    final item = await _editItem(PlanItem(lift: lift.trim()));
    if (item != null) setState(() => day.items.add(item));
  }

  Future<PlanItem?> _editItem(PlanItem item) => showDialog<PlanItem>(
    context: context,
    builder: (_) => _ItemDialog(item: item),
  );

  Future<void> _renameDay(PlanDay day) async {
    final loc = AppLocalizations.of(context);
    final ctrl = TextEditingController(text: day.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.planDayName),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(loc.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: Text(loc.ok)),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) setState(() => day.name = name.trim());
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final unit = widget.store.storage.listUnit;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.planEditorTitle),
        actions: [TextButton(onPressed: _save, child: Text(loc.save))],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: loc.planNameLabel,
              hintText: loc.planNameHint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notes,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: loc.planNotesLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          for (var d = 0; d < _plan.days.length; d++)
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _plan.days[d].name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            final day = _plan.days[d];
                            if (v == 'rename') _renameDay(day);
                            if (v == 'copy') {
                              setState(
                                () => _plan.days.insert(
                                  d + 1,
                                  PlanDay.fromJson(day.toJson())
                                    ..name = loc.planDayDefault(_plan.days.length + 1),
                                ),
                              );
                            }
                            if (v == 'delete') setState(() => _plan.days.removeAt(d));
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(value: 'rename', child: Text(loc.rename)),
                            PopupMenuItem(value: 'copy', child: Text(loc.planDayDuplicate)),
                            PopupMenuItem(value: 'delete', child: Text(loc.delete)),
                          ],
                        ),
                      ],
                    ),
                    for (var i = 0; i < _plan.days[d].items.length; i++)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: liftIconFor(
                          widget.store.storage,
                          _plan.days[d].items[i].lift,
                          size: 32,
                        ),
                        title: Text(planItemText(loc, widget.store, _plan.days[d].items[i], unit)),
                        trailing: IconButton(
                          icon: const Icon(AppIcons.close),
                          onPressed: () => setState(() => _plan.days[d].items.removeAt(i)),
                        ),
                        onTap: () async {
                          final edited = await _editItem(_plan.days[d].items[i]);
                          if (edited != null) setState(() => _plan.days[d].items[i] = edited);
                        },
                      ),
                    TextButton.icon(
                      icon: const Icon(AppIcons.plus),
                      label: Text(loc.planAddExercise),
                      onPressed: () => _addItem(_plan.days[d]),
                    ),
                  ],
                ),
              ),
            ),
          OutlinedButton.icon(
            icon: const Icon(AppIcons.plus),
            label: Text(loc.planAddDay),
            onPressed: () => setState(
              () => _plan.days.add(PlanDay(name: loc.planDayDefault(_plan.days.length + 1))),
            ),
          ),
        ],
      ),
    );
  }
}

enum _LoadMode { percent, weight, none }

class _ItemDialog extends StatefulWidget {
  const _ItemDialog({required this.item});

  final PlanItem item;

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  late final _sets = TextEditingController(text: '${widget.item.sets}');
  late final _reps = TextEditingController(text: '${widget.item.reps}');
  late _LoadMode _mode = widget.item.percent != null
      ? _LoadMode.percent
      : widget.item.weight != null
      ? _LoadMode.weight
      : _LoadMode.percent;
  late final _value = TextEditingController(
    text: widget.item.percent != null
        ? fmtWeight(widget.item.percent!)
        : widget.item.weight != null
        ? fmtWeight(widget.item.weight!)
        : '',
  );

  @override
  void dispose() {
    _sets.dispose();
    _reps.dispose();
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    Widget num(TextEditingController c, String label) => Expanded(
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );

    return AlertDialog(
      title: Text(widget.item.lift),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                num(_sets, loc.planSets),
                const SizedBox(width: 10),
                num(_reps, loc.workoutReps),
              ],
            ),
            const SizedBox(height: 14),
            SegmentedButton<_LoadMode>(
              segments: [
                ButtonSegment(value: _LoadMode.percent, label: Text(loc.planLoadPercent)),
                ButtonSegment(value: _LoadMode.weight, label: Text(loc.planLoadWeight)),
                ButtonSegment(value: _LoadMode.none, label: Text(loc.planLoadFree)),
              ],
              selected: {_mode},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            if (_mode != _LoadMode.none) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _value,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _mode == _LoadMode.percent
                      ? loc.planPercentLabel
                      : loc.planWeightLabel,
                  suffixText: _mode == _LoadMode.percent ? '%' : null,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.cancel)),
        TextButton(
          onPressed: () {
            final v = parseNumber(_value.text);
            Navigator.pop(
              context,
              PlanItem(
                lift: widget.item.lift,
                sets: (int.tryParse(_sets.text.trim()) ?? 1).clamp(1, 50),
                reps: (int.tryParse(_reps.text.trim()) ?? 1).clamp(1, 100),
                percent: _mode == _LoadMode.percent && v != null && v > 0 ? v : null,
                weight: _mode == _LoadMode.weight && v != null && v > 0 ? v : null,
              ),
            );
          },
          child: Text(loc.ok),
        ),
      ],
    );
  }
}

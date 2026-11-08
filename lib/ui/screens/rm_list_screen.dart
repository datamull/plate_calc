import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/lift_names.dart';
import '../../models/weight_unit.dart';
import '../../services/app_storage.dart';
import '../../services/lift_collection.dart';
import '../../utils/format.dart';
import '../widgets/ds.dart';
import '../widgets/lift_icon.dart';
import '../widgets/rm_history_sheet.dart';
import 'home_screen.dart';
import 'simple_rm_screen.dart';
import 'unit_converter_screen.dart';
import '../widgets/app_icons.dart';

class RmListScreen extends StatefulWidget {
  const RmListScreen({
    super.key,
    required this.storage,
    required this.collection,
    this.onOpenSettings,
  });

  final AppStorage storage;

  /// Movimientos que muestra esta lista (Haltero o un grupo de Gym).
  final LiftCollection collection;
  final VoidCallback? onOpenSettings;

  @override
  State<RmListScreen> createState() => _RmListScreenState();
}

class _RmListScreenState extends State<RmListScreen> {
  AppStorage get _storage => widget.storage;

  late WeightUnit _unit = _storage.listUnit;

  Future<void> _setUnit(WeightUnit u) async {
    setState(() => _unit = u);
    await _storage.setListUnit(u);
  }

  Future<void> _addLiftDialog() async {
    final loc = AppLocalizations.of(context);
    final res = await showDialog<({String name, bool barbell})>(
      context: context,
      builder: (_) => _AddLiftDialog(asksBarbell: widget.collection.asksBarbell),
    );
    if (res == null || res.name.trim().isEmpty) return;
    final added = await widget.collection.add(res.name, barbell: res.barbell);
    if (!mounted) return;
    if (!added) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.liftAlreadyExists)));
    }
    setState(() {});
  }

  Future<void> _openLift(String lift) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => widget.collection.isBarbell(lift)
            ? HomeScreen(
                storage: _storage,
                movementName: lift,
                initialUnit: _unit,
                onDelete: widget.collection.delete,
              )
            : SimpleRmScreen(
                storage: _storage,
                movementName: lift,
                initialUnit: _unit,
                onDelete: widget.collection.delete,
              ),
      ),
    );
    // Al volver se refrescan los RM (o se quita el movimiento si se borró).
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final lifts = widget.collection.lifts;

    return Scaffold(
      appBar: AppBar(
        actions: [
          SizedBox(
            width: 112,
            child: DsSegmented(
              compact: true,
              labels: [for (final u in WeightUnit.values) u.label],
              selected: WeightUnit.values.indexOf(_unit),
              onChanged: (i) => _setUnit(WeightUnit.values[i]),
            ),
          ),
          if (widget.onOpenSettings != null)
            IconButton(
              tooltip: loc.settingsTooltip,
              icon: const Icon(AppIcons.settings),
              onPressed: widget.onOpenSettings,
            ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          DsFab(
            icon: AppIcons.plates,
            tooltip: loc.converterTooltip,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const UnitConverterScreen())),
          ),
          const SizedBox(width: 12),
          DsFab(
            primary: true,
            icon: AppIcons.plus,
            tooltip: loc.addLiftTitle,
            onPressed: _addLiftDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          DsLargeHeader(title: widget.collection.title(loc)),
          const SizedBox(height: 12),
          DsBlock(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Ds.radiusBlock),
              child: Column(
                children: [
                  for (var i = 0; i < lifts.length; i++)
                    _LiftRow(
                      name: liftDisplayName(lifts[i]),
                      pose: LiftPose.parse(_storage.liftIcon(lifts[i])),
                      lastRm: _storage.lastRm(lifts[i], _unit),
                      last: _storage.history(lifts[i], _unit).firstOrNull,
                      unit: _unit,
                      divider: i < lifts.length - 1,
                      onTap: () => _openLift(lifts[i]),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de un movimiento: ícono, nombre y su último RM.
class _LiftRow extends StatelessWidget {
  const _LiftRow({
    required this.name,
    required this.pose,
    required this.lastRm,
    required this.last,
    required this.unit,
    required this.divider,
    required this.onTap,
  });

  final String name;
  final LiftPose? pose;
  final double? lastRm;
  final RmEntry? last;
  final WeightUnit unit;
  final bool divider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final rm = last?.reps != null
        ? rmEntryText(loc, last!, unit.label)
        : lastRm == null
        ? loc.noRmLabel
        : loc.historyRowRm(fmtWeight(lastRm!), unit.label);
    return DsRow(
      leading: LiftIcon(liftName: name, pose: pose, size: 48),
      title: name,
      subtitle: rm,
      divider: divider,
      onTap: onTap,
    );
  }
}

/// Diálogo con su propio controlador (en la v1 el controlador nunca se
/// liberaba).
class _AddLiftDialog extends StatefulWidget {
  const _AddLiftDialog({required this.asksBarbell});

  final bool asksBarbell;

  @override
  State<_AddLiftDialog> createState() => _AddLiftDialogState();
}

class _AddLiftDialogState extends State<_AddLiftDialog> {
  final _ctrl = TextEditingController();
  bool _barbell = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop((name: _ctrl.text.trim(), barbell: _barbell));

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(loc.addLiftTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(hintText: loc.addLiftHint),
            onSubmitted: (_) => _submit(),
          ),
          if (widget.asksBarbell) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _barbell,
              onChanged: (v) => setState(() => _barbell = v),
              title: Text(loc.barbellSwitch),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.deleteMovementCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(loc.saveLabel)),
      ],
    );
  }
}

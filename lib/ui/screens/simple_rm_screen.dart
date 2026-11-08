import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/lift_names.dart';
import '../../models/weight_unit.dart';
import '../../services/app_storage.dart';
import '../../utils/format.dart';
import '../widgets/ds.dart';
import '../widgets/glass_button.dart';
import '../widgets/lift_icon.dart';
import '../widgets/rm_history_sheet.dart';
import 'unit_converter_screen.dart';
import '../widgets/app_icons.dart';

/// Ejercicio sin barra olímpica (mancuernas, máquina, peso corporal): se
/// guarda peso, repeticiones hechas y, si se quiere, rondas, con su
/// historial. No tiene calculadora de discos.
class SimpleRmScreen extends StatefulWidget {
  const SimpleRmScreen({
    super.key,
    required this.storage,
    required this.movementName,
    required this.initialUnit,
    required this.onDelete,
  });

  final AppStorage storage;
  final String movementName;
  final WeightUnit initialUnit;
  final Future<void> Function(String lift) onDelete;

  @override
  State<SimpleRmScreen> createState() => _SimpleRmScreenState();
}

class _SimpleRmScreenState extends State<SimpleRmScreen> {
  AppStorage get _storage => widget.storage;
  String get _lift => widget.movementName;

  late WeightUnit _unit;
  final _rmCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  final _roundsCtrl = TextEditingController();

  // Igual que en la calculadora: al cambiar kg <-> lb se convierte desde el
  // valor original para no acumular redondeos.
  double? _rmOrigin;
  WeightUnit? _rmOriginUnit;
  bool _settingRmText = false;

  @override
  void initState() {
    super.initState();
    _loadUnit(widget.initialUnit);
    _rmCtrl.addListener(_onRmChanged);
  }

  @override
  void dispose() {
    _rmCtrl.dispose();
    _repsCtrl.dispose();
    _roundsCtrl.dispose();
    super.dispose();
  }

  void _onRmChanged() {
    if (_settingRmText) return;
    final v = parseNumber(_rmCtrl.text);
    _rmOrigin = (v != null && v > 0) ? v : null;
    _rmOriginUnit = _unit;
  }

  void _loadUnit(WeightUnit u) {
    _unit = u;
    final rm = _storage.lastRm(_lift, u);
    _settingRmText = true;
    _rmCtrl.text = rm == null ? '' : fmtWeight(rm);
    _settingRmText = false;
    _rmOrigin = rm;
    _rmOriginUnit = u;
    // Se precargan las reps y rondas del último registro.
    final last = _storage.history(_lift, u).firstOrNull;
    if (last?.reps != null && _repsCtrl.text.isEmpty) {
      _repsCtrl.text = '${last!.reps}';
      _roundsCtrl.text = last.rounds == null ? '' : '${last.rounds}';
    }
  }

  void _switchUnit(WeightUnit u) {
    if (u == _unit) return;
    final origin = _rmOrigin;
    final originUnit = _rmOriginUnit;
    if (origin == null || originUnit == null) {
      setState(() => _loadUnit(u));
      return;
    }
    final value = originUnit == u ? origin : u.round(originUnit.convert(origin, u));
    setState(() {
      _unit = u;
      _settingRmText = true;
      _rmCtrl.text = fmtWeight(value);
      _settingRmText = false;
    });
  }

  double get _rm => parseNumber(_rmCtrl.text) ?? 0;

  LiftPose? get _iconPose => LiftPose.parse(_storage.liftIcon(_lift));

  Future<void> _chooseIcon() async {
    final picked = await showLiftIconPicker(context, liftName: _lift, current: _iconPose);
    if (picked == null) return;
    await _storage.setLiftIcon(_lift, picked.pose?.name);
    if (mounted) setState(() {});
  }

  int? get _reps {
    final v = int.tryParse(_repsCtrl.text.trim());
    return (v != null && v > 0) ? v : null;
  }

  int? get _rounds {
    final v = int.tryParse(_roundsCtrl.text.trim());
    return (v != null && v > 0) ? v : null;
  }

  Future<void> _saveRm() async {
    final loc = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    FocusManager.instance.primaryFocus?.unfocus();
    final reps = _reps;
    // Sin reps hace falta un peso (sería un RM); con reps el peso puede ser 0
    // (peso corporal: dominadas, abdominales...).
    if (reps == null && _rm <= 0) {
      messenger.showSnackBar(SnackBar(content: Text(loc.saveSetInvalidSnack)));
      return;
    }
    await _storage.saveRm(_lift, _unit, _rm, reps: reps, rounds: reps == null ? null : _rounds);
    if (!mounted) return;
    setState(() {});
    messenger.showSnackBar(SnackBar(content: Text(loc.saveSetOkSnack(liftDisplayName(_lift)))));
  }

  Future<void> _deleteMovement() async {
    final loc = AppLocalizations.of(context);
    final name = liftDisplayName(_lift);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.deleteMovementDialogTitle),
        content: Text(loc.deleteMovementDialogContent(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.deleteMovementCancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc.deleteMovementConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await widget.onDelete(_lift);
      messenger.showSnackBar(SnackBar(content: Text(loc.deleteMovementOkSnack(name))));
      navigator.pop();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(loc.deleteMovementFailSnack)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final name = liftDisplayName(_lift);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: loc.chooseIconTooltip,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _chooseIcon,
                child: LiftIcon(liftName: _lift, pose: _iconPose, size: 34),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(child: Text(name, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: loc.converterTooltip,
            icon: const Icon(AppIcons.plates),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const UnitConverterScreen())),
          ),
          IconButton(
            tooltip: loc.saveRmTooltip,
            onPressed: _saveRm,
            icon: const Icon(AppIcons.save),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Text(loc.unitsLabel),
                const SizedBox(width: 12),
                SizedBox(
                  width: 128,
                  child: DsSegmented(
                    compact: true,
                    labels: [for (final u in WeightUnit.values) u.label],
                    selected: WeightUnit.values.indexOf(_unit),
                    onChanged: (i) => _switchUnit(WeightUnit.values[i]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rmCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: loc.simpleWeightLabel,
                helperText: loc.simpleWeightHelp,
                suffixText: _unit.label,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _repsCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(labelText: loc.simpleRepsLabel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _roundsCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: loc.simpleRoundsLabel,
                      helperText: loc.optional,
                    ),
                    onSubmitted: (_) => _saveRm(),
                  ),
                ),
              ],
            ),
            if (_storage.history(_lift, _unit).firstOrNull case final last?) ...[
              const SizedBox(height: 12),
              Text(
                loc.simpleLastEntry(rmEntryText(loc, last, _unit.label)),
                style: theme.textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              loc.noCalculatorHint,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            GlassButton(onPressed: _saveRm, prominent: true, label: loc.saveSetButton),
            const SizedBox(height: 8),
            GlassButton(
              onPressed: () => showRmHistorySheet(
                context,
                storage: _storage,
                lift: _lift,
                displayName: name,
                unit: _unit,
              ),
              icon: AppIcons.history,
              label: loc.historyButton,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              onPressed: _deleteMovement,
              icon: const Icon(AppIcons.trash),
              label: Text(loc.deleteMovementButton(name)),
            ),
          ],
        ),
      ),
    );
  }
}

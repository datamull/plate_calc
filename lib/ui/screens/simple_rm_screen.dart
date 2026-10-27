import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/lift_names.dart';
import '../../models/weight_unit.dart';
import '../../services/app_storage.dart';
import '../../utils/format.dart';
import '../widgets/glass_button.dart';
import '../widgets/lift_icon.dart';
import '../widgets/rm_history_sheet.dart';
import 'unit_converter_screen.dart';

/// Ejercicio sin barra olímpica (mancuernas, máquina, peso corporal): solo se
/// guarda el RM y su historial, sin calculadora de discos.
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

  Future<void> _saveRm() async {
    final loc = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    FocusManager.instance.primaryFocus?.unfocus();
    if (_rm <= 0) {
      messenger.showSnackBar(SnackBar(content: Text(loc.saveRmInvalidSnack)));
      return;
    }
    await _storage.saveRm(_lift, _unit, _rm);
    messenger.showSnackBar(
      SnackBar(content: Text(loc.saveRmOkSnack(liftDisplayName(_lift), _unit.label))),
    );
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
            icon: const Icon(Icons.calculate_outlined),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const UnitConverterScreen())),
          ),
          IconButton(
            tooltip: loc.saveRmTooltip,
            onPressed: _saveRm,
            icon: const Icon(Icons.save_outlined),
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
                SegmentedButton<WeightUnit>(
                  showSelectedIcon: false,
                  segments: [
                    for (final u in WeightUnit.values)
                      ButtonSegment(value: u, label: Text(u.label)),
                  ],
                  selected: {_unit},
                  onSelectionChanged: (s) => _switchUnit(s.first),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rmCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: loc.rmFieldWithMovement(name),
                suffixText: _unit.label,
              ),
              onSubmitted: (_) => _saveRm(),
            ),
            const SizedBox(height: 12),
            Text(
              loc.noCalculatorHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            GlassButton(onPressed: _saveRm, prominent: true, label: loc.saveRmTooltip),
            const SizedBox(height: 8),
            GlassButton(
              onPressed: () => showRmHistorySheet(
                context,
                storage: _storage,
                lift: _lift,
                displayName: name,
                unit: _unit,
              ),
              icon: Icons.history,
              label: loc.historyButton,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              onPressed: _deleteMovement,
              icon: const Icon(Icons.delete_outline),
              label: Text(loc.deleteMovementButton(name)),
            ),
          ],
        ),
      ),
    );
  }
}

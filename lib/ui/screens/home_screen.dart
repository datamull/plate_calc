import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/lift_names.dart';
import '../../models/settings.dart';
import '../../models/target_mode.dart';
import '../../models/weight_unit.dart';
import '../../services/app_storage.dart';
import '../../services/plate_calculator.dart';
import '../../utils/format.dart';
import '../widgets/glass_button.dart';
import '../widgets/lift_icon.dart';
import '../widgets/percent_table.dart';
import '../widgets/result_sheet.dart';
import '../widgets/rm_history_sheet.dart';

/// Calculadora de discos para un movimiento.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.storage,
    required this.movementName,
    required this.initialUnit,
  });

  final AppStorage storage;

  /// Clave del movimiento (para guardar RM e historial).
  final String movementName;
  final WeightUnit initialUnit;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppStorage get _storage => widget.storage;
  String get _lift => widget.movementName;

  late WeightUnit _unit;
  late Settings _settings;
  late TargetMode _mode;

  final _rmCtrl = TextEditingController();
  final _pctCtrl = TextEditingController(text: '100');
  final _collarsCtrl = TextEditingController();

  String? _error;

  @override
  void initState() {
    super.initState();
    _mode = TargetMode.parse(_storage.targetMode);
    _loadUnit(widget.initialUnit);
    // Antes la tabla de % no se actualizaba al escribir el RM.
    _rmCtrl.addListener(_onInputChanged);
    _pctCtrl.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _rmCtrl.dispose();
    _pctCtrl.dispose();
    _collarsCtrl.dispose();
    super.dispose();
  }

  void _onInputChanged() => setState(() => _error = null);

  /// Carga el equipamiento y el último RM de la unidad.
  /// En la v1 cambiar kg <-> lb dejaba los discos de la otra unidad
  /// (p. ej. discos de 25 kg tratados como 25 lb) y no recargaba el RM.
  void _loadUnit(WeightUnit u) {
    _unit = u;
    _settings = _storage.settings(u);
    final rm = _storage.lastRm(_lift, u);
    _rmCtrl.text = rm == null ? '' : fmtWeight(rm);
    _collarsCtrl.text = fmtWeight(_settings.collarsWeight);
    _error = null;
  }

  double get _rm => parseNumber(_rmCtrl.text) ?? 0;

  /// Porcentaje escrito, limitado a 0–120 %.
  double get _fraction => ((parseNumber(_pctCtrl.text) ?? 0) / 100).clamp(0.0, 1.2);

  Future<void> _updateSettings(Settings s) async {
    setState(() => _settings = s);
    await _storage.saveSettings(s);
  }

  void _calculate() {
    final loc = AppLocalizations.of(context);
    FocusManager.instance.primaryFocus?.unfocus();

    if (_rm <= 0) return setState(() => _error = loc.errorRmMissing);
    if (_fraction <= 0) return setState(() => _error = loc.errorPercentInvalid);

    final t = _mode.targets(
      rm: _rm,
      fraction: _fraction,
      bar: _settings.barWeight,
      collars: _settings.collarsWeight,
    );
    final result = computePlates(
      target: t.total,
      barWeight: _settings.barWeight,
      collarsWeight: _settings.collarsWeight,
      plates: _settings.plates,
    );
    if (result == null) return setState(() => _error = loc.errorTargetTooLow);

    setState(() => _error = null);
    showResultSheet(context, result: result, unit: _unit);
  }

  Future<void> _saveRm() async {
    final loc = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
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
      await _storage.deleteLift(_lift);
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
    final targets = _mode.targets(
      rm: _rm,
      fraction: _fraction,
      bar: _settings.barWeight,
      collars: _settings.collarsWeight,
    );
    final barOptions = {..._unit.barOptions, _settings.barWeight}.toList();
    const numberKeyboard = TextInputType.numberWithOptions(decimal: true);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LiftIcon(liftName: _lift, size: 34),
            const SizedBox(width: 10),
            Flexible(child: Text(name, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
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
            // Unidades
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
                  onSelectionChanged: (s) {
                    _loadUnit(s.first);
                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Barra + collares
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: DropdownButtonFormField<double>(
                    key: ValueKey('bar-${_unit.name}'),
                    initialValue: _settings.barWeight,
                    decoration: InputDecoration(labelText: loc.barLabel),
                    items: [
                      for (final w in barOptions)
                        DropdownMenuItem(value: w, child: Text('${fmtWeight(w)} ${_unit.label}')),
                    ],
                    onChanged: (w) {
                      if (w != null) _updateSettings(_settings.copyWith(barWeight: w));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _collarsCtrl,
                    keyboardType: numberKeyboard,
                    decoration: InputDecoration(
                      labelText: loc.collarsLabel,
                      suffixText: _unit.label,
                    ),
                    onChanged: (v) {
                      final c = parseNumber(v);
                      if (c != null && c >= 0) {
                        _updateSettings(_settings.copyWith(collarsWeight: c));
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Interpretación del RM
            DropdownButtonFormField<TargetMode>(
              initialValue: _mode,
              decoration: InputDecoration(labelText: loc.interpretRmAs),
              items: [
                DropdownMenuItem(value: TargetMode.totalInclBar, child: Text(loc.modeTotalInclBar)),
                DropdownMenuItem(value: TargetMode.perSideWithoutBar, child: Text(loc.modePerSide)),
              ],
              onChanged: (m) {
                if (m == null) return;
                setState(() => _mode = m);
                _storage.setTargetMode(m.name);
              },
            ),
            const SizedBox(height: 12),

            // RM y %
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _rmCtrl,
                    keyboardType: numberKeyboard,
                    decoration: InputDecoration(
                      labelText: loc.rmFieldWithMovement(name),
                      suffixText: _unit.label,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _pctCtrl,
                    keyboardType: numberKeyboard,
                    decoration: InputDecoration(labelText: loc.percentLabel, suffixText: '%'),
                    onSubmitted: (_) => _calculate(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Objetivo derivado
            Text(
              loc.derivedTargetLabel(fmtWeight(_fraction * 100, maxDecimals: 1)),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              _mode == TargetMode.totalInclBar
                  ? loc.derivedTotal(fmtWeight(targets.total, maxDecimals: 1), _unit.label)
                  : loc.derivedPerSide(fmtWeight(targets.perSide, maxDecimals: 1), _unit.label),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            PercentTable(
              rm: _rm,
              mode: _mode,
              bar: _settings.barWeight,
              collars: _settings.collarsWeight,
              selectedPercent: (_fraction * 100).round(),
              onSelect: (p) {
                _pctCtrl.text = '$p';
                _calculate();
              },
            ),
            const SizedBox(height: 16),

            if (_error != null) ...[
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 8),
            ],

            GlassButton(onPressed: _calculate, prominent: true, label: loc.calculateButton),
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

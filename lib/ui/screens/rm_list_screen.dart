import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/lift_names.dart';
import '../../models/weight_unit.dart';
import '../../services/app_storage.dart';
import '../../utils/format.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_button.dart';
import 'home_screen.dart';
import 'unit_converter_screen.dart';

class RmListScreen extends StatefulWidget {
  const RmListScreen({super.key, required this.storage, this.onOpenSettings});

  final AppStorage storage;
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
    final name = await showDialog<String>(context: context, builder: (_) => const _AddLiftDialog());
    if (name == null || name.trim().isEmpty) return;
    final added = await _storage.addLift(name);
    if (!mounted) return;
    if (!added) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.liftAlreadyExists)));
    }
    setState(() {});
  }

  Future<void> _openLift(String lift) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HomeScreen(storage: _storage, movementName: lift, initialUnit: _unit),
      ),
    );
    // Al volver se refrescan los RM (o se quita el movimiento si se borró).
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final lifts = _storage.lifts;
    final crossAxisCount = (MediaQuery.sizeOf(context).width ~/ 160).clamp(2, 4);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.yourLiftsTitle),
        actions: [
          IconButton(
            tooltip: loc.converterTooltip,
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => const UnitConverterScreen())),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SegmentedButton<WeightUnit>(
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: [
                for (final u in WeightUnit.values) ButtonSegment(value: u, label: Text(u.label)),
              ],
              selected: {_unit},
              onSelectionChanged: (s) => _setUnit(s.first),
            ),
          ),
          IconButton(
            tooltip: loc.settingsTooltip,
            icon: const Icon(Icons.settings),
            onPressed: widget.onOpenSettings,
          ),
        ],
      ),
      floatingActionButton: Tooltip(
        message: loc.addLiftTitle,
        child: GlassButton(
          circular: true,
          prominent: true,
          tint: AppColors.purple,
          onPressed: _addLiftDialog,
          icon: Icons.add,
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: lifts.length,
        itemBuilder: (context, i) {
          final lift = lifts[i];
          return _LiftCard(
            name: liftDisplayName(lift),
            lastRm: _storage.lastRm(lift, _unit),
            unit: _unit,
            onTap: () => _openLift(lift),
          );
        },
      ),
    );
  }
}

class _LiftCard extends StatelessWidget {
  const _LiftCard({
    required this.name,
    required this.lastRm,
    required this.unit,
    required this.onTap,
  });

  final String name;
  final double? lastRm;
  final WeightUnit unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 28),
              const SizedBox(height: 8),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                lastRm == null ? loc.noRmLabel : loc.historyRowRm(fmtWeight(lastRm!), unit.label),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Diálogo con su propio controlador (en la v1 el controlador nunca se
/// liberaba).
class _AddLiftDialog extends StatefulWidget {
  const _AddLiftDialog();

  @override
  State<_AddLiftDialog> createState() => _AddLiftDialogState();
}

class _AddLiftDialogState extends State<_AddLiftDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_ctrl.text.trim());

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(loc.addLiftTitle),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(hintText: loc.addLiftHint),
        onSubmitted: (_) => _submit(),
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

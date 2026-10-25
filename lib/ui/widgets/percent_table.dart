import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/target_mode.dart';
import '../../utils/format.dart';

/// Tabla de 10 % a 100 % del RM. Tocar una fila aplica ese porcentaje.
class PercentTable extends StatelessWidget {
  const PercentTable({
    super.key,
    required this.rm,
    required this.mode,
    required this.bar,
    required this.collars,
    required this.selectedPercent,
    required this.onSelect,
  });

  final double rm;
  final TargetMode mode;
  final double bar;
  final double collars;
  final int? selectedPercent;
  final ValueChanged<int> onSelect;

  static const _percents = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const bold = TextStyle(fontWeight: FontWeight.bold);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.percentTableTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  SizedBox(width: 56, child: Text(loc.percentTableHeaderPercent, style: bold)),
                  Expanded(child: Text(loc.percentTableHeaderTotal, style: bold)),
                  Expanded(child: Text(loc.percentTableHeaderPerSide, style: bold)),
                ],
              ),
            ),
            for (final p in _percents) _row(context, p),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, int percent) {
    final t = mode.targets(rm: rm, fraction: percent / 100, bar: bar, collars: collars);
    final selected = percent == selectedPercent;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onSelect(percent),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            children: [
              SizedBox(width: 56, child: Text('$percent%')),
              Expanded(child: Text(fmtWeight(t.total, maxDecimals: 1))),
              Expanded(child: Text(fmtWeight(t.perSide, maxDecimals: 1))),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/weight_unit.dart';
import '../../services/plate_calculator.dart';
import '../../utils/format.dart';
import 'barbell_visual.dart';
import 'plate_colors.dart';

/// Muestra el resultado del cálculo en una hoja inferior.
/// Reemplaza el panel animado manual de la v1 (que necesitaba su propio
/// fondo oscuro, manejo del botón atrás y cálculo de altura).
Future<void> showResultSheet(
  BuildContext context, {
  required PlateResult result,
  required WeightUnit unit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _ResultSheet(result: result, unit: unit),
  );
}

class _ResultSheet extends StatelessWidget {
  const _ResultSheet({required this.result, required this.unit});

  final PlateResult result;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final u = unit.label;

    final entries = result.used.entries.toList()..sort((a, b) => b.key.compareTo(a.key));

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              result.exact
                  ? loc.resultExact(fmtWeight(result.totalAchieved), u)
                  : loc.resultApprox(
                      fmtWeight(result.totalAchieved),
                      fmtWeight(result.shortfall),
                      u,
                    ),
              style: theme.textTheme.titleMedium?.copyWith(
                color: result.exact ? null : theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 12),
            BarbellView(perSide: result.perSide, unit: unit, height: 240),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              Text(loc.resultBarOnly)
            else ...[
              Text(loc.chosenDiscsTitle, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final e in entries) _PlateChip(weight: e.key, count: e.value, unit: unit),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlateChip extends StatelessWidget {
  const _PlateChip({required this.weight, required this.count, required this.unit});

  final double weight;
  final int count;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final c = PlateVisual.color(unit, weight);
    final style = Theme.of(context).textTheme.bodyMedium;
    return Chip(
      avatar: CircleAvatar(backgroundColor: c),
      side: BorderSide(color: c, width: 1.5),
      label: Text.rich(
        TextSpan(
          style: style,
          children: [
            TextSpan(
              text: fmtWeight(weight),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: ' ${unit.label}  ×$count'),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/weight_unit.dart';
import '../../utils/format.dart';
import '../widgets/plate_colors.dart';

/// Conversor rápido lb ↔ kg, con los discos más comunes como referencia.
class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({super.key});

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> {
  final _lbCtrl = TextEditingController();
  final _kgCtrl = TextEditingController();
  bool _updating = false;

  static const _lbPlates = [45.0, 35.0, 25.0, 10.0, 5.0, 2.5];

  @override
  void dispose() {
    _lbCtrl.dispose();
    _kgCtrl.dispose();
    super.dispose();
  }

  void _fromLb(String raw) {
    if (_updating) return;
    final v = parseNumber(raw);
    _updating = true;
    _kgCtrl.text = v == null ? '' : fmtWeight(v * kgPerLb, maxDecimals: 3);
    _updating = false;
  }

  void _fromKg(String raw) {
    if (_updating) return;
    final v = parseNumber(raw);
    _updating = true;
    _lbCtrl.text = v == null ? '' : fmtWeight(v * lbPerKg, maxDecimals: 3);
    _updating = false;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.converterTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _lbCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: loc.lbLabel, suffixText: 'lb'),
            onChanged: _fromLb,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _kgCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: loc.kgLabel, suffixText: 'kg'),
            onChanged: _fromKg,
          ),
          const SizedBox(height: 28),
          Text(loc.quickPlatesTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final lb in _lbPlates)
            ListTile(
              leading: CircleAvatar(
                radius: 9,
                backgroundColor: PlateVisual.color(WeightUnit.lb, lb),
              ),
              title: Text('${fmtWeight(lb)} lb'),
              trailing: Text(
                '≈ ${fmtWeight(lb * kgPerLb, maxDecimals: 2)} kg',
                style: theme.textTheme.bodyLarge,
              ),
              onTap: () {
                _lbCtrl.text = fmtWeight(lb);
                _fromLb(_lbCtrl.text);
              },
            ),
        ],
      ),
    );
  }
}

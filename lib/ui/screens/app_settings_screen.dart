import 'package:flutter/material.dart';

import '../../data/defaults.dart';
import '../../l10n/app_localizations.dart';
import '../../models/plate.dart';
import '../../models/settings.dart';
import '../../models/weight_unit.dart';
import '../../services/app_storage.dart';
import '../../services/cloud_sync.dart';
import '../../utils/format.dart';
import '../widgets/plate_colors.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({
    super.key,
    required this.storage,
    this.cloud,
    required this.currentLocaleCode,
    required this.onLocaleChanged,
  });

  final AppStorage storage;
  final CloudSync? cloud;

  /// 'es', 'en', 'fr' o null (idioma del sistema).
  final String? currentLocaleCode;
  final Future<void> Function(String? code) onLocaleChanged;

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  late String? _localeCode = widget.currentLocaleCode;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.settingsTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: loc.settingsTabLanguage),
              Tab(text: loc.settingsTabInventory),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _languageTab(loc),
            _InventoryEditor(storage: widget.storage),
          ],
        ),
      ),
    );
  }

  Widget _languageTab(AppLocalizations loc) {
    final options = <String?, String>{
      null: loc.settingsLanguageSystem,
      'es': loc.settingsLanguageSpanish,
      'en': loc.settingsLanguageEnglish,
      'fr': loc.settingsLanguageFrench,
    };
    return RadioGroup<String?>(
      groupValue: _localeCode,
      onChanged: (code) {
        setState(() => _localeCode = code);
        widget.onLocaleChanged(code);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(loc.settingsLanguageTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final e in options.entries)
            RadioListTile<String?>(value: e.key, title: Text(e.value)),
          const SizedBox(height: 24),
          Text(loc.iCloudSyncTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              widget.cloud?.available == true ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            ),
            title: Text(
              widget.cloud?.available == true ? loc.iCloudSyncOn : loc.iCloudSyncOff,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Editor de inventario (kg / lb)
// ─────────────────────────────────────────────────────────────────────────────

class _InventoryEditor extends StatefulWidget {
  const _InventoryEditor({required this.storage});

  final AppStorage storage;

  @override
  State<_InventoryEditor> createState() => _InventoryEditorState();
}

class _InventoryEditorState extends State<_InventoryEditor> {
  late final Map<WeightUnit, Settings> _edited = {
    for (final u in WeightUnit.values) u: widget.storage.settings(u),
  };

  void _setPlates(WeightUnit u, List<Plate> plates) =>
      setState(() => _edited[u] = _edited[u]!.copyWith(plates: plates));

  void _changeCount(WeightUnit u, int index, int delta) {
    final plates = [..._edited[u]!.plates];
    final p = plates[index];
    plates[index] = p.copyWith(count: (p.count + delta).clamp(0, 99));
    _setPlates(u, plates);
  }

  Future<void> _addPlate(WeightUnit u) async {
    final loc = AppLocalizations.of(context);
    final weight = await showDialog<double>(
      context: context,
      builder: (_) => _AddPlateDialog(unit: u),
    );
    if (weight == null || weight <= 0) return;
    final plates = [..._edited[u]!.plates];
    if (plates.any((p) => p.weight == weight)) return;
    plates.add(Plate(weight: weight, count: 2));
    _setPlates(u, plates);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(loc.inventoryDeletePlateHint)));
  }

  Future<void> _removePlate(WeightUnit u, int index) async {
    final loc = AppLocalizations.of(context);
    final p = _edited[u]!.plates[index];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(loc.inventoryRemovePlate(fmtWeight(p.weight), u.label)),
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
    if (ok == true) _setPlates(u, [..._edited[u]!.plates]..removeAt(index));
  }

  void _reset(WeightUnit u) => _setPlates(u, Defaults.settingsFor(u).plates);

  Future<void> _save() async {
    final loc = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    for (final s in _edited.values) {
      // Se guarda el inventario conservando barra y collares actuales.
      final current = widget.storage.settings(s.unit);
      await widget.storage.saveSettings(current.copyWith(plates: s.plates));
    }
    // La v1 mostraba el texto del botón ("Guardar inventario") como aviso.
    messenger.showSnackBar(SnackBar(content: Text(loc.inventorySavedSnack)));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: loc.inventoryKgTitle),
              Tab(text: loc.inventoryLbTitle),
            ],
          ),
          Expanded(child: TabBarView(children: [for (final u in WeightUnit.values) _grid(u, loc)])),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: Text(loc.inventorySaveButton),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _grid(WeightUnit u, AppLocalizations loc) {
    final plates = _edited[u]!.plates;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 140,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: plates.length,
          itemBuilder: (_, i) => _PlateTile(
            plate: plates[i],
            unit: u,
            onMinus: () => _changeCount(u, i, -1),
            onPlus: () => _changeCount(u, i, 1),
            onLongPress: () => _removePlate(u, i),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () => _addPlate(u),
              icon: const Icon(Icons.add),
              label: Text(loc.inventoryAddPlate),
            ),
            TextButton.icon(
              onPressed: () => _reset(u),
              icon: const Icon(Icons.restore),
              label: Text(loc.inventoryReset),
            ),
          ],
        ),
      ],
    );
  }
}

class _PlateTile extends StatelessWidget {
  const _PlateTile({
    required this.plate,
    required this.unit,
    required this.onMinus,
    required this.onPlus,
    required this.onLongPress,
  });

  final Plate plate;
  final WeightUnit unit;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final color = PlateVisual.color(unit, plate.weight);
    final ring = Colors.black.withValues(alpha: 0.45);

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onLongPress: onLongPress,
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [color.withValues(alpha: 0.95), color.withValues(alpha: 0.65)],
                        center: const Alignment(-0.3, -0.3),
                        radius: 0.95,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(2, 3),
                        ),
                      ],
                    ),
                    child: const SizedBox.expand(),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: ring, width: 3),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade300,
                      border: Border.all(color: ring, width: 2),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    child: Text(
                      '${fmtWeight(plate.weight)} ${unit.label}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        shadows: [
                          Shadow(blurRadius: 3, color: Colors.black54, offset: Offset(1, 1)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              iconSize: 20,
              onPressed: plate.count > 0 ? onMinus : null,
              icon: const Icon(Icons.remove),
            ),
            Text('${plate.count}', style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              visualDensity: VisualDensity.compact,
              iconSize: 20,
              onPressed: onPlus,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}

class _AddPlateDialog extends StatefulWidget {
  const _AddPlateDialog({required this.unit});

  final WeightUnit unit;

  @override
  State<_AddPlateDialog> createState() => _AddPlateDialogState();
}

class _AddPlateDialogState extends State<_AddPlateDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(parseNumber(_ctrl.text));

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(loc.inventoryAddPlate),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          hintText: loc.inventoryAddPlateHint,
          suffixText: widget.unit.label,
        ),
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

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/weight_unit.dart';
import '../../services/app_storage.dart';
import '../../utils/format.dart';

Future<void> showRmHistorySheet(
  BuildContext context, {
  required AppStorage storage,
  required String lift,
  required String displayName,
  required WeightUnit unit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) =>
        _RmHistorySheet(storage: storage, lift: lift, displayName: displayName, unit: unit),
  );
}

class _RmHistorySheet extends StatefulWidget {
  const _RmHistorySheet({
    required this.storage,
    required this.lift,
    required this.displayName,
    required this.unit,
  });

  final AppStorage storage;
  final String lift;
  final String displayName;
  final WeightUnit unit;

  @override
  State<_RmHistorySheet> createState() => _RmHistorySheetState();
}

class _RmHistorySheetState extends State<_RmHistorySheet> {
  late List<RmEntry> _entries = widget.storage.history(widget.lift, widget.unit);

  Future<void> _clear() async {
    final loc = AppLocalizations.of(context);
    // La v1 borraba todo el historial sin pedir confirmación.
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.clearHistoryDialogTitle),
        content: Text(loc.clearHistoryDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc.deleteMovementCancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc.historyClear),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.storage.clearHistory(widget.lift, widget.unit);
    if (!mounted) return;
    setState(() => _entries = []);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.historyClearedSnack)));
  }

  Future<void> _delete(RmEntry e) async {
    setState(() => _entries = [..._entries]..remove(e));
    await widget.storage.deleteHistoryEntry(widget.lift, widget.unit, e);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final u = widget.unit.label;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    loc.historySheetTitle(widget.displayName, u),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: _entries.isEmpty ? null : _clear,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(loc.historyClear),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_entries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(loc.historyEmpty, textAlign: TextAlign.center),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _entries.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final e = _entries[i];
                    return Dismissible(
                      key: ValueKey(e.ts),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        color: Theme.of(context).colorScheme.errorContainer,
                        child: const Icon(Icons.delete_outline),
                      ),
                      onDismissed: (_) => _delete(e),
                      child: ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(loc.historyRowRm(fmtWeight(e.rm), u)),
                        subtitle: Text(fmtDateTime(e.ts)),
                        trailing: IconButton(
                          tooltip: loc.deleteRecordTooltip,
                          icon: const Icon(Icons.close),
                          onPressed: () => _delete(e),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

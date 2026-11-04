import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/app_storage.dart';
import '../../services/training_store.dart';
import '../theme/app_theme.dart';
import '../widgets/ds.dart';
import 'category_screen.dart';
import 'coach_screen.dart';
import 'progress_screen.dart';
import 'train_screen.dart';

/// Pestañas principales. Las tres primeras son la parte de entrenamiento
/// (Hoy, Progreso, Box); la calculadora de discos (Discos) va aparte, a la
/// derecha y separada por una línea, porque es una herramienta.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.storage, this.onOpenSettings});

  final AppStorage storage;
  final VoidCallback? onOpenSettings;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late final _store = TrainingStore(widget.storage);
  int _tab = 0;

  /// Cambia en cada visita a una pestaña para que vuelva a leer los datos.
  int _visit = 0;

  void _go(int i) => setState(() {
    _tab = i;
    _visit++;
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final key = ValueKey('$_tab-$_visit');
    final body = switch (_tab) {
      1 => ProgressScreen(key: key, store: _store, onGoTrain: () => _go(0)),
      2 => CoachScreen(key: key, store: _store),
      3 => CategoryScreen(key: key, storage: widget.storage, onOpenSettings: widget.onOpenSettings),
      _ => TrainScreen(key: key, store: _store, onOpenSettings: widget.onOpenSettings),
    };
    return Scaffold(
      // Tocar fuera de un campo cierra el teclado.
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: body,
      ),
      bottomNavigationBar: _TabBar(
        selected: _tab,
        onSelect: _go,
        training: [
          (Icons.today_outlined, Icons.today, loc.tabToday),
          (Icons.insights_outlined, Icons.insights, loc.tabProgress),
          (Icons.groups_outlined, Icons.groups, loc.tabBox),
        ],
        tool: (Icons.calculate_outlined, Icons.calculate, loc.tabPlates),
      ),
    );
  }
}

typedef _Item = (IconData icon, IconData selectedIcon, String label);

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.selected,
    required this.onSelect,
    required this.training,
    required this.tool,
  });

  final int selected;
  final ValueChanged<int> onSelect;
  final List<_Item> training;
  final _Item tool;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Ds.hairline(context))),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                for (var i = 0; i < training.length; i++)
                  Expanded(
                    child: _TabItem(item: training[i], on: selected == i, onTap: () => onSelect(i)),
                  ),
                // Separación visual: la calculadora es una herramienta aparte.
                Container(width: 1, height: 30, color: Ds.hairline(context)),
                Expanded(
                  child: _TabItem(
                    item: tool,
                    on: selected == training.length,
                    onTap: () => onSelect(training.length),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.item, required this.on, required this.onTap});

  final _Item item;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = on ? AppColors.blue : Ds.muted(context);
    return Semantics(
      selected: on,
      button: true,
      label: item.$3,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(on ? item.$2 : item.$1, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              item.$3,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../services/app_storage.dart';
import '../../services/training_store.dart';
import '../theme/app_theme.dart';
import '../widgets/ds.dart';
import '../widgets/plate_glyph.dart';
import 'category_screen.dart';
import 'training_home.dart';
import '../widgets/app_icons.dart';

/// Dos pestañas: Discos (la calculadora, lo central; la app abre aquí) y
/// Entrenar (entrenamiento del día, historial y progreso).
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
      1 => TrainingHome(key: key, store: _store),
      _ => CategoryScreen(key: key, storage: widget.storage, onOpenSettings: widget.onOpenSettings),
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
        items: [(null, null, loc.tabPlates), (AppIcons.train, AppIcons.trainFill, loc.tabTrain)],
      ),
    );
  }
}

/// Ícono normal, ícono elegido y texto. Sin íconos se dibuja el disco.
typedef _Item = (IconData? icon, IconData? selectedIcon, String label);

class _TabBar extends StatelessWidget {
  const _TabBar({required this.selected, required this.onSelect, required this.items});

  final int selected;
  final ValueChanged<int> onSelect;
  final List<_Item> items;

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
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _TabItem(
                      item: items[i],
                      on: selected == i,
                      onTap: () {
                        if (selected != i) HapticFeedback.selectionClick();
                        onSelect(i);
                      },
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

/// Pestaña: ícono de trazo; elegida, ícono relleno sobre una cápsula del
/// color de acento.
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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DsPressable(
          scale: 0.92,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                width: on ? 60 : 44,
                height: 32,
                decoration: BoxDecoration(
                  color: on ? AppColors.blue.withValues(alpha: 0.16) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (c, a) => ScaleTransition(
                    scale: Tween(begin: 0.8, end: 1.0).animate(a),
                    child: FadeTransition(opacity: a, child: c),
                  ),
                  child: item.$1 == null
                      ? Center(
                          key: ValueKey(on),
                          child: PlateGlyph(color: color, filled: on),
                        )
                      : Icon(on ? item.$2 : item.$1, key: ValueKey(on), color: color, size: 24),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.$3,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.1,
                  fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

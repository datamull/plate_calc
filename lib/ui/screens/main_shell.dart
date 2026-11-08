import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../services/app_storage.dart';
import '../../services/training_store.dart';
import '../theme/app_theme.dart';
import '../widgets/ds.dart';
import 'category_screen.dart';
import 'training_home.dart';

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
        items: [('plates', loc.tabPlates), ('train', loc.tabTrain)],
      ),
    );
  }
}

/// Ícono (nombre del recurso en assets/icons) y texto de una pestaña.
typedef _Item = (String icon, String label);

/// Barra inferior: la pestaña elegida se marca con el ícono relleno en tiza
/// y una línea de señal en el borde superior que se desliza entre pestañas.
class _TabBar extends StatelessWidget {
  const _TabBar({required this.selected, required this.onSelect, required this.items});

  final int selected;
  final ValueChanged<int> onSelect;
  final List<_Item> items;

  @override
  Widget build(BuildContext context) {
    final n = items.length;
    final still = MediaQuery.disableAnimationsOf(context);
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Ds.hairline(context))),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Stack(
              children: [
                // Indicador: línea corta sobre el borde superior.
                Positioned.fill(
                  child: AnimatedAlign(
                    duration: still ? Duration.zero : const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment(n == 1 ? 0 : -1 + 2 * selected / (n - 1), -1),
                    child: FractionallySizedBox(
                      widthFactor: 1 / n,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 28,
                          height: 2,
                          decoration: BoxDecoration(
                            color: AppColors.blue,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < n; i++)
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
    final color = on ? Theme.of(context).colorScheme.onSurface : Ds.muted(context);
    return Semantics(
      selected: on,
      button: true,
      label: item.$2,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DsPressable(
          scale: 0.92,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Íconos de acero (disco torneado y atleta en snatch), exportados
              // a 3x con versión elegida y no elegida.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: Image.asset(
                  'assets/icons/tab_${item.$1}_${on ? 'on' : 'off'}.png',
                  key: ValueKey(on),
                  width: 28,
                  height: 28,
                  filterQuality: FilterQuality.medium,
                  excludeFromSemantics: true,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 160),
                style: TextStyle(
                  fontFamily: 'Barlow',
                  fontSize: 11,
                  letterSpacing: 0.2,
                  fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
                child: Text(item.$2, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

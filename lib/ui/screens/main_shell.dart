import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/app_storage.dart';
import '../../services/training_store.dart';
import 'category_screen.dart';
import 'coach_screen.dart';
import 'progress_screen.dart';
import 'train_screen.dart';

/// Pestañas principales: Calculadora, Entrenar, Progreso y Coach.
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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final key = ValueKey('$_tab-$_visit');
    final body = switch (_tab) {
      1 => TrainScreen(key: key, store: _store),
      2 => ProgressScreen(
        key: key,
        store: _store,
        onGoTrain: () => setState(() {
          _tab = 1;
          _visit++;
        }),
      ),
      3 => CoachScreen(key: key, store: _store),
      _ => CategoryScreen(key: key, storage: widget.storage, onOpenSettings: widget.onOpenSettings),
    };
    return Scaffold(
      // Tocar fuera de un campo cierra el teclado.
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: body,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() {
          _tab = i;
          _visit++;
        }),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.calculate_outlined), label: loc.tabCalc),
          NavigationDestination(icon: const Icon(Icons.fitness_center), label: loc.tabTrain),
          NavigationDestination(icon: const Icon(Icons.show_chart), label: loc.tabProgress),
          NavigationDestination(icon: const Icon(Icons.sports), label: loc.tabCoach),
        ],
      ),
    );
  }
}

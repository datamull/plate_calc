import 'package:flutter/material.dart';

import '../../data/defaults.dart';
import '../../l10n/app_localizations.dart';
import '../../services/app_storage.dart';
import '../../services/lift_collection.dart';
import '../widgets/ds.dart';
import '../widgets/lift_icon.dart';
import '../../l10n/lift_names.dart';
import '../../utils/format.dart';
import 'home_screen.dart';
import 'rm_list_screen.dart';
import 'simple_rm_screen.dart';
import '../widgets/app_icons.dart';

/// Primera pantalla: elegir entre Haltero (movimientos olímpicos) y Gym
/// (ejercicios por grupo muscular).
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.storage, this.onOpenSettings});

  final AppStorage storage;
  final VoidCallback? onOpenSettings;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  AppStorage get storage => widget.storage;

  /// Movimientos con RM guardado, para entrar directo a la calculadora.
  List<(String, LiftCollection, double)> _withRm() {
    final unit = storage.listUnit;
    final out = <(String, LiftCollection, double)>[];
    final cols = <LiftCollection>[
      HalteroLifts(storage),
      for (final g in Defaults.gymGroups.keys) GymGroupLifts(storage, g),
    ];
    for (final c in cols) {
      for (final l in c.lifts) {
        final rm = storage.lastRm(l, unit);
        if (rm != null && !out.any((e) => e.$1 == l)) out.add((l, c, rm));
      }
    }
    return out;
  }

  Future<void> _push(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) setState(() {});
  }

  Future<void> _openLift(String lift, LiftCollection c) => _push(
    c.isBarbell(lift)
        ? HomeScreen(
            storage: storage,
            movementName: lift,
            initialUnit: storage.listUnit,
            onDelete: c.delete,
          )
        : SimpleRmScreen(
            storage: storage,
            movementName: lift,
            initialUnit: storage.listUnit,
            onDelete: c.delete,
          ),
  );

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final onOpenSettings = widget.onOpenSettings;
    final rms = _withRm();
    final unit = storage.listUnit;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            DsLargeHeader(
              title: 'Plate Calc',
              trailing: IconButton(
                tooltip: loc.settingsTooltip,
                icon: const Icon(AppIcons.settings),
                onPressed: onOpenSettings,
              ),
            ),
            const SizedBox(height: 8),
            DsBlock(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                children: [
                  _CategoryRow(
                    title: loc.categoryHaltero,
                    subtitle: loc.categoryHalteroSubtitle,
                    pose: LiftPose.snatch,
                    onTap: () =>
                        _push(RmListScreen(storage: storage, collection: HalteroLifts(storage))),
                  ),
                  _CategoryRow(
                    title: loc.categoryGym,
                    subtitle: loc.categoryGymSubtitle,
                    pose: LiftPose.bench,
                    divider: false,
                    onTap: () => _push(GymGroupsScreen(storage: storage)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Acceso directo: tus RM guardados, con el valor a la vista.
            DsSection(loc.yourRms),
            if (rms.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(Ds.gutter, 4, Ds.gutter, 0),
                child: Text(loc.yourRmsEmpty, style: Ds.secondary(context)),
              )
            else
              DsBlock(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  children: [
                    for (var i = 0; i < rms.length; i++)
                      DsRow(
                        title: liftDisplayName(rms[i].$1),
                        divider: i < rms.length - 1,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              fmtWeight(rms[i].$3),
                              style: Ds.display(context).copyWith(fontSize: 24),
                            ),
                            const SizedBox(width: 3),
                            Text(unit.label, style: Ds.secondary(context)),
                            const SizedBox(width: 6),
                            Icon(AppIcons.chevron, size: 16, color: Ds.muted(context)),
                          ],
                        ),
                        onTap: () => _openLift(rms[i].$1, rms[i].$2),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Grupos musculares de la sección Gym.
class GymGroupsScreen extends StatefulWidget {
  const GymGroupsScreen({super.key, required this.storage});

  final AppStorage storage;

  @override
  State<GymGroupsScreen> createState() => _GymGroupsScreenState();
}

class _GymGroupsScreenState extends State<GymGroupsScreen> {
  static const _poses = {
    'chest': LiftPose.bench,
    'back': LiftPose.row,
    'legs': LiftPose.squat,
    'shoulders': LiftPose.press,
    'arms': LiftPose.curl,
    'core': LiftPose.core,
  };

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final groups = Defaults.gymGroups.keys.toList();

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          DsLargeHeader(title: loc.categoryGym),
          const SizedBox(height: 12),
          DsBlock(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Column(
              children: [
                for (var i = 0; i < groups.length; i++)
                  DsRow(
                    leading: LiftIcon(liftName: groups[i], pose: _poses[groups[i]], size: 44),
                    title: gymGroupName(loc, groups[i]),
                    subtitle: loc.exerciseCount(widget.storage.gymExercises(groups[i]).length),
                    divider: i < groups.length - 1,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => RmListScreen(
                            storage: widget.storage,
                            collection: GymGroupLifts(widget.storage, groups[i]),
                          ),
                        ),
                      );
                      if (mounted) setState(() {});
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de categoría: pictograma, nombre y descripción.
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.title,
    required this.subtitle,
    required this.pose,
    required this.onTap,
    this.divider = true,
  });

  final String title;
  final String subtitle;
  final LiftPose pose;
  final VoidCallback onTap;
  final bool divider;

  @override
  Widget build(BuildContext context) => DsRow(
    leading: LiftIcon(liftName: title, pose: pose, size: 48),
    title: title,
    subtitle: subtitle,
    divider: divider,
    onTap: onTap,
  );
}

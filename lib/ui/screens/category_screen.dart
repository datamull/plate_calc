import 'package:flutter/material.dart';

import '../../data/defaults.dart';
import '../../l10n/app_localizations.dart';
import '../../services/app_storage.dart';
import '../../services/lift_collection.dart';
import '../theme/app_theme.dart';
import '../widgets/ds.dart';
import '../widgets/lift_icon.dart';
import 'rm_list_screen.dart';
import '../widgets/app_icons.dart';

/// Primera pantalla: elegir entre Haltero (movimientos olímpicos) y Gym
/// (ejercicios por grupo muscular).
class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key, required this.storage, this.onOpenSettings});

  final AppStorage storage;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
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
            const SizedBox(height: 12),
            _BigCard(
              title: loc.categoryHaltero,
              subtitle: loc.categoryHalteroSubtitle,
              pose: LiftPose.snatch,
              accent: AppColors.blue,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RmListScreen(storage: storage, collection: HalteroLifts(storage)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _BigCard(
              title: loc.categoryGym,
              subtitle: loc.categoryGymSubtitle,
              pose: LiftPose.bench,
              accent: AppColors.purple,
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => GymGroupsScreen(storage: storage))),
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
    final theme = Theme.of(context);
    final groups = Defaults.gymGroups.keys.toList();
    final crossAxisCount = (MediaQuery.sizeOf(context).width ~/ 160).clamp(2, 4);

    return Scaffold(
      appBar: AppBar(title: Text(loc.categoryGym)),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: groups.length,
        itemBuilder: (context, i) {
          final g = groups[i];
          final count = widget.storage.gymExercises(g).length;
          return Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RmListScreen(
                      storage: widget.storage,
                      collection: GymGroupLifts(widget.storage, g),
                    ),
                  ),
                );
                if (mounted) setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LiftIcon(liftName: g, pose: _poses[g], size: 80),
                    const SizedBox(height: 8),
                    Text(
                      gymGroupName(loc, g),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      loc.exerciseCount(count),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BigCard extends StatelessWidget {
  const _BigCard({
    required this.title,
    required this.subtitle,
    required this.pose,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final LiftPose pose;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: DsBlock.color(context),
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 16, 22),
            child: Row(
              children: [
                LiftIcon(liftName: title, pose: pose, size: 88),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 4,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(title, style: Ds.title(context).copyWith(fontSize: 24)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: Ds.secondary(context)),
                    ],
                  ),
                ),
                Icon(AppIcons.chevron, color: Ds.muted(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

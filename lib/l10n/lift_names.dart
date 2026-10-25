import 'app_localizations.dart';

extension LiftNames on AppLocalizations {
  /// Nombre traducido de los movimientos base. Los movimientos creados por el
  /// usuario se muestran tal cual.
  String liftName(String key) => switch (key) {
    'Deadlift' => liftDeadlift,
    'Snatch' => liftSnatch,
    'Clean' => liftClean,
    'Jerk' => liftJerk,
    _ => key,
  };
}

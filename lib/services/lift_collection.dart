import '../l10n/app_localizations.dart';
import 'app_storage.dart';

/// Un grupo de movimientos que se muestra como lista de tarjetas: los de
/// Haltero o los de un grupo muscular de Gym.
abstract class LiftCollection {
  const LiftCollection(this.storage);

  final AppStorage storage;

  String title(AppLocalizations loc);
  List<String> get lifts;

  /// true si al agregar un movimiento se pregunta si es con barra.
  bool get asksBarbell;

  /// true si el movimiento usa barra olímpica (y por lo tanto calculadora).
  bool isBarbell(String lift);

  Future<bool> add(String name, {bool barbell = true});
  Future<void> delete(String name);
}

class HalteroLifts extends LiftCollection {
  const HalteroLifts(super.storage);

  @override
  String title(AppLocalizations loc) => loc.categoryHaltero;

  @override
  List<String> get lifts => storage.lifts;

  @override
  bool get asksBarbell => false;

  @override
  bool isBarbell(String lift) => true;

  @override
  Future<bool> add(String name, {bool barbell = true}) => storage.addLift(name);

  @override
  Future<void> delete(String name) => storage.deleteLift(name);
}

class GymGroupLifts extends LiftCollection {
  const GymGroupLifts(super.storage, this.group);

  final String group;

  @override
  String title(AppLocalizations loc) => gymGroupName(loc, group);

  @override
  List<String> get lifts => storage.gymExercises(group);

  @override
  bool get asksBarbell => true;

  @override
  bool isBarbell(String lift) => storage.isGymBarbell(lift);

  @override
  Future<bool> add(String name, {bool barbell = true}) =>
      storage.addGymExercise(group, name, barbell: barbell);

  @override
  Future<void> delete(String name) => storage.deleteGymExercise(group, name);
}

/// Nombre traducido de un grupo muscular.
String gymGroupName(AppLocalizations loc, String group) => switch (group) {
  'chest' => loc.groupChest,
  'back' => loc.groupBack,
  'legs' => loc.groupLegs,
  'shoulders' => loc.groupShoulders,
  'arms' => loc.groupArms,
  'core' => loc.groupCore,
  _ => group,
};

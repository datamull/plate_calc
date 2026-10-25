import '../models/plate.dart';
import '../models/settings.dart';
import '../models/weight_unit.dart';

/// Única fuente de los valores por defecto. En la v1 había dos inventarios
/// distintos (uno en Ajustes y otro en el cálculo) y no coincidían.
class Defaults {
  Defaults._();

  /// Movimientos que vienen con la app. El nombre es también la clave de
  /// almacenamiento, por eso no se traduce aquí (se traduce al mostrarlo).
  static const baseLifts = ['Deadlift', 'Snatch', 'Clean', 'Jerk'];

  static Settings settingsFor(WeightUnit unit) => unit == WeightUnit.kg
      ? Settings(
          unit: WeightUnit.kg,
          barWeight: 20,
          collarsWeight: 0,
          plates: const [
            Plate(weight: 25, count: 2),
            Plate(weight: 20, count: 2),
            Plate(weight: 15, count: 2),
            Plate(weight: 10, count: 4),
            Plate(weight: 5, count: 4),
            Plate(weight: 2.5, count: 4),
            Plate(weight: 2, count: 2),
            Plate(weight: 1.5, count: 2),
            Plate(weight: 1.25, count: 4),
            Plate(weight: 1, count: 2),
            Plate(weight: 0.5, count: 4),
          ],
        )
      : Settings(
          unit: WeightUnit.lb,
          barWeight: 45,
          collarsWeight: 0,
          plates: const [
            Plate(weight: 45, count: 8),
            Plate(weight: 35, count: 8),
            Plate(weight: 25, count: 8),
            Plate(weight: 10, count: 8),
            Plate(weight: 5, count: 6),
            Plate(weight: 2.5, count: 6),
            Plate(weight: 2, count: 2),
            Plate(weight: 1.25, count: 2),
            Plate(weight: 0.5, count: 2),
          ],
        );
}

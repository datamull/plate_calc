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

  /// Ejercicios de la sección Gym por grupo muscular (siempre en inglés, como
  /// los movimientos base). La clave del grupo se usa para guardar datos.
  static const gymGroups = <String, List<String>>{
    'chest': ['Bench Press', 'Incline Bench Press', 'Dumbbell Press', 'Chest Fly'],
    'back': ['Barbell Row', 'Lat Pulldown', 'Seated Row', 'Pull-Up'],
    'legs': ['Back Squat', 'Front Squat', 'Leg Press', 'Romanian Deadlift'],
    'shoulders': ['Overhead Press', 'Dumbbell Shoulder Press', 'Lateral Raise', 'Upright Row'],
    'arms': ['Barbell Curl', 'Dumbbell Curl', 'Triceps Pushdown', 'Skull Crusher'],
    'core': ['Cable Crunch', 'Hanging Leg Raise', 'Ab Wheel', 'Russian Twist'],
  };

  /// Ejercicios de Gym que se hacen con barra olímpica: solo estos tienen
  /// calculadora de discos. El resto (mancuernas, máquinas, peso corporal)
  /// solo guarda RM e historial.
  static const gymBarbell = {
    'Bench Press',
    'Incline Bench Press',
    'Barbell Row',
    'Back Squat',
    'Front Squat',
    'Romanian Deadlift',
    'Overhead Press',
    'Upright Row',
    'Barbell Curl',
  };

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

import '../l10n/app_localizations.dart';
import '../models/training.dart';

/// Programas por porcentaje que vienen con la app. Los pesos salen del RM de
/// cada persona al empezar cada día.
List<Plan> builtInPlans(AppLocalizations loc) => [_oly(loc), _strength(loc)];

const olyPlanId = 'tpl_oly4';
const strengthPlanId = 'tpl_str4';

PlanItem _i(String lift, int sets, int reps, double pct) =>
    PlanItem(lift: lift, sets: sets, reps: reps, percent: pct);

PlanItem _free(String lift, int sets, int reps) => PlanItem(lift: lift, sets: sets, reps: reps);

/// Halterofilia: 4 semanas, 3 días. Sube la intensidad 3 semanas y la cuarta
/// prueba singles pesados con menos volumen de sentadilla.
Plan _oly(AppLocalizations loc) {
  const oly = [70.0, 75.0, 80.0, 85.0];
  const squat = [75.0, 80.0, 85.0, 70.0];
  final days = <PlanDay>[];
  for (var w = 0; w < 4; w++) {
    days
      ..add(
        PlanDay(
          name: loc.planWeekDay(w + 1, 'A'),
          items: [_i('Snatch', 5, 2, oly[w]), _i('Back Squat', 5, 3, squat[w])],
        ),
      )
      ..add(
        PlanDay(
          name: loc.planWeekDay(w + 1, 'B'),
          items: [
            _i('Clean', 5, 2, oly[w]),
            _i('Jerk', 4, 2, oly[w]),
            _i('Front Squat', 4, 3, squat[w] - 5),
          ],
        ),
      )
      ..add(
        PlanDay(
          name: loc.planWeekDay(w + 1, 'C'),
          items: [
            _i('Snatch', 4, 1, oly[w] + 5),
            _i('Clean', 4, 1, oly[w] + 5),
            _i('Deadlift', 3, 3, squat[w] + 5),
          ],
        ),
      );
  }
  return Plan(id: olyPlanId, name: loc.planOlyName, days: days, notes: loc.planOlyNotes);
}

/// Fuerza: 4 semanas, 4 días, ondas de 5/3/1 (la cuarta semana es descarga).
Plan _strength(AppLocalizations loc) {
  const waves = [
    [(65.0, 5), (75.0, 5), (85.0, 5)],
    [(70.0, 3), (80.0, 3), (90.0, 3)],
    [(75.0, 5), (85.0, 3), (95.0, 1)],
    [(40.0, 5), (50.0, 5), (60.0, 5)],
  ];
  const mains = [
    ('Back Squat', 'Romanian Deadlift'),
    ('Bench Press', 'Barbell Row'),
    ('Deadlift', 'Front Squat'),
    ('Overhead Press', 'Pull-Up'),
  ];
  const letters = ['A', 'B', 'C', 'D'];
  final days = <PlanDay>[];
  for (var w = 0; w < 4; w++) {
    for (var d = 0; d < 4; d++) {
      final (main, extra) = mains[d];
      days.add(
        PlanDay(
          name: loc.planWeekDay(w + 1, letters[d]),
          items: [for (final (pct, reps) in waves[w]) _i(main, 1, reps, pct), _free(extra, 3, 8)],
        ),
      );
    }
  }
  return Plan(
    id: strengthPlanId,
    name: loc.planStrengthName,
    days: days,
    notes: loc.planStrengthNotes,
  );
}

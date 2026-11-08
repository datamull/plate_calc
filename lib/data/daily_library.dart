/// Biblioteca de entrenamientos del día, escrita para Plate Calc.
///
/// Crosstraining usa los WOD de referencia de dominio común; halterofilia y
/// gym son programación propia. Nada se copia de sitios que no permiten
/// republicar su contenido (como CrossFit.com). Cada estilo rota por fecha, así
/// todos los usuarios ven el mismo entrenamiento el mismo día, sin internet.
///
/// Los nombres de los movimientos van en inglés (como el resto de la app) y
/// los formatos (AMRAP, EMOM, For Time) son los nombres usados en todos los
/// idiomas. Los WOD de Crosstraining son los de referencia (Fran, Cindy,
/// Murph...) con sus nombres y pesos Rx de siempre.
library;

import '../models/weight_unit.dart';

enum TrainingStyle {
  crossfit,
  haltero,
  gym;

  static TrainingStyle? parse(String? s) => values.where((v) => v.name == s).firstOrNull;
}

/// Cómo se anota el resultado de un WOD.
enum ScoreType { time, rounds, load, none }

/// Formato del WOD (define el reloj).
enum WodFormat { forTime, amrap, emom, sets }

class DailyItem {
  const DailyItem(
    this.lift, {
    this.sets,
    this.reps = '',
    this.repsPerSet,
    this.percent,
    this.rmOf,
    this.rxKg,
    this.rxLb,
  });

  /// Movimiento (clave en inglés).
  final String lift;

  /// Series (solo halterofilia y gym).
  final int? sets;

  /// Repeticiones como se leen en la pizarra: "21-15-9", "400 m", "10".
  final String reps;

  /// Repeticiones por serie, para registrar (halterofilia y gym).
  final int? repsPerSet;

  /// % del RM de [rmOf] (o de [lift] si es null) para calcular tu peso.
  final double? percent;
  final String? rmOf;

  /// Peso Rx hombre/mujer cuando no depende del RM ("24/16").
  final String? rxKg;
  final String? rxLb;

  String get rmLift => rmOf ?? lift;

  String? rx(WeightUnit u) {
    final v = u == WeightUnit.kg ? rxKg : rxLb;
    if (v == null) return null;
    // Si ya trae unidad ("20/14 lb", "60/50 cm") se muestra tal cual.
    return RegExp('[a-zA-Z"#]').hasMatch(v) ? v : '$v ${u.label}';
  }
}

class DailyWorkout {
  const DailyWorkout({
    required this.id,
    required this.style,
    required this.name,
    required this.format,
    required this.items,
    this.minutes,
    this.rounds,
    this.score = ScoreType.none,
  });

  final String id;
  final TrainingStyle style;
  final String name;
  final WodFormat format;
  final List<DailyItem> items;

  /// Duración (AMRAP, EMOM) o límite de tiempo (For Time).
  final int? minutes;

  /// Rondas (For Time por rondas).
  final int? rounds;
  final ScoreType score;

  /// Etiqueta corta del formato: "AMRAP 12", "5 RONDAS FOR TIME", "EMOM 10".
  String get formatLabel => switch (format) {
    WodFormat.amrap => 'AMRAP $minutes′',
    WodFormat.emom => 'EMOM $minutes′',
    WodFormat.forTime =>
      rounds != null && rounds! > 1
          ? '$rounds RFT'
          : 'FOR TIME${minutes != null ? ' · cap $minutes′' : ''}',
    WodFormat.sets => '',
  };
}

// ── Entrenamiento del día ───────────────────────────────────────────────────

/// Lunes de referencia: el día 0 de la rotación.
final _epoch = DateTime(2026, 1, 5);

int dayIndex(DateTime day) {
  final d = DateTime(day.year, day.month, day.day);
  // Días de calendario (no horas) para no correrse con el cambio de horario.
  return DateTime.utc(
    d.year,
    d.month,
    d.day,
  ).difference(DateTime.utc(_epoch.year, _epoch.month, _epoch.day)).inDays;
}

/// Entrenamiento del día. [offset] lo cambia por otro de la misma
/// biblioteca (botón "Otro").
DailyWorkout dailyFor(TrainingStyle style, DateTime day, {int offset = 0}) {
  final list = switch (style) {
    TrainingStyle.crossfit => crossfitLibrary,
    TrainingStyle.haltero => halteroLibrary,
    TrainingStyle.gym => gymLibrary,
  };
  // Saltos de 5 (primo con el largo de cada biblioteca) para recorrerlas
  // todas y que "otro" no sea simplemente el de mañana.
  final i = (dayIndex(day) + offset * 5) % list.length;
  return list[i < 0 ? i + list.length : i];
}

// ── Crosstraining / WOD ──────────────────────────────────────────────────────────
DailyWorkout _wod(
  String id,
  String name,
  WodFormat f,
  List<DailyItem> items, {
  int? minutes,
  int? rounds,
}) => DailyWorkout(
  id: 'cf_$id',
  style: TrainingStyle.crossfit,
  name: name,
  format: f,
  items: items,
  minutes: minutes,
  rounds: rounds,
  score: switch (f) {
    WodFormat.forTime => ScoreType.time,
    WodFormat.amrap => ScoreType.rounds,
    WodFormat.emom => ScoreType.none,
    WodFormat.sets => ScoreType.load,
  },
);

const _i = DailyItem.new;

/// WOD de referencia ("benchmark") con su nombre y peso Rx de siempre: los
/// "Girls" y los "Hero WODs" que se programan en todos los boxes, más dos
/// días de fuerza. Rx en hombre/mujer.
final crossfitLibrary = <DailyWorkout>[
  _wod('fran', 'Fran', WodFormat.forTime, [
    _i('Thruster', reps: '21-15-9', rxKg: '43/29', rxLb: '95/65'),
    _i('Pull-Up', reps: '21-15-9'),
  ]),
  _wod('cindy', 'Cindy', WodFormat.amrap, minutes: 20, [
    _i('Pull-Up', reps: '5'),
    _i('Push-Up', reps: '10'),
    _i('Air Squat', reps: '15'),
  ]),
  _wod('grace', 'Grace', WodFormat.forTime, [
    _i('Clean & Jerk', reps: '30', rxKg: '61/43', rxLb: '135/95'),
  ]),
  _wod('helen', 'Helen', WodFormat.forTime, rounds: 3, [
    _i('Run', reps: '400 m'),
    _i('Kettlebell Swing', reps: '21', rxKg: '24/16', rxLb: '53/35'),
    _i('Pull-Up', reps: '12'),
  ]),
  _wod('diane', 'Diane', WodFormat.forTime, [
    _i('Deadlift', reps: '21-15-9', rxKg: '102/70', rxLb: '225/155'),
    _i('Handstand Push-Up', reps: '21-15-9'),
  ]),
  _wod('annie', 'Annie', WodFormat.forTime, [
    _i('Double Under', reps: '50-40-30-20-10'),
    _i('Sit-Up', reps: '50-40-30-20-10'),
  ]),
  _wod('isabel', 'Isabel', WodFormat.forTime, [
    _i('Snatch', reps: '30', rxKg: '61/43', rxLb: '135/95'),
  ]),
  _wod('karen', 'Karen', WodFormat.forTime, [
    _i('Wall Ball', reps: '150', rxKg: '9/6', rxLb: '20/14'),
  ]),
  _wod('jackie', 'Jackie', WodFormat.forTime, [
    _i('Row', reps: '1000 m'),
    _i('Thruster', reps: '50', rxKg: '20/15', rxLb: '45/35'),
    _i('Pull-Up', reps: '30'),
  ]),
  _wod('backsquat', 'Back Squat', WodFormat.sets, [
    _i('Back Squat', reps: '5-5-5-3-3-3', percent: 80),
  ]),
  _wod('elizabeth', 'Elizabeth', WodFormat.forTime, [
    _i('Squat Clean', reps: '21-15-9', rxKg: '61/43', rxLb: '135/95'),
    _i('Ring Dip', reps: '21-15-9'),
  ]),
  _wod('nancy', 'Nancy', WodFormat.forTime, rounds: 5, [
    _i('Run', reps: '400 m'),
    _i('Overhead Squat', reps: '15', rxKg: '43/29', rxLb: '95/65'),
  ]),
  _wod('chelsea', 'Chelsea', WodFormat.emom, minutes: 30, [
    _i('Pull-Up', reps: '5'),
    _i('Push-Up', reps: '10'),
    _i('Air Squat', reps: '15'),
  ]),
  _wod('kelly', 'Kelly', WodFormat.forTime, rounds: 5, [
    _i('Run', reps: '400 m'),
    _i('Box Jump', reps: '30', rxKg: '60/50 cm', rxLb: '24/20 in'),
    _i('Wall Ball', reps: '30', rxKg: '9/6', rxLb: '20/14'),
  ]),
  _wod('dt', 'DT', WodFormat.forTime, rounds: 5, [
    _i('Deadlift', reps: '12', rxKg: '70/47', rxLb: '155/105'),
    _i('Hang Power Clean', reps: '9', rxKg: '70/47', rxLb: '155/105'),
    _i('Push Jerk', reps: '6', rxKg: '70/47', rxLb: '155/105'),
  ]),
  _wod('mary', 'Mary', WodFormat.amrap, minutes: 20, [
    _i('Handstand Push-Up', reps: '5'),
    _i('Pistol', reps: '10'),
    _i('Pull-Up', reps: '15'),
  ]),
  _wod('amanda', 'Amanda', WodFormat.forTime, [
    _i('Muscle-Up', reps: '9-7-5'),
    _i('Squat Snatch', reps: '9-7-5', rxKg: '61/43', rxLb: '135/95'),
  ]),
  _wod('angie', 'Angie', WodFormat.forTime, [
    _i('Pull-Up', reps: '100'),
    _i('Push-Up', reps: '100'),
    _i('Sit-Up', reps: '100'),
    _i('Air Squat', reps: '100'),
  ]),
  _wod('deadlift', 'Deadlift', WodFormat.sets, [_i('Deadlift', reps: '5-5-3-3-1-1', percent: 85)]),
  _wod('barbara', 'Barbara', WodFormat.forTime, rounds: 5, [
    _i('Pull-Up', reps: '20'),
    _i('Push-Up', reps: '30'),
    _i('Sit-Up', reps: '40'),
    _i('Air Squat', reps: '50'),
    _i('Rest', reps: '3 min'),
  ]),
  _wod('jt', 'JT', WodFormat.forTime, [
    _i('Handstand Push-Up', reps: '21-15-9'),
    _i('Ring Dip', reps: '21-15-9'),
    _i('Push-Up', reps: '21-15-9'),
  ]),
  _wod('murph', 'Murph', WodFormat.forTime, [
    _i('Run', reps: '1 mile'),
    _i('Pull-Up', reps: '100'),
    _i('Push-Up', reps: '200'),
    _i('Air Squat', reps: '300'),
    _i('Run', reps: '1 mile'),
  ]),
];

// ── Halterofilia ────────────────────────────────────────────────────────────
DailyWorkout _hs(String id, String name, List<DailyItem> items) => DailyWorkout(
  id: 'hs_$id',
  style: TrainingStyle.haltero,
  name: name,
  format: WodFormat.sets,
  items: items,
  score: ScoreType.load,
);

DailyItem _s(String lift, int sets, int reps, double pct, {String? rmOf}) =>
    DailyItem(lift, sets: sets, repsPerSet: reps, reps: '$sets×$reps', percent: pct, rmOf: rmOf);

/// Ciclo de 3 semanas × 4 sesiones (sube la intensidad cada semana).
final halteroLibrary = <DailyWorkout>[
  for (final (w, oly, sq) in [(1, 70.0, 75.0), (2, 75.0, 80.0), (3, 80.0, 85.0)]) ...[
    _hs('w${w}a', 'Snatch + Back Squat', [
      _s('Snatch', 5, 2, oly),
      _s('Snatch Pull', 3, 3, oly + 20, rmOf: 'Snatch'),
      _s('Back Squat', 5, 3, sq),
    ]),
    _hs('w${w}b', 'Clean & Jerk + Front Squat', [
      _s('Clean', 5, 2, oly),
      _s('Jerk', 4, 2, oly),
      _s('Front Squat', 4, 3, sq - 5),
    ]),
    _hs('w${w}c', 'Hang + Push Press', [
      _s('Hang Snatch', 4, 2, oly - 10, rmOf: 'Snatch'),
      _s('Hang Clean', 4, 2, oly - 10, rmOf: 'Clean'),
      _s('Push Press', 4, 3, oly - 5, rmOf: 'Jerk'),
    ]),
    _hs('w${w}d', 'Snatch · Clean · Jerk · 1RM', [
      _s('Snatch', 4, 1, oly + 10),
      _s('Clean', 4, 1, oly + 10),
      _s('Jerk', 3, 1, oly + 10),
      _s('Deadlift', 3, 3, sq + 5),
    ]),
  ],
];

// ── Gym ─────────────────────────────────────────────────────────────────────
DailyWorkout _gs(String id, String name, List<DailyItem> items) => DailyWorkout(
  id: 'gy_$id',
  style: TrainingStyle.gym,
  name: name,
  format: WodFormat.sets,
  items: items,
  score: ScoreType.load,
);

DailyItem _g(String lift, int sets, int reps, {double? pct}) =>
    DailyItem(lift, sets: sets, repsPerSet: reps, reps: '$sets×$reps', percent: pct);

/// Push / Pull / Legs, una semana pesada y otra de volumen.
final gymLibrary = <DailyWorkout>[
  _gs('push_a', 'Push', [
    _g('Bench Press', 4, 6, pct: 75),
    _g('Overhead Press', 3, 8, pct: 65),
    _g('Incline Bench Press', 3, 10),
    _g('Lateral Raise', 3, 15),
    _g('Triceps Pushdown', 3, 12),
  ]),
  _gs('pull_a', 'Pull', [
    _g('Deadlift', 3, 5, pct: 80),
    _g('Barbell Row', 4, 8),
    _g('Lat Pulldown', 3, 10),
    _g('Seated Row', 3, 12),
    _g('Barbell Curl', 3, 10),
  ]),
  _gs('legs_a', 'Legs', [
    _g('Back Squat', 4, 6, pct: 75),
    _g('Romanian Deadlift', 3, 8),
    _g('Leg Press', 3, 12),
    _g('Hanging Leg Raise', 3, 12),
  ]),
  _gs('push_b', 'Push', [
    _g('Overhead Press', 4, 6, pct: 75),
    _g('Bench Press', 3, 10, pct: 65),
    _g('Dumbbell Press', 3, 12),
    _g('Chest Fly', 3, 15),
    _g('Skull Crusher', 3, 12),
  ]),
  _gs('pull_b', 'Pull', [
    _g('Pull-Up', 4, 8),
    _g('Barbell Row', 4, 6),
    _g('Seated Row', 3, 12),
    _g('Dumbbell Curl', 3, 12),
    _g('Ab Wheel', 3, 10),
  ]),
  _gs('legs_b', 'Legs', [
    _g('Front Squat', 4, 6, pct: 75),
    _g('Leg Press', 4, 10),
    _g('Romanian Deadlift', 3, 10),
    _g('Cable Crunch', 3, 15),
  ]),
];

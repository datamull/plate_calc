import 'weight_unit.dart';

/// Una serie: repeticiones, peso, esfuerzo percibido (RPE) y si se completó.
class WorkSet {
  WorkSet({this.reps = 0, this.weight = 0, this.rpe, this.done = false});

  int reps;
  double weight;
  double? rpe;
  bool done;

  WorkSet copy() => WorkSet(reps: reps, weight: weight, rpe: rpe, done: done);

  Map<String, dynamic> toJson() => {
    'r': reps,
    'w': weight,
    if (rpe != null) 'p': rpe,
    if (done) 'd': true,
  };

  static WorkSet fromJson(Map<String, dynamic> j) => WorkSet(
    reps: (j['r'] as num?)?.toInt() ?? 0,
    weight: (j['w'] as num?)?.toDouble() ?? 0,
    rpe: (j['p'] as num?)?.toDouble(),
    done: j['d'] == true,
  );
}

/// Un ejercicio dentro de un entrenamiento, con sus series.
class ExerciseLog {
  ExerciseLog({required this.lift, List<WorkSet>? sets, this.percent}) : sets = sets ?? [WorkSet()];

  final String lift;
  final List<WorkSet> sets;

  /// % del RM indicado por el plan (solo informativo).
  final double? percent;

  Map<String, dynamic> toJson() => {
    'l': lift,
    's': sets.map((s) => s.toJson()).toList(),
    if (percent != null) 'pc': percent,
  };

  static ExerciseLog fromJson(Map<String, dynamic> j) => ExerciseLog(
    lift: '${j['l']}',
    sets: [
      for (final s in (j['s'] as List? ?? const []))
        if (s is Map) WorkSet.fromJson(Map<String, dynamic>.from(s)),
    ],
    percent: (j['pc'] as num?)?.toDouble(),
  );
}

/// Un entrenamiento registrado (o en curso).
class Workout {
  Workout({
    required this.id,
    required this.date,
    required this.unit,
    this.title = '',
    this.notes = '',
    List<ExerciseLog>? exercises,
    this.planId,
    this.planName,
    this.dayIndex,
    this.coach,
    this.durationSec = 0,
    this.score,
    this.style,
  }) : exercises = exercises ?? [];

  final String id;
  DateTime date;
  final WeightUnit unit;
  String title;
  String notes;
  final List<ExerciseLog> exercises;

  /// Plan y día del que viene (para marcar el día como hecho).
  final String? planId;
  final String? planName;
  final int? dayIndex;

  /// Nombre del coach si el plan vino de un coach.
  final String? coach;
  int durationSec;

  /// Resultado de un WOD tal como se anota ("12:45", "8 + 14", "95 kg").
  String? score;

  /// Estilo del entrenamiento del día: 'crossfit', 'haltero' o 'gym'.
  final String? style;

  Iterable<WorkSet> get doneSets => exercises.expand((e) => e.sets).where((s) => s.done);

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'u': unit.name,
    if (title.isNotEmpty) 't': title,
    if (notes.isNotEmpty) 'n': notes,
    'e': exercises.map((e) => e.toJson()).toList(),
    if (planId != null) 'pid': planId,
    if (planName != null) 'pn': planName,
    if (dayIndex != null) 'di': dayIndex,
    if (coach != null) 'c': coach,
    if (durationSec > 0) 'dur': durationSec,
    if (score != null && score!.isNotEmpty) 'sc': score,
    if (style != null) 'st': style,
  };

  static Workout? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final j = Map<String, dynamic>.from(raw);
    final date = DateTime.tryParse('${j['date']}');
    if (date == null) return null;
    return Workout(
      id: '${j['id'] ?? date.microsecondsSinceEpoch}',
      date: date,
      unit: WeightUnit.parse(j['u'] as String?),
      title: (j['t'] as String?) ?? '',
      notes: (j['n'] as String?) ?? '',
      exercises: [
        for (final e in (j['e'] as List? ?? const []))
          if (e is Map) ExerciseLog.fromJson(Map<String, dynamic>.from(e)),
      ],
      planId: j['pid'] as String?,
      planName: j['pn'] as String?,
      dayIndex: (j['di'] as num?)?.toInt(),
      coach: j['c'] as String?,
      durationSec: (j['dur'] as num?)?.toInt() ?? 0,
      score: j['sc'] as String?,
      style: j['st'] as String?,
    );
  }
}

/// Un ejercicio de un plan: series × repeticiones, con % del RM o peso fijo.
class PlanItem {
  PlanItem({required this.lift, this.sets = 3, this.reps = 5, this.percent, this.weight});

  String lift;
  int sets;
  int reps;

  /// % del RM de cada atleta (p. ej. 80). Tiene prioridad sobre [weight].
  double? percent;

  /// Peso fijo, en la unidad del atleta.
  double? weight;

  Map<String, dynamic> toJson() => {
    'l': lift,
    's': sets,
    'r': reps,
    if (percent != null) 'pc': percent,
    if (weight != null) 'w': weight,
  };

  static PlanItem fromJson(Map<String, dynamic> j) => PlanItem(
    lift: '${j['l']}',
    sets: (j['s'] as num?)?.toInt() ?? 1,
    reps: (j['r'] as num?)?.toInt() ?? 1,
    percent: (j['pc'] as num?)?.toDouble(),
    weight: (j['w'] as num?)?.toDouble(),
  );
}

class PlanDay {
  PlanDay({required this.name, List<PlanItem>? items}) : items = items ?? [];

  String name;
  final List<PlanItem> items;

  Map<String, dynamic> toJson() => {'n': name, 'i': items.map((i) => i.toJson()).toList()};

  static PlanDay fromJson(Map<String, dynamic> j) => PlanDay(
    name: '${j['n'] ?? ''}',
    items: [
      for (final i in (j['i'] as List? ?? const []))
        if (i is Map) PlanItem.fromJson(Map<String, dynamic>.from(i)),
    ],
  );
}

/// Rutina o programa: uno o más días de ejercicios. Puede ser propio, de la
/// app (plantilla) o recibido de un coach.
class Plan {
  Plan({
    required this.id,
    required this.name,
    List<PlanDay>? days,
    this.coach,
    this.box,
    this.notes = '',
  }) : days = days ?? [];

  final String id;
  String name;
  final List<PlanDay> days;

  /// Coach y box que lo enviaron (null si es propio).
  String? coach;
  String? box;
  String notes;

  bool get fromCoach => coach != null && coach!.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'id': id,
    'n': name,
    'd': days.map((d) => d.toJson()).toList(),
    if (coach != null) 'c': coach,
    if (box != null) 'b': box,
    if (notes.isNotEmpty) 'no': notes,
  };

  static Plan? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final j = Map<String, dynamic>.from(raw);
    final days = j['d'];
    if (days is! List) return null;
    return Plan(
      id: '${j['id'] ?? DateTime.now().microsecondsSinceEpoch}',
      name: '${j['n'] ?? ''}',
      days: [
        for (final d in days)
          if (d is Map) PlanDay.fromJson(Map<String, dynamic>.from(d)),
      ],
      coach: j['c'] as String?,
      box: j['b'] as String?,
      notes: (j['no'] as String?) ?? '',
    );
  }
}

/// Resultado de un alumno recibido por el coach.
class AthleteResult {
  AthleteResult({required this.athlete, required this.workout, required this.received});

  final String athlete;
  final Workout workout;
  final DateTime received;

  Map<String, dynamic> toJson() => {
    'a': athlete,
    'w': workout.toJson(),
    'rc': received.toIso8601String(),
  };

  static AthleteResult? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final w = Workout.fromJson(raw['w']);
    if (w == null) return null;
    return AthleteResult(
      athlete: '${raw['a'] ?? ''}',
      workout: w,
      received: DateTime.tryParse('${raw['rc']}') ?? DateTime.now(),
    );
  }
}

String newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

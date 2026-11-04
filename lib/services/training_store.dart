import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:math' as math;

import '../data/daily_library.dart';
import '../data/defaults.dart';
import '../models/training.dart';
import '../models/weight_unit.dart';
import 'app_storage.dart';

/// Entrenamientos, planes y datos del modo coach.
///
/// Todo se guarda en las mismas preferencias que el resto de la app (claves
/// `training_*`), así el respaldo de iCloud lo incluye sin cambios.
class TrainingStore {
  TrainingStore(this.storage);

  final AppStorage storage;

  static const _kWorkouts = 'training_workouts';
  static const _kDraft = 'training_draft';
  static const _kPlans = 'training_plans';
  static const _kResults = 'training_results';
  static const _kCoachName = 'training_coach_name';
  static const _kCoachBox = 'training_coach_box';
  static const _kAthleteName = 'training_athlete_name';
  static const _kRest = 'training_rest';
  static const _kStyles = 'training_styles';

  // ── Entrenamientos ────────────────────────────────────────────────────────
  /// Del más reciente al más antiguo.
  List<Workout> get workouts {
    final raw = storage.readJson(_kWorkouts);
    if (raw is! List) return [];
    final out = raw.map(Workout.fromJson).whereType<Workout>().toList();
    out.sort((a, b) => b.date.compareTo(a.date));
    return out;
  }

  Future<void> _saveWorkouts(List<Workout> list) =>
      storage.writeJson(_kWorkouts, list.map((w) => w.toJson()).toList());

  /// Guarda (o reemplaza) un entrenamiento terminado.
  Future<void> saveWorkout(Workout w) async {
    final list = workouts..removeWhere((x) => x.id == w.id);
    await _saveWorkouts([w, ...list]);
  }

  Future<void> deleteWorkout(String id) async {
    await _saveWorkouts(workouts..removeWhere((w) => w.id == id));
  }

  Workout? get draft => Workout.fromJson(storage.readJson(_kDraft));
  Future<void> saveDraft(Workout? w) => storage.writeJson(_kDraft, w?.toJson());

  int get restSeconds => storage.readInt(_kRest) ?? 90;
  Future<void> setRestSeconds(int s) => storage.writeInt(_kRest, s);

  // ── Estilos y entrenamiento del día ─────────────────────────────────────────
  /// Estilos que el usuario eligió ver. Vacío = aún no eligió.
  List<TrainingStyle> get styles {
    final raw = storage.readJson(_kStyles);
    if (raw is! List) return [];
    return raw.map((e) => TrainingStyle.parse('$e')).whereType<TrainingStyle>().toList();
  }

  Future<void> setStyles(List<TrainingStyle> v) => storage.writeJson(_kStyles, [
    for (final s in TrainingStyle.values)
      if (v.contains(s)) s.name,
  ]);

  /// Tu peso para un movimiento del día (% de tu RM), o null sin RM.
  double? dailyWeight(DailyItem item, WeightUnit unit) {
    if (item.percent == null) return null;
    final rm = storage.lastRm(item.rmLift, unit);
    if (rm == null || rm <= 0) return null;
    return roundLoad(rm * item.percent! / 100, unit);
  }

  static String dailyKey(DailyWorkout d, DateTime day) =>
      'daily_${d.id}_${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}';

  /// El entrenamiento guardado para ese día y WOD, si ya se hizo.
  Workout? dailyDone(DailyWorkout d, DateTime day) {
    final key = dailyKey(d, day);
    return workouts.where((w) => w.planId == key).firstOrNull;
  }

  /// Entrenamiento de series (halterofilia, gym o WOD de cargas) listo para
  /// registrar, con los pesos calculados.
  Workout startDaily(DailyWorkout d, WeightUnit unit, {DateTime? day}) {
    final today = day ?? DateTime.now();
    return Workout(
      id: newId(),
      date: DateTime.now(),
      unit: unit,
      title: d.name,
      style: d.style.name,
      planId: dailyKey(d, today),
      exercises: [
        for (final item in d.items)
          ExerciseLog(
            lift: item.lift,
            percent: item.percent,
            sets: [
              for (var i = 0; i < (item.sets ?? _setsFromReps(item.reps).length); i++)
                WorkSet(
                  reps: item.repsPerSet ?? _setsFromReps(item.reps)[i],
                  weight: dailyWeight(item, unit) ?? 0,
                ),
            ],
          ),
      ],
    );
  }

  /// "5-5-3-3-1" → [5, 5, 3, 3, 1].
  static List<int> _setsFromReps(String reps) {
    final parts = reps.split('-').map((p) => int.tryParse(p.trim())).whereType<int>().toList();
    return parts.isEmpty ? [1] : parts;
  }

  /// Guarda el resultado de un WOD (tiempo o rondas).
  Future<Workout> saveWodResult(
    DailyWorkout d,
    WeightUnit unit, {
    required String score,
    int durationSec = 0,
    String notes = '',
  }) async {
    final w = Workout(
      id: newId(),
      date: DateTime.now(),
      unit: unit,
      title: d.name,
      style: d.style.name,
      planId: dailyKey(d, DateTime.now()),
      score: score,
      notes: notes,
      durationSec: durationSec,
    );
    await saveWorkout(w);
    return w;
  }

  // ── Planes ────────────────────────────────────────────────────────────────
  List<Plan> get plans {
    final raw = storage.readJson(_kPlans);
    if (raw is! List) return [];
    return raw.map(Plan.fromJson).whereType<Plan>().toList();
  }

  Future<void> savePlan(Plan p) async {
    final list = plans;
    final i = list.indexWhere((x) => x.id == p.id);
    if (i >= 0) {
      list[i] = p;
    } else {
      list.add(p);
    }
    await storage.writeJson(_kPlans, list.map((x) => x.toJson()).toList());
  }

  Future<void> deletePlan(String id) async {
    final list = plans..removeWhere((p) => p.id == id);
    await storage.writeJson(_kPlans, list.map((x) => x.toJson()).toList());
  }

  /// Días del plan ya hechos (según los entrenamientos guardados).
  Set<int> doneDays(String planId) => {
    for (final w in workouts)
      if (w.planId == planId && w.dayIndex != null) w.dayIndex!,
  };

  // ── Coach ─────────────────────────────────────────────────────────────────
  String get coachName => storage.readString(_kCoachName) ?? '';
  String get coachBox => storage.readString(_kCoachBox) ?? '';
  Future<void> setCoach(String name, String box) async {
    await storage.writeString(_kCoachName, name.trim());
    await storage.writeString(_kCoachBox, box.trim());
  }

  String get athleteName => storage.readString(_kAthleteName) ?? '';
  Future<void> setAthleteName(String n) => storage.writeString(_kAthleteName, n.trim());

  List<AthleteResult> get results {
    final raw = storage.readJson(_kResults);
    if (raw is! List) return [];
    final out = raw.map(AthleteResult.fromJson).whereType<AthleteResult>().toList();
    out.sort((a, b) => b.workout.date.compareTo(a.workout.date));
    return out;
  }

  /// Agrega un resultado. Devuelve false si ya estaba (mismo alumno y entreno).
  Future<bool> addResult(AthleteResult r) async {
    final list = results;
    if (list.any((x) => x.athlete == r.athlete && x.workout.id == r.workout.id)) return false;
    list.add(r);
    await storage.writeJson(_kResults, list.map((x) => x.toJson()).toList());
    return true;
  }

  Future<void> deleteAthlete(String athlete) async {
    final list = results..removeWhere((r) => r.athlete == athlete);
    await storage.writeJson(_kResults, list.map((x) => x.toJson()).toList());
  }

  /// Alumnos (sin repetir), ordenados por nombre.
  List<String> get athletes => ({for (final r in results) r.athlete}.toList()..sort());

  // ── Ejercicios ────────────────────────────────────────────────────────────
  /// Todos los ejercicios conocidos: Haltero y luego Gym, sin repetir.
  List<String> get allLifts {
    final seen = <String>{};
    return [
      for (final l in [
        ...storage.lifts,
        for (final g in Defaults.gymGroups.keys) ...storage.gymExercises(g),
      ])
        if (seen.add(l)) l,
    ];
  }

  /// true si se hace con barra olímpica (tiene calculadora de discos).
  bool isBarbell(String lift) => storage.lifts.contains(lift) || storage.isGymBarbell(lift);

  /// Peso de un ejercicio del plan para este atleta: % de su RM, redondeado
  /// a 1 kg o 5 lb. null si no hay RM ni peso fijo.
  double? targetWeight(PlanItem item, WeightUnit unit) {
    if (item.percent != null) {
      final rm = storage.lastRm(item.lift, unit);
      if (rm == null || rm <= 0) return null;
      return roundLoad(rm * item.percent! / 100, unit);
    }
    return item.weight;
  }

  /// Crea un entrenamiento a partir de un día del plan.
  Workout startFromPlan(Plan plan, int dayIndex, WeightUnit unit) {
    final day = plan.days[dayIndex];
    final logs = <ExerciseLog>[];
    for (final item in day.items) {
      final w = targetWeight(item, unit) ?? 0;
      final sets = [for (var i = 0; i < item.sets; i++) WorkSet(reps: item.reps, weight: w)];
      // Series seguidas del mismo ejercicio (p. ej. 5/3/1) van juntas.
      if (logs.isNotEmpty && logs.last.lift == item.lift) {
        logs.last.sets.addAll(sets);
      } else {
        logs.add(ExerciseLog(lift: item.lift, sets: sets, percent: item.percent));
      }
    }
    return Workout(
      id: newId(),
      date: DateTime.now(),
      unit: unit,
      title: day.name,
      exercises: logs,
      planId: plan.id,
      planName: plan.name,
      dayIndex: dayIndex,
      coach: plan.coach,
    );
  }

  /// Termina un entrenamiento: lo guarda, actualiza el RM si se levantó más
  /// en una serie de 1 repetición y devuelve los récords personales.
  Future<List<PersonalRecord>> finish(Workout w) async {
    final previous = workouts.where((x) => x.id != w.id).toList();
    final prs = findRecords(w, previous);
    for (final e in w.exercises) {
      final singles = e.sets.where((s) => s.done && s.reps == 1 && s.weight > 0);
      if (singles.isEmpty) continue;
      final best = singles.map((s) => s.weight).reduce(math.max);
      final rm = storage.lastRm(e.lift, w.unit);
      if (rm == null || best > rm) await storage.saveRm(e.lift, w.unit, best);
    }
    await saveWorkout(w);
    await saveDraft(null);
    return prs;
  }
}

// ── Cálculos ────────────────────────────────────────────────────────────────

/// Redondea a una carga práctica: 1 kg o 5 lb.
double roundLoad(double v, WeightUnit u) {
  final step = u == WeightUnit.kg ? 1.0 : 5.0;
  return (v / step).round() * step;
}

/// RM estimado (fórmula de Epley). Con más de 12 reps la estimación es mala,
/// así que se limita a 12.
double estimate1Rm(double weight, int reps) {
  if (weight <= 0 || reps <= 0) return 0;
  if (reps == 1) return weight;
  return weight * (1 + math.min(reps, 12) / 30);
}

enum RecordKind { heaviest, estimated }

class PersonalRecord {
  const PersonalRecord(this.lift, this.kind, this.value, this.unit, {this.previous});

  final String lift;
  final RecordKind kind;
  final double value;
  final WeightUnit unit;
  final double? previous;
}

/// Mejor marca de un ejercicio en un entrenamiento, en [unit].
class LiftSession {
  const LiftSession(this.date, this.heaviest, this.best1Rm, this.volume);

  final DateTime date;
  final double heaviest;
  final double best1Rm;

  /// Peso × repeticiones de todas las series hechas.
  final double volume;
}

LiftSession? sessionFor(Workout w, String lift, WeightUnit unit) {
  var heaviest = 0.0, best = 0.0, volume = 0.0, any = false;
  for (final e in w.exercises.where((e) => e.lift == lift)) {
    for (final s in e.sets.where((s) => s.done && s.reps > 0)) {
      final kg = w.unit.convert(s.weight, unit);
      any = true;
      heaviest = math.max(heaviest, kg);
      best = math.max(best, estimate1Rm(kg, s.reps));
      volume += kg * s.reps;
    }
  }
  return any ? LiftSession(w.date, heaviest, best, volume) : null;
}

/// Sesiones de un ejercicio, de la más antigua a la más nueva.
List<LiftSession> liftHistory(List<Workout> workouts, String lift, WeightUnit unit) {
  final out = [
    for (final w in workouts)
      if (sessionFor(w, lift, unit) case final s?) s,
  ];
  out.sort((a, b) => a.date.compareTo(b.date));
  return out;
}

/// Ejercicios que aparecen en los entrenamientos, del más usado al menos.
List<String> trainedLifts(List<Workout> workouts) {
  final count = <String, int>{};
  for (final w in workouts) {
    for (final e in w.exercises) {
      if (e.sets.any((s) => s.done)) count[e.lift] = (count[e.lift] ?? 0) + 1;
    }
  }
  return count.keys.toList()..sort((a, b) => count[b]!.compareTo(count[a]!));
}

/// Récords que [w] supera respecto de [previous].
List<PersonalRecord> findRecords(Workout w, List<Workout> previous) {
  final out = <PersonalRecord>[];
  final lifts = {for (final e in w.exercises) e.lift};
  for (final lift in lifts) {
    final now = sessionFor(w, lift, w.unit);
    if (now == null) continue;
    final before = liftHistory(previous, lift, w.unit);
    if (before.isEmpty) continue; // Primera vez: no cuenta como récord.
    final prevHeavy = before.map((s) => s.heaviest).reduce(math.max);
    final prevBest = before.map((s) => s.best1Rm).reduce(math.max);
    if (now.heaviest > prevHeavy + 0.001) {
      out.add(PersonalRecord(lift, RecordKind.heaviest, now.heaviest, w.unit, previous: prevHeavy));
    } else if (now.best1Rm > prevBest + 0.001) {
      out.add(PersonalRecord(lift, RecordKind.estimated, now.best1Rm, w.unit, previous: prevBest));
    }
  }
  return out;
}

/// Lunes de la semana de [d], a las 0:00. Se calcula con año/mes/día (no
/// restando Duration) para no correrse una hora en el cambio de horario.
DateTime _weekStart(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - 1));

DateTime _previousWeek(DateTime monday) => DateTime(monday.year, monday.month, monday.day - 7);

/// Semanas seguidas con al menos un entrenamiento. Si esta semana aún no hay
/// ninguno, se cuenta desde la semana pasada (la racha no se corta el lunes).
int weekStreak(List<Workout> workouts, {DateTime? now}) {
  final weeks = {for (final w in workouts) _weekStart(w.date.toLocal())};
  var week = _weekStart((now ?? DateTime.now()).toLocal());
  if (!weeks.contains(week)) week = _previousWeek(week);
  var streak = 0;
  while (weeks.contains(week)) {
    streak++;
    week = _previousWeek(week);
  }
  return streak;
}

/// Días (sin hora) con entrenamiento.
Set<DateTime> trainedDays(List<Workout> workouts) => {
  for (final w in workouts)
    DateTime(w.date.toLocal().year, w.date.toLocal().month, w.date.toLocal().day),
};

// ── Códigos para compartir ──────────────────────────────────────────────────

/// Un plan o resultado convertido en texto corto para compartir por
/// mensaje o QR: prefijo + JSON comprimido en base64.
class ShareCode {
  ShareCode._();

  static const planPrefix = 'PCPLAN1.';
  static const resultPrefix = 'PCRES1.';

  static String _pack(Object json) => base64Url.encode(gzip.encode(utf8.encode(jsonEncode(json))));

  static Object? _unpack(String data) {
    try {
      return jsonDecode(utf8.decode(gzip.decode(base64Url.decode(base64Url.normalize(data)))));
    } catch (_) {
      return null;
    }
  }

  static String _clean(String raw) => raw.replaceAll(RegExp(r'\s'), '');

  static String encodePlan(Plan p) => planPrefix + _pack(p.toJson());

  static String encodeResult(String athlete, Workout w) =>
      resultPrefix + _pack({'a': athlete, 'w': w.toJson()});

  /// Plan recibido, con id nuevo para no pisar uno propio.
  static Plan? decodePlan(String raw) {
    final s = _clean(raw);
    final i = s.indexOf(planPrefix);
    if (i < 0) return null;
    final p = Plan.fromJson(_unpack(s.substring(i + planPrefix.length)));
    if (p == null || p.days.isEmpty) return null;
    return Plan(
      id: 'c${newId()}',
      name: p.name,
      days: p.days,
      coach: p.coach,
      box: p.box,
      notes: p.notes,
    );
  }

  static AthleteResult? decodeResult(String raw) {
    final s = _clean(raw);
    final i = s.indexOf(resultPrefix);
    if (i < 0) return null;
    final j = _unpack(s.substring(i + resultPrefix.length));
    if (j is! Map) return null;
    final w = Workout.fromJson(j['w']);
    final a = '${j['a'] ?? ''}'.trim();
    if (w == null || a.isEmpty) return null;
    return AthleteResult(athlete: a, workout: w, received: DateTime.now());
  }
}

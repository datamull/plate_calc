import '../data/daily_library.dart';
import '../services/board_ai.dart';

/// Un bloque de un día del plan (fuerza, WOD, accesorios…), listo para
/// empezar como cualquier WOD de la app.
class PlanBlock {
  const PlanBlock({required this.wod, this.title, this.notes});

  final DailyWorkout wod;

  /// Encabezado tal como venía en el PDF ("Fuerza", "WOD"…).
  final String? title;

  /// Indicaciones cortas del coach (tempo, descanso, escalado).
  final String? notes;
}

/// Planificación semanal leída de un PDF. Se guarda la respuesta del
/// servidor tal cual y se convierte al abrirla, así una mejora del lector
/// también sirve para planes ya guardados.
class WeekPlan {
  const WeekPlan({
    required this.id,
    required this.uploadedAt,
    required this.weekStart,
    required this.days,
    this.title,
    this.fileName,
  });

  final String id;
  final DateTime uploadedAt;

  /// Lunes de la semana del plan.
  final DateTime weekStart;

  /// Bloques por día de la semana (1 = lunes … 7 = domingo).
  final Map<int, List<PlanBlock>> days;
  final String? title;
  final String? fileName;

  static const _dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  /// Fecha de un día de la semana del plan.
  DateTime dateOf(int weekday) => weekStart.add(Duration(days: weekday - 1));

  /// Lunes de la semana de [d] (a medianoche).
  static DateTime mondayOf(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  /// Lo que se guarda: la respuesta del servidor más los datos de la subida.
  static Map<String, Object?> envelope(
    Map<String, dynamic> server, {
    required DateTime now,
    String? fileName,
  }) {
    final ws = DateTime.tryParse('${server['week_start'] ?? ''}');
    return {
      'id': 'plan${now.millisecondsSinceEpoch}',
      'uploadedAt': now.toIso8601String(),
      'weekStart': mondayOf(ws ?? now).toIso8601String(),
      'file': fileName,
      'plan': server,
    };
  }

  static WeekPlan? fromJson(Object? raw, {required String fallbackName}) {
    if (raw is! Map) return null;
    final plan = raw['plan'];
    if (plan is! Map) return null;
    final id = '${raw['id'] ?? 'plan'}';
    final days = <int, List<PlanBlock>>{};
    final rawDays = plan['days'];
    if (rawDays is List) {
      for (final d in rawDays) {
        if (d is! Map) continue;
        final weekday = _dayKeys.indexOf('${d['day']}') + 1;
        if (weekday == 0 || d['blocks'] is! List) continue;
        final blocks = <PlanBlock>[];
        for (final b in d['blocks'] as List) {
          if (b is! Map) continue;
          final title = _str(b['title']);
          final parsed = BoardAi.fromJson(
            Map<String, dynamic>.from(b),
            fallbackName: title ?? fallbackName,
          );
          if (parsed == null || parsed.items.isEmpty) continue;
          // Identificador estable por bloque: así se marca como hecho.
          final wod = DailyWorkout(
            id: '${id}_${_dayKeys[weekday - 1]}_${blocks.length}',
            style: TrainingStyle.parse('${b['style']}') ?? TrainingStyle.crossfit,
            name: parsed.name,
            format: parsed.format,
            items: parsed.items,
            minutes: parsed.minutes,
            rounds: parsed.rounds,
            score: parsed.score,
          );
          blocks.add(PlanBlock(wod: wod, title: title, notes: _str(b['notes'])));
        }
        if (blocks.isNotEmpty) (days[weekday] ??= []).addAll(blocks);
      }
    }
    if (days.isEmpty) return null;
    return WeekPlan(
      id: id,
      uploadedAt: DateTime.tryParse('${raw['uploadedAt']}') ?? DateTime.now(),
      weekStart: mondayOf(DateTime.tryParse('${raw['weekStart']}') ?? DateTime.now()),
      days: days,
      title: _str(plan['title']),
      fileName: _str(raw['file']),
    );
  }

  static String? _str(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;
}

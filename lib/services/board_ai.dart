import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../data/daily_library.dart';
import 'board_parser.dart';

/// Lectura de la pizarra con IA (Gemini) a través del servidor de Plate Calc.
///
/// La dirección y el token llegan al compilar:
///   --dart-define=PLATECALC_AI_URL=https://…/api/scan-board
///   --dart-define=PLATECALC_AI_TOKEN=…
/// Sin ellos (o sin internet) devuelve null y la app usa el lector local.
class BoardAi {
  BoardAi._();

  static const url = String.fromEnvironment('PLATECALC_AI_URL');
  static const token = String.fromEnvironment('PLATECALC_AI_TOKEN');

  static bool get enabled => url.isNotEmpty && token.isNotEmpty;

  /// Envía la foto y devuelve el WOD leído, o null si no se pudo.
  static Future<DailyWorkout?> read(
    String imagePath, {
    required String fallbackName,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!enabled) return null;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final bytes = await File(imagePath).readAsBytes();
      final req = await client.postUrl(Uri.parse(url));
      req.headers
        ..contentType = ContentType.json
        ..set('x-app-token', token);
      req.write(jsonEncode({'image': base64Encode(bytes), 'mime': 'image/jpeg'}));
      final res = await req.close().timeout(timeout);
      final body = await res.transform(utf8.decoder).join().timeout(timeout);
      if (res.statusCode != 200) return null;
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic>) return null;
      return fromJson(json, fallbackName: fallbackName);
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  /// Respuesta del servidor → WOD de la app.
  static DailyWorkout? fromJson(Map<String, dynamic> j, {required String fallbackName}) {
    final rawItems = j['items'];
    if (rawItems is! List) return null;
    final format = switch (j['format']) {
      'amrap' => WodFormat.amrap,
      'emom' => WodFormat.emom,
      'sets' => WodFormat.sets,
      _ => WodFormat.forTime,
    };
    int? asInt(Object? v) => v is num && v > 0 ? v.round() : null;
    final minutes = asInt(j['minutes']);

    final items = <DailyItem>[];
    for (final raw in rawItems) {
      if (raw is! Map) continue;
      final move = '${raw['movement'] ?? ''}'.trim();
      if (move.isEmpty) continue;
      final known = BoardParser.matchMove(move);
      final reps = '${raw['reps'] ?? ''}'.trim();
      final rx = raw['rx'] is String && (raw['rx'] as String).trim().isNotEmpty
          ? (raw['rx'] as String).trim()
          : null;
      final pct = raw['percent'] is num ? (raw['percent'] as num).toDouble() : null;
      // "5x5" en fuerza → series y reps para registrar.
      final sr = RegExp(r'^(\d+)\s*[x×]\s*(\d+)$').firstMatch(reps);
      items.add(
        DailyItem(
          known ?? move,
          reps: sr == null ? reps : '${sr[1]}×${sr[2]}',
          sets: sr == null ? null : int.parse(sr[1]!),
          repsPerSet: sr == null ? null : int.parse(sr[2]!),
          percent: pct,
          rmOf: known == null ? null : BoardParser.rmOf(known),
          // El Rx se muestra tal como está en la pizarra ("20/14 lb").
          rxKg: rx,
          rxLb: rx,
        ),
      );
    }
    final name = j['name'] is String && (j['name'] as String).trim().isNotEmpty
        ? (j['name'] as String).trim()
        : (format == WodFormat.amrap && minutes != null ? 'AMRAP $minutes′' : fallbackName);

    return DailyWorkout(
      id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
      style: TrainingStyle.crossfit,
      name: name,
      format: format,
      items: items,
      minutes: minutes,
      rounds: asInt(j['rounds']),
      score: switch (format) {
        WodFormat.forTime => ScoreType.time,
        WodFormat.amrap => ScoreType.rounds,
        WodFormat.emom => ScoreType.none,
        WodFormat.sets => ScoreType.load,
      },
    );
  }
}

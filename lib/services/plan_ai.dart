import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'board_ai.dart';

/// Por qué no se pudo leer un plan.
enum PlanReadError { offline, tooLarge, unreadable }

/// Lectura del PDF de la planificación semanal con IA (Gemini) en el
/// servidor de Plate Calc. Usa la misma dirección y token que la pizarra,
/// cambiando /scan-board por /scan-plan.
class PlanAi {
  PlanAi._();

  /// El servidor acepta hasta ~3 MB de PDF.
  static const maxBytes = 3 * 1024 * 1024;

  static bool get enabled => BoardAi.enabled;

  static String get url => BoardAi.url.replaceFirst('scan-board', 'scan-plan');

  /// Envía el PDF. Devuelve la respuesta del servidor (para guardarla) o el
  /// motivo del error.
  static Future<(Map<String, dynamic>?, PlanReadError?)> read(
    Uint8List pdf, {
    Duration timeout = const Duration(seconds: 70),
  }) async {
    if (pdf.length > maxBytes) return (null, PlanReadError.tooLarge);
    if (!enabled) return (null, PlanReadError.offline);
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await client.postUrl(Uri.parse(url));
      req.headers
        ..contentType = ContentType.json
        ..set('x-app-token', BoardAi.token);
      req.write(jsonEncode({'pdf': base64Encode(pdf)}));
      final res = await req.close().timeout(timeout);
      final body = await res.transform(utf8.decoder).join().timeout(timeout);
      if (res.statusCode == 413) return (null, PlanReadError.tooLarge);
      if (res.statusCode != 200) {
        return (null, res.statusCode == 502 ? PlanReadError.unreadable : PlanReadError.offline);
      }
      final json = jsonDecode(body);
      if (json is! Map<String, dynamic> ||
          json['days'] is! List ||
          (json['days'] as List).isEmpty) {
        return (null, PlanReadError.unreadable);
      }
      return (json, null);
    } catch (_) {
      return (null, PlanReadError.offline);
    } finally {
      client.close(force: true);
    }
  }
}

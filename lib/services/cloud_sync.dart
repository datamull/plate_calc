import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app_storage.dart';

/// Respaldo automático en iCloud (almacén clave-valor de iCloud, sin login).
///
/// - Cada vez que los datos cambian, se sube una copia completa a iCloud
///   (al pasar la app a segundo plano y cada 20 s mientras está abierta).
/// - Al instalar la app en otro iPhone con el mismo Apple ID, la copia se
///   descarga y se restaura sola.
///
/// En Android, web o pruebas el canal no existe y todo queda desactivado.
class CloudSync with WidgetsBindingObserver {
  CloudSync(this.storage, {MethodChannel? channel, this.now = DateTime.now})
    : _channel = channel ?? const MethodChannel('platecalc/icloud');

  final AppStorage storage;
  final MethodChannel _channel;
  final DateTime Function() now;

  static const backupKey = 'platecalc_backup_v1';

  bool _available = false;
  bool get available => _available;

  Timer? _timer;

  /// Se llama cuando se restauraron datos de iCloud con la app abierta
  /// (p. ej. iCloud tardó en descargar la copia en un iPhone nuevo).
  VoidCallback? onRestored;

  /// Prepara el respaldo y restaura desde iCloud si corresponde.
  /// Devuelve true si se restauraron datos.
  Future<bool> start() async {
    try {
      _available = await _channel.invokeMethod<bool>('available') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
    if (!_available) return false;
    _channel.setMethodCallHandler(_onNativeCall);
    final restored = await _restoreIfNewer();
    if (!restored) await backupNow();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => backupNow());
    return restored;
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      backupNow();
    }
  }

  Future<void> _onNativeCall(MethodCall call) async {
    if (call.method != 'changed') return;
    // Llegó una copia de otro dispositivo o la descarga inicial de iCloud.
    if (await _restoreIfNewer()) onRestored?.call();
  }

  /// Sube los datos si cambiaron desde la última copia.
  Future<void> backupNow() async {
    if (!_available) return;
    final data = encodeData(storage.exportAll());
    final hash = _hash(data);
    if (hash == storage.cloudLastHash) return;
    final updatedAt = now().toUtc().toIso8601String();
    final payload = jsonEncode({'updatedAt': updatedAt, 'data': data});
    try {
      await _channel.invokeMethod<bool>('set', {'key': backupKey, 'value': payload});
      await storage.setCloudState(updatedAt: updatedAt, hash: hash);
    } on PlatformException {
      // Sin conexión o iCloud lleno: se reintenta en la próxima vuelta.
    }
  }

  /// Restaura la copia de iCloud si es más nueva que los datos locales.
  ///
  /// Si este iPhone tiene datos que nunca se respaldaron (p. ej. venía de la
  /// versión sin iCloud), se conservan los locales y no se pisa nada.
  Future<bool> _restoreIfNewer() async {
    if (!_available) return false;
    String? raw;
    try {
      raw = await _channel.invokeMethod<String>('get', {'key': backupKey});
    } on PlatformException {
      return false;
    }
    if (raw == null || raw.isEmpty) return false;

    final Map<String, dynamic> cloud;
    try {
      cloud = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return false;
    }
    final cloudAt = DateTime.tryParse('${cloud['updatedAt']}');
    final data = cloud['data'];
    if (cloudAt == null || data is! Map<String, dynamic>) return false;

    final localAt = DateTime.tryParse(storage.cloudLocalUpdatedAt ?? '');
    final shouldRestore = localAt == null ? !storage.hasUserData : cloudAt.isAfter(localAt);
    if (!shouldRestore) return false;

    await storage.importAll(decodeData(data));
    await storage.setCloudState(
      updatedAt: cloudAt.toUtc().toIso8601String(),
      hash: _hash(data),
    );
    return true;
  }

  /// Guarda cada valor con su tipo, porque en JSON 100.0 y 100 son lo mismo
  /// y el RM debe volver como double.
  static Map<String, dynamic> encodeData(Map<String, Object> values) => {
    for (final e in values.entries)
      e.key: switch (e.value) {
        final bool v => {'t': 'b', 'v': v},
        final int v => {'t': 'i', 'v': v},
        final double v => {'t': 'd', 'v': v},
        final String v => {'t': 's', 'v': v},
        final List<dynamic> v => {'t': 'l', 'v': v.map((x) => '$x').toList()},
        _ => {'t': 's', 'v': '${e.value}'},
      },
  };

  static Map<String, Object?> decodeData(Map<String, dynamic> data) {
    final out = <String, Object?>{};
    for (final e in data.entries) {
      final item = e.value;
      if (item is! Map) continue;
      final v = item['v'];
      out[e.key] = switch (item['t']) {
        'b' => v == true,
        'i' => (v as num).toInt(),
        'd' => (v as num).toDouble(),
        'l' => (v as List).map((x) => '$x').toList(),
        _ => '$v',
      };
    }
    return out;
  }

  static String _hash(Map<String, dynamic> data) {
    final keys = data.keys.toList()..sort();
    final canonical = jsonEncode({for (final k in keys) k: data[k]});
    // Hash simple (FNV-1a de 32 bits): solo sirve para detectar cambios.
    var h = 0x811c9dc5;
    for (final c in utf8.encode(canonical)) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h.toRadixString(16);
  }
}

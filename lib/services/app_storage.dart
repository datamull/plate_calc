import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/defaults.dart';
import '../models/settings.dart';
import '../models/weight_unit.dart';

class RmEntry {
  final double rm;
  final DateTime ts;
  const RmEntry(this.rm, this.ts);
}

/// Único punto de acceso a los datos guardados.
///
/// Se inicializa una sola vez al abrir la app ([AppStorage.load]); después
/// todas las lecturas son síncronas (antes cada pantalla y cada tarjeta
/// llamaba a `SharedPreferences.getInstance()` por separado).
///
/// Las claves son las mismas de la v1, así que los RM, historiales,
/// movimientos e inventarios de los usuarios actuales se conservan.
class AppStorage {
  AppStorage(this._prefs);

  final SharedPreferences _prefs;

  static Future<AppStorage> load() async => AppStorage(await SharedPreferences.getInstance());

  // ── Claves (compatibles con v1) ───────────────────────────────────────────
  static const _kLocale = 'app_locale';
  static const _kCustomLifts = 'custom_lifts';
  static String _kRm(String lift, WeightUnit u) => 'rm_${lift}_${u.name}';
  static String _kHistory(String lift, WeightUnit u) => 'history_${lift}_${u.name}';
  static String _kInventory(WeightUnit u) => 'inventory_settings_${u.name}';

  // ── Claves nuevas en v2 ───────────────────────────────────────────────────
  static const _kHiddenBaseLifts = 'hidden_base_lifts';
  static const _kListUnit = 'lifts_units';
  static const _kTargetMode = 'target_mode';
  static String _kLiftIcon(String lift) => 'lift_icon_$lift';
  static String _kGymCustom(String group) => 'gym_custom_$group';
  static String _kGymHidden(String group) => 'gym_hidden_$group';
  static const _kGymBarbell = 'gym_barbell';

  // ── Respaldo (iCloud) ─────────────────────────────────────────────────────
  /// Claves locales del respaldo que no se copian a la nube.
  static bool _isLocalOnly(String key) => key.startsWith('cloud_');

  /// true si hay datos propios del usuario (RM, historial, movimientos,
  /// inventario...). Una instalación nueva no tiene ninguno.
  bool get hasUserData => _prefs.getKeys().any(
    (k) =>
        k.startsWith('rm_') ||
        k.startsWith('history_') ||
        k.startsWith('inventory_settings_') ||
        k.startsWith('gym_') ||
        k == _kCustomLifts ||
        k == _kHiddenBaseLifts,
  );

  /// Todos los datos guardados, listos para convertir a JSON.
  Map<String, Object> exportAll() {
    final out = <String, Object>{};
    for (final k in _prefs.getKeys()) {
      if (_isLocalOnly(k)) continue;
      final v = _prefs.get(k);
      if (v != null) out[k] = v;
    }
    return out;
  }

  /// Reemplaza los datos locales por los del respaldo.
  Future<void> importAll(Map<String, Object?> data) async {
    for (final k in _prefs.getKeys().toList()) {
      if (!_isLocalOnly(k)) await _prefs.remove(k);
    }
    for (final e in data.entries) {
      final v = e.value;
      if (_isLocalOnly(e.key)) continue;
      if (v is bool) {
        await _prefs.setBool(e.key, v);
      } else if (v is int) {
        await _prefs.setInt(e.key, v);
      } else if (v is double) {
        await _prefs.setDouble(e.key, v);
      } else if (v is String) {
        await _prefs.setString(e.key, v);
      } else if (v is List) {
        await _prefs.setStringList(e.key, v.map((x) => '$x').toList());
      }
    }
  }

  String? get cloudLocalUpdatedAt => _prefs.getString('cloud_local_updated_at');
  String? get cloudLastHash => _prefs.getString('cloud_last_hash');

  Future<void> setCloudState({required String updatedAt, required String hash}) async {
    await _prefs.setString('cloud_local_updated_at', updatedAt);
    await _prefs.setString('cloud_last_hash', hash);
  }

  // ── Idioma ────────────────────────────────────────────────────────────────
  String? get localeCode => _prefs.getString(_kLocale);

  Future<void> setLocaleCode(String? code) =>
      code == null ? _prefs.remove(_kLocale) : _prefs.setString(_kLocale, code);

  // ── Preferencias de uso ───────────────────────────────────────────────────
  WeightUnit get listUnit =>
      WeightUnit.parse(_prefs.getString(_kListUnit), fallback: WeightUnit.lb);

  Future<void> setListUnit(WeightUnit u) => _prefs.setString(_kListUnit, u.name);

  String? get targetMode => _prefs.getString(_kTargetMode);

  Future<void> setTargetMode(String mode) => _prefs.setString(_kTargetMode, mode);

  // ── Movimientos ───────────────────────────────────────────────────────────
  List<String> get lifts {
    final hidden = _prefs.getStringList(_kHiddenBaseLifts) ?? const [];
    final custom = _prefs.getStringList(_kCustomLifts) ?? const [];
    return [...Defaults.baseLifts.where((l) => !hidden.contains(l)), ...custom];
  }

  /// Agrega un movimiento. Devuelve false si ya existe (sin distinguir
  /// mayúsculas). Si era un movimiento base oculto, lo vuelve a mostrar.
  Future<bool> addLift(String name) async {
    final n = name.trim();
    if (n.isEmpty) return false;
    final hidden = [...?_prefs.getStringList(_kHiddenBaseLifts)];
    final base = Defaults.baseLifts.where((b) => _same(b, n));
    if (base.isNotEmpty && hidden.remove(base.first)) {
      await _prefs.setStringList(_kHiddenBaseLifts, hidden);
      return true;
    }
    if (lifts.any((l) => _same(l, n))) return false;
    final custom = [...?_prefs.getStringList(_kCustomLifts), n];
    await _prefs.setStringList(_kCustomLifts, custom);
    return true;
  }

  // ── Gym: ejercicios por grupo muscular ────────────────────────────────────
  List<String> gymExercises(String group) {
    final base = Defaults.gymGroups[group] ?? const <String>[];
    final hidden = _prefs.getStringList(_kGymHidden(group)) ?? const [];
    final custom = _prefs.getStringList(_kGymCustom(group)) ?? const [];
    return [...base.where((l) => !hidden.contains(l)), ...custom];
  }

  /// true si el ejercicio de Gym se hace con barra (tiene calculadora).
  bool isGymBarbell(String name) =>
      Defaults.gymBarbell.contains(name) ||
      (_prefs.getStringList(_kGymBarbell) ?? const []).contains(name);

  /// Agrega un ejercicio al grupo. Devuelve false si ya existe en ese grupo.
  Future<bool> addGymExercise(String group, String name, {required bool barbell}) async {
    final n = name.trim();
    if (n.isEmpty) return false;
    final base = (Defaults.gymGroups[group] ?? const <String>[]).where((b) => _same(b, n));
    final hidden = [...?_prefs.getStringList(_kGymHidden(group))];
    if (base.isNotEmpty && hidden.remove(base.first)) {
      await _prefs.setStringList(_kGymHidden(group), hidden);
      return true;
    }
    if (gymExercises(group).any((l) => _same(l, n))) return false;
    await _prefs.setStringList(_kGymCustom(group), [...?_prefs.getStringList(_kGymCustom(group)), n]);
    if (barbell) {
      final list = {...?_prefs.getStringList(_kGymBarbell), n}.toList();
      await _prefs.setStringList(_kGymBarbell, list);
    }
    return true;
  }

  /// Quita un ejercicio del grupo. Su RM e historial se borran solo si el
  /// mismo nombre no se usa en Haltero ni en otro grupo.
  Future<void> deleteGymExercise(String group, String name) async {
    if ((Defaults.gymGroups[group] ?? const <String>[]).contains(name)) {
      final hidden = {...?_prefs.getStringList(_kGymHidden(group)), name}.toList();
      await _prefs.setStringList(_kGymHidden(group), hidden);
    } else {
      final custom = [...?_prefs.getStringList(_kGymCustom(group))]
        ..removeWhere((l) => _same(l, name));
      await _prefs.setStringList(_kGymCustom(group), custom);
    }
    final stillUsed = lifts.contains(name) ||
        Defaults.gymGroups.keys.any((g) => g != group && gymExercises(g).contains(name));
    if (!stillUsed) await _removeLiftData(name);
  }

  Future<void> _removeLiftData(String name) async {
    for (final u in WeightUnit.values) {
      await _prefs.remove(_kRm(name, u));
      await _prefs.remove(_kHistory(name, u));
    }
    await _prefs.remove(_kLiftIcon(name));
    final barbell = [...?_prefs.getStringList(_kGymBarbell)]..remove(name);
    await _prefs.setStringList(_kGymBarbell, barbell);
  }

  /// Elimina un movimiento con su RM e historial en ambas unidades.
  /// En la v1 los movimientos base reaparecían y el RM no se borraba
  /// (se usaba una clave distinta a la de guardado).
  Future<void> deleteLift(String name) async {
    if (Defaults.baseLifts.contains(name)) {
      final hidden = {...?_prefs.getStringList(_kHiddenBaseLifts), name}.toList();
      await _prefs.setStringList(_kHiddenBaseLifts, hidden);
    } else {
      final custom = [...?_prefs.getStringList(_kCustomLifts)]..removeWhere((l) => _same(l, name));
      await _prefs.setStringList(_kCustomLifts, custom);
    }
    // Si el mismo ejercicio está en Gym, se conservan su RM e historial.
    final inGym = Defaults.gymGroups.keys.any((g) => gymExercises(g).contains(name));
    if (!inGym) await _removeLiftData(name);
    // Clave usada por una pantalla antigua de la v1.
    await _prefs.remove('rm_history_$name');
  }

  /// Ícono elegido por el usuario para un movimiento (nombre de [LiftPose]),
  /// o null si se elige automáticamente según el nombre.
  String? liftIcon(String lift) => _prefs.getString(_kLiftIcon(lift));

  Future<void> setLiftIcon(String lift, String? pose) => pose == null
      ? _prefs.remove(_kLiftIcon(lift))
      : _prefs.setString(_kLiftIcon(lift), pose);

  static bool _same(String a, String b) => a.trim().toLowerCase() == b.trim().toLowerCase();

  // ── RM e historial ────────────────────────────────────────────────────────
  double? lastRm(String lift, WeightUnit u) => _prefs.getDouble(_kRm(lift, u));

  /// Guarda el RM como último valor y lo agrega al historial.
  Future<void> saveRm(String lift, WeightUnit u, double rm) async {
    await _prefs.setDouble(_kRm(lift, u), rm);
    final list = _rawHistory(lift, u)..add({'rm': rm, 'ts': DateTime.now().toIso8601String()});
    await _prefs.setString(_kHistory(lift, u), jsonEncode(list));
  }

  /// Historial ordenado del más reciente al más antiguo.
  List<RmEntry> history(String lift, WeightUnit u) {
    final out = <RmEntry>[];
    for (final e in _rawHistory(lift, u)) {
      final rm = e['rm'];
      final ts = DateTime.tryParse('${e['ts']}');
      if (rm is num && ts != null) out.add(RmEntry(rm.toDouble(), ts));
    }
    out.sort((a, b) => b.ts.compareTo(a.ts));
    return out;
  }

  Future<void> deleteHistoryEntry(String lift, WeightUnit u, RmEntry entry) async {
    final list = _rawHistory(lift, u)..removeWhere((e) => e['ts'] == entry.ts.toIso8601String());
    await _prefs.setString(_kHistory(lift, u), jsonEncode(list));
  }

  Future<void> clearHistory(String lift, WeightUnit u) => _prefs.remove(_kHistory(lift, u));

  List<Map<String, dynamic>> _rawHistory(String lift, WeightUnit u) {
    final raw = _prefs.getString(_kHistory(lift, u));
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.whereType<Map<Object?, Object?>>().map(Map<String, dynamic>.from).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Inventario / equipamiento ─────────────────────────────────────────────
  Settings settings(WeightUnit u) {
    final fallback = Defaults.settingsFor(u);
    final raw = _prefs.getString(_kInventory(u));
    if (raw == null) return fallback;
    try {
      return Settings.fromJson(jsonDecode(raw), fallback);
    } catch (_) {
      return fallback;
    }
  }

  Future<void> saveSettings(Settings s) =>
      _prefs.setString(_kInventory(s.unit), jsonEncode(s.toJson()));
}

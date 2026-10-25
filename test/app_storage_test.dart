import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plate_calc/data/defaults.dart';
import 'package:plate_calc/models/plate.dart';
import 'package:plate_calc/models/weight_unit.dart';
import 'package:plate_calc/services/app_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppStorage> storageWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return AppStorage.load();
}

void main() {
  group('compatibilidad con datos de la v1', () {
    test('lee RM, historial, movimientos e inventario guardados por la v1', () async {
      final s = await storageWith({
        'rm_Snatch_kg': 80.0,
        'history_Snatch_kg': jsonEncode([
          {'rm': 75.0, 'ts': '2025-01-01T10:00:00.000'},
          {'rm': 80.0, 'ts': '2025-03-01T10:00:00.000'},
        ]),
        'custom_lifts': ['Front Squat'],
        'inventory_settings_kg': jsonEncode([
          {'weight': 20, 'count': 6},
          {'weight': 10, 'count': 2},
        ]),
        'app_locale': 'fr',
      });

      expect(s.lastRm('Snatch', WeightUnit.kg), 80);
      expect(s.history('Snatch', WeightUnit.kg).map((e) => e.rm), [80, 75]);
      expect(s.lifts, [...Defaults.baseLifts, 'Front Squat']);
      expect(s.settings(WeightUnit.kg).plates, const [
        Plate(weight: 20, count: 6),
        Plate(weight: 10, count: 2),
      ]);
      expect(s.settings(WeightUnit.kg).barWeight, 20);
      expect(s.localeCode, 'fr');
    });

    test('formato v1 antiguo {plates: [...]} y datos corruptos', () async {
      final s = await storageWith({
        'inventory_settings_lb': jsonEncode({
          'plates': [
            {'weight': 45, 'count': 4},
            {'weight': 'x', 'count': 2}, // inválido: se ignora
          ],
        }),
        'inventory_settings_kg': '{no es json',
        'history_Clean_kg': 'basura',
      });
      expect(s.settings(WeightUnit.lb).plates, const [Plate(weight: 45, count: 4)]);
      expect(s.settings(WeightUnit.kg).plates, Defaults.settingsFor(WeightUnit.kg).plates);
      expect(s.history('Clean', WeightUnit.kg), isEmpty);
    });
  });

  group('movimientos', () {
    test('borrar un movimiento base lo oculta y borra su RM e historial', () async {
      final s = await storageWith({});
      await s.saveRm('Deadlift', WeightUnit.kg, 200);
      await s.saveRm('Deadlift', WeightUnit.lb, 440);
      await s.deleteLift('Deadlift');

      expect(s.lifts, isNot(contains('Deadlift')));
      expect(s.lastRm('Deadlift', WeightUnit.kg), isNull);
      expect(s.lastRm('Deadlift', WeightUnit.lb), isNull);
      expect(s.history('Deadlift', WeightUnit.kg), isEmpty);

      // Se puede volver a agregar.
      expect(await s.addLift('deadlift'), isTrue);
      expect(s.lifts, contains('Deadlift'));
    });

    test('no permite duplicados', () async {
      final s = await storageWith({});
      expect(await s.addLift('Front Squat'), isTrue);
      expect(await s.addLift(' front squat '), isFalse);
      expect(await s.addLift('snatch'), isFalse);
      expect(s.lifts.where((l) => l == 'Front Squat'), hasLength(1));
    });

    test('borrar un movimiento propio', () async {
      final s = await storageWith({
        'custom_lifts': ['Press'],
      });
      await s.saveRm('Press', WeightUnit.kg, 60);
      await s.deleteLift('Press');
      expect(s.lifts, isNot(contains('Press')));
      expect(s.lastRm('Press', WeightUnit.kg), isNull);
    });
  });

  test('guardar RM actualiza el último valor y el historial', () async {
    final s = await storageWith({});
    await s.saveRm('Jerk', WeightUnit.kg, 100);
    await s.saveRm('Jerk', WeightUnit.kg, 105);
    expect(s.lastRm('Jerk', WeightUnit.kg), 105);
    final h = s.history('Jerk', WeightUnit.kg);
    expect(h, hasLength(2));
    await s.deleteHistoryEntry('Jerk', WeightUnit.kg, h.first);
    expect(s.history('Jerk', WeightUnit.kg), hasLength(1));
  });

  test('barra y collares se guardan con el inventario', () async {
    final s = await storageWith({});
    await s.saveSettings(s.settings(WeightUnit.kg).copyWith(barWeight: 15, collarsWeight: 2.5));
    final again = await AppStorage.load();
    expect(again.settings(WeightUnit.kg).barWeight, 15);
    expect(again.settings(WeightUnit.kg).collarsWeight, 2.5);
  });
}

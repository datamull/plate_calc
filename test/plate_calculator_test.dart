import 'package:flutter_test/flutter_test.dart';
import 'package:plate_calc/data/defaults.dart';
import 'package:plate_calc/models/plate.dart';
import 'package:plate_calc/models/weight_unit.dart';
import 'package:plate_calc/services/plate_calculator.dart';

double sum(List<double> l) => l.fold(0, (s, w) => s + w);

void main() {
  group('computePlates', () {
    test('devuelve null si el objetivo es menor que la barra', () {
      expect(computePlates(target: 15, barWeight: 20, collarsWeight: 0, plates: const []), isNull);
    });

    test('solo barra -> sin discos, exacto', () {
      final r = computePlates(
        target: 20,
        barWeight: 20,
        collarsWeight: 0,
        plates: Defaults.settingsFor(WeightUnit.kg).plates,
      )!;
      expect(r.perSide, isEmpty);
      expect(r.exact, isTrue);
      expect(r.totalAchieved, 20);
    });

    test('100 kg con inventario por defecto', () {
      final r = computePlates(
        target: 100,
        barWeight: 20,
        collarsWeight: 0,
        plates: Defaults.settingsFor(WeightUnit.kg).plates,
      )!;
      expect(r.exact, isTrue);
      expect(sum(r.perSide), 40);
      expect(r.perSide, [25, 15]); // menos discos posible
    });

    test('encuentra la combinación exacta donde la v1 (greedy) fallaba', () {
      // 45 + 2*60 = 165 lb. Greedy: 45+10 = 55 por lado. Correcto: 35+25.
      final r = computePlates(
        target: 165,
        barWeight: 45,
        collarsWeight: 0,
        plates: const [
          Plate(weight: 45, count: 2),
          Plate(weight: 35, count: 2),
          Plate(weight: 25, count: 2),
          Plate(weight: 10, count: 2),
        ],
      )!;
      expect(r.exact, isTrue);
      expect(r.perSide, [35, 25]);
    });

    test('a igual cantidad de discos, prefiere los más pesados', () {
      final r = computePlates(
        target: 200,
        barWeight: 45,
        collarsWeight: 0,
        plates: Defaults.settingsFor(WeightUnit.lb).plates,
      )!;
      expect(r.perSide, [45, 25, 5, 2.5]); // no 35+35+5+2.5
    });

    test('nunca se pasa del objetivo', () {
      final plates = Defaults.settingsFor(WeightUnit.lb).plates;
      for (var t = 45.0; t <= 1000; t += 2.5) {
        final r = computePlates(target: t, barWeight: 45, collarsWeight: 0, plates: plates)!;
        expect(r.totalAchieved, lessThanOrEqualTo(t + 1e-9), reason: 'target $t');
        expect(sum(r.perSide) * 2 + 45, closeTo(r.totalAchieved, 1e-9));
      }
    });

    test('respeta la cantidad disponible de cada disco', () {
      final r = computePlates(
        target: 220,
        barWeight: 20,
        collarsWeight: 0,
        plates: const [Plate(weight: 25, count: 4)], // 2 por lado
      )!;
      expect(r.perSide, [25, 25]);
      expect(r.exact, isFalse);
      expect(r.shortfall, 100);
      expect(r.used, {25.0: 4});
    });

    test('discos impares: el sobrante no se usa', () {
      final r = computePlates(
        target: 70,
        barWeight: 20,
        collarsWeight: 0,
        plates: const [Plate(weight: 25, count: 3)],
      )!;
      expect(r.perSide, [25]);
      expect(r.exact, isTrue);
    });

    test('sin errores de coma flotante con fraccionarios', () {
      final r = computePlates(
        target: 20 + 2 * 3.75,
        barWeight: 20,
        collarsWeight: 0,
        plates: Defaults.settingsFor(WeightUnit.kg).plates,
      )!;
      expect(r.exact, isTrue);
      expect(r.totalAchieved, closeTo(27.5, 1e-9));
    });

    test('incluye collares en el total', () {
      final r = computePlates(
        target: 105,
        barWeight: 20,
        collarsWeight: 5,
        plates: Defaults.settingsFor(WeightUnit.kg).plates,
      )!;
      expect(sum(r.perSide), 40);
      expect(r.totalAchieved, 105);
    });

    test('objetivo no alcanzable con exactitud -> mejor aproximación por debajo', () {
      final r = computePlates(
        target: 101.3,
        barWeight: 20,
        collarsWeight: 0,
        plates: Defaults.settingsFor(WeightUnit.kg).plates,
      )!;
      expect(r.exact, isFalse);
      expect(r.totalAchieved, 101);
      expect(r.shortfall, closeTo(0.3, 1e-9));
    });

    test('pesos grandes en lb siguen siendo rápidos', () {
      final sw = Stopwatch()..start();
      final r = computePlates(
        target: 45 + 2 * 45 * 4 + 2 * 35 * 4 + 5,
        barWeight: 45,
        collarsWeight: 0,
        plates: Defaults.settingsFor(WeightUnit.lb).plates,
      )!;
      expect(sw.elapsedMilliseconds, lessThan(200));
      expect(r.totalAchieved, 45 + 2 * 45 * 4 + 2 * 35 * 4 + 5);
    });
  });
}

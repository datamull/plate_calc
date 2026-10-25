import '../models/plate.dart';

class PlateResult {
  /// Discos de UN lado, del más pesado (junto al centro) al más liviano.
  final List<double> perSide;

  /// Peso del disco -> cantidad total usada (ambos lados).
  final Map<double, int> used;

  /// Peso total logrado (barra + collares + discos).
  final double totalAchieved;

  /// Cuánto falta para el objetivo (0 si es exacto).
  final double shortfall;

  const PlateResult({
    required this.perSide,
    required this.used,
    required this.totalAchieved,
    required this.shortfall,
  });

  bool get exact => shortfall < 0.005;
}

/// Trabajamos en centésimas enteras para evitar errores de coma flotante
/// (p. ej. 0.1 + 0.2 != 0.3).
int _toCents(double v) => (v * 100).round();

int _gcd(int a, int b) {
  while (b != 0) {
    final t = b;
    b = a % b;
    a = t;
  }
  return a.abs();
}

/// Calcula la mejor combinación de discos.
///
/// [target] es SIEMPRE el peso TOTAL objetivo (barra y collares incluidos).
/// Devuelve null si el objetivo es menor que barra + collares.
///
/// A diferencia de la v1 (que elegía de mayor a menor y podía fallar, p. ej.
/// 60 lb por lado con discos de 45/35/25/10: la v1 daba 45+10=55 en vez de
/// 35+25=60), aquí se busca la combinación exacta con programación dinámica:
///   1. el mayor peso posible sin pasarse del objetivo;
///   2. entre esas, la que usa menos discos;
///   3. si empatan, la que usa discos más pesados (como se carga en el gym).
PlateResult? computePlates({
  required double target,
  required double barWeight,
  required double collarsWeight,
  required List<Plate> plates,
}) {
  final baseCents = _toCents(barWeight) + _toCents(collarsWeight);
  final targetCents = _toCents(target);
  if (targetCents < baseCents) return null;

  // Solo sirven discos que se pueden poner de a pares (uno por lado).
  final types = <({int cents, int pairs})>[];
  for (final p in plates) {
    final c = _toCents(p.weight);
    final pairs = p.count ~/ 2;
    if (c > 0 && pairs > 0) types.add((cents: c, pairs: pairs));
  }
  types.sort((a, b) => b.cents.compareTo(a.cents));

  final perSideTargetCents = (targetCents - baseCents) ~/ 2;
  if (types.isEmpty || perSideTargetCents == 0) {
    return _result(const [], baseCents, targetCents);
  }

  // Reducimos la escala al máximo común divisor de los discos (en kg suele
  // ser 0,25 o 0,5) para que la tabla sea pequeña.
  final step = types.map((t) => t.cents).reduce(_gcd);
  final totalAvail = types.fold<int>(0, (s, t) => s + t.cents * t.pairs) ~/ step;
  final cap = (perSideTargetCents ~/ step).clamp(0, totalAvail);

  // Mochila acotada con división binaria (1, 2, 4, ... discos por paquete).
  final bundles = <({int cents, int qty})>[];
  for (final t in types) {
    var left = t.pairs;
    var k = 1;
    while (left > 0) {
      final q = k < left ? k : left;
      bundles.add((cents: t.cents, qty: q));
      left -= q;
      k <<= 1;
    }
  }

  // Costo = discos * _big - suma de cuadrados de los pesos: minimiza la
  // cantidad de discos y, a igual cantidad, prefiere discos pesados.
  // Valores < 2^53 para funcionar también en web.
  const big = 1000000000000; // 1e12
  const inf = 9000000000000000; // 9e15
  final best = List<int>.filled(cap + 1, inf);
  best[0] = 0;
  // take[i][s] = el paquete i se usa en la solución óptima para la suma s.
  final take = List.generate(bundles.length, (_) => List<bool>.filled(cap + 1, false));

  for (var i = 0; i < bundles.length; i++) {
    final u = bundles[i].cents ~/ step;
    final q = bundles[i].qty;
    final w = u * q;
    final cost = q * big - q * u * u;
    for (var s = cap; s >= w; s--) {
      final prev = best[s - w];
      if (prev != inf && prev + cost < best[s]) {
        best[s] = prev + cost;
        take[i][s] = true;
      }
    }
  }

  var s = cap;
  while (s > 0 && best[s] == inf) {
    s--;
  }

  final perSide = <double>[];
  for (var i = bundles.length - 1; i >= 0 && s > 0; i--) {
    if (take[i][s]) {
      for (var j = 0; j < bundles[i].qty; j++) {
        perSide.add(bundles[i].cents / 100);
      }
      s -= (bundles[i].cents ~/ step) * bundles[i].qty;
    }
  }
  perSide.sort((a, b) => b.compareTo(a));

  return _result(perSide, baseCents, targetCents);
}

PlateResult _result(List<double> perSide, int baseCents, int targetCents) {
  final used = <double, int>{};
  var sideCents = 0;
  for (final w in perSide) {
    used[w] = (used[w] ?? 0) + 2;
    sideCents += _toCents(w);
  }
  final achieved = baseCents + 2 * sideCents;
  return PlateResult(
    perSide: List.unmodifiable(perSide),
    used: Map.unmodifiable(used),
    totalAchieved: achieved / 100,
    shortfall: (targetCents - achieved) / 100,
  );
}

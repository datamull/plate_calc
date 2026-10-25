import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/weight_unit.dart';

/// Colores de los discos (solo visuales).
///
/// Libras: 45 azul, 35 rojo, 25 verde, 10 amarillo, 5 azul, 2.5 verde.
/// Kilos: cada disco usa el color de su equivalente en libras
/// (20 kg ≈ 45 lb azul, 15 kg ≈ 35 lb rojo, 10 kg ≈ 25 lb verde, etc.).
/// Cualquier otro peso recibe un color fijo y aleatorio (siempre el mismo
/// para ese peso, para que no cambie al redibujar).
class PlateVisual {
  PlateVisual._();

  static const _blue = Color(0xFF1E88E5);
  static const _red = Color(0xFFE53935);
  static const _green = Color(0xFF43A047);
  static const _yellow = Color(0xFFFDD835);

  static final Map<double, Color> _lb = {
    45: _blue,
    35: _red,
    25: _green,
    10: _yellow,
    5: _blue,
    2.5: _green,
  };

  static final Map<double, Color> _kg = {
    20: _blue,
    15: _red,
    10: _green,
    5: _yellow,
    2.5: _blue,
    1.25: _green,
  };

  static const _palette = <Color>[
    Color(0xFF8E24AA), // morado
    Color(0xFF00897B), // turquesa
    Color(0xFFFB8C00), // naranja
    Color(0xFFEC407A), // rosa
    Color(0xFF26C6DA), // cian
    Color(0xFF6D4C41), // café
    Color(0xFF3949AB), // índigo
    Color(0xFF78909C), // gris
  ];

  static Color color(WeightUnit unit, double w) {
    final table = unit == WeightUnit.kg ? _kg : _lb;
    for (final e in table.entries) {
      if ((e.key - w).abs() < 0.001) return e.value;
    }
    // Peso sin color asignado: aleatorio pero fijo para ese peso.
    final seed = (w * 1000).round() + (unit == WeightUnit.kg ? 7 : 0);
    return _palette[math.Random(seed).nextInt(_palette.length)];
  }
}

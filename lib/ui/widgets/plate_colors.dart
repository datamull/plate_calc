import 'package:flutter/material.dart';

import '../../models/weight_unit.dart';

/// Colores y anchos (solo visuales) de los discos.
class PlateVisual {
  PlateVisual._();

  static const _fallback = Color(0xFF757575);

  static final Map<double, Color> _kg = {
    25: const Color(0xFFE53935), // rojo
    20: const Color(0xFF1E88E5), // azul
    15: const Color(0xFFFDD835), // amarillo
    10: const Color(0xFF43A047), // verde
    5: const Color(0xFF8E24AA), // morado
    2.5: const Color(0xFF546E7A),
    2: const Color(0xFF64B5F6),
    1.5: const Color(0xFFFFF176),
    1.25: const Color(0xFF90A4AE),
    1: const Color(0xFF81C784),
    0.5: const Color(0xFFB0BEC5),
  };

  static final Map<double, Color> _lb = {
    45: const Color(0xFFE53935), // rojo
    35: const Color(0xFFFDD835), // amarillo
    25: const Color(0xFF43A047), // verde
    10: const Color(0xFF1E88E5), // azul
    5: const Color(0xFF8E24AA), // morado
    2.5: const Color(0xFF546E7A),
    2: const Color(0xFF64B5F6),
    1.25: const Color(0xFF90A4AE),
    0.5: const Color(0xFFB0BEC5),
  };

  static Color color(WeightUnit unit, double w) {
    final table = unit == WeightUnit.kg ? _kg : _lb;
    for (final e in table.entries) {
      if ((e.key - w).abs() < 0.001) return e.value;
    }
    return _fallback;
  }

  /// Ancho relativo: los discos pesados son más anchos.
  static double width(WeightUnit unit, double w) {
    final big = unit == WeightUnit.kg ? 25.0 : 45.0;
    final ratio = (w / big).clamp(0.0, 1.0);
    return 10 + 20 * ratio; // de 10 a 30 px
  }
}

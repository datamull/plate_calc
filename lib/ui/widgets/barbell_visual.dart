import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/weight_unit.dart';
import 'plate_colors.dart';

/// Dibujo de la barra cargada (simétrica).
class BarbellView extends StatelessWidget {
  const BarbellView({super.key, required this.perSide, required this.unit, this.height = 180});

  /// Discos de un lado, del más pesado al más liviano.
  final List<double> perSide;
  final WeightUnit unit;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarbellPainter(
          perSide: perSide,
          unit: unit,
          barColor: scheme.outline,
          sleeveColor: scheme.onSurface,
        ),
      ),
    );
  }
}

class _BarbellPainter extends CustomPainter {
  _BarbellPainter({
    required this.perSide,
    required this.unit,
    required this.barColor,
    required this.sleeveColor,
  });

  final List<double> perSide;
  final WeightUnit unit;
  final Color barColor;
  final Color sleeveColor;

  static const _barThickness = 10.0;
  static const _baseGap = 4.0;
  static const _clipWidth = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final sleeveLength = size.width * 0.28;
    final plateHeight = size.height * 0.45;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: size.width - 2 * sleeveLength,
          height: _barThickness,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = barColor,
    );

    final sleevePaint = Paint()..color = sleeveColor;
    canvas.drawRect(
      Rect.fromLTWH(0, cy - _barThickness / 2, sleeveLength, _barThickness),
      sleevePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width - sleeveLength, cy - _barThickness / 2, sleeveLength, _barThickness),
      sleevePaint,
    );

    // Si los discos no caben en la manga, se escalan.
    final baseWidths = perSide.map((w) => PlateVisual.width(unit, w)).toList();
    final available = sleeveLength - 16;
    final need =
        baseWidths.fold<double>(0, (s, w) => s + w) +
        (perSide.isEmpty ? 0 : _baseGap * (perSide.length - 1));
    final scale = need > available ? available / need : 1.0;
    final gap = _baseGap * scale;

    var leftEdge = sleeveLength; // borde interno de la manga izquierda
    var rightEdge = size.width - sleeveLength; // borde interno de la derecha

    for (var i = 0; i < perSide.length; i++) {
      final pw = baseWidths[i] * scale;
      final g = i == 0 ? 0.0 : gap;
      final paint = Paint()..color = PlateVisual.color(unit, perSide[i]);
      final top = cy - plateHeight / 2;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rightEdge + g, top, pw, plateHeight),
          const Radius.circular(6),
        ),
        paint,
      );
      rightEdge += pw + g;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(leftEdge - pw - g, top, pw, plateHeight),
          const Radius.circular(6),
        ),
        paint,
      );
      leftEdge -= pw + g;
    }

    // Collares al final de los discos.
    final clipPaint = Paint()..color = sleeveColor;
    final clipH = plateHeight * 0.35;
    for (final x in [leftEdge - _clipWidth / 2, rightEdge + _clipWidth / 2]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, cy), width: _clipWidth, height: clipH),
          const Radius.circular(1),
        ),
        clipPaint,
      );
    }
  }

  // En la v1 siempre devolvía true (redibujaba en cada frame del panel).
  @override
  bool shouldRepaint(_BarbellPainter old) =>
      !listEquals(old.perSide, perSide) ||
      old.unit != unit ||
      old.barColor != barColor ||
      old.sleeveColor != sleeveColor;
}

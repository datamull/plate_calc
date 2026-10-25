import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/weight_unit.dart';
import '../../utils/format.dart';
import 'plate_colors.dart';

/// Dibujo de MEDIA barra: solo un lado, porque ambos lados se cargan igual.
/// El centro de la barra queda a la izquierda y los discos se apilan hacia
/// afuera (el más pesado queda pegado al centro, como en un gimnasio).
class BarbellView extends StatelessWidget {
  const BarbellView({super.key, required this.perSide, required this.unit, this.height = 240});

  /// Discos de un lado, del más pesado al más liviano.
  final List<double> perSide;
  final WeightUnit unit;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _HalfBarbellPainter(perSide: perSide, unit: unit),
      ),
    );
  }
}

class _HalfBarbellPainter extends CustomPainter {
  _HalfBarbellPainter({required this.perSide, required this.unit});

  final List<double> perSide;
  final WeightUnit unit;

  // Medidas reales aproximadas, en milímetros.
  static const _plateDiameterMm = 450.0;
  static const _shaftMm = 28.0;
  static const _sleeveMm = 50.0;
  static const _collarMm = 52.0;
  static const _collarWidthMm = 14.0;
  static const _margin = 24.0;

  /// Grosor del disco en mm: los más pesados son más gruesos.
  static double _thicknessMm(WeightUnit unit, double w) {
    final lb = unit == WeightUnit.kg ? w * 2.2046 : w;
    return (10 + 1.05 * lb).clamp(8.0, 70.0);
  }

  /// Grosor en píxeles: proporcional al peso, con un mínimo para poder
  /// escribir el peso sobre el disco.
  static double _thicknessPx(WeightUnit unit, double w) {
    final mm = _thicknessMm(unit, w);
    return math.max(14.0, 16 + (mm - 20) * 0.5);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;

    // Escala de altura: el disco de 450 mm ocupa casi toda la altura.
    final ppm = size.height * 0.9 / _plateDiameterMm;
    final plateH = _plateDiameterMm * ppm;
    const x0 = _margin; // inicio de las mangas (el centro de la barra está en x = 0)

    var widths = [for (final w in perSide) _thicknessPx(unit, w)];
    final collarW = math.max(8.0, _collarWidthMm * ppm * 1.6);
    final avail = size.width - x0 - collarW - 6;
    final total = widths.fold<double>(0, (s, w) => s + w);
    if (total > avail && total > 0) {
      final k = avail / total;
      widths = [for (final w in widths) w * k];
    }
    final platesPx = widths.fold<double>(0, (s, w) => s + w);

    // Eje de la barra desde el centro (x = 0) hasta el borde derecho.
    final shaftH = _shaftMm * ppm;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, cy - shaftH / 2, size.width, shaftH),
        Radius.circular(shaftH / 2),
      ),
      _metal(cy, shaftH, const [Color(0xFF8E97A3), Color(0xFFE4E8ED), Color(0xFF6B7480)]),
    );

    // Marca del centro de la barra: el extremo derecho, donde termina la parte larga.
    final centerLine = Paint()
      ..color = const Color(0xFF8FB4F5).withValues(alpha: 0.8)
      ..strokeWidth = 1.2;
    final edge = size.width - 1.5;
    for (var y = 4.0; y < size.height - 4; y += 9) {
      canvas.drawLine(Offset(edge, y), Offset(edge, y + 4), centerLine);
    }
    final centerTxt = TextPainter(
      text: const TextSpan(
        text: 'CENTRO',
        style: TextStyle(
          color: Color(0xFF8FB4F5),
          fontSize: 9,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    centerTxt.paint(canvas, Offset(size.width - centerTxt.width - 6, 2));

    // Manga: parte de la barra donde van los discos y el collar (metal oscuro).
    final sleeveH = _sleeveMm * ppm;
    final sleeveEnd = x0 + platesPx + collarW + 4;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x0, cy - sleeveH / 2, sleeveEnd - x0, sleeveH),
        Radius.circular(sleeveH * 0.2),
      ),
      _metal(cy, sleeveH, const [Color(0xFF59616C), Color(0xFF9BA4AF), Color(0xFF3A4048)]),
    );

    // Discos: de adentro (pesados) hacia afuera.
    var x = x0;
    // Del más liviano (pegado al centro) al más pesado (pegado al collar).
    for (var i = perSide.length - 1; i >= 0; i--) {
      final tw = widths[i];
      final color = PlateVisual.color(unit, perSide[i]);
      final rect = Rect.fromLTWH(x, cy - plateH / 2, tw, plateH);
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(tw * 0.18));

      // Caucho: color base con sombra arriba y abajo para dar volumen.
      canvas.drawRRect(
        rrect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(color, Colors.black, 0.35)!,
              color,
              Color.lerp(color, Colors.white, 0.12)!,
              color,
              Color.lerp(color, Colors.black, 0.35)!,
            ],
            stops: const [0, 0.25, 0.5, 0.75, 1],
          ).createShader(rect),
      );

      // Brillo lateral.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + tw * 0.2, rect.top + plateH * 0.03, tw * 0.12, plateH * 0.94),
          Radius.circular(tw * 0.06),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.2),
      );

      // Peso impreso, leído de abajo hacia arriba.
      if (tw >= 13) {
        final tp = TextPainter(
          text: TextSpan(
            text: '${fmtWeight(perSide[i])} ${unit.label.toUpperCase()}',
            style: TextStyle(
              color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
              fontSize: math.min(13.0, tw * 0.6),
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: plateH * 0.9);
        canvas.save();
        canvas.translate(x + tw / 2, cy);
        canvas.rotate(-math.pi / 2);
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      }

      // Línea oscura entre discos.
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = Colors.black.withValues(alpha: 0.45),
      );
      x += tw;
    }

    // Collar: pieza de metal oscuro, al final de los discos.
    final collarH = _collarMm * ppm * 1.1;
    final collarRect = Rect.fromLTWH(x + 2, cy - collarH / 2, collarW, collarH);
    canvas.drawRRect(
      RRect.fromRectAndRadius(collarRect, const Radius.circular(3)),
      _metal(cy, collarH, const [Color(0xFF2C3238), Color(0xFF4A525C), Color(0xFF1B1F24)]),
    );
  }

  Paint _metal(double cy, double h, List<Color> colors) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
    ).createShader(Rect.fromCenter(center: Offset(0, cy), width: 1e4, height: h));

  @override
  bool shouldRepaint(_HalfBarbellPainter old) =>
      !listEquals(old.perSide, perSide) || old.unit != unit;
}

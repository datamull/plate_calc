import 'package:flutter/widgets.dart';

/// Ícono de disco de pesas, dibujado a mano para que combine con el trazo de
/// Phosphor: borde, aro interior y centro hueco. [filled] para la pestaña
/// elegida.
class PlateGlyph extends StatelessWidget {
  const PlateGlyph({super.key, required this.color, this.filled = false, this.size = 24});

  final Color color;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: _PlatePainter(color: color, filled: filled),
    ),
  );
}

class _PlatePainter extends CustomPainter {
  const _PlatePainter({required this.color, required this.filled});

  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final s = size.width / 24;
    if (filled) {
      final body = Path()
        ..fillType = PathFillType.evenOdd
        ..addOval(Rect.fromCircle(center: c, radius: 10.5 * s))
        ..addOval(Rect.fromCircle(center: c, radius: 2.6 * s));
      canvas.drawPath(body, Paint()..color = color);
      // Aro interior "grabado" en el disco.
      canvas.drawCircle(
        c,
        6.6 * s,
        Paint()
          ..blendMode = BlendMode.dstOut
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3 * s,
      );
    } else {
      final line = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * s;
      canvas
        ..drawCircle(c, 10 * s, line)
        ..drawCircle(c, 2.8 * s, line)
        ..drawCircle(c, 6.6 * s, line..color = color.withValues(alpha: 0.55));
    }
  }

  @override
  bool shouldRepaint(_PlatePainter old) => old.color != color || old.filled != filled;
}

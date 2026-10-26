import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Posición del levantamiento que se dibuja en el pictograma.
enum LiftPose { deadlift, clean, snatch, jerk, squat, bench, press, generic }

/// Elige el pictograma según el nombre del movimiento. Los 4 base vienen en
/// inglés; para los creados por el usuario se reconocen palabras clave en
/// inglés, español y francés. Si no hay coincidencia, se usa una barra.
LiftPose liftPoseFor(String name) {
  final n = _normalize(name);
  bool has(List<String> words) => words.any(n.contains);

  // "Clean and jerk" / "cargada y envión": se muestra el envión.
  if (has(['jerk', 'envion', 'jete', 'split'])) return LiftPose.jerk;
  if (has(['snatch', 'arranque', 'arrache', 'overhead squat', 'ohs'])) return LiftPose.snatch;
  if (has(['clean', 'cargada', 'epaule', 'front squat', 'sentadilla frontal'])) {
    return LiftPose.clean;
  }
  if (has(['deadlift', 'peso muerto', 'souleve', 'rdl', 'muerto'])) return LiftPose.deadlift;
  if (has(['bench', 'banca', 'couche', 'pecho'])) return LiftPose.bench;
  if (has(['squat', 'sentadilla', 'accroupi', 'flexion'])) return LiftPose.squat;
  if (has(['press', 'militar', 'thruster', 'push', 'developpe', 'hombro'])) {
    return LiftPose.press;
  }
  return LiftPose.generic;
}

String _normalize(String s) {
  const from = 'áàäâéèëêíìïîóòöôúùüûñç';
  const to = 'aaaaeeeeiiiioooouuuunc';
  final lower = s.toLowerCase();
  final buf = StringBuffer();
  for (final ch in lower.split('')) {
    final i = from.indexOf(ch);
    buf.write(i >= 0 ? to[i] : ch);
  }
  return buf.toString();
}

/// Pictograma del movimiento: una figura de perfil con la barra (vista de
/// frente al disco) en la posición característica del levantamiento.
class LiftIcon extends StatelessWidget {
  const LiftIcon({super.key, required this.liftName, this.size = 48, this.framed = true});

  final String liftName;
  final double size;

  /// Si es true, se dibuja dentro de un círculo con el degradado de la marca.
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pose = liftPoseFor(liftName);
    final icon = CustomPaint(
      size: Size.square(size),
      painter: _LiftPainter(pose: pose, figure: scheme.onSurface),
    );
    if (!framed) return icon;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.blue.withValues(alpha: 0.22),
            AppColors.purple.withValues(alpha: 0.22),
          ],
        ),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.35)),
      ),
      padding: EdgeInsets.all(size * 0.07),
      child: icon,
    );
  }
}

class _LiftPainter extends CustomPainter {
  _LiftPainter({required this.pose, required this.figure});

  final LiftPose pose;
  final Color figure;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 100;
    canvas.save();
    canvas.scale(s);

    final line = Paint()
      ..color = figure
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final head = Paint()..color = figure;
    final floor = Paint()
      ..color = figure.withValues(alpha: 0.35)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    void limb(List<Offset> pts) {
      final p = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final o in pts.skip(1)) {
        p.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(p, line);
    }

    void plate(Offset c, double r) {
      final rect = Rect.fromCircle(center: c, radius: r);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.blue, AppColors.purple],
          ).createShader(rect),
      );
      canvas.drawCircle(c, r * 0.28, Paint()..color = const Color(0xFFD9DEE7));
    }

    const o = Offset.new;

    switch (pose) {
      case LiftPose.deadlift:
        // Bisagra de cadera, barra en el suelo.
        canvas.drawLine(o(6, 94), o(94, 94), floor);
        plate(o(60, 75), 19);
        canvas.drawCircle(o(75, 33), 8.5, head);
        limb([o(66, 44), o(32, 52), o(52, 68), o(46, 92), o(58, 92)]);
        limb([o(66, 44), o(60, 75)]);
      case LiftPose.clean:
        // Recepción en rack frontal.
        canvas.drawLine(o(6, 94), o(94, 94), floor);
        plate(o(62, 32), 16);
        canvas.drawCircle(o(38, 15), 8.5, head);
        limb([o(42, 29), o(38, 58), o(58, 72), o(48, 92), o(60, 92)]);
        limb([o(42, 31), o(58, 46), o(62, 32)]);
      case LiftPose.snatch:
        // Sentadilla profunda con la barra arriba.
        canvas.drawLine(o(6, 94), o(94, 94), floor);
        plate(o(54, 17), 15);
        canvas.drawCircle(o(42, 42), 8.5, head);
        limb([o(50, 52), o(34, 72), o(64, 72), o(54, 92), o(66, 92)]);
        limb([o(50, 52), o(54, 17)]);
      case LiftPose.jerk:
        // Tijera: una pierna adelante y otra atrás, barra arriba.
        canvas.drawLine(o(6, 94), o(94, 94), floor);
        plate(o(52, 17), 14);
        canvas.drawCircle(o(41, 40), 8.5, head);
        limb([o(50, 50), o(50, 66)]);
        limb([o(50, 66), o(68, 76), o(70, 92), o(82, 92)]);
        limb([o(50, 66), o(34, 80), o(18, 92)]);
        limb([o(50, 50), o(52, 17)]);
      case LiftPose.squat:
        // Sentadilla trasera, barra sobre la espalda.
        canvas.drawLine(o(6, 94), o(94, 94), floor);
        plate(o(42, 36), 16);
        canvas.drawCircle(o(66, 30), 8.5, head);
        limb([o(56, 42), o(32, 64), o(60, 68), o(50, 92), o(62, 92)]);
        limb([o(56, 44), o(62, 56), o(44, 38)]);
      case LiftPose.bench:
        // Acostado en el banco empujando la barra.
        final bench = Paint()
          ..color = figure.withValues(alpha: 0.5)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(o(16, 78), o(88, 78), bench);
        canvas.drawLine(o(24, 78), o(24, 94), bench);
        canvas.drawLine(o(80, 78), o(80, 94), bench);
        plate(o(66, 22), 16);
        canvas.drawCircle(o(84, 64), 8.5, head);
        limb([o(72, 68), o(38, 68), o(24, 52), o(14, 92)]);
        limb([o(68, 68), o(66, 22)]);
      case LiftPose.press:
        // De pie, barra sobre la cabeza.
        canvas.drawLine(o(6, 94), o(94, 94), floor);
        plate(o(52, 17), 14);
        canvas.drawCircle(o(40, 40), 8.5, head);
        limb([o(50, 50), o(50, 72), o(50, 92), o(62, 92)]);
        limb([o(50, 50), o(52, 17)]);
      case LiftPose.generic:
        // Barra vista de frente.
        final bar = Paint()
          ..color = const Color(0xFFD9DEE7)
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(o(6, 50), o(94, 50), bar);
        for (final x in [20.0, 80.0]) {
          final r = RRect.fromRectAndRadius(
            Rect.fromCenter(center: o(x, 50), width: 12, height: 54),
            const Radius.circular(4),
          );
          canvas.drawRRect(
            r,
            Paint()
              ..shader = const LinearGradient(
                colors: [AppColors.blue, AppColors.purple],
              ).createShader(r.outerRect),
          );
        }
        for (final x in [30.0, 70.0]) {
          final r = RRect.fromRectAndRadius(
            Rect.fromCenter(center: o(x, 50), width: 8, height: 36),
            const Radius.circular(3),
          );
          canvas.drawRRect(r, Paint()..color = figure.withValues(alpha: 0.8));
        }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LiftPainter old) => old.pose != pose || old.figure != figure;
}

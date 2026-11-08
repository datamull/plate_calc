import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/lift_names.dart';
import '../../services/app_storage.dart';
import '../../services/training_store.dart';
import '../theme/app_theme.dart';
import 'lift_icon.dart';
import 'app_icons.dart';

/// Pictograma del ejercicio respetando el que eligió el usuario.
Widget liftIconFor(AppStorage storage, String lift, {double size = 40}) {
  final saved = storage.liftIcon(lift);
  final pose = LiftPose.values.where((p) => p.name == saved).firstOrNull;
  return LiftIcon(liftName: lift, pose: pose, size: size);
}

/// Elegir un ejercicio de la lista (Haltero + Gym) o escribir uno nuevo.
Future<String?> pickExercise(BuildContext context, TrainingStore store) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _ExercisePicker(store: store),
  );
}

class _ExercisePicker extends StatefulWidget {
  const _ExercisePicker({required this.store});

  final TrainingStore store;

  @override
  State<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<_ExercisePicker> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final q = _query.trim().toLowerCase();
    final all = widget.store.allLifts;
    final list = q.isEmpty ? all : all.where((l) => l.toLowerCase().contains(q)).toList();
    final exact = all.any((l) => l.toLowerCase() == q);

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _ctrl,
              autofocus: false,
              decoration: InputDecoration(
                prefixIcon: const Icon(AppIcons.search),
                hintText: loc.pickExerciseHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          if (q.isNotEmpty && !exact)
            ListTile(
              leading: const Icon(AppIcons.plus),
              title: Text(loc.pickExerciseNew(_query.trim())),
              onTap: () => Navigator.of(context).pop(_query.trim()),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, i) => ListTile(
                leading: liftIconFor(widget.store.storage, list[i], size: 36),
                title: Text(liftDisplayName(list[i])),
                onTap: () => Navigator.of(context).pop(list[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gráfico de línea simple (sin paquetes externos).
class SimpleLineChart extends StatelessWidget {
  const SimpleLineChart({
    super.key,
    required this.values,
    required this.labels,
    this.color = AppColors.blue,
    this.height = 180,
    this.format,
  });

  final List<double> values;

  /// Etiqueta de cada punto (se muestran la primera y la última).
  final List<String> labels;
  final Color color;
  final double height;
  final String Function(double)? format;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _LinePainter(
          values: values,
          labels: labels,
          color: color,
          grid: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          text: theme.colorScheme.onSurfaceVariant,
          format: format ?? (v) => v.round().toString(),
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.values,
    required this.labels,
    required this.color,
    required this.grid,
    required this.text,
    required this.format,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;
  final Color grid;
  final Color text;
  final String Function(double) format;

  TextPainter _tp(String s) => TextPainter(
    text: TextSpan(
      text: s,
      style: TextStyle(color: text, fontSize: 11),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    var lo = values.reduce(math.min);
    var hi = values.reduce(math.max);
    if (hi - lo < 1) {
      lo -= 1;
      hi += 1;
    }
    final pad = (hi - lo) * 0.1;
    lo -= pad;
    hi += pad;

    const left = 40.0, bottom = 20.0, top = 8.0, right = 8.0;
    final w = size.width - left - right;
    final h = size.height - top - bottom;
    double y(double v) => top + h - (v - lo) / (hi - lo) * h;
    double x(int i) => left + (values.length == 1 ? w / 2 : i * w / (values.length - 1));

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var k = 0; k <= 3; k++) {
      final v = lo + (hi - lo) * k / 3;
      final yy = y(v);
      canvas.drawLine(Offset(left, yy), Offset(size.width - right, yy), gridPaint);
      final tp = _tp(format(v));
      tp.paint(canvas, Offset(left - tp.width - 6, yy - tp.height / 2));
    }

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final p = Offset(x(i), y(values[i]));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    final fill = Path.from(path)
      ..lineTo(x(values.length - 1), top + h)
      ..lineTo(x(0), top + h)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, top, size.width, h)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    final dot = Paint()..color = color;
    for (var i = 0; i < values.length; i++) {
      canvas.drawCircle(Offset(x(i), y(values[i])), 3.5, dot);
    }

    if (labels.isNotEmpty) {
      final first = _tp(labels.first);
      first.paint(canvas, Offset(left, size.height - first.height));
      if (labels.length > 1) {
        final last = _tp(labels.last);
        last.paint(canvas, Offset(size.width - right - last.width, size.height - last.height));
      }
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.values != values || old.color != color;
}

/// Tarjeta con un número grande y una etiqueta.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label, this.icon});

  final String value;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            if (icon != null) Icon(icon, size: 20, color: theme.colorScheme.primary),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

String shortDate(DateTime d) {
  final l = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(l.day)}/${two(l.month)}';
}

String fmtDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  if (m >= 60) {
    return '${m ~/ 60}:${(m % 60).toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '$m:${s.toString().padLeft(2, '0')}';
}

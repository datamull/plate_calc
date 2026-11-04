import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Sistema visual de la parte de entrenamiento ("instrumento de
/// entrenamiento"): superficies planas separadas por líneas finas, un solo
/// acento (azul de la marca), verde solo para "hecho", números grandes con
/// cifras tabulares y una jerarquía tipográfica fija:
///
///   Display 34/800 · Título 20/700 · Cuerpo 16/400 · Etiqueta 12/600 MAYÚS
abstract final class Ds {
  static const gutter = 20.0;
  static const rowHeight = 56.0;
  static const done = Color(0xFF2FBF71);

  static Color hairline(BuildContext c) =>
      Theme.of(c).colorScheme.onSurface.withValues(alpha: 0.10);

  static Color muted(BuildContext c) => Theme.of(c).colorScheme.onSurfaceVariant;

  static const tabular = [FontFeature.tabularFigures()];

  static TextStyle display(BuildContext c) => TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    height: 1.05,
    letterSpacing: -0.5,
    color: Theme.of(c).colorScheme.onSurface,
    fontFeatures: tabular,
  );

  static TextStyle title(BuildContext c) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: Theme.of(c).colorScheme.onSurface,
  );

  static TextStyle body(BuildContext c) =>
      TextStyle(fontSize: 16, height: 1.35, color: Theme.of(c).colorScheme.onSurface);

  static TextStyle secondary(BuildContext c) =>
      TextStyle(fontSize: 14, height: 1.35, color: muted(c));

  static TextStyle label(BuildContext c) =>
      TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.1, color: muted(c));
}

/// Encabezado grande de pantalla, con etiqueta pequeña arriba (p. ej. la fecha).
class DsLargeHeader extends StatelessWidget {
  const DsLargeHeader({super.key, required this.title, this.eyebrow, this.trailing});

  final String title;
  final String? eyebrow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Ds.gutter, 12, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) Text(eyebrow!.toUpperCase(), style: Ds.label(context)),
                if (eyebrow != null) const SizedBox(height: 4),
                Text(title, style: Ds.display(context)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Título de sección: etiqueta en mayúsculas y acción opcional a la derecha.
class DsSection extends StatelessWidget {
  const DsSection(this.text, {super.key, this.help, this.action, this.onAction});

  final String text;
  final String? help;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Ds.gutter, 28, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(text.toUpperCase(), style: Ds.label(context))),
              if (action != null)
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: onAction,
                  child: Text(action!),
                ),
            ],
          ),
          if (help != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(help!, style: Ds.secondary(context)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Fila plana con línea fina abajo (reemplaza a las tarjetas).
class DsRow extends StatelessWidget {
  const DsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.divider = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: Ds.rowHeight),
        margin: const EdgeInsets.only(left: Ds.gutter),
        padding: const EdgeInsets.fromLTRB(0, 10, Ds.gutter, 10),
        decoration: BoxDecoration(
          border: divider ? Border(bottom: BorderSide(color: Ds.hairline(context))) : null,
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 14)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: Ds.body(context).copyWith(fontWeight: FontWeight.w600)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: Ds.secondary(context)),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              Icon(Icons.chevron_right, color: Ds.muted(context), size: 20),
          ],
        ),
      ),
    );
  }
}

/// Fila de números grandes separados por líneas verticales finas.
class DsStatStrip extends StatelessWidget {
  const DsStatStrip({super.key, required this.stats});

  final List<(String value, String label)> stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Ds.gutter),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              if (i > 0) VerticalDivider(width: 28, thickness: 1, color: Ds.hairline(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stats[i].$1, style: Ds.display(context)),
                    const SizedBox(height: 4),
                    Text(stats[i].$2, style: Ds.secondary(context)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Botón principal a lo ancho, con margen lateral estándar.
class DsPrimaryButton extends StatelessWidget {
  const DsPrimaryButton({super.key, required this.label, this.icon, required this.onPressed});

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Ds.gutter),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.blue,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        icon: Icon(icon ?? Icons.play_arrow_rounded),
        label: Text(label),
        onPressed: onPressed,
      ),
    );
  }
}

/// Bloque redondeado sobre el fondo (estilo "inset grouped" de iOS).
class DsBlock extends StatelessWidget {
  const DsBlock({super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final EdgeInsets padding;

  static Color color(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? const Color(0xFF171B23) : Colors.white;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: padding,
      decoration: BoxDecoration(color: color(context), borderRadius: BorderRadius.circular(24)),
      child: child,
    );
  }
}

/// Selector segmentado tipo píldora (Hoy · Historial · Progreso).
class DsSegmented extends StatelessWidget {
  const DsSegmented({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF171B23) : const Color(0xFFE4E7EE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selected
                        ? (dark ? const Color(0xFF2A303B) : Colors.white)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: i == selected && !dark
                        ? const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: i == selected ? FontWeight.w700 : FontWeight.w500,
                      color: i == selected
                          ? Theme.of(context).colorScheme.onSurface
                          : Ds.muted(context),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Etiqueta pequeña con fondo de color suave.
class DsPill extends StatelessWidget {
  const DsPill(this.text, {super.key, this.color = AppColors.blue});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

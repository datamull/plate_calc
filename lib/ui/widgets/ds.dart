import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'app_icons.dart';

/// Sistema visual de la parte de entrenamiento ("instrumento de
/// entrenamiento"): superficies planas separadas por líneas finas, un solo
/// acento (azul de la marca), verde solo para "hecho", números grandes con
/// cifras tabulares y una jerarquía tipográfica fija:
///
///   Display 34/800 · Título 20/700 · Cuerpo 16/400 · Etiqueta 12/600 MAYÚS
abstract final class Ds {
  static const gutter = 20.0;

  /// Radios: bloques, botones y chips.
  static const radiusBlock = 16.0;
  static const radiusButton = 12.0;
  static const radiusChip = 10.0;
  static const rowHeight = 56.0;
  static const done = Color(0xFF22C55E);

  static Color hairline(BuildContext c) =>
      Theme.of(c).colorScheme.onSurface.withValues(alpha: 0.10);

  static Color muted(BuildContext c) => Theme.of(c).colorScheme.onSurfaceVariant;

  static const tabular = [FontFeature.tabularFigures()];

  static TextStyle display(BuildContext c) => TextStyle(
    fontFamily: 'BarlowCondensed',
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: 0,
    color: Theme.of(c).colorScheme.onSurface,
    fontFeatures: tabular,
  );

  static TextStyle title(BuildContext c) => TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    color: Theme.of(c).colorScheme.onSurface,
  );

  static TextStyle body(BuildContext c) =>
      TextStyle(fontSize: 16, height: 1.35, color: Theme.of(c).colorScheme.onSurface);

  static TextStyle secondary(BuildContext c) =>
      TextStyle(fontSize: 14, height: 1.35, color: muted(c));

  static TextStyle label(BuildContext c) =>
      TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: 1.3, color: muted(c));
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
      splashFactory: NoSplash.splashFactory,
      highlightColor: Ds.hairline(context),
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
              Icon(AppIcons.chevron, color: Ds.muted(context).withValues(alpha: 0.6), size: 22),
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
      child: DsButton(label: label, icon: icon ?? AppIcons.play, onPressed: onPressed),
    );
  }
}

/// Tipo de botón: uno principal por pantalla, el resto secundarios o
/// fantasma.
enum DsButtonKind { primary, secondary, outline, ghost }

/// Botón de la app: se hunde un poco al tocarlo, vibra suave y no tiene
/// ondas ni sombras. 54 de alto (más que los 44 mínimos de Apple).
class DsButton extends StatelessWidget {
  const DsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.kind = DsButtonKind.primary,
    this.expand = true,
    this.height = 50,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final DsButtonKind kind;
  final bool expand;
  final double height;

  static Color secondaryFill(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? AppColors.surfaceHigh : const Color(0xFFE7E6E1);

  @override
  Widget build(BuildContext context) {
    final on = Theme.of(context).colorScheme.onSurface;
    final (bg, fg) = switch (kind) {
      DsButtonKind.primary => (
        Theme.of(context).brightness == Brightness.dark ? AppColors.chalk : const Color(0xFF111112),
        Theme.of(context).brightness == Brightness.dark ? AppColors.onAccent : AppColors.chalk,
      ),
      DsButtonKind.secondary => (secondaryFill(context), on),
      DsButtonKind.outline => (Colors.transparent, on),
      DsButtonKind.ghost => (Colors.transparent, Ds.muted(context)),
    };
    final style = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) && kind != DsButtonKind.ghost
            ? bg.withValues(alpha: 0.35)
            : bg,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? fg.withValues(alpha: 0.45) : fg,
      ),
      overlayColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.pressed) ? Colors.black.withValues(alpha: 0.10) : null,
      ),
      splashFactory: NoSplash.splashFactory,
      elevation: const WidgetStatePropertyAll(0),
      minimumSize: WidgetStatePropertyAll(Size(expand ? double.infinity : height, height)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 18)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Ds.radiusButton),
          side: kind == DsButtonKind.outline
              ? BorderSide(color: on.withValues(alpha: 0.16))
              : BorderSide.none,
        ),
      ),
      textStyle: WidgetStatePropertyAll(
        TextStyle(
          fontFamily: 'Barlow',
          fontSize: kind == DsButtonKind.ghost ? 15 : 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconSize: const WidgetStatePropertyAll(18),
    );
    final tap = onPressed == null
        ? null
        : () {
            HapticFeedback.selectionClick();
            onPressed!();
          };
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon), if (label.isNotEmpty) const SizedBox(width: 8)],
        if (label.isNotEmpty) Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
    final button = kind == DsButtonKind.ghost
        ? TextButton(style: style, onPressed: tap, child: child)
        : FilledButton(style: style, onPressed: tap, child: child);
    return DsPressable(enabled: onPressed != null, child: button);
  }
}

/// Se encoge un poco mientras se mantiene presionado (sin animación si el
/// usuario pidió reducir el movimiento). No captura el toque: solo escucha.
class DsPressable extends StatefulWidget {
  const DsPressable({super.key, required this.child, this.enabled = true, this.scale = 0.97});

  final Widget child;
  final bool enabled;
  final double scale;

  @override
  State<DsPressable> createState() => _DsPressableState();
}

class _DsPressableState extends State<DsPressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.enabled && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down && !still ? widget.scale : 1,
        duration: Duration(milliseconds: _down ? 90 : 160),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Píldora seleccionable (estilos, ejercicios, métricas).
class DsChip extends StatelessWidget {
  const DsChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = AppColors.blue,
    this.dot = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  /// Muestra un punto del color antes del texto.
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final on = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      child: DsPressable(
        scale: 0.96,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!selected) HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.surfaceHigh : Colors.transparent,
              borderRadius: BorderRadius.circular(Ds.radiusChip),
              border: Border.all(color: selected ? AppColors.steelLine : Ds.hairline(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dot) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: selected ? color : Ds.muted(context).withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? on : Ds.muted(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Aparece con un leve desplazamiento hacia arriba. [index] escalona la
/// entrada de las filas de una lista.
class DsFadeIn extends StatelessWidget {
  const DsFadeIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final delay = (index.clamp(0, 8)) * 0.06;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + (delay * 1000).round()),
      curve: Interval(delay / (0.36 + delay), 1, curve: Curves.easeOutCubic),
      builder: (_, t, c) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 12), child: c),
      ),
      child: child,
    );
  }
}

/// Bloque redondeado sobre el fondo (estilo "inset grouped" de iOS).
class DsBlock extends StatelessWidget {
  const DsBlock({super.key, required this.child, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final EdgeInsets padding;

  static Color color(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? AppColors.surface : Colors.white;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Mismo margen que el texto y los botones de la pantalla.
      margin: const EdgeInsets.symmetric(horizontal: Ds.gutter),
      padding: padding,
      decoration: BoxDecoration(
        color: color(context),
        borderRadius: BorderRadius.circular(Ds.radiusBlock),
      ),
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
    this.compact = false,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  /// Versión chica, sin margen lateral (para la barra superior).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final n = labels.length;
    return Container(
      margin: compact ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: Ds.gutter),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: dark ? AppColors.surface : const Color(0xFFE7E6E1),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Stack(
        children: [
          // Fondo del segmento elegido: se desliza.
          Positioned.fill(
            child: AnimatedAlign(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment(n == 1 ? 0 : -1 + 2 * selected / (n - 1), 0),
              child: FractionallySizedBox(
                widthFactor: 1 / n,
                child: Container(
                  decoration: BoxDecoration(
                    color: dark ? const Color(0xFF26262A) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < n; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == selected,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (i != selected) HapticFeedback.selectionClick();
                        onChanged(i);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: compact ? 30 : 36,
                        alignment: Alignment.center,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontFamily: 'Barlow',
                            fontSize: 14,
                            fontWeight: i == selected ? FontWeight.w700 : FontWeight.w500,
                            color: i == selected
                                ? Theme.of(context).colorScheme.onSurface
                                : Ds.muted(context),
                          ),
                          child: Text(labels[i], maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
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

/// Botón flotante redondo. [primary]: tiza con ícono negro (la acción
/// principal de la pantalla); si no, acero con borde fino. Sombra neutra,
/// sin brillos de color.
class DsFab extends StatelessWidget {
  const DsFab({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final size = primary ? 58.0 : 50.0;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: DsPressable(
          scale: 0.92,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onPressed();
            },
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: primary ? AppColors.chalk : AppColors.surfaceHigh,
                shape: BoxShape.circle,
                border: primary ? null : Border.all(color: AppColors.steelLine),
                boxShadow: const [
                  BoxShadow(color: Color(0x73000000), blurRadius: 20, offset: Offset(0, 8)),
                ],
              ),
              child: Icon(
                icon,
                size: primary ? 24 : 21,
                color: primary ? AppColors.onAccent : AppColors.chalk,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

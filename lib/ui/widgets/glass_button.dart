import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Botón de cristal estilo iOS: desenfoque de lo que hay detrás, brillo en el
/// borde superior, sombra con color y un leve "hundimiento" al tocarlo.
class GlassButton extends StatefulWidget {
  const GlassButton({
    super.key,
    required this.onPressed,
    this.child,
    this.icon,
    this.label,
    this.prominent = false,
    this.circular = false,
    this.tint = AppColors.blue,
  });

  final VoidCallback? onPressed;
  final Widget? child;
  final IconData? icon;
  final String? label;

  /// Botón principal: color de acento lleno. Si es false, es secundario (translúcido).
  final bool prominent;

  /// Botón redondo (p. ej. el botón de agregar).
  final bool circular;

  final Color tint;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = widget.onPressed != null;
    final radius = widget.circular ? 999.0 : 18.0;
    final height = widget.circular ? 60.0 : 52.0;

    final Color top;
    final Color bottom;
    final Color foreground;
    final Color border;
    if (widget.prominent) {
      top = widget.tint.withValues(alpha: 0.95);
      bottom = widget.tint.withValues(alpha: 0.7);
      foreground = Colors.white;
      border = Colors.white.withValues(alpha: 0.35);
    } else {
      final base = isDark ? Colors.white : Colors.black;
      top = base.withValues(alpha: isDark ? 0.14 : 0.08);
      bottom = base.withValues(alpha: isDark ? 0.05 : 0.02);
      foreground = isDark ? AppColors.white : const Color(0xFF0D1117);
      border = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.18);
    }

    final content =
        widget.child ??
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 20, color: foreground),
              if (widget.label != null) const SizedBox(width: 8),
            ],
            if (widget.label != null)
              Flexible(
                child: Text(
                  widget.label!,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    fontSize: 16,
                  ),
                ),
              ),
          ],
        );

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          onTap: widget.onPressed,
          child: Container(
            height: widget.circular ? height : null,
            width: widget.circular ? height : double.infinity,
            constraints: BoxConstraints(minHeight: height),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                if (widget.prominent)
                  BoxShadow(
                    color: widget.tint.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: widget.circular
                      ? EdgeInsets.zero
                      : const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: _pressed ? [bottom, bottom] : [top, bottom],
                    ),
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(color: border, width: 1),
                  ),
                  foregroundDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    // Brillo superior, como el cristal de iOS.
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [
                        Colors.white.withValues(alpha: _pressed ? 0.08 : 0.28),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

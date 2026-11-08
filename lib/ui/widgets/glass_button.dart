import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'ds.dart';

/// Botón de las pantallas de cálculo. Antes era de "cristal" con brillo y
/// sombra de color; ahora usa el mismo botón plano del resto de la app
/// ([DsButton]) para que todo se vea igual.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.onPressed,
    this.icon,
    this.label,
    this.prominent = false,
    this.circular = false,
    this.tint = AppColors.blue,
  });

  final VoidCallback? onPressed;
  final IconData? icon;
  final String? label;

  /// Botón principal (color de acento). Si es false, es secundario.
  final bool prominent;

  /// Botón redondo solo con ícono.
  final bool circular;

  final Color tint;

  @override
  Widget build(BuildContext context) {
    if (circular) {
      return DsPressable(
        child: Material(
          color: prominent ? tint : DsButton.secondaryFill(context),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            splashFactory: NoSplash.splashFactory,
            onTap: onPressed,
            child: SizedBox.square(
              dimension: 56,
              child: Icon(icon, color: prominent ? AppColors.onAccent : null),
            ),
          ),
        ),
      );
    }
    return DsButton(
      kind: prominent ? DsButtonKind.primary : DsButtonKind.secondary,
      icon: icon,
      label: label ?? '',
      onPressed: onPressed,
    );
  }
}

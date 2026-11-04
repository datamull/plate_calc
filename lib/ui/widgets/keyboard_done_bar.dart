import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Barra con botón "Listo" pegada encima del teclado.
///
/// El teclado numérico del iPhone no tiene tecla para cerrarse, así que sin
/// esto el usuario queda atrapado en la pantalla. Se pone una sola vez en
/// `MaterialApp.builder` y sirve para todos los campos de la app.
class KeyboardDoneBar extends StatelessWidget {
  const KeyboardDoneBar({super.key, required this.child});

  final Widget child;

  static const height = 44.0;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    if (inset <= 0) return child;
    final theme = Theme.of(context);
    return Stack(
      children: [
        // El contenido termina encima de la barra para que no la tape.
        MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(viewInsets: EdgeInsets.only(bottom: inset + height)),
          child: child,
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: inset,
          height: height,
          child: Material(
            color: theme.colorScheme.surfaceContainerHigh,
            elevation: 2,
            child: Row(
              children: [
                const Spacer(),
                TextButton(
                  key: const ValueKey('keyboard-done'),
                  onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: Text(
                    AppLocalizations.of(context).keyboardDone,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

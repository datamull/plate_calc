import 'package:flutter/widgets.dart';

/// Íconos de la app: Phosphor (licencia MIT), con sus fuentes en
/// assets/fonts. Un solo grosor de trazo (Bold, acorde al texto seminegrita)
/// y relleno solo para estados elegidos o hechos.
abstract final class AppIcons {
  // Calcular discos y entrenar.
  static const IconData plates = IconData(0xe538, fontFamily: 'PhosphorBold');
  static const IconData platesFill = IconData(0xe538, fontFamily: 'PhosphorFill');
  static const IconData train = IconData(0xe0b6, fontFamily: 'PhosphorBold');
  static const IconData trainFill = IconData(0xe0b6, fontFamily: 'PhosphorFill');

  // Acciones.
  static const IconData plus = IconData(0xe3d4, fontFamily: 'PhosphorBold');
  static const IconData minus = IconData(0xe32a, fontFamily: 'PhosphorBold');
  static const IconData trash = IconData(0xe4a6, fontFamily: 'PhosphorBold');
  static const IconData play = IconData(0xe3d0, fontFamily: 'PhosphorFill');
  static const IconData pause = IconData(0xe39e, fontFamily: 'PhosphorFill');
  static const IconData skip = IconData(0xe5a6, fontFamily: 'PhosphorFill');
  static const IconData camera = IconData(0xe10e, fontFamily: 'PhosphorBold');
  static const IconData gallery = IconData(0xe836, fontFamily: 'PhosphorBold');
  static const IconData history = IconData(0xe1a0, fontFamily: 'PhosphorBold');
  static const IconData restore = IconData(0xe038, fontFamily: 'PhosphorBold');
  static const IconData close = IconData(0xe4f6, fontFamily: 'PhosphorBold');
  static const IconData chevron = IconData(0xe13a, fontFamily: 'PhosphorBold');
  static const IconData check = IconData(0xe182, fontFamily: 'PhosphorBold');
  static const IconData checkCircle = IconData(0xe184, fontFamily: 'PhosphorFill');
  static const IconData circle = IconData(0xe18a, fontFamily: 'PhosphorBold');
  static const IconData save = IconData(0xe248, fontFamily: 'PhosphorBold');
  static const IconData saveFill = IconData(0xe248, fontFamily: 'PhosphorFill');
  static const IconData qr = IconData(0xe3e6, fontFamily: 'PhosphorBold');
  static const IconData scanQr = IconData(0xebb6, fontFamily: 'PhosphorBold');
  static const IconData more = IconData(0xe1fe, fontFamily: 'PhosphorBold');
  static const IconData sparkle = IconData(0xe6a2, fontFamily: 'PhosphorFill');
  static const IconData tune = IconData(0xe434, fontFamily: 'PhosphorBold');
  static const IconData timer = IconData(0xe492, fontFamily: 'PhosphorBold');
  static const IconData star = IconData(0xe46a, fontFamily: 'PhosphorFill');
  static const IconData shuffle = IconData(0xe422, fontFamily: 'PhosphorBold');
  static const IconData settings = IconData(0xe272, fontFamily: 'PhosphorBold');
  static const IconData settingsFill = IconData(0xe272, fontFamily: 'PhosphorFill');
  static const IconData send = IconData(0xe396, fontFamily: 'PhosphorFill');
  static const IconData search = IconData(0xe30c, fontFamily: 'PhosphorBold');
  static const IconData external = IconData(0xe092, fontFamily: 'PhosphorBold');
  static const IconData edit = IconData(0xe3b4, fontFamily: 'PhosphorBold');
  static const IconData copy = IconData(0xe1ca, fontFamily: 'PhosphorBold');
  static const IconData paste = IconData(0xe198, fontFamily: 'PhosphorBold');
  static const IconData cloudOff = IconData(0xe1b6, fontFamily: 'PhosphorBold');
  static const IconData cloudDone = IconData(0xe1b0, fontFamily: 'PhosphorBold');
  static const IconData whistle = IconData(0xe730, fontFamily: 'PhosphorBold');

  static const IconData pdf = IconData(0xe702, fontFamily: 'PhosphorBold');
  static const IconData refresh = IconData(0xe094, fontFamily: 'PhosphorBold');
  static const IconData rest = IconData(0xe330, fontFamily: 'PhosphorBold');

  // Progreso y resultados.
  static const IconData fire = IconData(0xe242, fontFamily: 'PhosphorFill');
  static const IconData bolt = IconData(0xe2de, fontFamily: 'PhosphorFill');
  static const IconData chart = IconData(0xe156, fontFamily: 'PhosphorBold');
  static const IconData trophy = IconData(0xe67e, fontFamily: 'PhosphorFill');
  static const IconData flag = IconData(0xe244, fontFamily: 'PhosphorBold');
  static const IconData flagFill = IconData(0xe244, fontFamily: 'PhosphorFill');
}

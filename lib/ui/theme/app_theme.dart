import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;

/// Identidad "Tiza y Hierro": base monocroma (hierro, acero, tiza) con los
/// colores del logo: azul de señal para lo activo y morado para Gym.
abstract final class AppColors {
  static const background = Color(0xFF0B0B0C); // hierro
  static const surface = Color(0xFF141415); // acero
  static const surfaceHigh = Color(0xFF1C1C1E); // acero elevado
  static const steelLine = Color(0xFF26262A);

  /// Color de señal: el azul del logo de Kilo.
  static const blue = Color(0xFF1893E2);
  static const onAccent = Color(0xFF0B0B0C);

  /// Tiza: texto principal y relleno del botón principal.
  static const white = Color(0xFFF2F0EB);
  static const chalk = white;
  static const muted = Color(0xFF8D8B86);

  /// Halterofilia (amarillo de disco de 15) y Gym (morado del logo).
  static const sky = Color(0xFFE9C46A);
  static const purple = Color(0xFF8A52E0);

  static const brandGradient = LinearGradient(
    colors: [blue, blue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      brightness: brightness,
      primary: AppColors.blue,
      secondary: AppColors.purple,
      surface: isDark ? AppColors.surface : const Color(0xFFF4F3EF),
      onPrimary: AppColors.onAccent,
      primaryContainer: isDark ? const Color(0xFF2A2A2E) : const Color(0xFFE7E6E1),
      onPrimaryContainer: isDark ? AppColors.chalk : const Color(0xFF111112),
      // Texto neutro: sin el tinte que deja la semilla naranja.
      onSurface: isDark ? AppColors.white : const Color(0xFF111214),
      onSurfaceVariant: isDark ? AppColors.muted : const Color(0xFF5B616B),
      surfaceContainerHighest: isDark ? AppColors.surfaceHigh : const Color(0xFFE7E7EA),
      outlineVariant: isDark ? AppColors.steelLine : const Color(0xFFDADBDF),
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Barlow',
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? AppColors.background : const Color(0xFFF4F3EF),
      // Transición de iOS (con gesto de volver deslizando) en todas las plataformas.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      splashFactory: NoSplash.splashFactory,
      tabBarTheme: TabBarThemeData(
        indicatorColor: isDark ? AppColors.chalk : const Color(0xFF111112),
        labelColor: isDark ? AppColors.chalk : const Color(0xFF111112),
        unselectedLabelColor: AppColors.muted,
        dividerColor: isDark ? AppColors.steelLine : const Color(0xFFDADBDF),
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(
          fontFamily: 'Barlow',
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Barlow',
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? (isDark ? AppColors.chalk : const Color(0xFF111112))
              : AppColors.muted,
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.blue : null,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.background : const Color(0xFFF4F3EF),
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Barlow',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.chalk : const Color(0xFF111112),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.blue,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? AppColors.white : const Color(0xFF0D1117),
          backgroundColor: isDark ? const Color(0xFF222936) : const Color(0xFFE6E9F0),
          side: BorderSide.none,
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? const Color(0xFF16181C) : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        dragHandleColor: isDark ? const Color(0xFF3A3A3E) : const Color(0xFFCFCEC9),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.surface : Colors.white,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: isDark ? AppColors.steelLine : const Color(0xFFDADBDF)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? AppColors.chalk : const Color(0xFF111112),
          foregroundColor: isDark ? AppColors.onAccent : AppColors.chalk,
          minimumSize: const Size.fromHeight(50),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.blue,
        foregroundColor: AppColors.onAccent,
        elevation: 0,
        shape: StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceHigh : Colors.white,
        // Etiqueta dentro del campo (no montada sobre el borde).
        border: const _FillBorder(),
        enabledBorder: const _FillBorder(),
        focusedBorder: _FillBorder(
          side: BorderSide(
            color: isDark ? AppColors.chalk.withValues(alpha: 0.7) : const Color(0xFF111112),
            width: 1.2,
          ),
        ),
        errorBorder: const _FillBorder(side: BorderSide(color: Color(0xFFFF453A))),
        focusedErrorBorder: const _FillBorder(
          side: BorderSide(color: Color(0xFFFF453A), width: 1.2),
        ),
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        labelStyle: const TextStyle(color: AppColors.muted, fontSize: 15),
        floatingLabelStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
        hintStyle: const TextStyle(color: AppColors.muted),
        suffixStyle: const TextStyle(color: AppColors.muted),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.blue : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.onAccent : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

/// Borde de campo relleno con esquinas redondeadas que deja la etiqueta
/// flotante dentro del campo (isOutline = false).
class _FillBorder extends InputBorder {
  const _FillBorder({BorderSide side = BorderSide.none}) : super(borderSide: side);

  static const _radius = BorderRadius.all(Radius.circular(12));

  @override
  bool get isOutline => false;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  _FillBorder copyWith({BorderSide? borderSide}) =>
      _FillBorder(side: borderSide ?? this.borderSide);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_radius.toRRect(rect));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_radius.toRRect(rect));

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    if (borderSide.style == BorderStyle.none) return;
    canvas.drawRRect(_radius.toRRect(rect).deflate(borderSide.width / 2), borderSide.toPaint());
  }

  @override
  ShapeBorder scale(double t) => _FillBorder(side: borderSide.scale(t));
}

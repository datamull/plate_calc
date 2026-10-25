/// Cómo se interpreta el RM al calcular un porcentaje.
enum TargetMode {
  /// El RM es el peso total (barra incluida).
  totalInclBar,

  /// El RM es el peso de discos por lado (sin barra).
  perSideWithoutBar;

  static TargetMode parse(String? raw) =>
      values.firstWhere((m) => m.name == raw, orElse: () => TargetMode.perSideWithoutBar);

  /// Devuelve (total, porLado) para un RM y una fracción (0.8 = 80 %).
  ({double total, double perSide}) targets({
    required double rm,
    required double fraction,
    required double bar,
    required double collars,
  }) {
    if (this == totalInclBar) {
      final total = rm * fraction;
      final perSide = ((total - bar - collars) / 2).clamp(0.0, double.infinity);
      return (total: total, perSide: perSide);
    }
    final perSide = rm * fraction;
    return (total: bar + collars + 2 * perSide, perSide: perSide);
  }
}

const double kgPerLb = 0.45359237;
const double lbPerKg = 2.20462262;

/// Unidad de peso. El `name` ('kg' / 'lb') se usa como clave de almacenamiento
/// para mantener compatibilidad con los datos guardados por la versión 1.x.
enum WeightUnit {
  kg,
  lb;

  String get label => name;

  /// Barras olímpicas disponibles para esta unidad (masculina, femenina).
  List<double> get barOptions => this == kg ? const [20, 15] : const [45, 33];

  double get defaultBar => barOptions.first;

  WeightUnit get other => this == kg ? lb : kg;

  /// Convierte [value] de esta unidad a [to], sin redondear.
  double convert(double value, WeightUnit to) {
    if (to == this) return value;
    return this == lb ? value * kgPerLb : value * lbPerKg;
  }

  /// Paso de redondeo al mostrar un peso convertido: 0.5 kg o 1 lb.
  double get roundingStep => this == kg ? 0.5 : 1;

  /// Redondea [value] al paso más cercano de esta unidad.
  double round(double value) => (value / roundingStep).round() * roundingStep;

  static WeightUnit parse(String? raw, {WeightUnit fallback = WeightUnit.kg}) {
    for (final u in values) {
      if (u.name == raw) return u;
    }
    return fallback;
  }
}

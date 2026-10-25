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

  static WeightUnit parse(String? raw, {WeightUnit fallback = WeightUnit.kg}) {
    for (final u in values) {
      if (u.name == raw) return u;
    }
    return fallback;
  }
}

/// Formatea un peso sin ceros sobrantes: 100 -> "100", 2.5 -> "2.5",
/// 1.25 -> "1.25".
///
/// Reemplaza el `toString().replaceAll('.0', '')` de la v1, que mostraba
/// mal valores como 1.05 ("15") o 100.05 ("10005").
String fmtWeight(double v, {int maxDecimals = 2}) {
  var s = v.toStringAsFixed(maxDecimals);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  }
  return s == '-0' ? '0' : s;
}

/// Lee un número escrito por el usuario aceptando coma o punto decimal.
double? parseNumber(String raw) =>
    double.tryParse(raw.trim().replaceAll('%', '').replaceAll(',', '.'));

String fmtDateTime(DateTime dt) {
  final d = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year}  ${two(d.hour)}:${two(d.minute)}';
}

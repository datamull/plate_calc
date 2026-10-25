/// Un tipo de disco del inventario: su peso y cuántas unidades hay en total.
class Plate {
  final double weight;
  final int count;

  const Plate({required this.weight, required this.count});

  Plate copyWith({double? weight, int? count}) =>
      Plate(weight: weight ?? this.weight, count: count ?? this.count);

  Map<String, dynamic> toJson() => {'weight': weight, 'count': count};

  /// Devuelve null si la entrada es inválida (en vez de lanzar una excepción).
  static Plate? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final w = json['weight'];
    final c = json['count'];
    if (w is! num || c is! num || w <= 0 || c < 0) return null;
    return Plate(weight: w.toDouble(), count: c.toInt());
  }

  @override
  bool operator ==(Object other) =>
      other is Plate && other.weight == weight && other.count == count;

  @override
  int get hashCode => Object.hash(weight, count);
}

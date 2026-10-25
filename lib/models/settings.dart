import 'plate.dart';
import 'weight_unit.dart';

/// Equipamiento para una unidad: barra, collares e inventario de discos.
class Settings {
  final WeightUnit unit;
  final double barWeight;
  final double collarsWeight;
  final List<Plate> plates;

  Settings({
    required this.unit,
    required this.barWeight,
    required this.collarsWeight,
    required List<Plate> plates,
  }) : plates = List<Plate>.unmodifiable(
         <Plate>[...plates]..sort((a, b) => b.weight.compareTo(a.weight)),
       );

  Settings copyWith({double? barWeight, double? collarsWeight, List<Plate>? plates}) => Settings(
    unit: unit,
    barWeight: barWeight ?? this.barWeight,
    collarsWeight: collarsWeight ?? this.collarsWeight,
    plates: plates ?? this.plates,
  );

  Map<String, dynamic> toJson() => {
    'bar': barWeight,
    'collars': collarsWeight,
    'plates': plates.map((p) => p.toJson()).toList(),
  };

  /// Lee tanto el formato v1 (lista de discos o `{plates: [...]}`) como el v2
  /// (`{bar, collars, plates}`). Ante datos corruptos devuelve [fallback].
  static Settings fromJson(Object? json, Settings fallback) {
    List<Object?>? rawPlates;
    double? bar;
    double? collars;

    if (json is List) {
      rawPlates = json;
    } else if (json is Map) {
      if (json['plates'] is List) rawPlates = json['plates'] as List;
      if (json['bar'] is num) bar = (json['bar'] as num).toDouble();
      if (json['collars'] is num) collars = (json['collars'] as num).toDouble();
    }

    final plates = rawPlates?.map(Plate.tryFromJson).whereType<Plate>().toList();

    return fallback.copyWith(
      barWeight: (bar != null && bar >= 0) ? bar : null,
      collarsWeight: (collars != null && collars >= 0) ? collars : null,
      plates: (plates != null && plates.isNotEmpty) ? plates : null,
    );
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:plate_calc/data/daily_library.dart';
import 'package:plate_calc/models/weight_unit.dart';
import 'package:plate_calc/services/board_ai.dart';

void main() {
  test('sin dirección configurada, la IA está apagada (usa el lector local)', () {
    expect(BoardAi.enabled, isFalse);
  });

  test('respuesta de Gemini → WOD de la app (tu pizarra)', () {
    final w = BoardAi.fromJson({
      'name': null,
      'format': 'amrap',
      'minutes': 32,
      'rounds': null,
      'items': [
        {'reps': '100', 'movement': 'Wall Ball', 'rx': '20/14 lb', 'percent': null},
        {'reps': '90', 'movement': 'Double Under'},
        {'reps': '80 cal', 'movement': 'Row'},
        {'reps': '70', 'movement': 'Dumbbell Snatch', 'rx': '50/35 lb'},
        {'reps': '60 cal', 'movement': 'Echo Bike'},
        {'reps': '10', 'movement': 'Bar Muscle-Up'},
      ],
    }, fallbackName: 'WOD')!;
    expect(w.format, WodFormat.amrap);
    expect(w.minutes, 32);
    expect(w.name, 'AMRAP 32′');
    expect(w.items.map((i) => i.lift), [
      'Wall Ball',
      'Double Under',
      'Row',
      'Dumbbell Snatch',
      'Bike',
      'Bar Muscle-Up',
    ]);
    // El Rx se muestra con la unidad de la pizarra aunque el usuario use kg.
    expect(w.items.first.rx(WeightUnit.kg), '20/14 lb');
  });

  test('fuerza 5x5 con % queda como series para registrar', () {
    final w = BoardAi.fromJson({
      'format': 'sets',
      'items': [
        {'reps': '5x5', 'movement': 'Back Squat', 'percent': 75},
      ],
    }, fallbackName: 'WOD')!;
    expect(w.format, WodFormat.sets);
    final i = w.items.single;
    expect((i.sets, i.repsPerSet, i.percent), (5, 5, 75.0));
  });

  test('respuesta rota → null', () {
    expect(BoardAi.fromJson({'format': 'amrap'}, fallbackName: 'WOD'), isNull);
  });
}

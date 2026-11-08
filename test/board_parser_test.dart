import 'package:flutter_test/flutter_test.dart';
import 'package:plate_calc/data/daily_library.dart';
import 'package:plate_calc/services/board_parser.dart';

DailyWorkout p(String t) => BoardParser.parse(t, fallbackName: 'Pizarra');

void main() {
  test('For Time clásico con 21-15-9 y Rx', () {
    final w = p('FRAN\nFor Time\n21-15-9\nThrusters 95/65 lb\nPull ups');
    expect(w.name, 'Fran');
    expect(w.format, WodFormat.forTime);
    expect(w.items.map((i) => i.lift), ['Thruster', 'Pull-Up']);
    expect(w.items.first.rxLb, '95/65');
  });

  test('AMRAP con reps al inicio y abreviaturas', () {
    final w = p('AMRAP 12 min\n10 T2B\n15 KBS 24/16 kg\n50 DU\n200 m run');
    expect(w.format, WodFormat.amrap);
    expect(w.minutes, 12);
    expect(w.items.map((i) => i.lift), ['Toes-to-Bar', 'Kettlebell Swing', 'Double Under', 'Run']);
    expect(w.items.map((i) => i.reps), ['10', '15', '50', '200 m']);
    expect(w.items[1].rxKg, '24/16');
  });

  test('rondas, time cap, español y errores de lectura', () {
    final w = p('5 rondas por tiempo\nTC: 20\n12 burpess\n15 sentadillas\n400m correr');
    expect(w.rounds, 5);
    expect(w.minutes, 20);
    expect(w.items.map((i) => i.lift), ['Burpee', 'Air Squat', 'Run']);
  });

  test('EMOM y reps al final', () {
    final w = p('EMOM 10\nPower clean x 3 @70%\nBurpees x 8');
    expect(w.format, WodFormat.emom);
    expect(w.minutes, 10);
    expect(w.items.first.lift, 'Power Clean');
    expect(w.items.first.percent, 70);
    expect(w.items.first.rmLift, 'Clean');
    expect(w.items.last.reps, '8');
  });

  test('fuerza: series × reps se registra por series', () {
    final w = p('Strength\n5x5 Back Squat @ 75%');
    expect(w.format, WodFormat.sets);
    expect(w.items.single.lift, 'Back Squat');
    expect(w.items.single.sets, 5);
    expect(w.items.single.repsPerSet, 5);
    expect(w.items.single.percent, 75);
  });

  test('movimiento desconocido con reps se conserva tal cual', () {
    final w = p('For time\n30 GHD situps\n20 Sandbag cleans');
    expect(w.items.length, 2);
    expect(w.items.last.lift, 'Sandbag Cleans');
  });

  group('pizarra escrita a mano (foto real de un box)', () {
    const expected = [
      ('100', 'Wall Ball'),
      ('90', 'Double Under'),
      ('80 cal', 'Row'),
      ('70', 'Dumbbell Snatch'),
      ('60 cal', 'Bike'),
      ('50', 'Burpee'),
      ('40', 'Pull-Up'),
      ('30', 'Dumbbell Lunge'),
      ('20', 'Push-Up'),
      ('10', 'Bar Muscle-Up'),
    ];
    final variants = {
      'lectura limpia con logos':
          "AMRAP32:\nCLUB\nL'EPAULE\n-100 VVB\n90 DU\n80 calrow\n70 dbsnatch\n60 cal echo\n"
          '50 burpees\n40 pull-ups\n30 db lunges\n20 posh-ups\n10 BNU\nCROSSFIT\n25 COMPETITION LB',
      'letras por números y líneas juntas':
          'ANRAP 3Z:\n+00 WB 90 Du\n8O cal row\n7O dlb snatch\n6O cal echo\nS0 burpees\n'
          '4O pull-ops\n3O db lunges\n2O push-ups\nlO BMU',
    };
    for (final v in variants.entries) {
      test(v.key, () {
        final w = BoardParser.parse(v.value, fallbackName: 'WOD');
        expect(w.format, WodFormat.amrap);
        expect(w.minutes, 32);
        expect([for (final i in w.items) (i.reps, i.lift)], expected);
      });
    }
  });
}

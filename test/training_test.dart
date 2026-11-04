import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_calc/main.dart';
import 'package:plate_calc/models/training.dart';
import 'package:plate_calc/models/weight_unit.dart';
import 'package:plate_calc/services/app_storage.dart';
import 'package:plate_calc/services/training_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<TrainingStore> makeStore([Map<String, Object> prefs = const {}]) async {
  SharedPreferences.setMockInitialValues(prefs);
  return TrainingStore(await AppStorage.load());
}

Workout workoutWith(String lift, List<(double, int)> sets, {DateTime? date}) => Workout(
  id: newId(),
  date: date ?? DateTime.now(),
  unit: WeightUnit.kg,
  exercises: [
    ExerciseLog(
      lift: lift,
      sets: [for (final (w, r) in sets) WorkSet(weight: w, reps: r, done: true)],
    ),
  ],
);

void main() {
  test('RM estimado (Epley) y redondeo de cargas', () {
    expect(estimate1Rm(100, 1), 100);
    expect(estimate1Rm(100, 5), closeTo(116.67, 0.01));
    expect(estimate1Rm(100, 20), estimate1Rm(100, 12)); // limitado a 12
    expect(estimate1Rm(0, 5), 0);
    expect(roundLoad(72.4, WeightUnit.kg), 72);
    expect(roundLoad(137, WeightUnit.lb), 135);
  });

  test('empezar un día del plan calcula los pesos con el RM y agrupa series', () async {
    final store = await makeStore({'rm_Snatch_kg': 100.0});
    final plan = Plan(
      id: 'p1',
      name: 'Ciclo',
      days: [
        PlanDay(
          name: 'Día 1',
          items: [
            PlanItem(lift: 'Snatch', sets: 2, reps: 2, percent: 70),
            PlanItem(lift: 'Snatch', sets: 1, reps: 1, percent: 85),
            PlanItem(lift: 'Back Squat', sets: 3, reps: 5, percent: 80), // sin RM
            PlanItem(lift: 'Pull-Up', sets: 3, reps: 8),
          ],
        ),
      ],
    );
    final w = store.startFromPlan(plan, 0, WeightUnit.kg);
    expect(w.exercises.map((e) => e.lift), ['Snatch', 'Back Squat', 'Pull-Up']);
    expect(w.exercises[0].sets.map((s) => s.weight), [70, 70, 85]);
    expect(w.exercises[1].sets.first.weight, 0);
    expect(w.planId, 'p1');
    expect(w.dayIndex, 0);
  });

  test('terminar: guarda, detecta récords y sube el RM con un single más pesado', () async {
    final store = await makeStore({'rm_Clean_kg': 100.0});
    await store.finish(workoutWith('Clean', [(90, 3)], date: DateTime(2026, 10, 1)));

    final prs = await store.finish(workoutWith('Clean', [(95, 2), (105, 1)]));
    expect(prs.single.kind, RecordKind.heaviest);
    expect(prs.single.value, 105);
    expect(store.storage.lastRm('Clean', WeightUnit.kg), 105);
    expect(store.workouts.length, 2);
    expect(store.draft, isNull);
  });

  test('la primera vez no cuenta como récord', () async {
    final store = await makeStore();
    expect(await store.finish(workoutWith('Jerk', [(80, 2)])), isEmpty);
  });

  test('racha de semanas', () {
    final now = DateTime(2026, 11, 4); // miércoles
    final ws = [
      workoutWith('Snatch', [(50, 1)], date: DateTime(2026, 10, 27)), // semana anterior
      workoutWith('Snatch', [(50, 1)], date: DateTime(2026, 10, 21)), // 2 semanas antes
      workoutWith('Snatch', [(50, 1)], date: DateTime(2026, 10, 1)), // corta la racha
    ];
    expect(weekStreak(ws, now: now), 2);
    ws.add(workoutWith('Snatch', [(50, 1)], date: DateTime(2026, 11, 3)));
    expect(weekStreak(ws, now: now), 3);
  });

  test('códigos: plan y resultado van y vuelven, y un código malo se rechaza', () {
    final plan = Plan(
      id: 'x',
      name: 'WOD lunes',
      coach: 'Ana',
      box: 'Box Québec',
      days: [
        PlanDay(
          name: 'A',
          items: [PlanItem(lift: 'Snatch', sets: 5, reps: 2, percent: 75)],
        ),
      ],
    );
    final code = ShareCode.encodePlan(plan);
    expect(code, startsWith(ShareCode.planPrefix));
    // Se acepta aunque venga con espacios o saltos de línea (WhatsApp).
    final back = ShareCode.decodePlan('Hola! ${code.substring(0, 20)}\n${code.substring(20)}');
    expect(back!.name, 'WOD lunes');
    expect(back.coach, 'Ana');
    expect(back.id, isNot('x'));
    expect(back.days.single.items.single.percent, 75);

    final w = workoutWith('Snatch', [(80, 2)]);
    final r = ShareCode.decodeResult(ShareCode.encodeResult('Seba', w))!;
    expect(r.athlete, 'Seba');
    expect(r.workout.exercises.single.sets.single.weight, 80);

    expect(ShareCode.decodePlan('PCPLAN1.basura'), isNull);
    expect(ShareCode.decodeResult(code), isNull);
  });

  test('el coach no duplica un resultado ya recibido', () async {
    final store = await makeStore();
    final r = AthleteResult(
      athlete: 'Seba',
      workout: workoutWith('Snatch', [(80, 2)]),
      received: DateTime.now(),
    );
    expect(await store.addResult(r), isTrue);
    expect(await store.addResult(r), isFalse);
    expect(store.athletes, ['Seba']);
  });

  testWidgets('registrar un entrenamiento libre y verlo en Progreso', (tester) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'es', 'lifts_units': 'kg'});
    final storage = await AppStorage.load();
    await tester.pumpWidget(PlateCalcApp(storage: storage));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrenar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Empezar entrenamiento'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Agregar ejercicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Snatch'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '60'); // peso
    await tester.enterText(fields.at(1), '3'); // reps
    await tester.tap(find.byTooltip('Serie hecha'));
    await tester.pump();
    expect(find.textContaining('Descanso'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Terminar entrenamiento'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Terminar entrenamiento'));
    await tester.pumpAndSettle();
    expect(find.text('Entrenamiento guardado 💪'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.textContaining('1 serie'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('1 serie'), findsOneWidget);

    await tester.tap(find.text('Progreso'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Máx. 60 kg · RMe 66 kg'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Máx. 60 kg · RMe 66 kg'), findsOneWidget);
  });

  testWidgets('programa por porcentaje muestra los pesos con el RM', (tester) async {
    SharedPreferences.setMockInitialValues({
      'app_locale': 'es',
      'lifts_units': 'kg',
      'rm_Snatch_kg': 100.0,
    });
    final storage = await AppStorage.load();
    await tester.pumpWidget(PlateCalcApp(storage: storage));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrenar'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Halterofilia · 4 semanas'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Halterofilia · 4 semanas'));
    await tester.pumpAndSettle();

    expect(find.text('Empezar: Semana 1 · Día A'), findsOneWidget);
    expect(find.text('• Snatch 5×2 · 70% (70 kg)'), findsOneWidget);
    expect(find.text('• Back Squat 5×3 · 75% (sin RM guardado)'), findsOneWidget);
  });

  testWidgets('pestaña Coach abre y explica cómo funciona', (tester) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'es'});
    final storage = await AppStorage.load();
    await tester.pumpWidget(PlateCalcApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coach'));
    await tester.pumpAndSettle();
    expect(find.text('Configura tu perfil de coach'), findsOneWidget);
    expect(find.text('Crear plan o WOD'), findsOneWidget);
  });
}

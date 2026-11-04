import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_calc/data/daily_library.dart';
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

  test('entrenamiento del día: rota por fecha y es igual para todos ese día', () {
    final d1 = dailyFor(TrainingStyle.crossfit, DateTime(2026, 11, 4, 8));
    final d1b = dailyFor(TrainingStyle.crossfit, DateTime(2026, 11, 4, 22));
    final d2 = dailyFor(TrainingStyle.crossfit, DateTime(2026, 11, 5));
    expect(d1.id, d1b.id);
    expect(d1.id, isNot(d2.id));
    // Cubre todo el año sin errores y con fechas antes del inicio.
    for (var i = -30; i < 400; i++) {
      for (final s in TrainingStyle.values) {
        dailyFor(s, DateTime(2026, 1, 1).add(Duration(days: i)));
      }
    }
  });

  test('pesos del día salen del RM del movimiento base', () async {
    final store = await makeStore({'rm_Front Squat_kg': 100.0, 'rm_Snatch_kg': 80.0});
    const thruster = DailyItem('Thruster', reps: '21-15-9', percent: 45, rmOf: 'Front Squat');
    expect(store.dailyWeight(thruster, WeightUnit.kg), 45);
    expect(store.dailyWeight(const DailyItem('Pull-Up', reps: '21'), WeightUnit.kg), isNull);

    final hs = halteroLibrary.first;
    final w = store.startDaily(hs, WeightUnit.kg);
    expect(w.style, 'haltero');
    expect(w.exercises.first.lift, 'Snatch');
    expect(w.exercises.first.sets.length, 5);
    expect(w.exercises.first.sets.first.weight, 56); // 70% de 80
    expect(w.exercises.first.sets.first.reps, 2);

    // "5-5-3-3-1-1" se convierte en 6 series.
    final levis = crossfitLibrary.firstWhere((d) => d.id == 'cf_levis');
    final lw = store.startDaily(levis, WeightUnit.kg);
    expect(lw.exercises.first.sets.map((s) => s.reps), [5, 5, 3, 3, 1, 1]);
  });

  test('guardar resultado de WOD marca el día como hecho', () async {
    final store = await makeStore();
    final wod = dailyFor(TrainingStyle.crossfit, DateTime.now());
    expect(store.dailyDone(wod, DateTime.now()), isNull);
    await store.saveWodResult(wod, WeightUnit.kg, score: '12:45');
    expect(store.dailyDone(wod, DateTime.now())!.score, '12:45');
  });

  testWidgets('abre en la calculadora; Entrenar pide estilos y muestra el día', (tester) async {
    SharedPreferences.setMockInitialValues({
      'app_locale': 'es',
      'lifts_units': 'kg',
      'rm_Snatch_kg': 100.0,
    });
    final storage = await AppStorage.load();
    await tester.pumpWidget(PlateCalcApp(storage: storage));
    await tester.pumpAndSettle();

    // Lo central es la calculadora.
    expect(find.text('Haltero'), findsOneWidget);

    await tester.tap(find.text('Entrenar'));
    await tester.pumpAndSettle();
    expect(find.text('Un entrenamiento cada día'), findsOneWidget);

    await tester.tap(find.text('Elegir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Halterofilia'));
    await tester.pump();
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();

    final hs = dailyFor(TrainingStyle.haltero, DateTime.now());
    expect(find.text(hs.name), findsOneWidget);
    final snatch = hs.items.where((i) => i.lift == 'Snatch').firstOrNull;
    if (snatch != null) {
      final kg = (100 * snatch.percent! / 100).round();
      expect(find.text('$kg kg'), findsWidgets);
    }

    // Empezar → registrar una serie → terminar → queda "Hecho".
    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Serie hecha').first);
    await tester.pump();
    await tester.tap(find.text('Terminar').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Hecho'), findsOneWidget);

    // Historial y Progreso lo muestran.
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    expect(find.text(hs.name), findsOneWidget);
    await tester.tap(find.text('Progreso'));
    await tester.pumpAndSettle();
    expect(find.text('semanas seguidas'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Récords personales'.toUpperCase()),
      200,
      scrollable: find
          .byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down)
          .last,
    );
    expect(find.text('Récords personales'.toUpperCase()), findsOneWidget);
  });

  testWidgets('WOD con reloj: terminar y anotar el resultado', (tester) async {
    SharedPreferences.setMockInitialValues({
      'app_locale': 'es',
      'lifts_units': 'kg',
      'training_styles': '["crossfit"]',
    });
    final storage = await AppStorage.load();
    await tester.pumpWidget(PlateCalcApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrenar'));
    await tester.pumpAndSettle();

    final wod = dailyFor(TrainingStyle.crossfit, DateTime.now());
    expect(find.text(wod.name), findsOneWidget);
    expect(find.text('WOD oficial de CrossFit.com'), findsOneWidget);
    if (wod.format == WodFormat.sets) return; // día de cargas: se registra por series

    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminar'));
    await tester.pumpAndSettle();
    final field = find.byType(TextField).first;
    await tester.enterText(field, '7');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hecho ·'), findsOneWidget);
  });

  testWidgets('el teclado numérico se cierra con "Listo"', (tester) async {
    SharedPreferences.setMockInitialValues({'app_locale': 'es', 'lifts_units': 'kg'});
    final storage = await AppStorage.load();
    await tester.pumpWidget(PlateCalcApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Haltero'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Snatch'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField).first);
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('keyboard-done')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('keyboard-done')));
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus?.context?.widget is EditableText, isFalse);
  });
}

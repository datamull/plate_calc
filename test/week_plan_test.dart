import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_calc/data/daily_library.dart';
import 'package:plate_calc/l10n/app_localizations.dart';
import 'package:plate_calc/models/weight_unit.dart';
import 'package:plate_calc/models/week_plan.dart';
import 'package:plate_calc/services/app_storage.dart';
import 'package:plate_calc/services/training_store.dart';
import 'package:plate_calc/ui/screens/plan_view.dart';
import 'package:plate_calc/ui/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Respuesta real del servidor para el PDF "PROGRAMMATION IMPULSION"
/// (lunes y miércoles).
Map<String, dynamic> _server() =>
    jsonDecode(File('test/fixtures/plan_impulsion.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('el plan del PDF se convierte en bloques por día', () {
    final env = WeekPlan.envelope(_server(), now: DateTime(2026, 11, 11), fileName: 'plan.pdf');
    final plan = WeekPlan.fromJson(jsonDecode(jsonEncode(env)), fallbackName: 'WOD')!;

    // Sin fecha en el PDF: la semana es la de la subida (lunes 9).
    expect(plan.weekStart, DateTime(2026, 11, 9));
    expect(plan.days.keys, [1, 3]);
    final mon = plan.days[1]!;
    expect(mon.map((b) => b.title), ['FORCE / TECHNIQUE', 'WOD / METCON', 'RENFORCEMENT']);

    final emom = mon.first.wod;
    expect(emom.format, WodFormat.emom);
    expect(emom.minutes, 12);
    expect(emom.items.first.lift, 'Squat Snatch');
    expect(emom.items.first.percent, 80);

    final metcon = mon[1].wod;
    expect(metcon.rounds, 4);
    expect(metcon.items.map((i) => i.lift), contains('Dumbbell Box Step-Over'));

    // Los nombres de la IA no se cambian por parecidos.
    final wed = plan.days[3]!;
    expect(wed[1].wod.items.map((i) => i.lift), containsAll(['Wall Walk', 'Burpee Pull-Up']));

    // Identificadores estables y distintos por bloque.
    final ids = [
      for (final b in [...mon, ...wed]) b.wod.id,
    ];
    expect(ids.toSet().length, ids.length);
  });

  test('un bloque hecho queda marcado aunque se haga otro día', () async {
    SharedPreferences.setMockInitialValues({});
    final store = TrainingStore(await AppStorage.load());
    await store.saveWeekPlan(WeekPlan.envelope(_server(), now: DateTime(2026, 11, 9)));
    final plan = store.weekPlan(fallbackName: 'WOD')!;
    final block = plan.days[1]!.last.wod;
    expect(store.planDone(block), isNull);

    final w = store.startDaily(block, WeightUnit.kg, day: DateTime(2026, 11, 10));
    await store.saveWorkout(w);
    expect(store.planDone(block), isNotNull);
  });


  test('la semana propuesta: la del PDF, o la siguiente si se sube el fin de semana', () {
    expect(WeekPlan.suggestedWeek({}, DateTime(2026, 11, 11)), DateTime(2026, 11, 9));
    expect(WeekPlan.suggestedWeek({}, DateTime(2026, 11, 13)), DateTime(2026, 11, 16));
    expect(WeekPlan.suggestedWeek({}, DateTime(2026, 11, 15, 22)), DateTime(2026, 11, 16));
    expect(
      WeekPlan.suggestedWeek({'week_start': '2026-11-25'}, DateTime(2026, 11, 15)),
      DateTime(2026, 11, 23),
    );
  });

  test('cada semana guarda su plan; se puede mover y borrar', () async {
    // Plan único de la versión anterior: se conserva.
    final old = WeekPlan.envelope(_server(), now: DateTime(2026, 11, 9));
    SharedPreferences.setMockInitialValues({'training_week_plan': jsonEncode(old)});
    final store = TrainingStore(await AppStorage.load());
    expect(store.weekPlans(fallbackName: 'WOD').single.weekStart, DateTime(2026, 11, 9));

    final next = WeekPlan.envelope(
      _server(),
      now: DateTime(2026, 11, 15, 1),
      weekStart: DateTime(2026, 11, 18),
    );
    await store.saveWeekPlan(next);
    var plans = store.weekPlans(fallbackName: 'WOD');
    expect(plans.map((p) => p.weekStart), [DateTime(2026, 11, 9), DateTime(2026, 11, 16)]);
    expect(store.weekPlan(fallbackName: 'WOD', now: DateTime(2026, 11, 17))!.id, next['id']);
    expect(store.hasPlanFor(DateTime(2026, 11, 20)), isTrue);

    // Mover el de la semana 9 a la 16 reemplaza al que estaba ahí.
    await store.moveWeekPlan('${old['id']}', DateTime(2026, 11, 16));
    plans = store.weekPlans(fallbackName: 'WOD');
    expect(plans.single.id, old['id']);
    expect(plans.single.weekStart, DateTime(2026, 11, 16));

    await store.deleteWeekPlan('${old['id']}');
    expect(store.weekPlans(fallbackName: 'WOD'), isEmpty);
  });

  test('marcar el día como hecho sin registrar', () async {
    SharedPreferences.setMockInitialValues({});
    final store = TrainingStore(await AppStorage.load());
    await store.saveWeekPlan(
      WeekPlan.envelope(_server(), now: DateTime(2026, 11, 9), weekStart: DateTime(2026, 11, 9)),
    );
    final plan = store.weekPlan(fallbackName: 'WOD', now: DateTime(2026, 11, 9))!;
    final wods = [for (final b in plan.days[1]!) b.wod];
    await store.markPlanDone(wods, WeightUnit.kg, plan.dateOf(1));
    expect(wods.every((w) => store.planDone(w) != null), isTrue);
    expect(store.planDone(wods.first)!.date, DateTime(2026, 11, 9, 12));
    // Volver a marcar no duplica.
    await store.markPlanDone(wods, WeightUnit.kg, plan.dateOf(1));
    expect(store.workouts.length, wods.length);
  });

  Future<void> pumpPlan(WidgetTester tester, TrainingStore store) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: PlanView(store: store)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sin plan: explica la sección y ofrece subir el PDF', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = TrainingStore(await AppStorage.load());
    await pumpPlan(tester, store);
    expect(find.text('Tu semana, en un PDF'), findsOneWidget);
    expect(find.text('Subir PDF del plan'), findsOneWidget);
  });

  testWidgets('botón fijo abajo: marca todo el día como hecho', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = TrainingStore(await AppStorage.load());
    // Semana ya pasada: abre en su primer día con entrenamiento (pendiente).
    final monday = WeekPlan.mondayOf(DateTime.now()).subtract(const Duration(days: 7));
    await store.saveWeekPlan(
      WeekPlan.envelope(_server(), now: monday, weekStart: monday),
    );
    await pumpPlan(tester, store);

    final button = find.text('Marcar el día como hecho');
    expect(button, findsOneWidget);
    // Está fijo bajo la lista, visible sin desplazarse.
    expect(tester.getBottomLeft(button).dy, greaterThan(500));
    await tester.tap(button);
    await tester.pumpAndSettle();

    final plan = store.weekPlans(fallbackName: 'WOD').single;
    expect(plan.days[1]!.every((b) => store.planDone(b.wod) != null), isTrue);
    expect(button, findsNothing);
  });

  testWidgets('con plan: días, bloques y cambio de día', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = TrainingStore(await AppStorage.load());
    await store.saveWeekPlan(
      WeekPlan.envelope(_server(), now: DateTime.now(), weekStart: DateTime.now()),
    );
    await pumpPlan(tester, store);

    // Va al final de la lista: según el día puede estar fuera de pantalla.
    await tester.scrollUntilVisible(
      find.text('Nuevo PDF'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Nuevo PDF'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await tester.pumpAndSettle();
    // Elegir el miércoles muestra su WOD.
    final wed = WeekPlan.mondayOf(DateTime.now()).add(const Duration(days: 2));
    // La tira de días va antes que los bloques: el primero es el del día.
    await tester.tap(find.text('${wed.day}').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Wall Walk'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Wall Walk'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

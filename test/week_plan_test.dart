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

  testWidgets('con plan: días, bloques y cambio de día', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = TrainingStore(await AppStorage.load());
    await store.saveWeekPlan(WeekPlan.envelope(_server(), now: DateTime.now()));
    await pumpPlan(tester, store);

    expect(find.text('Nuevo PDF'), findsOneWidget);
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

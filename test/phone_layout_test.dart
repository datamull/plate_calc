import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_calc/main.dart';
import 'package:plate_calc/models/training.dart';
import 'package:plate_calc/models/weight_unit.dart';
import 'package:plate_calc/services/app_storage.dart';
import 'package:plate_calc/services/training_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plate_calc/ui/widgets/app_icons.dart';

/// Las pantallas de entrenamiento no se desbordan en un iPhone chico
/// (375 × 667) en ningún idioma ni estilo.
void main() {
  for (final lang in ['es', 'en', 'fr']) {
    testWidgets('entrenar en teléfono chico ($lang)', (tester) async {
      tester.view.physicalSize = const Size(750, 1334);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({
        'app_locale': lang,
        'lifts_units': 'lb',
        'rm_Snatch_lb': 225.0,
        'rm_Clean_lb': 275.0,
        'rm_Front Squat_lb': 285.0,
        'rm_Back Squat_lb': 315.0,
        'training_styles': '["crossfit","haltero","gym"]',
      });
      final storage = await AppStorage.load();
      final store = TrainingStore(storage);
      for (var i = 0; i < 4; i++) {
        await store.saveWorkout(
          Workout(
            id: 'w$i',
            date: DateTime.now().subtract(Duration(days: i * 5)),
            unit: WeightUnit.lb,
            title: 'Session $i',
            exercises: [
              ExerciseLog(
                lift: 'Snatch',
                sets: [WorkSet(weight: 150.0 + i * 5, reps: 2, done: true)],
              ),
            ],
          ),
        );
      }
      await tester.pumpWidget(PlateCalcApp(storage: storage));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(AppIcons.train));
      await tester.pumpAndSettle();
      for (final chip in find.byType(ChoiceChip).evaluate().toList()) {
        await tester.tap(find.byWidget(chip.widget));
        await tester.pumpAndSettle();
      }
      final segments = find.descendant(
        of: find.byType(GestureDetector),
        matching: find.byType(AnimatedContainer),
      );
      for (final i in [1, 2, 0]) {
        await tester.tap(segments.at(i));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }
}

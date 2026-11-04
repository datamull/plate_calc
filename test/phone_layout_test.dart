import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_calc/main.dart';
import 'package:plate_calc/services/app_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Las pantallas nuevas no se desbordan en un iPhone chico (375 × 667).
void main() {
  for (final lang in ['es', 'en', 'fr']) {
    testWidgets('pantallas de entrenamiento en teléfono chico ($lang)', (tester) async {
      tester.view.physicalSize = const Size(750, 1334);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({
        'app_locale': lang,
        'lifts_units': 'lb',
        'rm_Snatch_lb': 225.0,
        'rm_Back Squat_lb': 315.0,
      });
      final storage = await AppStorage.load();
      await tester.pumpWidget(PlateCalcApp(storage: storage));
      await tester.pumpAndSettle();

      final tabs = find.byType(NavigationDestination);
      for (var i = 1; i < 4; i++) {
        await tester.tap(tabs.at(i));
        await tester.pumpAndSettle();
      }

      // Programa → empezar el día → pantalla de registro.
      await tester.tap(tabs.at(1));
      await tester.pumpAndSettle();
      final tpl = find.byIcon(Icons.auto_graph).first;
      await tester.scrollUntilVisible(tpl, 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(tpl);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.play_arrow).first);
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsWidgets);
      await tester.tap(find.byIcon(Icons.radio_button_unchecked).first);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}

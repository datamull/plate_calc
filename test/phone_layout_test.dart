import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_calc/main.dart';
import 'package:plate_calc/services/app_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Las pantallas nuevas no se desbordan en un iPhone chico (375 × 667).
const _oly = {
  'es': 'Halterofilia · 4 semanas',
  'en': 'Weightlifting · 4 weeks',
  'fr': 'Haltérophilie · 4 semaines',
};

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

      // Las 4 pestañas (por ícono, sirve en cualquier idioma).
      for (final icon in [
        Icons.insights_outlined,
        Icons.groups_outlined,
        Icons.calculate_outlined,
        Icons.today_outlined,
      ]) {
        await tester.tap(find.byIcon(icon));
        await tester.pumpAndSettle();
      }

      // Programa → pizarra en Hoy → empezar → pantalla de registro.
      final tpl = find.text(_oly[lang]!);
      await tester.scrollUntilVisible(tpl, 200, scrollable: find.byType(Scrollable).first);
      await tester.ensureVisible(tpl);
      await tester.pumpAndSettle();
      await tester.tap(tpl);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      final start = find.byIcon(Icons.play_arrow_rounded);
      await tester.ensureVisible(start);
      await tester.pumpAndSettle();
      await tester.tap(start);
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsWidgets);
      await tester.tap(find.byIcon(Icons.radio_button_unchecked).first);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}

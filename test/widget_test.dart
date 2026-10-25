import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_calc/main.dart';
import 'package:plate_calc/ui/widgets/glass_button.dart';
import 'package:plate_calc/models/weight_unit.dart';
import 'package:plate_calc/services/app_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpApp(WidgetTester tester, Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  final storage = await AppStorage.load();
  await tester.pumpWidget(PlateCalcApp(storage: storage));
  await tester.pumpAndSettle();
}

/// Desplaza la lista de la pantalla actual hasta [text] y lo toca.
Future<void> scrollAndTap(WidgetTester tester, String text) async {
  final list = find
      .descendant(of: find.byType(ListView).last, matching: find.byType(Scrollable))
      .first;
  await tester.scrollUntilVisible(find.text(text), 200, scrollable: list);
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('flujo completo: abrir movimiento, calcular y ver resultado', (tester) async {
    await pumpApp(tester, {
      'app_locale': 'es',
      'lifts_units': 'kg',
      'rm_Snatch_kg': 100.0,
      'target_mode': 'totalInclBar',
    });

    // Movimientos base traducidos y RM visible en la tarjeta.
    expect(find.text('Snatch'), findsOneWidget);
    expect(find.text('RM: 100 kg'), findsOneWidget);

    await tester.tap(find.text('Snatch'));
    await tester.pumpAndSettle();

    // El RM guardado se precarga.
    expect(find.widgetWithText(TextField, '100'), findsWidgets);

    // Escribir el porcentaje actualiza el objetivo en vivo.
    await tester.enterText(find.widgetWithText(TextField, 'Porcentaje'), '80');
    await tester.pump();
    expect(find.text('TOTAL: 80 kg'), findsOneWidget);

    await scrollAndTap(tester, 'Calcular distribución de discos');

    // 80 kg = 20 + 2 × 30 → 25 + 5 por lado.
    expect(find.text('Alcanzado: 80 kg (exacto)'), findsOneWidget);
  });

  testWidgets('sin RM muestra un error claro', (tester) async {
    await pumpApp(tester, {'app_locale': 'en', 'lifts_units': 'kg'});
    await tester.tap(find.text('Clean'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, 'Calculate plate distribution');
    expect(find.text('Enter your 1RM.'), findsOneWidget);
  });

  testWidgets('agregar y eliminar un movimiento', (tester) async {
    await pumpApp(tester, {'app_locale': 'es'});

    await tester.tap(find.byType(GlassButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Front Squat');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Front Squat'), findsOneWidget);

    await tester.tap(find.text('Front Squat'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, 'Eliminar Front Squat');
    await tester.tap(find.text('Eliminar').last);
    await tester.pumpAndSettle();

    expect(find.text('Front Squat'), findsNothing);
  });

  testWidgets('ajustes: cambiar idioma y guardar inventario', (tester) async {
    await pumpApp(tester, {'app_locale': 'es'});
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Inglés'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Inventory'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add).first); // +1 al disco de 25 kg
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save inventory'));
    await tester.pumpAndSettle();
    expect(find.text('Inventory saved.'), findsOneWidget);

    final storage = await AppStorage.load();
    expect(storage.localeCode, 'en');
    expect(storage.settings(WeightUnit.kg).plates.first.count, 3);
  });
}

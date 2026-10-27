import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_calc/main.dart';
import 'package:plate_calc/models/weight_unit.dart';
import 'package:plate_calc/services/app_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpApp(WidgetTester tester, Map<String, Object> prefs, {String? open}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final storage = await AppStorage.load();
  await tester.pumpWidget(PlateCalcApp(storage: storage));
  await tester.pumpAndSettle();
  if (open != null) {
    await tester.tap(find.text(open));
    await tester.pumpAndSettle();
  }
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
    }, open: 'Haltero');

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

  testWidgets('cambiar kg/lb convierte el RM y vuelve al valor original', (tester) async {
    await pumpApp(tester, {
      'app_locale': 'es',
      'lifts_units': 'lb',
      'rm_Snatch_lb': 135.0,
    }, open: 'Haltero');
    await tester.tap(find.text('Snatch'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '135'), findsWidgets);

    // 135 lb = 61.2 kg -> redondeado a 61 kg (no queda en cero).
    await tester.tap(find.text('kg').first);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '61'), findsWidgets);

    // Al volver a lb se recupera el valor original, sin error de redondeo.
    await tester.tap(find.text('lb').first);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '135'), findsWidgets);

    // Botón de la calculadora dentro del movimiento.
    await tester.tap(find.byIcon(Icons.calculate_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Conversor de unidades'), findsOneWidget);
  });

  testWidgets('elegir un ícono distinto para un movimiento', (tester) async {
    await pumpApp(tester, {'app_locale': 'es'}, open: 'Haltero');
    await tester.tap(find.text('Snatch'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Cambiar ícono'));
    await tester.pumpAndSettle();
    expect(find.text('Elige un ícono'), findsOneWidget);
    await tester.tap(find.text('Squat'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lift_icon_Snatch'), 'squat');

    // Volver a automático borra la elección.
    await tester.tap(find.byTooltip('Cambiar ícono'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Automático (según el nombre)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Automático (según el nombre)'));
    await tester.pumpAndSettle();
    expect(prefs.getString('lift_icon_Snatch'), isNull);
  });

  testWidgets('sin RM muestra un error claro', (tester) async {
    await pumpApp(tester, {'app_locale': 'en', 'lifts_units': 'kg'}, open: 'Weightlifting');
    await tester.tap(find.text('Clean'));
    await tester.pumpAndSettle();
    await scrollAndTap(tester, 'Calculate plate distribution');
    expect(find.text('Enter your 1RM.'), findsOneWidget);
  });

  testWidgets('agregar y eliminar un movimiento', (tester) async {
    await pumpApp(tester, {'app_locale': 'es'}, open: 'Haltero');

    await tester.tap(find.byIcon(Icons.add));
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

  testWidgets('Gym: grupos, ejercicio sin barra guarda RM y con barra abre la calculadora', (
    tester,
  ) async {
    await pumpApp(tester, {'app_locale': 'es', 'lifts_units': 'kg'}, open: 'Gym');
    expect(find.text('Pecho'), findsOneWidget);
    expect(find.text('Abdomen'), findsOneWidget);

    await tester.tap(find.text('Pecho'));
    await tester.pumpAndSettle();
    for (final e in ['Bench Press', 'Incline Bench Press', 'Dumbbell Press', 'Chest Fly']) {
      expect(find.text(e), findsOneWidget);
    }

    // Sin barra: solo RM e historial.
    await tester.tap(find.text('Dumbbell Press'));
    await tester.pumpAndSettle();
    expect(find.text('Calcular distribución de discos'), findsNothing);
    await tester.enterText(find.byType(TextField), '30');
    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble('rm_Dumbbell Press_kg'), 30);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('RM: 30 kg'), findsOneWidget);

    // Con barra: calculadora de discos.
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Calcular distribución de discos'),
      200,
      scrollable: find
          .descendant(of: find.byType(ListView).last, matching: find.byType(Scrollable))
          .first,
    );
    expect(find.text('Calcular distribución de discos'), findsOneWidget);
  });

  testWidgets('Gym: agregar un ejercicio con barra', (tester) async {
    await pumpApp(tester, {'app_locale': 'es'}, open: 'Gym');
    await tester.tap(find.text('Brazos'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'EZ Curl');
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('EZ Curl'), findsOneWidget);

    final storage = await AppStorage.load();
    expect(storage.gymExercises('arms'), contains('EZ Curl'));
    expect(storage.isGymBarbell('EZ Curl'), isTrue);
    expect(storage.lifts, isNot(contains('EZ Curl')));
  });
}

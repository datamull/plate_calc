# Plate Calc

Calculadora de discos para halterofilia, CrossFit y powerlifting (iOS, hecha
con Flutter). Indica qué discos poner en cada lado de la barra para llegar a
un porcentaje de tu RM, con tu propio inventario de discos.

- Movimientos con RM e historial, en kg y lb
- Tabla de porcentajes 10–100 % del RM
- Cálculo exacto con el inventario disponible (menos discos posible)
- Inventario editable (agregar, quitar y contar discos)
- Español, inglés y francés; modo oscuro

## Estructura

```
lib/
  main.dart                 Arranque, idioma y tema
  data/defaults.dart        Inventario y movimientos por defecto
  models/                   Plate, Settings, WeightUnit, TargetMode
  services/
    app_storage.dart        Todo el acceso a datos guardados
    plate_calculator.dart   Algoritmo de cálculo de discos
  ui/screens/               Lista de movimientos, calculadora, ajustes
  ui/widgets/               Barra dibujada, tabla de %, hojas de resultado/historial
  utils/format.dart         Formato y lectura de números
  l10n/                     Traducciones (*.arb). Los .dart se generan solos.
test/                       Pruebas automáticas
```

## Comandos

```bash
flutter pub get        # instalar dependencias
flutter analyze        # revisar el código
flutter test           # ejecutar las pruebas
flutter run            # abrir en simulador o iPhone (requiere Mac + Xcode)
flutter gen-l10n       # regenerar traducciones tras editar lib/l10n/*.arb
```

## Publicar una versión

1. Sube el número de versión en `pubspec.yaml` (`version: 2.0.1+...`).
2. Haz push a GitHub e inicia el workflow `ios-release` en Codemagic.
3. Codemagic analiza, prueba, compila, firma y sube a TestFlight.
   El número de build se asigna solo.

## Datos de los usuarios

Las claves de almacenamiento son las mismas de la versión 1, así que al
actualizar se conservan los RM, historiales, movimientos e inventarios.

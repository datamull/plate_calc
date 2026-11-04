# Cambios

## 3.0.0 (beta en TestFlight)

- Nuevas pestañas: Calculadora, Entrenar, Progreso y Coach.
- Entrenar: registro de sesiones con series, peso, repeticiones y RPE; temporizador de descanso; calculadora de discos por serie; entrenamiento en curso se guarda solo.
- Rutinas propias y programas por porcentaje (Halterofilia 4 semanas, Fuerza 5/3/1) que calculan los pesos con el RM de cada persona.
- Progreso: racha de semanas, calendario, RM estimado (Epley), récords personales automáticos y gráficos de RM estimado, máximo y volumen por ejercicio. Un single más pesado actualiza el RM.
- Barra "Listo" encima del teclado en toda la app (el teclado numérico del iPhone no se podía cerrar).
- Progreso explica cada sección y, si aún no hay entrenamientos, lleva a Entrenar.
- Ejercicios sin barra: se anotan peso (vacío = peso corporal), repeticiones hechas y rondas opcionales, con su historial.
- Coach: perfil de coach y box, planes/WOD compartidos por QR o código; los alumnos devuelven su resultado con otro QR y el coach ve el historial y las marcas de cada uno.

## 2.2.0

### Nuevo
- Pantalla de inicio con dos secciones: **Haltero** (los movimientos de
  siempre) y **Gym**.
- Gym: 6 grupos musculares (pecho, espalda, piernas, hombros, brazos,
  abdomen) con 4 ejercicios cada uno. Se pueden agregar y borrar ejercicios
  en cada grupo.
- Los ejercicios con barra olímpica usan la calculadora de discos; los de
  mancuernas, máquina o peso corporal solo guardan RM e historial.
- Respaldo automático en iCloud, sin login: los datos se recuperan solos al
  instalar la app en otro iPhone con el mismo Apple ID.
- Nuevos pictogramas: remo, curl y abdominales.
- Android: nombre "Plate Calc", API 36 (exigida por Google Play) y
  compilación firmada del App Bundle en Codemagic.

## 2.1.0

### Nuevo diseño
- Interfaz renovada con los colores del logo (azul y morado sobre fondo oscuro).
- Botones de cristal estilo iOS.
- Ícono de la app con el logo.
- Resultado con media barra realista: discos con grosor según su peso, peso
  impreso, collar como tope y marca del centro de la barra.
- Discos de menos de 10 lb (unos 4.5 kg) dibujados a la mitad del diámetro,
  como en un gimnasio.
- Colores de discos por peso (lb: 45 azul, 35 rojo, 25 verde, 10 amarillo,
  5 azul, 2.5 verde; kg con su equivalente).
- Conversor rápido lb ↔ kg, junto al botón "+" en la pantalla principal.
- Pictograma propio para cada movimiento (Deadlift, Snatch, Clean, Jerk). Los movimientos creados por el usuario se reconocen por nombre (squat, bench, press, etc. en inglés, español o francés); si no hay coincidencia se muestra una barra.
- Movimientos base siempre en inglés (Deadlift, Snatch, Clean, Jerk), sin importar el idioma de la app.

### Mejoras
- Al cambiar kg ↔ lb dentro de un movimiento, el RM escrito se convierte a la
  otra unidad (redondeado a 0.5 kg / 1 lb) y la tabla de porcentajes se
  actualiza; antes quedaba todo en cero. Al volver se recupera el valor original.
- Tabla de porcentajes redondeada a 0.5 (pesos que se pueden cargar).
- Botón de la calculadora lb ↔ kg dentro de cada movimiento, junto a guardar.
- Elegir el ícono de cada movimiento: tocar el ícono dentro del movimiento
  abre un selector con los 8 dibujos o la opción automática (según el nombre).

## 2.0.0

### Errores corregidos
- **Cálculo de discos**: el algoritmo anterior (de mayor a menor) a veces no
  encontraba la combinación exacta aunque existiera. Ahora busca la mejor
  combinación posible, con la menor cantidad de discos.
- **Cambio kg ↔ lb en la calculadora**: se seguían usando los discos de la
  otra unidad (p. ej. discos de 25 kg tratados como 25 lb) y no se recargaba
  el RM de esa unidad.
- **Eliminar movimiento**: el RM no se borraba (se buscaba con una clave
  distinta a la de guardado) y los movimientos base (Deadlift, Snatch…)
  reaparecían después de "eliminarlos".
- **Dos inventarios distintos**: Ajustes mostraba un inventario por defecto
  y la calculadora usaba otro. Ahora hay uno solo.
- **Tabla de porcentajes**: no se actualizaba al escribir el RM.
- **Formato de pesos**: valores como 1.05 se mostraban como "15".
- **Collares**: no aceptaban coma decimal.
- **Idioma**: la app arrancaba en el idioma del sistema y cambiaba un instante
  después.
- **Limpiar historial**: borraba todo sin pedir confirmación.
- Al guardar el inventario, el aviso mostraba el texto del botón.
- Fugas de memoria (controladores de texto que nunca se liberaban).

### Mejoras
- Inventario: agregar discos de cualquier peso, quitarlos (mantener
  presionado) y restaurar valores por defecto.
- Se recuerdan la unidad elegida, el modo de RM, la barra y los collares.
- Historial: borrar registros individuales (deslizar o ×).
- Modo oscuro.
- Avisos claros cuando falta el RM.
- Colores para todos los discos (antes los de 2, 1.5, 1 kg y 35 lb salían grises).

### Código y repositorio
- `home_screen.dart` pasó de 1086 a ~350 líneas, separado en widgets.
- Un solo servicio de datos (`AppStorage`) en vez de accesos repartidos.
- Eliminado código sin uso: 3 pantallas/widgets muertos y el servicio antiguo.
- Eliminadas las plataformas que no se usan (Linux, Windows, macOS, web).
- Todas las APIs obsoletas reemplazadas; `flutter analyze` sin advertencias.
- 25 pruebas automáticas (cálculo, datos, compatibilidad con v1, interfaz).
- Codemagic: ejecuta análisis y pruebas antes de compilar, compila una sola
  vez y asigna el número de build automáticamente.

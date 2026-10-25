# Cambios

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
- Movimientos base siempre en inglés (Deadlift, Snatch, Clean, Jerk), sin importar el idioma de la app.
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

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Calculadora de Discos';

  @override
  String get unitsLabel => 'Unidades:';

  @override
  String get barLabel => 'Barra';

  @override
  String get collarsLabel => 'Collares';

  @override
  String get interpretRmAs => 'Interpretar RM% como:';

  @override
  String get modeTotalInclBar => 'Total (incluye barra)';

  @override
  String get modePerSide => 'Por lado (sin barra)';

  @override
  String get rmFieldNoMovement => 'Tu 1RM';

  @override
  String rmFieldWithMovement(String movementName) {
    return '1RM de $movementName';
  }

  @override
  String get percentLabel => 'Porcentaje';

  @override
  String derivedTargetLabel(String percent) {
    return 'Objetivo derivado de $percent% del RM:';
  }

  @override
  String derivedTotal(String weight, String units) {
    return 'TOTAL: $weight $units';
  }

  @override
  String derivedPerSide(String weight, String units) {
    return 'POR LADO (discos): $weight $units';
  }

  @override
  String get percentTableTitle => 'Tabla de porcentajes (toca para aplicar)';

  @override
  String get percentTableHeaderPercent => '%';

  @override
  String get percentTableHeaderTotal => 'Total';

  @override
  String get percentTableHeaderPerSide => 'Por lado (sin barra)';

  @override
  String get calculateButton => 'Calcular distribución de discos';

  @override
  String get historyButton => 'Historial RM';

  @override
  String historySheetTitle(String movementName, String units) {
    return 'Historial RM — $movementName ($units)';
  }

  @override
  String get historyClear => 'Limpiar';

  @override
  String get historyEmpty => 'No hay registros aún. Guarda un RM para crear entradas.';

  @override
  String get historyClearedSnack => 'Historial limpiado.';

  @override
  String historyRowRm(String rm, String units) {
    return 'RM: $rm $units';
  }

  @override
  String get saveRmTooltip => 'Guardar RM';

  @override
  String get saveRmInvalidSnack => 'Ingresa un RM válido antes de guardar.';

  @override
  String saveRmOkSnack(String movementName, String units) {
    return 'RM guardado para $movementName ($units).';
  }

  @override
  String get deleteMovementDialogTitle => 'Eliminar movimiento';

  @override
  String deleteMovementDialogContent(String movementName) {
    return '¿Eliminar \"$movementName\" por completo? Se borrará de tu lista y su RM/Historial.';
  }

  @override
  String get deleteMovementCancel => 'Cancelar';

  @override
  String get deleteMovementConfirm => 'Eliminar';

  @override
  String deleteMovementButton(String movementName) {
    return 'Eliminar $movementName';
  }

  @override
  String deleteMovementOkSnack(String movementName) {
    return 'Movimiento eliminado: $movementName';
  }

  @override
  String get deleteMovementFailSnack => 'No se pudo eliminar.';

  @override
  String get errorPercentInvalid => 'Ingresa un porcentaje válido (> 0).';

  @override
  String get errorTargetTooLow => 'El objetivo es menor que la barra o los datos no son válidos.';

  @override
  String get panelCloseTooltip => 'Cerrar';

  @override
  String resultExact(String weight, String units) {
    return 'Alcanzado: $weight $units (exacto)';
  }

  @override
  String resultApprox(String weight, String shortfall, String units) {
    return 'Mejor aproximación: $weight $units (faltan $shortfall $units)';
  }

  @override
  String get chosenDiscsTitle => 'Discos elegidos (totales):';

  @override
  String get yourLiftsTitle => 'Tus movimientos';

  @override
  String get addLiftTitle => 'Agregar movimiento';

  @override
  String get addLiftHint => 'Ej: Front Squat';

  @override
  String get saveLabel => 'Guardar';

  @override
  String get noRmLabel => 'Sin RM';

  @override
  String get deleteRecordTooltip => 'Eliminar registro';

  @override
  String get clearHistoryDialogTitle => 'Limpiar historial';

  @override
  String get clearHistoryDialogContent => '¿Eliminar todo el historial de este movimiento?';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsTabLanguage => 'Idioma';

  @override
  String get settingsTabInventory => 'Inventario';

  @override
  String get settingsLanguageTitle => 'Idioma de la aplicación';

  @override
  String get settingsLanguageSystem => 'Usar idioma del sistema';

  @override
  String get settingsLanguageSpanish => 'Español';

  @override
  String get settingsLanguageFrench => 'Francés';

  @override
  String get settingsLanguageEnglish => 'Inglés';

  @override
  String get inventoryKgTitle => 'Discos en kg';

  @override
  String get inventoryLbTitle => 'Discos en lb';

  @override
  String get inventorySaveButton => 'Guardar inventario';

  @override
  String get liftAlreadyExists => 'Ese movimiento ya existe.';

  @override
  String get errorRmMissing => 'Ingresa tu 1RM.';

  @override
  String get inventorySavedSnack => 'Inventario guardado.';

  @override
  String get inventoryAddPlate => 'Agregar disco';

  @override
  String get inventoryAddPlateHint => 'Peso del disco';

  @override
  String get inventoryDeletePlateHint => 'Mantén presionado un disco para quitarlo.';

  @override
  String inventoryRemovePlate(String weight, String units) {
    return '¿Quitar el disco de $weight $units?';
  }

  @override
  String get inventoryReset => 'Restaurar valores por defecto';

  @override
  String get settingsTooltip => 'Configuración';

  @override
  String get resultBarOnly => 'Solo la barra, sin discos.';

  @override
  String get converterTitle => 'Conversor de unidades';

  @override
  String get converterTooltip => 'Conversor de unidades';

  @override
  String get lbLabel => 'Libras (lb)';

  @override
  String get kgLabel => 'Kilogramos (kg)';

  @override
  String get quickPlatesTitle => 'Equivalencias rápidas de discos';

  @override
  String get chooseIconTitle => 'Elige un ícono';

  @override
  String get chooseIconTooltip => 'Cambiar ícono';

  @override
  String get iconAuto => 'Automático (según el nombre)';

  @override
  String get categoryHaltero => 'Haltero';

  @override
  String get categoryHalteroSubtitle => 'Movimientos olímpicos y los tuyos';

  @override
  String get categoryGym => 'Gym';

  @override
  String get categoryGymSubtitle => 'Ejercicios por grupo muscular';

  @override
  String get groupChest => 'Pecho';

  @override
  String get groupBack => 'Espalda';

  @override
  String get groupLegs => 'Piernas';

  @override
  String get groupShoulders => 'Hombros';

  @override
  String get groupArms => 'Brazos';

  @override
  String get groupCore => 'Abdomen';

  @override
  String exerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ejercicios',
      one: '1 ejercicio',
    );
    return '$_temp0';
  }

  @override
  String get barbellSwitch => 'Usa barra olímpica (calculadora de discos)';

  @override
  String get noCalculatorHint =>
      'Este ejercicio no usa barra: anota el peso, las repeticiones y las rondas, y lleva su historial.';

  @override
  String get iCloudSyncTitle => 'Respaldo en iCloud';

  @override
  String get iCloudSyncOn =>
      'Tus datos se guardan en iCloud y se recuperan solos en un iPhone nuevo con el mismo Apple ID.';

  @override
  String get iCloudSyncOff =>
      'iCloud no está disponible. Inicia sesión en iCloud en Ajustes para respaldar tus datos.';

  @override
  String get iCloudRestored => 'Datos recuperados de iCloud';

  @override
  String get tabCalc => 'Calculadora';

  @override
  String get tabTrain => 'Entrenar';

  @override
  String get tabProgress => 'Progreso';

  @override
  String get tabCoach => 'Coach';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get edit => 'Editar';

  @override
  String get save => 'Guardar';

  @override
  String get rename => 'Cambiar nombre';

  @override
  String get workoutStartFree => 'Empezar entrenamiento';

  @override
  String get workoutResume => 'Seguir entrenamiento en curso';

  @override
  String get workoutFree => 'Entrenamiento';

  @override
  String get workoutAddExercise => 'Agregar ejercicio';

  @override
  String get workoutRemoveExercise => 'Quitar ejercicio';

  @override
  String get workoutAddSet => 'Agregar serie';

  @override
  String get workoutReps => 'Reps';

  @override
  String get workoutPlates => 'Discos para esta serie';

  @override
  String get workoutSetDone => 'Serie hecha';

  @override
  String get workoutNotes => 'Notas';

  @override
  String get workoutFinish => 'Terminar entrenamiento';

  @override
  String get workoutDiscard => 'Descartar entrenamiento';

  @override
  String get workoutDiscardTitle => '¿Descartar este entrenamiento?';

  @override
  String get workoutNoSetsTitle => 'No hay series hechas';

  @override
  String get workoutNoSetsBody => 'Marca las series hechas con el círculo para guardarlas.';

  @override
  String get workoutDeleteTitle => '¿Eliminar este entrenamiento?';

  @override
  String workoutPercentOfRm(String percent) {
    return '$percent% del RM';
  }

  @override
  String get restLabel => 'Descanso';

  @override
  String get restSkip => 'Saltar';

  @override
  String get restDefault => 'Descanso entre series';

  @override
  String get summaryTitle => 'Entrenamiento guardado 💪';

  @override
  String get summaryTitlePr => '¡Nuevo récord personal! 🏆';

  @override
  String summaryStats(int sets, String volume, String unit) {
    return '$sets series · $volume $unit levantados';
  }

  @override
  String prHeaviest(String weight, String unit) {
    return 'más pesado hasta ahora, $weight $unit';
  }

  @override
  String prEstimated(String weight, String unit) {
    return 'mejor RM estimado, $weight $unit';
  }

  @override
  String get sendToCoach => 'Enviar al coach';

  @override
  String get athleteNameTitle => 'Tu nombre';

  @override
  String get athleteNameHint => 'Para que tu coach sepa que eres tú';

  @override
  String get resultShareTitle => 'Tu resultado';

  @override
  String resultShareSubtitle(String coach) {
    return 'Muéstrale este QR a $coach o mándale el código por mensaje.';
  }

  @override
  String get draftReplaceTitle => 'Entrenamiento en curso';

  @override
  String get draftReplaceBody =>
      'Tienes un entrenamiento sin terminar. ¿Empezar uno nuevo y descartarlo?';

  @override
  String setsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series',
      one: '1 serie',
    );
    return '$_temp0';
  }

  @override
  String get myPlans => 'Mis planes';

  @override
  String get myPlansEmpty => 'Crea una rutina, usa un programa de abajo o importa el de tu coach.';

  @override
  String get planCreate => 'Crear rutina';

  @override
  String get importPlanShort => 'Plan del coach';

  @override
  String get importPlanTitle => 'Importar plan del coach';

  @override
  String importPlanDone(String name) {
    return 'Plan \"$name\" agregado';
  }

  @override
  String get importInvalid => 'Ese código no es válido. Revisa que se haya copiado completo.';

  @override
  String get templatesTitle => 'Programas por porcentaje';

  @override
  String get historyTitle => 'Historial';

  @override
  String get historyWorkoutsEmpty => 'Aquí aparecerán tus entrenamientos terminados.';

  @override
  String get planUntitled => 'Plan sin nombre';

  @override
  String planFromCoach(String coach) {
    return 'Coach $coach';
  }

  @override
  String planProgress(int done, int total) {
    return '$done de $total días hechos';
  }

  @override
  String planDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get planShare => 'Compartir con QR';

  @override
  String planShareTitle(String name) {
    return 'Compartir \"$name\"';
  }

  @override
  String get planShareSubtitle =>
      'Tus alumnos lo escanean en Plate Calc → Entrenar → Plan del coach. Los pesos se calculan con el RM de cada uno.';

  @override
  String planStartNext(String day) {
    return 'Empezar: $day';
  }

  @override
  String get planStartDay => 'Empezar este día';

  @override
  String get planNoRm => 'sin RM guardado';

  @override
  String planDeleteTitle(String name) {
    return '¿Eliminar \"$name\"?';
  }

  @override
  String planWeekDay(int week, String day) {
    return 'Semana $week · Día $day';
  }

  @override
  String planDayDefault(int n) {
    return 'Día $n';
  }

  @override
  String get planOlyName => 'Halterofilia · 4 semanas';

  @override
  String get planOlyNotes => '3 días por semana. Arranque, envión y sentadillas por % de tu RM.';

  @override
  String get planStrengthName => 'Fuerza 5/3/1 · 4 semanas';

  @override
  String get planStrengthNotes =>
      '4 días por semana: sentadilla, banca, peso muerto y press. La semana 4 es de descarga.';

  @override
  String get planEditorTitle => 'Rutina';

  @override
  String get planNameLabel => 'Nombre';

  @override
  String get planNameHint => 'Ej.: WOD lunes, Ciclo de sentadilla';

  @override
  String get planNotesLabel => 'Notas para los alumnos (opcional)';

  @override
  String get planNameRequired => 'Ponle un nombre';

  @override
  String get planNeedsExercise => 'Agrega al menos un ejercicio';

  @override
  String get planAddExercise => 'Agregar ejercicio';

  @override
  String get planAddDay => 'Agregar día';

  @override
  String get planDayName => 'Nombre del día';

  @override
  String get planDayDuplicate => 'Duplicar';

  @override
  String get planSets => 'Series';

  @override
  String get planLoadPercent => '% RM';

  @override
  String get planLoadWeight => 'Peso';

  @override
  String get planLoadFree => 'Libre';

  @override
  String get planPercentLabel => 'Porcentaje del RM';

  @override
  String get planWeightLabel => 'Peso fijo';

  @override
  String get pickExerciseHint => 'Busca o escribe un ejercicio nuevo';

  @override
  String pickExerciseNew(String name) {
    return 'Usar \"$name\"';
  }

  @override
  String get shareCopyCode => 'Copiar código';

  @override
  String get shareCopied => 'Código copiado. Pégalo en WhatsApp, un correo…';

  @override
  String get shareHowTo => 'La otra persona abre Plate Calc y escanea el QR o pega el código.';

  @override
  String get shareScanQr => 'Escanear QR';

  @override
  String get sharePasteLabel => 'O pega el código';

  @override
  String get sharePaste => 'Pegar';

  @override
  String get shareImport => 'Importar';

  @override
  String get shareCameraError =>
      'No se puede abrir la cámara. Permite el acceso a la cámara para Plate Calc en Ajustes, o pega el código.';

  @override
  String get statStreak => 'semanas seguidas';

  @override
  String get statThisMonth => 'este mes';

  @override
  String get statTotal => 'en total';

  @override
  String get e1rmCalcTitle => 'RM estimado';

  @override
  String get e1rmCalcHelp => 'Peso y repeticiones de una serie exigente (fórmula de Epley).';

  @override
  String get e1rmWeight => 'Peso';

  @override
  String e1rmResult(String weight, String unit) {
    return '≈ $weight $unit';
  }

  @override
  String e1rmShort(String weight, String unit) {
    return 'RMe $weight $unit';
  }

  @override
  String get recordsTitle => 'Récords personales';

  @override
  String get recordsEmpty => 'Termina un entrenamiento para ver tus récords y gráficos.';

  @override
  String recordHeaviest(String weight, String unit) {
    return 'Máx. $weight $unit';
  }

  @override
  String currentRm(String weight, String unit) {
    return 'RM guardado: $weight $unit';
  }

  @override
  String get metricE1rm => 'RM est.';

  @override
  String get metricHeaviest => 'Máximo';

  @override
  String get metricVolume => 'Volumen';

  @override
  String get chartNeedsMore =>
      'Necesitas al menos 2 entrenamientos con este ejercicio para ver el gráfico.';

  @override
  String get coachProfile => 'Perfil de coach';

  @override
  String get coachNameLabel => 'Tu nombre';

  @override
  String get coachBoxLabel => 'Box o gimnasio';

  @override
  String get coachSetupTitle => 'Configura tu perfil de coach';

  @override
  String get coachSetupSubtitle => 'Tu nombre y box salen en los planes que compartes';

  @override
  String get coachDefaultName => 'Coach';

  @override
  String get coachHowItWorks =>
      '1. Crea un plan o WOD con % del RM.\n2. Compártelo con un QR: cada alumno ve sus propios pesos.\n3. Después de entrenar, te mandan su resultado con otro QR.';

  @override
  String get coachPlansTitle => 'Planes para tu box';

  @override
  String get coachCreatePlan => 'Crear plan o WOD';

  @override
  String get coachAthletesTitle => 'Alumnos';

  @override
  String get coachAthletesEmpty => 'Cuando un alumno te mande un resultado, aparecerá aquí.';

  @override
  String get importResultTitle => 'Recibir resultado de alumno';

  @override
  String importResultDone(String name) {
    return 'Resultado de $name guardado';
  }

  @override
  String get importResultDuplicate => 'Ya tenías este resultado';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entrenamientos',
      one: '1 entrenamiento',
    );
    return '$_temp0';
  }

  @override
  String lastWorkout(String date) {
    return 'último $date';
  }

  @override
  String athleteDeleteTitle(String name) {
    return '¿Eliminar a $name y sus resultados?';
  }

  @override
  String get keyboardDone => 'Listo';

  @override
  String get optional => 'Opcional';

  @override
  String get progressIntroTitle => '¿Para qué sirve esta pestaña?';

  @override
  String get progressIntroBody =>
      'Muestra cómo vas mejorando. Se llena sola con los entrenamientos que terminas en la pestaña Entrenar: días entrenados, récords y un gráfico por ejercicio.';

  @override
  String get progressGoTrain => 'Ir a Entrenar';

  @override
  String get progressConsistencyTitle => 'Constancia';

  @override
  String get progressConsistencyHelp =>
      'Semanas seguidas con al menos un entrenamiento, y cuántos llevas.';

  @override
  String get progressCalendarTitle => 'Calendario';

  @override
  String get progressCalendarHelp =>
      'Los días de color son los que entrenaste. Toca uno para ver ese entrenamiento.';

  @override
  String get progressRecordsHelp =>
      'Tu mejor marca en cada ejercicio. Toca uno para ver su gráfico.';

  @override
  String e1rmExample(String weight, String result) {
    return 'Ejemplo: $weight a 5 repeticiones ≈ RM de $result';
  }

  @override
  String get simpleWeightLabel => 'Peso';

  @override
  String get simpleWeightHelp => 'Déjalo vacío si es peso corporal';

  @override
  String get simpleRepsLabel => 'Repeticiones hechas';

  @override
  String get simpleRoundsLabel => 'Rondas';

  @override
  String simpleLastEntry(String entry) {
    return 'Último: $entry';
  }

  @override
  String get saveSetButton => 'Guardar';

  @override
  String get saveSetInvalidSnack => 'Ingresa las repeticiones hechas (o un peso).';

  @override
  String saveSetOkSnack(String movementName) {
    return 'Guardado para $movementName.';
  }

  @override
  String get bodyweight => 'Peso corporal';

  @override
  String setsRepsLine(String weight, int reps) {
    return '$weight × $reps reps';
  }

  @override
  String roundsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rondas',
      one: '1 ronda',
    );
    return '$_temp0';
  }

  @override
  String get tabToday => 'Hoy';

  @override
  String get tabBox => 'Box';

  @override
  String get tabPlates => 'Discos';

  @override
  String get todayInProgress => 'En curso';

  @override
  String get todayResume => 'Seguir';

  @override
  String get todayNext => 'Próxima sesión';

  @override
  String get todayNoPlanBody =>
      'No tienes un plan activo. Elige un programa abajo, crea una rutina o escanea el plan de tu coach.';

  @override
  String get todayFreeWorkout => 'O empieza un entrenamiento libre';

  @override
  String get todayRecent => 'Recientes';

  @override
  String get seeAll => 'Ver todo';

  @override
  String get colSet => 'SERIE';

  @override
  String get colPrevious => 'ANTERIOR';

  @override
  String get workoutFinishShort => 'Terminar';

  @override
  String get styleCrossfit => 'Crosstraining';

  @override
  String get styleHaltero => 'Halterofilia';

  @override
  String get styleGym => 'Gym';

  @override
  String get styleCrossfitDesc => 'WOD diario: AMRAP, EMOM, For Time';

  @override
  String get styleHalteroDesc => 'Arranque, envión y sentadillas por % del RM';

  @override
  String get styleGymDesc => 'Push / Pull / Legs';

  @override
  String get stylesTitle => '¿Qué entrenas?';

  @override
  String get stylesFirstTitle => 'Un entrenamiento cada día';

  @override
  String get stylesFirstBody =>
      'Elige qué entrenas y cada día tendrás una sesión nueva, con tus pesos según tu RM.';

  @override
  String get stylesChoose => 'Elegir';

  @override
  String get todayStart => 'Empezar';

  @override
  String get todayDone => 'Hecho';

  @override
  String get crossfitOfficialWod => 'WOD oficial de CrossFit.com';

  @override
  String get wodGo => 'Empezar';

  @override
  String get wodPause => 'Pausa';

  @override
  String get wodContinue => 'Seguir';

  @override
  String get wodRound => 'Ronda';

  @override
  String get wodScoreTitle => 'Tu resultado';

  @override
  String get wodScoreTime => 'Tiempo (mm:ss)';

  @override
  String get wodScoreRounds => 'Rondas';

  @override
  String get wodScoreReps => '+ reps';

  @override
  String wodSaved(String score) {
    return 'Guardado: $score';
  }

  @override
  String get wodResultsTitle => 'Resultados de WOD';

  @override
  String get progressEmpty => 'Termina tu primer entrenamiento para ver aquí tu progreso.';

  @override
  String get statThisWeek => 'esta semana';

  @override
  String get chartThisWeek => 'Esta semana';

  @override
  String chartWeeksAgo(int n) {
    return 'Hace $n sem';
  }

  @override
  String get metricE1rmLong => 'Mejor RM estimado';

  @override
  String get metricHeaviestLong => 'Peso máximo';

  @override
  String get todayOther => 'Otro';

  @override
  String get scanButton => 'Foto de la pizarra';

  @override
  String get scanCamera => 'Tomar foto';

  @override
  String get scanGallery => 'Elegir de las fotos';

  @override
  String get scanReading => 'Leyendo la pizarra…';

  @override
  String get scanNothing =>
      'No encontré ejercicios. Prueba de nuevo con más luz y la pizarra completa en la foto.';

  @override
  String get scanPermission =>
      'No se puede abrir la cámara. Permite el acceso para Plate Calc en Ajustes.';

  @override
  String get scanTitle => 'Pizarra';

  @override
  String get scanDefaultName => 'WOD de la pizarra';

  @override
  String get scanCheck =>
      'Revísalo antes de empezar: cambia el formato o quita lo que se haya leído mal.';

  @override
  String get scanRetake => 'Tomar otra foto';

  @override
  String get scanTapToEdit => 'Toca un ejercicio para corregirlo.';

  @override
  String get scanRawText => 'Texto leído de la foto';

  @override
  String get scanRepsLabel => 'Reps / distancia / calorías';

  @override
  String get scanMoveLabel => 'Ejercicio';

  @override
  String get scanRxLabel => 'Peso Rx (opcional)';

  @override
  String get scanByAi => '✦ LEÍDO CON IA';

  @override
  String get aiConsentTitle => '¿Leer la pizarra con IA?';

  @override
  String get aiConsentBody =>
      'Para leer la pizarra, Plate Calc envía la foto a Google Gemini (el servicio de IA de Google) a través de nuestro servidor. Google puede usarla para mejorar sus productos. Nosotros no guardamos la foto ni la asociamos a ti.\n\nSi prefieres, la app la lee solo en tu teléfono (menos preciso). Puedes cambiarlo en Ajustes.';

  @override
  String get aiConsentYes => 'Usar IA';

  @override
  String get aiConsentNo => 'Solo en mi teléfono';

  @override
  String get aiSettingTitle => 'Fotos de la pizarra';

  @override
  String get aiSettingSwitch => 'Leer con IA (Google Gemini)';

  @override
  String get aiSettingHelp =>
      'La foto se envía a Google para leerla. Apagado: se lee solo en este teléfono.';

  @override
  String get detailDuration => 'Duración';

  @override
  String get detailResult => 'Resultado';

  @override
  String get detailMovements => 'Movimientos';

  @override
  String get detailExercises => 'Ejercicios';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Calculateur de plaques';

  @override
  String get unitsLabel => 'Unités :';

  @override
  String get barLabel => 'Barre';

  @override
  String get collarsLabel => 'Collets';

  @override
  String get interpretRmAs => 'Interpréter RM% comme :';

  @override
  String get modeTotalInclBar => 'Total (barre incluse)';

  @override
  String get modePerSide => 'Par côté (sans la barre)';

  @override
  String get rmFieldNoMovement => 'Ton 1RM';

  @override
  String rmFieldWithMovement(String movementName) {
    return '1RM de $movementName';
  }

  @override
  String get percentLabel => 'Pourcentage';

  @override
  String derivedTargetLabel(String percent) {
    return 'Objectif dérivé de $percent % du RM :';
  }

  @override
  String derivedTotal(String weight, String units) {
    return 'TOTAL : $weight $units';
  }

  @override
  String derivedPerSide(String weight, String units) {
    return 'PAR CÔTÉ (disques) : $weight $units';
  }

  @override
  String get percentTableTitle => 'Tableau des pourcentages (touche pour appliquer)';

  @override
  String get percentTableHeaderPercent => '%';

  @override
  String get percentTableHeaderTotal => 'Total';

  @override
  String get percentTableHeaderPerSide => 'Par côté (sans la barre)';

  @override
  String get calculateButton => 'Calculer la répartition des plaques';

  @override
  String get historyButton => 'Historique de RM';

  @override
  String historySheetTitle(String movementName, String units) {
    return 'Historique de RM — $movementName ($units)';
  }

  @override
  String get historyClear => 'Effacer';

  @override
  String get historyEmpty =>
      'Aucun enregistrement pour l’instant. Enregistre un RM pour créer des entrées.';

  @override
  String get historyClearedSnack => 'Historique effacé.';

  @override
  String historyRowRm(String rm, String units) {
    return 'RM : $rm $units';
  }

  @override
  String get saveRmTooltip => 'Enregistrer le RM';

  @override
  String get saveRmInvalidSnack => 'Entre un RM valide avant d’enregistrer.';

  @override
  String saveRmOkSnack(String movementName, String units) {
    return 'RM enregistré pour $movementName ($units).';
  }

  @override
  String get deleteMovementDialogTitle => 'Supprimer le mouvement';

  @override
  String deleteMovementDialogContent(String movementName) {
    return 'Supprimer « $movementName » complètement ? Il sera retiré de ta liste ainsi que son RM / historique.';
  }

  @override
  String get deleteMovementCancel => 'Annuler';

  @override
  String get deleteMovementConfirm => 'Supprimer';

  @override
  String deleteMovementButton(String movementName) {
    return 'Supprimer $movementName';
  }

  @override
  String deleteMovementOkSnack(String movementName) {
    return 'Mouvement supprimé : $movementName';
  }

  @override
  String get deleteMovementFailSnack => 'Impossible de supprimer.';

  @override
  String get errorPercentInvalid => 'Entre un pourcentage valide (> 0).';

  @override
  String get errorTargetTooLow =>
      'L’objectif est inférieur au poids de la barre ou les données ne sont pas valides.';

  @override
  String get panelCloseTooltip => 'Fermer';

  @override
  String resultExact(String weight, String units) {
    return 'Atteint : $weight $units (exact)';
  }

  @override
  String resultApprox(String weight, String shortfall, String units) {
    return 'Meilleure approximation : $weight $units (il manque $shortfall $units)';
  }

  @override
  String get chosenDiscsTitle => 'Plaques choisies (totales) :';

  @override
  String get yourLiftsTitle => 'Tes mouvements';

  @override
  String get addLiftTitle => 'Ajouter un mouvement';

  @override
  String get addLiftHint => 'Ex.: Front Squat';

  @override
  String get saveLabel => 'Enregistrer';

  @override
  String get noRmLabel => 'Sans RM';

  @override
  String get deleteRecordTooltip => 'Supprimer l’enregistrement';

  @override
  String get clearHistoryDialogTitle => 'Effacer l’historique';

  @override
  String get clearHistoryDialogContent => 'Supprimer tout l’historique de ce mouvement ?';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsTabLanguage => 'Langue';

  @override
  String get settingsTabInventory => 'Inventaire';

  @override
  String get settingsLanguageTitle => 'Langue de l’application';

  @override
  String get settingsLanguageSystem => 'Utiliser la langue du système';

  @override
  String get settingsLanguageSpanish => 'Espagnol';

  @override
  String get settingsLanguageFrench => 'Français';

  @override
  String get settingsLanguageEnglish => 'Anglais';

  @override
  String get inventoryKgTitle => 'Disques en kg';

  @override
  String get inventoryLbTitle => 'Disques en lb';

  @override
  String get inventorySaveButton => 'Enregistrer l’inventaire';

  @override
  String get liftAlreadyExists => 'Ce mouvement existe déjà.';

  @override
  String get errorRmMissing => 'Entrez votre 1RM.';

  @override
  String get inventorySavedSnack => 'Inventaire enregistré.';

  @override
  String get inventoryAddPlate => 'Ajouter un disque';

  @override
  String get inventoryAddPlateHint => 'Poids du disque';

  @override
  String get inventoryDeletePlateHint => 'Appuyez longuement sur un disque pour le retirer.';

  @override
  String inventoryRemovePlate(String weight, String units) {
    return 'Retirer le disque de $weight $units ?';
  }

  @override
  String get inventoryReset => 'Rétablir les valeurs par défaut';

  @override
  String get settingsTooltip => 'Paramètres';

  @override
  String get resultBarOnly => 'Seulement la barre, sans disques.';

  @override
  String get converterTitle => 'Convertisseur d\'unités';

  @override
  String get converterTooltip => 'Convertisseur d\'unités';

  @override
  String get lbLabel => 'Livres (lb)';

  @override
  String get kgLabel => 'Kilogrammes (kg)';

  @override
  String get quickPlatesTitle => 'Équivalences rapides des disques';

  @override
  String get chooseIconTitle => 'Choisir une icône';

  @override
  String get chooseIconTooltip => 'Changer l\'icône';

  @override
  String get iconAuto => 'Automatique (selon le nom)';

  @override
  String get categoryHaltero => 'Haltérophilie';

  @override
  String get categoryHalteroSubtitle => 'Mouvements olympiques et les vôtres';

  @override
  String get categoryGym => 'Gym';

  @override
  String get categoryGymSubtitle => 'Exercices par groupe musculaire';

  @override
  String get groupChest => 'Pectoraux';

  @override
  String get groupBack => 'Dos';

  @override
  String get groupLegs => 'Jambes';

  @override
  String get groupShoulders => 'Épaules';

  @override
  String get groupArms => 'Bras';

  @override
  String get groupCore => 'Abdominaux';

  @override
  String exerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercices',
      one: '1 exercice',
    );
    return '$_temp0';
  }

  @override
  String get barbellSwitch => 'Avec barre olympique (calcul des disques)';

  @override
  String get noCalculatorHint =>
      'Pas de barre pour cet exercice : note la charge, les répétitions et les tours, et garde son historique.';

  @override
  String get iCloudSyncTitle => 'Sauvegarde iCloud';

  @override
  String get iCloudSyncOn =>
      'Vos données sont sauvegardées dans iCloud et restaurées automatiquement sur un nouvel iPhone avec le même identifiant Apple.';

  @override
  String get iCloudSyncOff =>
      'iCloud n\'est pas disponible. Connectez-vous à iCloud dans Réglages pour sauvegarder vos données.';

  @override
  String get iCloudRestored => 'Données restaurées depuis iCloud';

  @override
  String get tabCalc => 'Calculatrice';

  @override
  String get tabTrain => 'Entraîner';

  @override
  String get tabProgress => 'Progrès';

  @override
  String get tabCoach => 'Coach';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get save => 'Enregistrer';

  @override
  String get rename => 'Renommer';

  @override
  String get workoutStartFree => 'Commencer un entraînement';

  @override
  String get workoutResume => 'Reprendre l\'entraînement en cours';

  @override
  String get workoutFree => 'Entraînement';

  @override
  String get workoutAddExercise => 'Ajouter un exercice';

  @override
  String get workoutRemoveExercise => 'Retirer l\'exercice';

  @override
  String get workoutAddSet => 'Ajouter une série';

  @override
  String get workoutReps => 'Reps';

  @override
  String get workoutPlates => 'Disques pour cette série';

  @override
  String get workoutSetDone => 'Série faite';

  @override
  String get workoutNotes => 'Notes';

  @override
  String get workoutFinish => 'Terminer l\'entraînement';

  @override
  String get workoutDiscard => 'Abandonner l\'entraînement';

  @override
  String get workoutDiscardTitle => 'Abandonner cet entraînement ?';

  @override
  String get workoutNoSetsTitle => 'Aucune série faite';

  @override
  String get workoutNoSetsBody => 'Coche les séries faites avec le cercle pour les enregistrer.';

  @override
  String get workoutDeleteTitle => 'Supprimer cet entraînement ?';

  @override
  String workoutPercentOfRm(String percent) {
    return '$percent % du 1RM';
  }

  @override
  String get restLabel => 'Repos';

  @override
  String get restSkip => 'Passer';

  @override
  String get restDefault => 'Repos entre les séries';

  @override
  String get summaryTitle => 'Entraînement enregistré 💪';

  @override
  String get summaryTitlePr => 'Nouveau record personnel ! 🏆';

  @override
  String summaryStats(int sets, String volume, String unit) {
    return '$sets séries · $volume $unit soulevés';
  }

  @override
  String prHeaviest(String weight, String unit) {
    return 'le plus lourd à ce jour, $weight $unit';
  }

  @override
  String prEstimated(String weight, String unit) {
    return 'meilleur 1RM estimé, $weight $unit';
  }

  @override
  String get sendToCoach => 'Envoyer au coach';

  @override
  String get athleteNameTitle => 'Ton nom';

  @override
  String get athleteNameHint => 'Pour que ton coach sache que c’est toi';

  @override
  String get resultShareTitle => 'Ton résultat';

  @override
  String resultShareSubtitle(String coach) {
    return 'Montre ce QR à $coach ou envoie le code par message.';
  }

  @override
  String get draftReplaceTitle => 'Entraînement en cours';

  @override
  String get draftReplaceBody =>
      'Tu as un entraînement non terminé. En commencer un nouveau et l\'abandonner ?';

  @override
  String setsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count séries',
      one: '1 série',
    );
    return '$_temp0';
  }

  @override
  String get myPlans => 'Mes plans';

  @override
  String get myPlansEmpty =>
      'Crée une routine, utilise un programme ci-dessous ou importe celui de ton coach.';

  @override
  String get planCreate => 'Créer une routine';

  @override
  String get importPlanShort => 'Plan du coach';

  @override
  String get importPlanTitle => 'Importer le plan du coach';

  @override
  String importPlanDone(String name) {
    return 'Plan « $name » ajouté';
  }

  @override
  String get importInvalid => 'Ce code n\'est pas valide. Vérifie qu\'il a été copié en entier.';

  @override
  String get templatesTitle => 'Programmes en pourcentage';

  @override
  String get historyTitle => 'Historique';

  @override
  String get historyWorkoutsEmpty => 'Tes entraînements terminés apparaîtront ici.';

  @override
  String get planUntitled => 'Plan sans nom';

  @override
  String planFromCoach(String coach) {
    return 'Coach $coach';
  }

  @override
  String planProgress(int done, int total) {
    return '$done sur $total jours faits';
  }

  @override
  String planDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get planShare => 'Partager avec QR';

  @override
  String planShareTitle(String name) {
    return 'Partager « $name »';
  }

  @override
  String get planShareSubtitle =>
      'Tes athlètes le scannent dans Plate Calc → Entraîner → Plan du coach. Les charges sont calculées avec le 1RM de chacun.';

  @override
  String planStartNext(String day) {
    return 'Commencer : $day';
  }

  @override
  String get planStartDay => 'Commencer ce jour';

  @override
  String get planNoRm => 'pas de 1RM';

  @override
  String planDeleteTitle(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String planWeekDay(int week, String day) {
    return 'Semaine $week · Jour $day';
  }

  @override
  String planDayDefault(int n) {
    return 'Jour $n';
  }

  @override
  String get planOlyName => 'Haltérophilie · 4 semaines';

  @override
  String get planOlyNotes => '3 jours par semaine. Arraché, épaulé-jeté et squats en % de ton 1RM.';

  @override
  String get planStrengthName => 'Force 5/3/1 · 4 semaines';

  @override
  String get planStrengthNotes =>
      '4 jours par semaine : squat, développé couché, soulevé de terre et press. La semaine 4 est une décharge.';

  @override
  String get planEditorTitle => 'Routine';

  @override
  String get planNameLabel => 'Nom';

  @override
  String get planNameHint => 'Ex. : WOD lundi, Cycle de squat';

  @override
  String get planNotesLabel => 'Notes pour les athlètes (facultatif)';

  @override
  String get planNameRequired => 'Donne-lui un nom';

  @override
  String get planNeedsExercise => 'Ajoute au moins un exercice';

  @override
  String get planAddExercise => 'Ajouter un exercice';

  @override
  String get planAddDay => 'Ajouter un jour';

  @override
  String get planDayName => 'Nom du jour';

  @override
  String get planDayDuplicate => 'Dupliquer';

  @override
  String get planSets => 'Séries';

  @override
  String get planLoadPercent => '% 1RM';

  @override
  String get planLoadWeight => 'Charge';

  @override
  String get planLoadFree => 'Libre';

  @override
  String get planPercentLabel => 'Pourcentage du 1RM';

  @override
  String get planWeightLabel => 'Charge fixe';

  @override
  String get pickExerciseHint => 'Cherche ou écris un nouvel exercice';

  @override
  String pickExerciseNew(String name) {
    return 'Utiliser « $name »';
  }

  @override
  String get shareCopyCode => 'Copier le code';

  @override
  String get shareCopied => 'Code copié. Colle-le dans WhatsApp, un courriel…';

  @override
  String get shareHowTo => 'L\'autre personne ouvre Plate Calc et scanne le QR ou colle le code.';

  @override
  String get shareScanQr => 'Scanner le QR';

  @override
  String get sharePasteLabel => 'Ou colle le code';

  @override
  String get sharePaste => 'Coller';

  @override
  String get shareImport => 'Importer';

  @override
  String get shareCameraError =>
      'Impossible d\'ouvrir la caméra. Autorise l\'accès à la caméra pour Plate Calc dans Réglages, ou colle le code.';

  @override
  String get statStreak => 'semaines de suite';

  @override
  String get statThisMonth => 'ce mois-ci';

  @override
  String get statTotal => 'au total';

  @override
  String get e1rmCalcTitle => '1RM estimé';

  @override
  String get e1rmCalcHelp => 'Charge et répétitions d\'une série difficile (formule d\'Epley).';

  @override
  String get e1rmWeight => 'Charge';

  @override
  String e1rmResult(String weight, String unit) {
    return '≈ $weight $unit';
  }

  @override
  String e1rmShort(String weight, String unit) {
    return '1RMe $weight $unit';
  }

  @override
  String get recordsTitle => 'Records personnels';

  @override
  String get recordsEmpty => 'Termine un entraînement pour voir tes records et graphiques.';

  @override
  String recordHeaviest(String weight, String unit) {
    return 'Max $weight $unit';
  }

  @override
  String currentRm(String weight, String unit) {
    return '1RM enregistré : $weight $unit';
  }

  @override
  String get metricE1rm => '1RM est.';

  @override
  String get metricHeaviest => 'Max';

  @override
  String get metricVolume => 'Volume';

  @override
  String get chartNeedsMore =>
      'Il faut au moins 2 entraînements avec cet exercice pour voir le graphique.';

  @override
  String get coachProfile => 'Profil du coach';

  @override
  String get coachNameLabel => 'Ton nom';

  @override
  String get coachBoxLabel => 'Box ou gym';

  @override
  String get coachSetupTitle => 'Configure ton profil de coach';

  @override
  String get coachSetupSubtitle => 'Ton nom et ta box apparaissent sur les plans partagés';

  @override
  String get coachDefaultName => 'Coach';

  @override
  String get coachHowItWorks =>
      '1. Crée un plan ou WOD en % du 1RM.\n2. Partage-le avec un QR : chaque athlète voit ses propres charges.\n3. Après la séance, ils t’envoient leur résultat avec un autre QR.';

  @override
  String get coachPlansTitle => 'Plans pour ta box';

  @override
  String get coachCreatePlan => 'Créer un plan ou WOD';

  @override
  String get coachAthletesTitle => 'Athlètes';

  @override
  String get coachAthletesEmpty => 'Quand un athlète t’envoie un résultat, il apparaîtra ici.';

  @override
  String get importResultTitle => 'Recevoir le résultat d\'un athlète';

  @override
  String importResultDone(String name) {
    return 'Résultat de $name enregistré';
  }

  @override
  String get importResultDuplicate => 'Tu avais déjà ce résultat';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entraînements',
      one: '1 entraînement',
    );
    return '$_temp0';
  }

  @override
  String lastWorkout(String date) {
    return 'dernier $date';
  }

  @override
  String athleteDeleteTitle(String name) {
    return 'Supprimer $name et ses résultats ?';
  }

  @override
  String get keyboardDone => 'OK';

  @override
  String get optional => 'Facultatif';

  @override
  String get progressIntroTitle => 'À quoi sert cet onglet ?';

  @override
  String get progressIntroBody =>
      'Il montre comment tu progresses. Il se remplit tout seul avec les entraînements terminés dans l’onglet Entraîner : jours entraînés, records et un graphique par exercice.';

  @override
  String get progressGoTrain => 'Aller à Entraîner';

  @override
  String get progressConsistencyTitle => 'Régularité';

  @override
  String get progressConsistencyHelp =>
      'Semaines de suite avec au moins un entraînement, et combien tu en as fait.';

  @override
  String get progressCalendarTitle => 'Calendrier';

  @override
  String get progressCalendarHelp =>
      'Les jours en couleur sont ceux où tu t’es entraîné. Touche-en un pour voir la séance.';

  @override
  String get progressRecordsHelp =>
      'Ta meilleure marque pour chaque exercice. Touche-en un pour voir son graphique.';

  @override
  String e1rmExample(String weight, String result) {
    return 'Exemple : $weight pour 5 reps ≈ 1RM de $result';
  }

  @override
  String get simpleWeightLabel => 'Charge';

  @override
  String get simpleWeightHelp => 'Laisse vide pour le poids du corps';

  @override
  String get simpleRepsLabel => 'Répétitions faites';

  @override
  String get simpleRoundsLabel => 'Tours';

  @override
  String simpleLastEntry(String entry) {
    return 'Dernier : $entry';
  }

  @override
  String get saveSetButton => 'Enregistrer';

  @override
  String get saveSetInvalidSnack => 'Indique les répétitions faites (ou une charge).';

  @override
  String saveSetOkSnack(String movementName) {
    return 'Enregistré pour $movementName.';
  }

  @override
  String get bodyweight => 'Poids du corps';

  @override
  String setsRepsLine(String weight, int reps) {
    return '$weight × $reps reps';
  }

  @override
  String roundsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tours',
      one: '1 tour',
    );
    return '$_temp0';
  }

  @override
  String get tabToday => 'Aujourd\'hui';

  @override
  String get tabBox => 'Box';

  @override
  String get tabPlates => 'Disques';

  @override
  String get todayInProgress => 'En cours';

  @override
  String get todayResume => 'Reprendre';

  @override
  String get todayNext => 'Prochaine séance';

  @override
  String get todayNoPlanBody =>
      'Aucun plan actif. Choisis un programme ci-dessous, crée une routine ou scanne le plan de ton coach.';

  @override
  String get todayFreeWorkout => 'Ou commence un entraînement libre';

  @override
  String get todayRecent => 'Récents';

  @override
  String get seeAll => 'Tout voir';

  @override
  String get colSet => 'SÉRIE';

  @override
  String get colPrevious => 'PRÉCÉDENT';

  @override
  String get workoutFinishShort => 'Terminer';

  @override
  String get styleCrossfit => 'Crosstraining';

  @override
  String get styleHaltero => 'Haltérophilie';

  @override
  String get styleGym => 'Gym';

  @override
  String get styleCrossfitDesc => 'WOD du jour : AMRAP, EMOM, For Time';

  @override
  String get styleHalteroDesc => 'Arraché, épaulé-jeté et squats en % du 1RM';

  @override
  String get styleGymDesc => 'Push / Pull / Legs';

  @override
  String get stylesTitle => 'Qu’est-ce que tu entraînes ?';

  @override
  String get stylesFirstTitle => 'Un entraînement chaque jour';

  @override
  String get stylesFirstBody =>
      'Choisis ce que tu entraînes et tu auras une séance chaque jour, avec tes charges selon ton 1RM.';

  @override
  String get stylesChoose => 'Choisir';

  @override
  String get todayStart => 'Commencer';

  @override
  String get todayDone => 'Fait';

  @override
  String get crossfitOfficialWod => 'WOD officiel de CrossFit.com';

  @override
  String get wodGo => 'Démarrer';

  @override
  String get wodPause => 'Pause';

  @override
  String get wodContinue => 'Reprendre';

  @override
  String get wodRound => 'Tour';

  @override
  String get wodScoreTitle => 'Ton résultat';

  @override
  String get wodScoreTime => 'Temps (mm:ss)';

  @override
  String get wodScoreRounds => 'Tours';

  @override
  String get wodScoreReps => '+ reps';

  @override
  String wodSaved(String score) {
    return 'Enregistré : $score';
  }

  @override
  String get wodResultsTitle => 'Résultats de WOD';

  @override
  String get progressEmpty => 'Termine ton premier entraînement pour voir ton progrès ici.';

  @override
  String get statThisWeek => 'cette semaine';

  @override
  String get chartThisWeek => 'Cette semaine';

  @override
  String chartWeeksAgo(int n) {
    return 'Il y a $n sem';
  }

  @override
  String get metricE1rmLong => 'Meilleur 1RM estimé';

  @override
  String get metricHeaviestLong => 'Charge maximale';

  @override
  String get todayOther => 'Autre';

  @override
  String get scanButton => 'Photo du tableau';

  @override
  String get scanCamera => 'Prendre une photo';

  @override
  String get scanGallery => 'Choisir dans les photos';

  @override
  String get scanReading => 'Lecture du tableau…';

  @override
  String get scanNothing =>
      'Aucun exercice trouvé. Réessaie avec plus de lumière et tout le tableau dans la photo.';

  @override
  String get scanPermission =>
      'Impossible d\'ouvrir la caméra. Autorise l\'accès pour Plate Calc dans Réglages.';

  @override
  String get scanTitle => 'Tableau';

  @override
  String get scanDefaultName => 'WOD du tableau';

  @override
  String get scanCheck =>
      'Vérifie avant de commencer : change le format ou retire ce qui a été mal lu.';

  @override
  String get scanRetake => 'Prendre une autre photo';

  @override
  String get scanTapToEdit => 'Touche un exercice pour le corriger.';

  @override
  String get scanRawText => 'Texte lu sur la photo';

  @override
  String get scanRepsLabel => 'Reps / distance / calories';

  @override
  String get scanMoveLabel => 'Exercice';

  @override
  String get scanRxLabel => 'Charge Rx (facultatif)';

  @override
  String get scanByAi => '✦ LU PAR IA';

  @override
  String get aiConsentTitle => 'Lire le tableau avec l’IA ?';

  @override
  String get aiConsentBody =>
      'Pour lire le tableau, Plate Calc envoie la photo à Google Gemini (le service d’IA de Google) via notre serveur. Google peut l’utiliser pour améliorer ses produits. Nous ne conservons pas la photo et ne l’associons pas à toi.\n\nSi tu préfères, l’app la lit seulement sur ton téléphone (moins précis). Tu peux changer ça dans Réglages.';

  @override
  String get aiConsentYes => 'Utiliser l’IA';

  @override
  String get aiConsentNo => 'Seulement sur mon téléphone';

  @override
  String get aiSettingTitle => 'Photos du tableau';

  @override
  String get aiSettingSwitch => 'Lire avec l’IA (Google Gemini)';

  @override
  String get aiSettingHelp =>
      'La photo est envoyée à Google pour la lire. Désactivé : lecture seulement sur ce téléphone.';

  @override
  String get detailDuration => 'Durée';

  @override
  String get detailResult => 'Résultat';

  @override
  String get detailMovements => 'Mouvements';

  @override
  String get detailExercises => 'Exercices';

  @override
  String get freeWorkoutRow => 'Entraînement libre';

  @override
  String get yourRms => 'Vos 1RM';

  @override
  String get yourRmsEmpty =>
      'Enregistrez votre 1RM sur un mouvement et il apparaîtra ici, à un toucher du calculateur.';

  @override
  String get tabPlan => 'Plan';

  @override
  String get planEmptyTitle => 'Votre semaine, en un PDF';

  @override
  String get planEmptyBody =>
      'Importez la programmation envoyée par votre coach ou votre box. L\'IA la lit et prépare chaque jour d\'entraînement.';

  @override
  String get planUpload => 'Importer le PDF du plan';

  @override
  String get planReplace => 'Nouveau PDF';

  @override
  String get planReplaceHint =>
      'Quand le plan de la semaine suivante arrive, importez-le pour remplacer celui-ci.';

  @override
  String get planReading => 'Lecture de votre plan… cela peut prendre jusqu\'à une minute.';

  @override
  String planWeekOf(String date) {
    return 'Semaine du $date';
  }

  @override
  String get planRestDay => 'Jour de repos';

  @override
  String get planRestBody => 'Aucun entraînement prévu ce jour-là.';

  @override
  String get planErrorOffline =>
      'Impossible de lire le plan. Vérifiez votre connexion et réessayez.';

  @override
  String get planErrorTooLarge =>
      'Le PDF dépasse 3 Mo. Exportez une version plus légère et réessayez.';

  @override
  String get planErrorUnreadable =>
      'Je n\'ai trouvé aucun entraînement dans ce PDF. Est-ce bien la programmation de la semaine ?';

  @override
  String get planAiOff => 'La lecture par IA n\'est pas disponible dans cette version.';

  @override
  String get planAiDeclined => 'Pour lire le PDF, activez la lecture par IA dans les Réglages.';

  @override
  String get planReplaceTitle => 'Remplacer le plan ?';

  @override
  String get planReplaceBody =>
      'Le plan actuel est supprimé. Ce que vous avez déjà fait reste dans l\'historique.';

  @override
  String get planReplaceConfirm => 'Remplacer';

  @override
  String get planReadByAi =>
      'Lu par IA. Vérifiez les charges et les répétitions avant de commencer.';

  @override
  String get barCenterLabel => 'CENTRE';

  @override
  String get orOption => 'ou';
}

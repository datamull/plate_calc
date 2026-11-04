// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Plate Calculator';

  @override
  String get unitsLabel => 'Units:';

  @override
  String get barLabel => 'Bar';

  @override
  String get collarsLabel => 'Collars';

  @override
  String get interpretRmAs => 'Interpret RM% as:';

  @override
  String get modeTotalInclBar => 'Total (includes bar)';

  @override
  String get modePerSide => 'Per side (without bar)';

  @override
  String get rmFieldNoMovement => 'Your 1RM';

  @override
  String rmFieldWithMovement(String movementName) {
    return '$movementName 1RM';
  }

  @override
  String get percentLabel => 'Percent';

  @override
  String derivedTargetLabel(String percent) {
    return 'Target derived from $percent% RM:';
  }

  @override
  String derivedTotal(String weight, String units) {
    return 'TOTAL: $weight $units';
  }

  @override
  String derivedPerSide(String weight, String units) {
    return 'PER SIDE (plates): $weight $units';
  }

  @override
  String get percentTableTitle => 'Percentage table (tap to apply)';

  @override
  String get percentTableHeaderPercent => '%';

  @override
  String get percentTableHeaderTotal => 'Total';

  @override
  String get percentTableHeaderPerSide => 'Per side (without bar)';

  @override
  String get calculateButton => 'Calculate plate distribution';

  @override
  String get historyButton => 'RM History';

  @override
  String historySheetTitle(String movementName, String units) {
    return 'RM History — $movementName ($units)';
  }

  @override
  String get historyClear => 'Clear';

  @override
  String get historyEmpty => 'No records yet. Save an RM to create entries.';

  @override
  String get historyClearedSnack => 'History cleared.';

  @override
  String historyRowRm(String rm, String units) {
    return 'RM: $rm $units';
  }

  @override
  String get saveRmTooltip => 'Save RM';

  @override
  String get saveRmInvalidSnack => 'Enter a valid RM before saving.';

  @override
  String saveRmOkSnack(String movementName, String units) {
    return 'RM saved for $movementName ($units).';
  }

  @override
  String get deleteMovementDialogTitle => 'Delete movement';

  @override
  String deleteMovementDialogContent(String movementName) {
    return 'Delete \"$movementName\" completely? It will be removed along with its RM/History.';
  }

  @override
  String get deleteMovementCancel => 'Cancel';

  @override
  String get deleteMovementConfirm => 'Delete';

  @override
  String deleteMovementButton(String movementName) {
    return 'Delete $movementName';
  }

  @override
  String deleteMovementOkSnack(String movementName) {
    return 'Movement deleted: $movementName';
  }

  @override
  String get deleteMovementFailSnack => 'Could not delete movement.';

  @override
  String get errorPercentInvalid => 'Enter a valid percentage (> 0).';

  @override
  String get errorTargetTooLow => 'Target is below bar weight or the data is invalid.';

  @override
  String get panelCloseTooltip => 'Close';

  @override
  String resultExact(String weight, String units) {
    return 'Reached: $weight $units (exact)';
  }

  @override
  String resultApprox(String weight, String shortfall, String units) {
    return 'Best approximation: $weight $units (short by $shortfall $units)';
  }

  @override
  String get chosenDiscsTitle => 'Chosen discs (total):';

  @override
  String get yourLiftsTitle => 'Your lifts';

  @override
  String get addLiftTitle => 'Add movement';

  @override
  String get addLiftHint => 'Ex: Front Squat';

  @override
  String get saveLabel => 'Save';

  @override
  String get noRmLabel => 'No RM';

  @override
  String get deleteRecordTooltip => 'Delete record';

  @override
  String get clearHistoryDialogTitle => 'Clear history';

  @override
  String get clearHistoryDialogContent => 'Delete all history for this lift?';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTabLanguage => 'Language';

  @override
  String get settingsTabInventory => 'Inventory';

  @override
  String get settingsLanguageTitle => 'App Language';

  @override
  String get settingsLanguageSystem => 'Use system language';

  @override
  String get settingsLanguageSpanish => 'Spanish';

  @override
  String get settingsLanguageFrench => 'French';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get inventoryKgTitle => 'Plates in kg';

  @override
  String get inventoryLbTitle => 'Plates in lb';

  @override
  String get inventorySaveButton => 'Save inventory';

  @override
  String get liftAlreadyExists => 'That movement already exists.';

  @override
  String get errorRmMissing => 'Enter your 1RM.';

  @override
  String get inventorySavedSnack => 'Inventory saved.';

  @override
  String get inventoryAddPlate => 'Add plate';

  @override
  String get inventoryAddPlateHint => 'Plate weight';

  @override
  String get inventoryDeletePlateHint => 'Long-press a plate to remove it.';

  @override
  String inventoryRemovePlate(String weight, String units) {
    return 'Remove the $weight $units plate?';
  }

  @override
  String get inventoryReset => 'Restore defaults';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get resultBarOnly => 'Just the bar, no plates.';

  @override
  String get converterTitle => 'Unit converter';

  @override
  String get converterTooltip => 'Unit converter';

  @override
  String get lbLabel => 'Pounds (lb)';

  @override
  String get kgLabel => 'Kilograms (kg)';

  @override
  String get quickPlatesTitle => 'Quick plate equivalents';

  @override
  String get chooseIconTitle => 'Choose an icon';

  @override
  String get chooseIconTooltip => 'Change icon';

  @override
  String get iconAuto => 'Automatic (by name)';

  @override
  String get categoryHaltero => 'Weightlifting';

  @override
  String get categoryHalteroSubtitle => 'Olympic lifts and your movements';

  @override
  String get categoryGym => 'Gym';

  @override
  String get categoryGymSubtitle => 'Exercises by muscle group';

  @override
  String get groupChest => 'Chest';

  @override
  String get groupBack => 'Back';

  @override
  String get groupLegs => 'Legs';

  @override
  String get groupShoulders => 'Shoulders';

  @override
  String get groupArms => 'Arms';

  @override
  String get groupCore => 'Core';

  @override
  String exerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
    );
    return '$_temp0';
  }

  @override
  String get barbellSwitch => 'Uses an Olympic barbell (plate calculator)';

  @override
  String get noCalculatorHint =>
      'No plate calculator for this exercise: just save your 1RM and keep its history.';

  @override
  String get iCloudSyncTitle => 'iCloud backup';

  @override
  String get iCloudSyncOn =>
      'Your data is saved to iCloud and restored automatically on a new iPhone with the same Apple ID.';

  @override
  String get iCloudSyncOff =>
      'iCloud is not available. Sign in to iCloud in Settings to back up your data.';

  @override
  String get iCloudRestored => 'Data restored from iCloud';

  @override
  String get tabCalc => 'Calculator';

  @override
  String get tabTrain => 'Train';

  @override
  String get tabProgress => 'Progress';

  @override
  String get tabCoach => 'Coach';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get save => 'Save';

  @override
  String get rename => 'Rename';

  @override
  String get workoutStartFree => 'Start a workout';

  @override
  String get workoutResume => 'Resume workout in progress';

  @override
  String get workoutFree => 'Workout';

  @override
  String get workoutAddExercise => 'Add exercise';

  @override
  String get workoutRemoveExercise => 'Remove exercise';

  @override
  String get workoutAddSet => 'Add set';

  @override
  String get workoutReps => 'Reps';

  @override
  String get workoutPlates => 'Plates for this set';

  @override
  String get workoutSetDone => 'Set done';

  @override
  String get workoutNotes => 'Notes';

  @override
  String get workoutFinish => 'Finish workout';

  @override
  String get workoutDiscard => 'Discard workout';

  @override
  String get workoutDiscardTitle => 'Discard this workout?';

  @override
  String get workoutNoSetsTitle => 'No sets done';

  @override
  String get workoutNoSetsBody => 'Mark sets as done with the circle to save them.';

  @override
  String get workoutDeleteTitle => 'Delete this workout?';

  @override
  String workoutPercentOfRm(String percent) {
    return '$percent% of 1RM';
  }

  @override
  String get restLabel => 'Rest';

  @override
  String get restSkip => 'Skip';

  @override
  String get restDefault => 'Rest time between sets';

  @override
  String get summaryTitle => 'Workout saved 💪';

  @override
  String get summaryTitlePr => 'New personal record! 🏆';

  @override
  String summaryStats(int sets, String volume, String unit) {
    return '$sets sets · $volume $unit lifted';
  }

  @override
  String prHeaviest(String weight, String unit) {
    return 'heaviest ever, $weight $unit';
  }

  @override
  String prEstimated(String weight, String unit) {
    return 'best estimated 1RM, $weight $unit';
  }

  @override
  String get sendToCoach => 'Send to coach';

  @override
  String get athleteNameTitle => 'Your name';

  @override
  String get athleteNameHint => 'So your coach knows it is you';

  @override
  String get resultShareTitle => 'Your result';

  @override
  String resultShareSubtitle(String coach) {
    return 'Show this QR to $coach or send the code by message.';
  }

  @override
  String get draftReplaceTitle => 'Workout in progress';

  @override
  String get draftReplaceBody => 'You have an unfinished workout. Start a new one and discard it?';

  @override
  String setsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets',
      one: '1 set',
    );
    return '$_temp0';
  }

  @override
  String get myPlans => 'My plans';

  @override
  String get myPlansEmpty => 'Create a routine, use a program below or import one from your coach.';

  @override
  String get planCreate => 'Create routine';

  @override
  String get importPlanShort => 'Coach plan';

  @override
  String get importPlanTitle => 'Import plan from coach';

  @override
  String importPlanDone(String name) {
    return 'Plan \"$name\" added';
  }

  @override
  String get importInvalid => 'That code is not valid. Check that it was copied complete.';

  @override
  String get templatesTitle => 'Percentage programs';

  @override
  String get historyTitle => 'History';

  @override
  String get historyWorkoutsEmpty => 'Your finished workouts will appear here.';

  @override
  String get planUntitled => 'Untitled plan';

  @override
  String planFromCoach(String coach) {
    return 'Coach $coach';
  }

  @override
  String planProgress(int done, int total) {
    return '$done of $total days done';
  }

  @override
  String planDaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get planShare => 'Share with QR';

  @override
  String planShareTitle(String name) {
    return 'Share \"$name\"';
  }

  @override
  String get planShareSubtitle =>
      'Your athletes scan it in Plate Calc → Train → Coach plan. Weights are calculated with each one\'s 1RM.';

  @override
  String planStartNext(String day) {
    return 'Start: $day';
  }

  @override
  String get planStartDay => 'Start this day';

  @override
  String get planNoRm => 'no 1RM saved';

  @override
  String planDeleteTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String planWeekDay(int week, String day) {
    return 'Week $week · Day $day';
  }

  @override
  String planDayDefault(int n) {
    return 'Day $n';
  }

  @override
  String get planOlyName => 'Weightlifting · 4 weeks';

  @override
  String get planOlyNotes => '3 days a week. Snatch, clean & jerk and squats by % of your 1RM.';

  @override
  String get planStrengthName => 'Strength 5/3/1 · 4 weeks';

  @override
  String get planStrengthNotes =>
      '4 days a week: squat, bench, deadlift and press. Week 4 is a deload.';

  @override
  String get planEditorTitle => 'Routine';

  @override
  String get planNameLabel => 'Name';

  @override
  String get planNameHint => 'E.g. Monday WOD, Squat cycle';

  @override
  String get planNotesLabel => 'Notes for athletes (optional)';

  @override
  String get planNameRequired => 'Give it a name';

  @override
  String get planNeedsExercise => 'Add at least one exercise';

  @override
  String get planAddExercise => 'Add exercise';

  @override
  String get planAddDay => 'Add day';

  @override
  String get planDayName => 'Day name';

  @override
  String get planDayDuplicate => 'Duplicate';

  @override
  String get planSets => 'Sets';

  @override
  String get planLoadPercent => '% 1RM';

  @override
  String get planLoadWeight => 'Weight';

  @override
  String get planLoadFree => 'Free';

  @override
  String get planPercentLabel => 'Percentage of 1RM';

  @override
  String get planWeightLabel => 'Fixed weight';

  @override
  String get pickExerciseHint => 'Search or type a new exercise';

  @override
  String pickExerciseNew(String name) {
    return 'Use \"$name\"';
  }

  @override
  String get shareCopyCode => 'Copy code';

  @override
  String get shareCopied => 'Code copied. Paste it in WhatsApp, an email…';

  @override
  String get shareHowTo => 'The other person opens Plate Calc and scans the QR or pastes the code.';

  @override
  String get shareScanQr => 'Scan QR';

  @override
  String get sharePasteLabel => 'Or paste the code';

  @override
  String get sharePaste => 'Paste';

  @override
  String get shareImport => 'Import';

  @override
  String get shareCameraError =>
      'Cannot open the camera. Allow camera access for Plate Calc in Settings, or paste the code.';

  @override
  String get statStreak => 'weeks in a row';

  @override
  String get statThisMonth => 'this month';

  @override
  String get statTotal => 'workouts';

  @override
  String get e1rmCalcTitle => 'Estimated 1RM';

  @override
  String get e1rmCalcHelp => 'Weight and reps of a hard set (Epley formula).';

  @override
  String get e1rmWeight => 'Weight';

  @override
  String e1rmResult(String weight, String unit) {
    return '≈ $weight $unit';
  }

  @override
  String e1rmShort(String weight, String unit) {
    return 'e1RM $weight $unit';
  }

  @override
  String get recordsTitle => 'Personal records';

  @override
  String get recordsEmpty => 'Finish a workout to see your records and charts.';

  @override
  String recordHeaviest(String weight, String unit) {
    return 'Max $weight $unit';
  }

  @override
  String currentRm(String weight, String unit) {
    return 'Saved 1RM: $weight $unit';
  }

  @override
  String get metricE1rm => 'Est. 1RM';

  @override
  String get metricHeaviest => 'Max';

  @override
  String get metricVolume => 'Volume';

  @override
  String get chartNeedsMore => 'You need at least 2 workouts with this exercise to see the chart.';

  @override
  String get coachProfile => 'Coach profile';

  @override
  String get coachNameLabel => 'Your name';

  @override
  String get coachBoxLabel => 'Box or gym';

  @override
  String get coachSetupTitle => 'Set up your coach profile';

  @override
  String get coachSetupSubtitle => 'Name and box appear on the plans you share';

  @override
  String get coachDefaultName => 'Coach';

  @override
  String get coachHowItWorks =>
      '1. Create a plan or WOD with % of 1RM.\n2. Share it with a QR: each athlete gets their own weights.\n3. After training, they send you their result with another QR.';

  @override
  String get coachPlansTitle => 'Plans for your box';

  @override
  String get coachCreatePlan => 'Create plan or WOD';

  @override
  String get coachAthletesTitle => 'Athletes';

  @override
  String get coachAthletesEmpty => 'When an athlete sends you a result, they will appear here.';

  @override
  String get importResultTitle => 'Receive athlete result';

  @override
  String importResultDone(String name) {
    return 'Result from $name saved';
  }

  @override
  String get importResultDuplicate => 'You already had this result';

  @override
  String resultsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workouts',
      one: '1 workout',
    );
    return '$_temp0';
  }

  @override
  String lastWorkout(String date) {
    return 'last $date';
  }

  @override
  String athleteDeleteTitle(String name) {
    return 'Delete $name and their results?';
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('es'), Locale('fr')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Plate Calculator'**
  String get appTitle;

  /// No description provided for @unitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Units:'**
  String get unitsLabel;

  /// No description provided for @barLabel.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get barLabel;

  /// No description provided for @collarsLabel.
  ///
  /// In en, this message translates to:
  /// **'Collars'**
  String get collarsLabel;

  /// No description provided for @interpretRmAs.
  ///
  /// In en, this message translates to:
  /// **'Interpret RM% as:'**
  String get interpretRmAs;

  /// No description provided for @modeTotalInclBar.
  ///
  /// In en, this message translates to:
  /// **'Total (includes bar)'**
  String get modeTotalInclBar;

  /// No description provided for @modePerSide.
  ///
  /// In en, this message translates to:
  /// **'Per side (without bar)'**
  String get modePerSide;

  /// No description provided for @rmFieldNoMovement.
  ///
  /// In en, this message translates to:
  /// **'Your 1RM'**
  String get rmFieldNoMovement;

  /// Label when a movement name exists
  ///
  /// In en, this message translates to:
  /// **'{movementName} 1RM'**
  String rmFieldWithMovement(String movementName);

  /// No description provided for @percentLabel.
  ///
  /// In en, this message translates to:
  /// **'Percent'**
  String get percentLabel;

  /// No description provided for @derivedTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target derived from {percent}% RM:'**
  String derivedTargetLabel(String percent);

  /// No description provided for @derivedTotal.
  ///
  /// In en, this message translates to:
  /// **'TOTAL: {weight} {units}'**
  String derivedTotal(String weight, String units);

  /// No description provided for @derivedPerSide.
  ///
  /// In en, this message translates to:
  /// **'PER SIDE (plates): {weight} {units}'**
  String derivedPerSide(String weight, String units);

  /// No description provided for @percentTableTitle.
  ///
  /// In en, this message translates to:
  /// **'Percentage table (tap to apply)'**
  String get percentTableTitle;

  /// No description provided for @percentTableHeaderPercent.
  ///
  /// In en, this message translates to:
  /// **'%'**
  String get percentTableHeaderPercent;

  /// No description provided for @percentTableHeaderTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get percentTableHeaderTotal;

  /// No description provided for @percentTableHeaderPerSide.
  ///
  /// In en, this message translates to:
  /// **'Per side (without bar)'**
  String get percentTableHeaderPerSide;

  /// No description provided for @calculateButton.
  ///
  /// In en, this message translates to:
  /// **'Calculate plate distribution'**
  String get calculateButton;

  /// No description provided for @historyButton.
  ///
  /// In en, this message translates to:
  /// **'RM History'**
  String get historyButton;

  /// No description provided for @historySheetTitle.
  ///
  /// In en, this message translates to:
  /// **'RM History — {movementName} ({units})'**
  String historySheetTitle(String movementName, String units);

  /// No description provided for @historyClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get historyClear;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No records yet. Save an RM to create entries.'**
  String get historyEmpty;

  /// No description provided for @historyClearedSnack.
  ///
  /// In en, this message translates to:
  /// **'History cleared.'**
  String get historyClearedSnack;

  /// No description provided for @historyRowRm.
  ///
  /// In en, this message translates to:
  /// **'RM: {rm} {units}'**
  String historyRowRm(String rm, String units);

  /// No description provided for @saveRmTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save RM'**
  String get saveRmTooltip;

  /// No description provided for @saveRmInvalidSnack.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid RM before saving.'**
  String get saveRmInvalidSnack;

  /// No description provided for @saveRmOkSnack.
  ///
  /// In en, this message translates to:
  /// **'RM saved for {movementName} ({units}).'**
  String saveRmOkSnack(String movementName, String units);

  /// No description provided for @deleteMovementDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete movement'**
  String get deleteMovementDialogTitle;

  /// No description provided for @deleteMovementDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{movementName}\" completely? It will be removed along with its RM/History.'**
  String deleteMovementDialogContent(String movementName);

  /// No description provided for @deleteMovementCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get deleteMovementCancel;

  /// No description provided for @deleteMovementConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteMovementConfirm;

  /// No description provided for @deleteMovementButton.
  ///
  /// In en, this message translates to:
  /// **'Delete {movementName}'**
  String deleteMovementButton(String movementName);

  /// No description provided for @deleteMovementOkSnack.
  ///
  /// In en, this message translates to:
  /// **'Movement deleted: {movementName}'**
  String deleteMovementOkSnack(String movementName);

  /// No description provided for @deleteMovementFailSnack.
  ///
  /// In en, this message translates to:
  /// **'Could not delete movement.'**
  String get deleteMovementFailSnack;

  /// No description provided for @errorPercentInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid percentage (> 0).'**
  String get errorPercentInvalid;

  /// No description provided for @errorTargetTooLow.
  ///
  /// In en, this message translates to:
  /// **'Target is below bar weight or the data is invalid.'**
  String get errorTargetTooLow;

  /// No description provided for @panelCloseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get panelCloseTooltip;

  /// No description provided for @resultExact.
  ///
  /// In en, this message translates to:
  /// **'Reached: {weight} {units} (exact)'**
  String resultExact(String weight, String units);

  /// No description provided for @resultApprox.
  ///
  /// In en, this message translates to:
  /// **'Best approximation: {weight} {units} (short by {shortfall} {units})'**
  String resultApprox(String weight, String shortfall, String units);

  /// No description provided for @chosenDiscsTitle.
  ///
  /// In en, this message translates to:
  /// **'Chosen discs (total):'**
  String get chosenDiscsTitle;

  /// No description provided for @yourLiftsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your lifts'**
  String get yourLiftsTitle;

  /// No description provided for @addLiftTitle.
  ///
  /// In en, this message translates to:
  /// **'Add movement'**
  String get addLiftTitle;

  /// No description provided for @addLiftHint.
  ///
  /// In en, this message translates to:
  /// **'Ex: Front Squat'**
  String get addLiftHint;

  /// No description provided for @saveLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLabel;

  /// No description provided for @noRmLabel.
  ///
  /// In en, this message translates to:
  /// **'No RM'**
  String get noRmLabel;

  /// No description provided for @deleteRecordTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete record'**
  String get deleteRecordTooltip;

  /// No description provided for @clearHistoryDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get clearHistoryDialogTitle;

  /// No description provided for @clearHistoryDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Delete all history for this lift?'**
  String get clearHistoryDialogContent;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsTabLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsTabLanguage;

  /// No description provided for @settingsTabInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get settingsTabInventory;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'Use system language'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get settingsLanguageSpanish;

  /// No description provided for @settingsLanguageFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get settingsLanguageFrench;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @inventoryKgTitle.
  ///
  /// In en, this message translates to:
  /// **'Plates in kg'**
  String get inventoryKgTitle;

  /// No description provided for @inventoryLbTitle.
  ///
  /// In en, this message translates to:
  /// **'Plates in lb'**
  String get inventoryLbTitle;

  /// No description provided for @inventorySaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save inventory'**
  String get inventorySaveButton;

  /// No description provided for @liftAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'That movement already exists.'**
  String get liftAlreadyExists;

  /// No description provided for @errorRmMissing.
  ///
  /// In en, this message translates to:
  /// **'Enter your 1RM.'**
  String get errorRmMissing;

  /// No description provided for @inventorySavedSnack.
  ///
  /// In en, this message translates to:
  /// **'Inventory saved.'**
  String get inventorySavedSnack;

  /// No description provided for @inventoryAddPlate.
  ///
  /// In en, this message translates to:
  /// **'Add plate'**
  String get inventoryAddPlate;

  /// No description provided for @inventoryAddPlateHint.
  ///
  /// In en, this message translates to:
  /// **'Plate weight'**
  String get inventoryAddPlateHint;

  /// No description provided for @inventoryDeletePlateHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press a plate to remove it.'**
  String get inventoryDeletePlateHint;

  /// No description provided for @inventoryRemovePlate.
  ///
  /// In en, this message translates to:
  /// **'Remove the {weight} {units} plate?'**
  String inventoryRemovePlate(String weight, String units);

  /// No description provided for @inventoryReset.
  ///
  /// In en, this message translates to:
  /// **'Restore defaults'**
  String get inventoryReset;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @resultBarOnly.
  ///
  /// In en, this message translates to:
  /// **'Just the bar, no plates.'**
  String get resultBarOnly;

  /// No description provided for @converterTitle.
  ///
  /// In en, this message translates to:
  /// **'Unit converter'**
  String get converterTitle;

  /// No description provided for @converterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Unit converter'**
  String get converterTooltip;

  /// No description provided for @lbLabel.
  ///
  /// In en, this message translates to:
  /// **'Pounds (lb)'**
  String get lbLabel;

  /// No description provided for @kgLabel.
  ///
  /// In en, this message translates to:
  /// **'Kilograms (kg)'**
  String get kgLabel;

  /// No description provided for @quickPlatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick plate equivalents'**
  String get quickPlatesTitle;

  /// No description provided for @chooseIconTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose an icon'**
  String get chooseIconTitle;

  /// No description provided for @chooseIconTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change icon'**
  String get chooseIconTooltip;

  /// No description provided for @iconAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic (by name)'**
  String get iconAuto;

  /// No description provided for @categoryHaltero.
  ///
  /// In en, this message translates to:
  /// **'Weightlifting'**
  String get categoryHaltero;

  /// No description provided for @categoryHalteroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Olympic lifts and your movements'**
  String get categoryHalteroSubtitle;

  /// No description provided for @categoryGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get categoryGym;

  /// No description provided for @categoryGymSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Exercises by muscle group'**
  String get categoryGymSubtitle;

  /// No description provided for @groupChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get groupChest;

  /// No description provided for @groupBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get groupBack;

  /// No description provided for @groupLegs.
  ///
  /// In en, this message translates to:
  /// **'Legs'**
  String get groupLegs;

  /// No description provided for @groupShoulders.
  ///
  /// In en, this message translates to:
  /// **'Shoulders'**
  String get groupShoulders;

  /// No description provided for @groupArms.
  ///
  /// In en, this message translates to:
  /// **'Arms'**
  String get groupArms;

  /// No description provided for @groupCore.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get groupCore;

  /// No description provided for @exerciseCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 exercise} other{{count} exercises}}'**
  String exerciseCount(int count);

  /// No description provided for @barbellSwitch.
  ///
  /// In en, this message translates to:
  /// **'Uses an Olympic barbell (plate calculator)'**
  String get barbellSwitch;

  /// No description provided for @noCalculatorHint.
  ///
  /// In en, this message translates to:
  /// **'No barbell for this exercise: log the weight, reps and rounds, and keep its history.'**
  String get noCalculatorHint;

  /// No description provided for @iCloudSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'iCloud backup'**
  String get iCloudSyncTitle;

  /// No description provided for @iCloudSyncOn.
  ///
  /// In en, this message translates to:
  /// **'Your data is saved to iCloud and restored automatically on a new iPhone with the same Apple ID.'**
  String get iCloudSyncOn;

  /// No description provided for @iCloudSyncOff.
  ///
  /// In en, this message translates to:
  /// **'iCloud is not available. Sign in to iCloud in Settings to back up your data.'**
  String get iCloudSyncOff;

  /// No description provided for @iCloudRestored.
  ///
  /// In en, this message translates to:
  /// **'Data restored from iCloud'**
  String get iCloudRestored;

  /// No description provided for @tabCalc.
  ///
  /// In en, this message translates to:
  /// **'Calculator'**
  String get tabCalc;

  /// No description provided for @tabTrain.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get tabTrain;

  /// No description provided for @tabProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get tabProgress;

  /// No description provided for @tabCoach.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get tabCoach;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @workoutStartFree.
  ///
  /// In en, this message translates to:
  /// **'Start a workout'**
  String get workoutStartFree;

  /// No description provided for @workoutResume.
  ///
  /// In en, this message translates to:
  /// **'Resume workout in progress'**
  String get workoutResume;

  /// No description provided for @workoutFree.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get workoutFree;

  /// No description provided for @workoutAddExercise.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get workoutAddExercise;

  /// No description provided for @workoutRemoveExercise.
  ///
  /// In en, this message translates to:
  /// **'Remove exercise'**
  String get workoutRemoveExercise;

  /// No description provided for @workoutAddSet.
  ///
  /// In en, this message translates to:
  /// **'Add set'**
  String get workoutAddSet;

  /// No description provided for @workoutReps.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get workoutReps;

  /// No description provided for @workoutPlates.
  ///
  /// In en, this message translates to:
  /// **'Plates for this set'**
  String get workoutPlates;

  /// No description provided for @workoutSetDone.
  ///
  /// In en, this message translates to:
  /// **'Set done'**
  String get workoutSetDone;

  /// No description provided for @workoutNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get workoutNotes;

  /// No description provided for @workoutFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish workout'**
  String get workoutFinish;

  /// No description provided for @workoutDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard workout'**
  String get workoutDiscard;

  /// No description provided for @workoutDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this workout?'**
  String get workoutDiscardTitle;

  /// No description provided for @workoutNoSetsTitle.
  ///
  /// In en, this message translates to:
  /// **'No sets done'**
  String get workoutNoSetsTitle;

  /// No description provided for @workoutNoSetsBody.
  ///
  /// In en, this message translates to:
  /// **'Mark sets as done with the circle to save them.'**
  String get workoutNoSetsBody;

  /// No description provided for @workoutDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this workout?'**
  String get workoutDeleteTitle;

  /// No description provided for @workoutPercentOfRm.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of 1RM'**
  String workoutPercentOfRm(String percent);

  /// No description provided for @restLabel.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get restLabel;

  /// No description provided for @restSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get restSkip;

  /// No description provided for @restDefault.
  ///
  /// In en, this message translates to:
  /// **'Rest time between sets'**
  String get restDefault;

  /// No description provided for @summaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout saved 💪'**
  String get summaryTitle;

  /// No description provided for @summaryTitlePr.
  ///
  /// In en, this message translates to:
  /// **'New personal record! 🏆'**
  String get summaryTitlePr;

  /// No description provided for @summaryStats.
  ///
  /// In en, this message translates to:
  /// **'{sets} sets · {volume} {unit} lifted'**
  String summaryStats(int sets, String volume, String unit);

  /// No description provided for @prHeaviest.
  ///
  /// In en, this message translates to:
  /// **'heaviest ever, {weight} {unit}'**
  String prHeaviest(String weight, String unit);

  /// No description provided for @prEstimated.
  ///
  /// In en, this message translates to:
  /// **'best estimated 1RM, {weight} {unit}'**
  String prEstimated(String weight, String unit);

  /// No description provided for @sendToCoach.
  ///
  /// In en, this message translates to:
  /// **'Send to coach'**
  String get sendToCoach;

  /// No description provided for @athleteNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get athleteNameTitle;

  /// No description provided for @athleteNameHint.
  ///
  /// In en, this message translates to:
  /// **'So your coach knows it is you'**
  String get athleteNameHint;

  /// No description provided for @resultShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Your result'**
  String get resultShareTitle;

  /// No description provided for @resultShareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show this QR to {coach} or send the code by message.'**
  String resultShareSubtitle(String coach);

  /// No description provided for @draftReplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout in progress'**
  String get draftReplaceTitle;

  /// No description provided for @draftReplaceBody.
  ///
  /// In en, this message translates to:
  /// **'You have an unfinished workout. Start a new one and discard it?'**
  String get draftReplaceBody;

  /// No description provided for @setsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 set} other{{count} sets}}'**
  String setsCount(int count);

  /// No description provided for @myPlans.
  ///
  /// In en, this message translates to:
  /// **'My plans'**
  String get myPlans;

  /// No description provided for @myPlansEmpty.
  ///
  /// In en, this message translates to:
  /// **'Create a routine, use a program below or import one from your coach.'**
  String get myPlansEmpty;

  /// No description provided for @planCreate.
  ///
  /// In en, this message translates to:
  /// **'Create routine'**
  String get planCreate;

  /// No description provided for @importPlanShort.
  ///
  /// In en, this message translates to:
  /// **'Coach plan'**
  String get importPlanShort;

  /// No description provided for @importPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Import plan from coach'**
  String get importPlanTitle;

  /// No description provided for @importPlanDone.
  ///
  /// In en, this message translates to:
  /// **'Plan \"{name}\" added'**
  String importPlanDone(String name);

  /// No description provided for @importInvalid.
  ///
  /// In en, this message translates to:
  /// **'That code is not valid. Check that it was copied complete.'**
  String get importInvalid;

  /// No description provided for @templatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Percentage programs'**
  String get templatesTitle;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyWorkoutsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your finished workouts will appear here.'**
  String get historyWorkoutsEmpty;

  /// No description provided for @planUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled plan'**
  String get planUntitled;

  /// No description provided for @planFromCoach.
  ///
  /// In en, this message translates to:
  /// **'Coach {coach}'**
  String planFromCoach(String coach);

  /// No description provided for @planProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} days done'**
  String planProgress(int done, int total);

  /// No description provided for @planDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String planDaysCount(int count);

  /// No description provided for @planShare.
  ///
  /// In en, this message translates to:
  /// **'Share with QR'**
  String get planShare;

  /// No description provided for @planShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share \"{name}\"'**
  String planShareTitle(String name);

  /// No description provided for @planShareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your athletes scan it in Plate Calc → Train → Coach plan. Weights are calculated with each one\'s 1RM.'**
  String get planShareSubtitle;

  /// No description provided for @planStartNext.
  ///
  /// In en, this message translates to:
  /// **'Start: {day}'**
  String planStartNext(String day);

  /// No description provided for @planStartDay.
  ///
  /// In en, this message translates to:
  /// **'Start this day'**
  String get planStartDay;

  /// No description provided for @planNoRm.
  ///
  /// In en, this message translates to:
  /// **'no 1RM saved'**
  String get planNoRm;

  /// No description provided for @planDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String planDeleteTitle(String name);

  /// No description provided for @planWeekDay.
  ///
  /// In en, this message translates to:
  /// **'Week {week} · Day {day}'**
  String planWeekDay(int week, String day);

  /// No description provided for @planDayDefault.
  ///
  /// In en, this message translates to:
  /// **'Day {n}'**
  String planDayDefault(int n);

  /// No description provided for @planOlyName.
  ///
  /// In en, this message translates to:
  /// **'Weightlifting · 4 weeks'**
  String get planOlyName;

  /// No description provided for @planOlyNotes.
  ///
  /// In en, this message translates to:
  /// **'3 days a week. Snatch, clean & jerk and squats by % of your 1RM.'**
  String get planOlyNotes;

  /// No description provided for @planStrengthName.
  ///
  /// In en, this message translates to:
  /// **'Strength 5/3/1 · 4 weeks'**
  String get planStrengthName;

  /// No description provided for @planStrengthNotes.
  ///
  /// In en, this message translates to:
  /// **'4 days a week: squat, bench, deadlift and press. Week 4 is a deload.'**
  String get planStrengthNotes;

  /// No description provided for @planEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Routine'**
  String get planEditorTitle;

  /// No description provided for @planNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get planNameLabel;

  /// No description provided for @planNameHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. Monday WOD, Squat cycle'**
  String get planNameHint;

  /// No description provided for @planNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes for athletes (optional)'**
  String get planNotesLabel;

  /// No description provided for @planNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give it a name'**
  String get planNameRequired;

  /// No description provided for @planNeedsExercise.
  ///
  /// In en, this message translates to:
  /// **'Add at least one exercise'**
  String get planNeedsExercise;

  /// No description provided for @planAddExercise.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get planAddExercise;

  /// No description provided for @planAddDay.
  ///
  /// In en, this message translates to:
  /// **'Add day'**
  String get planAddDay;

  /// No description provided for @planDayName.
  ///
  /// In en, this message translates to:
  /// **'Day name'**
  String get planDayName;

  /// No description provided for @planDayDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get planDayDuplicate;

  /// No description provided for @planSets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get planSets;

  /// No description provided for @planLoadPercent.
  ///
  /// In en, this message translates to:
  /// **'% 1RM'**
  String get planLoadPercent;

  /// No description provided for @planLoadWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get planLoadWeight;

  /// No description provided for @planLoadFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get planLoadFree;

  /// No description provided for @planPercentLabel.
  ///
  /// In en, this message translates to:
  /// **'Percentage of 1RM'**
  String get planPercentLabel;

  /// No description provided for @planWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Fixed weight'**
  String get planWeightLabel;

  /// No description provided for @pickExerciseHint.
  ///
  /// In en, this message translates to:
  /// **'Search or type a new exercise'**
  String get pickExerciseHint;

  /// No description provided for @pickExerciseNew.
  ///
  /// In en, this message translates to:
  /// **'Use \"{name}\"'**
  String pickExerciseNew(String name);

  /// No description provided for @shareCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get shareCopyCode;

  /// No description provided for @shareCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied. Paste it in WhatsApp, an email…'**
  String get shareCopied;

  /// No description provided for @shareHowTo.
  ///
  /// In en, this message translates to:
  /// **'The other person opens Plate Calc and scans the QR or pastes the code.'**
  String get shareHowTo;

  /// No description provided for @shareScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get shareScanQr;

  /// No description provided for @sharePasteLabel.
  ///
  /// In en, this message translates to:
  /// **'Or paste the code'**
  String get sharePasteLabel;

  /// No description provided for @sharePaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get sharePaste;

  /// No description provided for @shareImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get shareImport;

  /// No description provided for @shareCameraError.
  ///
  /// In en, this message translates to:
  /// **'Cannot open the camera. Allow camera access for Plate Calc in Settings, or paste the code.'**
  String get shareCameraError;

  /// No description provided for @statStreak.
  ///
  /// In en, this message translates to:
  /// **'weeks in a row'**
  String get statStreak;

  /// No description provided for @statThisMonth.
  ///
  /// In en, this message translates to:
  /// **'this month'**
  String get statThisMonth;

  /// No description provided for @statTotal.
  ///
  /// In en, this message translates to:
  /// **'in total'**
  String get statTotal;

  /// No description provided for @e1rmCalcTitle.
  ///
  /// In en, this message translates to:
  /// **'Estimated 1RM'**
  String get e1rmCalcTitle;

  /// No description provided for @e1rmCalcHelp.
  ///
  /// In en, this message translates to:
  /// **'Weight and reps of a hard set (Epley formula).'**
  String get e1rmCalcHelp;

  /// No description provided for @e1rmWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get e1rmWeight;

  /// No description provided for @e1rmResult.
  ///
  /// In en, this message translates to:
  /// **'≈ {weight} {unit}'**
  String e1rmResult(String weight, String unit);

  /// No description provided for @e1rmShort.
  ///
  /// In en, this message translates to:
  /// **'e1RM {weight} {unit}'**
  String e1rmShort(String weight, String unit);

  /// No description provided for @recordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal records'**
  String get recordsTitle;

  /// No description provided for @recordsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Finish a workout to see your records and charts.'**
  String get recordsEmpty;

  /// No description provided for @recordHeaviest.
  ///
  /// In en, this message translates to:
  /// **'Max {weight} {unit}'**
  String recordHeaviest(String weight, String unit);

  /// No description provided for @currentRm.
  ///
  /// In en, this message translates to:
  /// **'Saved 1RM: {weight} {unit}'**
  String currentRm(String weight, String unit);

  /// No description provided for @metricE1rm.
  ///
  /// In en, this message translates to:
  /// **'Est. 1RM'**
  String get metricE1rm;

  /// No description provided for @metricHeaviest.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get metricHeaviest;

  /// No description provided for @metricVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get metricVolume;

  /// No description provided for @chartNeedsMore.
  ///
  /// In en, this message translates to:
  /// **'You need at least 2 workouts with this exercise to see the chart.'**
  String get chartNeedsMore;

  /// No description provided for @coachProfile.
  ///
  /// In en, this message translates to:
  /// **'Coach profile'**
  String get coachProfile;

  /// No description provided for @coachNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get coachNameLabel;

  /// No description provided for @coachBoxLabel.
  ///
  /// In en, this message translates to:
  /// **'Box or gym'**
  String get coachBoxLabel;

  /// No description provided for @coachSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your coach profile'**
  String get coachSetupTitle;

  /// No description provided for @coachSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Name and box appear on the plans you share'**
  String get coachSetupSubtitle;

  /// No description provided for @coachDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get coachDefaultName;

  /// No description provided for @coachHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'1. Create a plan or WOD with % of 1RM.\n2. Share it with a QR: each athlete gets their own weights.\n3. After training, they send you their result with another QR.'**
  String get coachHowItWorks;

  /// No description provided for @coachPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Plans for your box'**
  String get coachPlansTitle;

  /// No description provided for @coachCreatePlan.
  ///
  /// In en, this message translates to:
  /// **'Create plan or WOD'**
  String get coachCreatePlan;

  /// No description provided for @coachAthletesTitle.
  ///
  /// In en, this message translates to:
  /// **'Athletes'**
  String get coachAthletesTitle;

  /// No description provided for @coachAthletesEmpty.
  ///
  /// In en, this message translates to:
  /// **'When an athlete sends you a result, they will appear here.'**
  String get coachAthletesEmpty;

  /// No description provided for @importResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive athlete result'**
  String get importResultTitle;

  /// No description provided for @importResultDone.
  ///
  /// In en, this message translates to:
  /// **'Result from {name} saved'**
  String importResultDone(String name);

  /// No description provided for @importResultDuplicate.
  ///
  /// In en, this message translates to:
  /// **'You already had this result'**
  String get importResultDuplicate;

  /// No description provided for @resultsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 workout} other{{count} workouts}}'**
  String resultsCount(int count);

  /// No description provided for @lastWorkout.
  ///
  /// In en, this message translates to:
  /// **'last {date}'**
  String lastWorkout(String date);

  /// No description provided for @athleteDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name} and their results?'**
  String athleteDeleteTitle(String name);

  /// No description provided for @keyboardDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get keyboardDone;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @progressIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'What is this tab for?'**
  String get progressIntroTitle;

  /// No description provided for @progressIntroBody.
  ///
  /// In en, this message translates to:
  /// **'It shows how you are improving. It fills in by itself with the workouts you finish in the Train tab: days trained, records and a chart for each exercise.'**
  String get progressIntroBody;

  /// No description provided for @progressGoTrain.
  ///
  /// In en, this message translates to:
  /// **'Go to Train'**
  String get progressGoTrain;

  /// No description provided for @progressConsistencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get progressConsistencyTitle;

  /// No description provided for @progressConsistencyHelp.
  ///
  /// In en, this message translates to:
  /// **'Weeks in a row with at least one workout, and how many you did.'**
  String get progressConsistencyHelp;

  /// No description provided for @progressCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get progressCalendarTitle;

  /// No description provided for @progressCalendarHelp.
  ///
  /// In en, this message translates to:
  /// **'Colored days are days you trained. Tap one to see that workout.'**
  String get progressCalendarHelp;

  /// No description provided for @progressRecordsHelp.
  ///
  /// In en, this message translates to:
  /// **'Your best mark in each exercise. Tap one to see its chart.'**
  String get progressRecordsHelp;

  /// No description provided for @e1rmExample.
  ///
  /// In en, this message translates to:
  /// **'Example: {weight} for 5 reps ≈ 1RM of {result}'**
  String e1rmExample(String weight, String result);

  /// No description provided for @simpleWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get simpleWeightLabel;

  /// No description provided for @simpleWeightHelp.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for bodyweight'**
  String get simpleWeightHelp;

  /// No description provided for @simpleRepsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reps done'**
  String get simpleRepsLabel;

  /// No description provided for @simpleRoundsLabel.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get simpleRoundsLabel;

  /// No description provided for @simpleLastEntry.
  ///
  /// In en, this message translates to:
  /// **'Last: {entry}'**
  String simpleLastEntry(String entry);

  /// No description provided for @saveSetButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveSetButton;

  /// No description provided for @saveSetInvalidSnack.
  ///
  /// In en, this message translates to:
  /// **'Enter the reps done (or a weight).'**
  String get saveSetInvalidSnack;

  /// No description provided for @saveSetOkSnack.
  ///
  /// In en, this message translates to:
  /// **'Saved for {movementName}.'**
  String saveSetOkSnack(String movementName);

  /// No description provided for @bodyweight.
  ///
  /// In en, this message translates to:
  /// **'Bodyweight'**
  String get bodyweight;

  /// No description provided for @setsRepsLine.
  ///
  /// In en, this message translates to:
  /// **'{weight} × {reps} reps'**
  String setsRepsLine(String weight, int reps);

  /// No description provided for @roundsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 round} other{{count} rounds}}'**
  String roundsCount(int count);

  /// No description provided for @tabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tabToday;

  /// No description provided for @tabBox.
  ///
  /// In en, this message translates to:
  /// **'Box'**
  String get tabBox;

  /// No description provided for @tabPlates.
  ///
  /// In en, this message translates to:
  /// **'Plates'**
  String get tabPlates;

  /// No description provided for @todayInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get todayInProgress;

  /// No description provided for @todayResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get todayResume;

  /// No description provided for @todayNext.
  ///
  /// In en, this message translates to:
  /// **'Next session'**
  String get todayNext;

  /// No description provided for @todayNoPlanBody.
  ///
  /// In en, this message translates to:
  /// **'No active plan. Pick a program below, create a routine or scan your coach’s plan.'**
  String get todayNoPlanBody;

  /// No description provided for @todayFreeWorkout.
  ///
  /// In en, this message translates to:
  /// **'Or start a free workout'**
  String get todayFreeWorkout;

  /// No description provided for @todayRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get todayRecent;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @colSet.
  ///
  /// In en, this message translates to:
  /// **'SET'**
  String get colSet;

  /// No description provided for @colPrevious.
  ///
  /// In en, this message translates to:
  /// **'PREVIOUS'**
  String get colPrevious;

  /// No description provided for @workoutFinishShort.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get workoutFinishShort;

  /// No description provided for @styleCrossfit.
  ///
  /// In en, this message translates to:
  /// **'Crosstraining'**
  String get styleCrossfit;

  /// No description provided for @styleHaltero.
  ///
  /// In en, this message translates to:
  /// **'Weightlifting'**
  String get styleHaltero;

  /// No description provided for @styleGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get styleGym;

  /// No description provided for @styleCrossfitDesc.
  ///
  /// In en, this message translates to:
  /// **'Daily WOD: AMRAP, EMOM, For Time'**
  String get styleCrossfitDesc;

  /// No description provided for @styleHalteroDesc.
  ///
  /// In en, this message translates to:
  /// **'Snatch, clean & jerk and squats by % of 1RM'**
  String get styleHalteroDesc;

  /// No description provided for @styleGymDesc.
  ///
  /// In en, this message translates to:
  /// **'Push / Pull / Legs'**
  String get styleGymDesc;

  /// No description provided for @stylesTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you train?'**
  String get stylesTitle;

  /// No description provided for @stylesFirstTitle.
  ///
  /// In en, this message translates to:
  /// **'A workout every day'**
  String get stylesFirstTitle;

  /// No description provided for @stylesFirstBody.
  ///
  /// In en, this message translates to:
  /// **'Choose what you train and you will get a new session every day, with your weights from your 1RM.'**
  String get stylesFirstBody;

  /// No description provided for @stylesChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get stylesChoose;

  /// No description provided for @todayStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get todayStart;

  /// No description provided for @todayDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get todayDone;

  /// No description provided for @crossfitOfficialWod.
  ///
  /// In en, this message translates to:
  /// **'CrossFit.com official WOD'**
  String get crossfitOfficialWod;

  /// No description provided for @wodGo.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get wodGo;

  /// No description provided for @wodPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get wodPause;

  /// No description provided for @wodContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get wodContinue;

  /// No description provided for @wodRound.
  ///
  /// In en, this message translates to:
  /// **'Round'**
  String get wodRound;

  /// No description provided for @wodScoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Your result'**
  String get wodScoreTitle;

  /// No description provided for @wodScoreTime.
  ///
  /// In en, this message translates to:
  /// **'Time (mm:ss)'**
  String get wodScoreTime;

  /// No description provided for @wodScoreRounds.
  ///
  /// In en, this message translates to:
  /// **'Rounds'**
  String get wodScoreRounds;

  /// No description provided for @wodScoreReps.
  ///
  /// In en, this message translates to:
  /// **'+ reps'**
  String get wodScoreReps;

  /// No description provided for @wodSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved: {score}'**
  String wodSaved(String score);

  /// No description provided for @wodResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'WOD results'**
  String get wodResultsTitle;

  /// No description provided for @progressEmpty.
  ///
  /// In en, this message translates to:
  /// **'Finish your first workout to see your progress here.'**
  String get progressEmpty;

  /// No description provided for @statThisWeek.
  ///
  /// In en, this message translates to:
  /// **'this week'**
  String get statThisWeek;

  /// No description provided for @chartThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get chartThisWeek;

  /// No description provided for @chartWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} wk ago'**
  String chartWeeksAgo(int n);

  /// No description provided for @metricE1rmLong.
  ///
  /// In en, this message translates to:
  /// **'Best estimated 1RM'**
  String get metricE1rmLong;

  /// No description provided for @metricHeaviestLong.
  ///
  /// In en, this message translates to:
  /// **'Heaviest lift'**
  String get metricHeaviestLong;

  /// No description provided for @todayOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get todayOther;

  /// No description provided for @scanButton.
  ///
  /// In en, this message translates to:
  /// **'Photo of the whiteboard'**
  String get scanButton;

  /// No description provided for @scanCamera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get scanCamera;

  /// No description provided for @scanGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from photos'**
  String get scanGallery;

  /// No description provided for @scanReading.
  ///
  /// In en, this message translates to:
  /// **'Reading the whiteboard…'**
  String get scanReading;

  /// No description provided for @scanNothing.
  ///
  /// In en, this message translates to:
  /// **'No exercises found. Try again with more light and the whole board in the photo.'**
  String get scanNothing;

  /// No description provided for @scanPermission.
  ///
  /// In en, this message translates to:
  /// **'Cannot open the camera. Allow access for Plate Calc in Settings.'**
  String get scanPermission;

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Whiteboard'**
  String get scanTitle;

  /// No description provided for @scanDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Whiteboard WOD'**
  String get scanDefaultName;

  /// No description provided for @scanCheck.
  ///
  /// In en, this message translates to:
  /// **'Check it before you start: change the format or remove anything misread.'**
  String get scanCheck;

  /// No description provided for @scanRetake.
  ///
  /// In en, this message translates to:
  /// **'Take another photo'**
  String get scanRetake;

  /// No description provided for @scanTapToEdit.
  ///
  /// In en, this message translates to:
  /// **'Tap an exercise to fix it.'**
  String get scanTapToEdit;

  /// No description provided for @scanRawText.
  ///
  /// In en, this message translates to:
  /// **'Text read from the photo'**
  String get scanRawText;

  /// No description provided for @scanRepsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reps / distance / calories'**
  String get scanRepsLabel;

  /// No description provided for @scanMoveLabel.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get scanMoveLabel;

  /// No description provided for @scanRxLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight Rx (optional)'**
  String get scanRxLabel;

  /// No description provided for @scanByAi.
  ///
  /// In en, this message translates to:
  /// **'✦ READ WITH AI'**
  String get scanByAi;

  /// No description provided for @aiConsentTitle.
  ///
  /// In en, this message translates to:
  /// **'Read the whiteboard with AI?'**
  String get aiConsentTitle;

  /// No description provided for @aiConsentBody.
  ///
  /// In en, this message translates to:
  /// **'To read the whiteboard, Plate Calc sends the photo to Google Gemini (Google’s AI service) through our server. Google may use it to improve its products. We don’t store the photo or link it to you.\n\nIf you prefer, the app can read it only on your phone (less accurate). You can change this in Settings.'**
  String get aiConsentBody;

  /// No description provided for @aiConsentYes.
  ///
  /// In en, this message translates to:
  /// **'Use AI'**
  String get aiConsentYes;

  /// No description provided for @aiConsentNo.
  ///
  /// In en, this message translates to:
  /// **'Only on my phone'**
  String get aiConsentNo;

  /// No description provided for @aiSettingTitle.
  ///
  /// In en, this message translates to:
  /// **'Whiteboard photos'**
  String get aiSettingTitle;

  /// No description provided for @aiSettingSwitch.
  ///
  /// In en, this message translates to:
  /// **'Read with AI (Google Gemini)'**
  String get aiSettingSwitch;

  /// No description provided for @aiSettingHelp.
  ///
  /// In en, this message translates to:
  /// **'The photo is sent to Google to read it. Off: read only on this phone.'**
  String get aiSettingHelp;

  /// No description provided for @detailDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get detailDuration;

  /// No description provided for @detailResult.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get detailResult;

  /// No description provided for @detailMovements.
  ///
  /// In en, this message translates to:
  /// **'Movements'**
  String get detailMovements;

  /// No description provided for @detailExercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get detailExercises;

  /// No description provided for @freeWorkoutRow.
  ///
  /// In en, this message translates to:
  /// **'Free workout'**
  String get freeWorkoutRow;

  /// No description provided for @yourRms.
  ///
  /// In en, this message translates to:
  /// **'Your 1RMs'**
  String get yourRms;

  /// No description provided for @yourRmsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Save a 1RM on any lift and it will show up here, one tap from the calculator.'**
  String get yourRmsEmpty;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

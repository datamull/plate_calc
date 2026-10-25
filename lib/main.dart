import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'services/app_storage.dart';
import 'ui/screens/app_settings_screen.dart';
import 'ui/screens/rm_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Se cargan los datos antes del primer frame: así el idioma guardado se
  // aplica desde el inicio (en la v1 la app arrancaba en el idioma del
  // sistema y cambiaba un instante después).
  final storage = await AppStorage.load();
  runApp(PlateCalcApp(storage: storage));
}

class PlateCalcApp extends StatefulWidget {
  const PlateCalcApp({super.key, required this.storage});

  final AppStorage storage;

  @override
  State<PlateCalcApp> createState() => _PlateCalcAppState();
}

class _PlateCalcAppState extends State<PlateCalcApp> {
  late String? _localeCode = widget.storage.localeCode;

  Future<void> _changeLocale(String? code) async {
    await widget.storage.setLocaleCode(code);
    setState(() => _localeCode = code);
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness b) => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4), brightness: b),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _localeCode == null ? null : Locale(_localeCode!),
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => RmListScreen(
          storage: widget.storage,
          onOpenSettings: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AppSettingsScreen(
                storage: widget.storage,
                currentLocaleCode: _localeCode,
                onLocaleChanged: _changeLocale,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

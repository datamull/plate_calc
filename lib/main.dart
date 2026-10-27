import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'services/app_storage.dart';
import 'services/cloud_sync.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/app_settings_screen.dart';
import 'ui/screens/category_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Se cargan los datos antes del primer frame: así el idioma guardado se
  // aplica desde el inicio (en la v1 la app arrancaba en el idioma del
  // sistema y cambiaba un instante después).
  final storage = await AppStorage.load();
  // Respaldo en iCloud: en un iPhone nuevo recupera los datos antes de
  // mostrar la primera pantalla.
  final cloud = CloudSync(storage);
  await cloud.start();
  runApp(PlateCalcApp(storage: storage, cloud: cloud));
}

class PlateCalcApp extends StatefulWidget {
  const PlateCalcApp({super.key, required this.storage, this.cloud});

  final AppStorage storage;
  final CloudSync? cloud;

  @override
  State<PlateCalcApp> createState() => _PlateCalcAppState();
}

class _PlateCalcAppState extends State<PlateCalcApp> {
  late String? _localeCode = widget.storage.localeCode;

  /// Cambia cuando se restauran datos de iCloud con la app abierta, para
  /// volver a construir todas las pantallas con los datos nuevos.
  int _dataVersion = 0;
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    widget.cloud?.onRestored = () {
      if (!mounted) return;
      setState(() {
        _localeCode = widget.storage.localeCode;
        _dataVersion++;
      });
      final ctx = _messengerKey.currentContext;
      if (ctx != null) {
        _messengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(ctx).iCloudRestored)),
        );
      }
    };
  }

  Future<void> _changeLocale(String? code) async {
    await widget.storage.setLocaleCode(code);
    setState(() => _localeCode = code);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: ValueKey(_dataVersion),
      scaffoldMessengerKey: _messengerKey,
      debugShowCheckedModeBanner: false,
      locale: _localeCode == null ? null : Locale(_localeCode!),
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => CategoryScreen(
          storage: widget.storage,
          onOpenSettings: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AppSettingsScreen(
                storage: widget.storage,
                cloud: widget.cloud,
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

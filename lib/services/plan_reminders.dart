import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/week_plan.dart';
import 'training_store.dart';

/// Aviso al final del día: "¿Completaste el entrenamiento de hoy?".
///
/// Todo es local: el teléfono guarda los avisos de los próximos días que
/// tienen entrenamiento en el plan y aún no están hechos. Se recalculan cada
/// vez que cambia el plan o se marca un día como hecho, así que un día ya
/// completado no avisa.
class PlanReminders {
  PlanReminders._();

  /// Hora del aviso (hora local del teléfono).
  static const hour = 20;

  /// Días hacia adelante que se programan (iOS acepta hasta 64 avisos).
  static const _horizon = 14;
  static const _idBase = 4200;

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  static Future<void> init() async {
    if (_ready || !_supported) return;
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // El permiso se pide después, cuando el usuario sube su primer plan.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('PlanReminders.init: $e');
    }
  }

  /// Pide permiso para avisar (solo muestra el diálogo del sistema la
  /// primera vez).
  static Future<bool> requestPermission() async {
    await init();
    if (!_ready) return false;
    try {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, sound: true) ?? false;
      }
      final android = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    } catch (e) {
      debugPrint('PlanReminders.requestPermission: $e');
      return false;
    }
  }

  /// Vuelve a programar los avisos según el plan y lo ya hecho.
  static Future<void> sync(
    TrainingStore store, {
    required String title,
    required String body,
    required String fallbackName,
    DateTime? now,
  }) async {
    await init();
    if (!_ready) return;
    try {
      final today = now ?? DateTime.now();
      final plans = store.weekPlans(fallbackName: fallbackName);
      for (var i = 0; i < _horizon; i++) {
        await _plugin.cancel(id: _idBase + i);
      }
      if (!store.planRemindersOn) return;
      for (var i = 0; i < _horizon; i++) {
        final day = DateTime(today.year, today.month, today.day + i);
        final at = DateTime(day.year, day.month, day.day, hour);
        if (!at.isAfter(today)) continue;
        final blocks = _blocksOn(plans, day);
        if (blocks.isEmpty || blocks.every((b) => store.planDone(b.wod) != null)) continue;
        await _plugin.zonedSchedule(
          id: _idBase + i,
          // Instante exacto en UTC: la hora local (con cambio de horario) ya
          // la resolvió DateTime.
          scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
          title: title,
          body: body,
          payload: 'plan',
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'plan_reminder',
              'Plan',
              importance: Importance.defaultImportance,
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
      }
    } catch (e) {
      debugPrint('PlanReminders.sync: $e');
    }
  }

  static List<PlanBlock> _blocksOn(List<WeekPlan> plans, DateTime day) {
    for (final p in plans) {
      if (p.contains(day)) return p.days[day.weekday] ?? const [];
    }
    return const [];
  }
}

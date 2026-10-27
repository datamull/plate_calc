import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_calc/models/weight_unit.dart';
import 'package:plate_calc/services/app_storage.dart';
import 'package:plate_calc/services/cloud_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// iCloud simulado: un mapa en memoria.
class FakeICloud {
  FakeICloud({this.available = true});

  final bool available;
  final store = <String, String>{};
  int sets = 0;

  Future<Object?> handle(MethodCall call) async {
    final args = (call.arguments as Map?)?.cast<String, Object?>();
    switch (call.method) {
      case 'available':
        return available;
      case 'get':
        return store[args!['key']];
      case 'set':
        sets++;
        store[args!['key']! as String] = args['value']! as String;
        return true;
    }
    return null;
  }
}

const channel = MethodChannel('platecalc/icloud');

Future<(AppStorage, CloudSync, FakeICloud)> setUpSync(
  Map<String, Object> local, {
  FakeICloud? cloud,
  DateTime? now,
}) async {
  SharedPreferences.setMockInitialValues(local);
  final storage = await AppStorage.load();
  final fake = cloud ?? FakeICloud();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    channel,
    fake.handle,
  );
  final sync = CloudSync(storage, channel: channel, now: () => now ?? DateTime.utc(2026, 10, 27));
  return (storage, sync, fake);
}

String backupWith(Map<String, Object> data, DateTime at) =>
    jsonEncode({'updatedAt': at.toIso8601String(), 'data': CloudSync.encodeData(data)});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('iPhone nuevo: restaura la copia de iCloud con los tipos correctos', () async {
    final fake = FakeICloud();
    fake.store[CloudSync.backupKey] = backupWith({
      'rm_Snatch_kg': 100.0,
      'custom_lifts': ['Front Squat'],
      'app_locale': 'es',
    }, DateTime.utc(2026, 10, 1));

    final (storage, sync, _) = await setUpSync({}, cloud: fake);
    expect(await sync.start(), isTrue);
    sync.dispose();

    expect(storage.lastRm('Snatch', WeightUnit.kg), 100.0);
    expect(storage.lifts, contains('Front Squat'));
    expect(storage.localeCode, 'es');
  });

  test('datos locales nunca respaldados no se pisan: se suben a iCloud', () async {
    final fake = FakeICloud();
    fake.store[CloudSync.backupKey] = backupWith({'rm_Snatch_kg': 50.0}, DateTime.utc(2026, 1, 1));

    final (storage, sync, _) = await setUpSync({'rm_Snatch_kg': 120.0}, cloud: fake);
    expect(await sync.start(), isFalse);
    sync.dispose();

    expect(storage.lastRm('Snatch', WeightUnit.kg), 120.0);
    final uploaded = jsonDecode(fake.store[CloudSync.backupKey]!) as Map<String, dynamic>;
    expect(CloudSync.decodeData(uploaded['data'] as Map<String, dynamic>)['rm_Snatch_kg'], 120.0);
  });

  test('solo sube cuando los datos cambian', () async {
    final (storage, sync, fake) = await setUpSync({'rm_Jerk_lb': 200.0});
    await sync.start();
    sync.dispose();
    final afterStart = fake.sets;

    await sync.backupNow();
    expect(fake.sets, afterStart);

    await storage.saveRm('Jerk', WeightUnit.lb, 205);
    await sync.backupNow();
    expect(fake.sets, afterStart + 1);
  });

  test('una copia más nueva de otro iPhone reemplaza los datos', () async {
    final fake = FakeICloud();
    final (storage, sync, _) = await setUpSync(
      {
        'rm_Clean_kg': 90.0,
        'cloud_local_updated_at': DateTime.utc(2026, 10, 1).toIso8601String(),
        'cloud_last_hash': 'x',
      },
      cloud: fake,
    );
    fake.store[CloudSync.backupKey] = backupWith({'rm_Clean_kg': 95.0}, DateTime.utc(2026, 10, 2));
    expect(await sync.start(), isTrue);
    sync.dispose();
    expect(storage.lastRm('Clean', WeightUnit.kg), 95.0);
  });

  test('sin iCloud (Android, web o sesión cerrada) no hace nada', () async {
    final (storage, sync, fake) = await setUpSync({
      'rm_Snatch_kg': 80.0,
    }, cloud: FakeICloud(available: false));
    expect(await sync.start(), isFalse);
    sync.dispose();
    expect(fake.sets, 0);
    expect(storage.lastRm('Snatch', WeightUnit.kg), 80.0);
  });
}

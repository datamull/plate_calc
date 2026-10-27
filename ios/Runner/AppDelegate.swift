import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var iCloudChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerICloudChannel(messenger: engineBridge.applicationRegistrar.messenger())
  }

  /// Respaldo en iCloud con el almacén clave-valor (NSUbiquitousKeyValueStore):
  /// no requiere login, usa el Apple ID con que el iPhone está conectado a iCloud.
  private func registerICloudChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "platecalc/icloud", binaryMessenger: messenger)
    iCloudChannel = channel
    let store = NSUbiquitousKeyValueStore.default

    channel.setMethodCallHandler { call, result in
      let args = call.arguments as? [String: Any]
      switch call.method {
      case "available":
        result(FileManager.default.ubiquityIdentityToken != nil)
      case "get":
        guard let key = args?["key"] as? String else {
          result(FlutterError(code: "bad_args", message: "Falta la clave", details: nil))
          return
        }
        store.synchronize()
        result(store.string(forKey: key))
      case "set":
        guard let key = args?["key"] as? String, let value = args?["value"] as? String else {
          result(FlutterError(code: "bad_args", message: "Faltan clave o valor", details: nil))
          return
        }
        store.set(value, forKey: key)
        result(store.synchronize())
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Avisa a Flutter cuando llega una copia desde iCloud (otro iPhone o la
    // descarga inicial en un iPhone nuevo).
    NotificationCenter.default.addObserver(
      forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
      object: store,
      queue: .main
    ) { [weak self] note in
      let keys = note.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] ?? []
      self?.iCloudChannel?.invokeMethod("changed", arguments: keys)
    }
    store.synchronize()
  }
}

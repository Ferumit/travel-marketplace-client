import Flutter
import UIKit
import YandexMapsMobile

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Инициализация Яндекс MapKit ДО создания Flutter Engine
    // Ключ должен совпадать с MainApplication.kt и yandex_map_config.dart
    YMKMapKit.setApiKey("YOUR_YANDEX_MAPKIT_API_KEY")
    // YMKMapKit.setLocale("ru") // раскомментируй для принудительного русского языка карты
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

// Конфигурация Яндекс MapKit.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:ui';
import 'package:yandex_mapkit/yandex_mapkit.dart';

abstract final class YandexMapConfig {
  // ── API-ключ ──────────────────────────────────────────────────────────────
  /// Замени на свой ключ из Яндекс Developer Console.
  /// Используй разные ключи для debug/release при необходимости.
  static const String apiKey = 'YOUR_YANDEX_MAPKIT_API_KEY';

  // ── Начальные настройки карты ──────────────────────────────────────────────
  static const defaultPoint = Point(
    latitude: 43.238949,
    longitude: 76.889709,
  ); // Almaty by default
  static const double defaultZoom = 12.0;
  static const double overviewZoom = 8.0;

  // ── Настройки Маршрута ─────────────────────────────────────────────────────
  static const routeLineColor = Color(0xFF00E5FF); // Primary cyan
  static const routeLineWidth = 5.0;
  static const routeOutlineColor = Color(0xFF000000);
  static const routeOutlineWidth = 1.0;

  // ── Настройки поведения карты ─────────────────────────────────────────────
  static const bool nightModeEnabled = false;

  // ── Точность геолокации (метры) ───────────────────────────────────────────
  static const double locationAccuracyMeters = 50.0;
}


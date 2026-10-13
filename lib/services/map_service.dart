import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../map/yandex_map_config.dart';

/// Центральный сервис для работы с Yandex Maps. Singleton: [MapService.instance].
///
/// Управляет контроллером камеры и маркерами на карте.
/// API-ключ задаётся нативно: Android — `MainApplication.kt`, iOS — `AppDelegate.swift`.
class MapService {
  MapService._();
  static final MapService instance = MapService._();

  YandexMapController? _controller;

  final Map<String, PlacemarkMapObject> _placemarks = {};

  final _objectsController = StreamController<List<MapObject>>.broadcast();
  Stream<List<MapObject>> get mapObjects => _objectsController.stream;

  Point? _userLocation;
  Point? get userLocation => _userLocation;

  // ── Контроллер карты ──────────────────────────────────────────────────────

  void attachController(YandexMapController controller) {
    _controller = controller;
    debugPrint('[MapService] Controller attached ✓');
  }

  void detachController() {
    _controller = null;
  }

  // ── Камера ────────────────────────────────────────────────────────────────

  Future<void> moveCamera({
    required double latitude,
    required double longitude,
    double zoom = YandexMapConfig.defaultZoom,
    bool animated = true,
  }) async {
    final controller = _controller;
    if (controller == null) return;
    await controller.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: Point(latitude: latitude, longitude: longitude),
          zoom: zoom,
        ),
      ),
      animation: animated
          ? const MapAnimation(type: MapAnimationType.smooth, duration: 0.5)
          : null,
    );
  }

  Future<void> moveCameraToUser({
    double zoom = YandexMapConfig.defaultZoom,
  }) async {
    final loc = _userLocation;
    if (loc == null) return;
    await moveCamera(
      latitude: loc.latitude,
      longitude: loc.longitude,
      zoom: zoom,
    );
  }

  // ── Маркеры ───────────────────────────────────────────────────────────────

  /// Добавляет или обновляет маркер по уникальному [id].
  void addPlacemark({
    required String id,
    required double latitude,
    required double longitude,
    PlacemarkIcon? icon,
    PlacemarkText? text,
  }) {
    _placemarks[id] = PlacemarkMapObject(
      mapId: MapObjectId(id),
      point: Point(latitude: latitude, longitude: longitude),
      icon:
          icon ??
          PlacemarkIcon.single(
            PlacemarkIconStyle(
              image: BitmapDescriptor.fromAssetImage(
                'packages/yandex_mapkit/lib/assets/arrow.png',
              ),
              scale: 1.5,
            ),
          ),
      text: text,
    );
    _notifyObjectsUpdated();
  }

  void removePlacemark(String id) {
    if (_placemarks.remove(id) != null) _notifyObjectsUpdated();
  }

  void clearPlacemarks() {
    _placemarks.clear();
    _notifyObjectsUpdated();
  }

  // ── Позиция пользователя ──────────────────────────────────────────────────

  /// Обновляет известную позицию пользователя. Вызывается из [LocationService].
  void updateUserLocation(double latitude, double longitude) {
    _userLocation = Point(latitude: latitude, longitude: longitude);
  }

  // ── Внутреннее ────────────────────────────────────────────────────────────

  void _notifyObjectsUpdated() {
    if (!_objectsController.isClosed) {
      _objectsController.add([..._placemarks.values]);
    }
  }

  void dispose() {
    if (!_objectsController.isClosed) {
      _objectsController.close();
    }
    _controller = null;
  }
}


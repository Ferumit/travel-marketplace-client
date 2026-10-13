import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'map_service.dart';

/// Статус разрешения на геолокацию.
enum LocationStatus {
  unknown,
  ready,
  denied,

  /// Пользователь выбрал «Больше не спрашивать» / отключил в настройках.
  deniedForever,

  /// GPS отключён на уровне устройства.
  serviceDisabled,
}

/// Сервис геолокации. Singleton: [LocationService.instance].
///
/// Запрашивает разрешения, предоставляет текущую позицию и непрерывный стрим GPS.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  LocationStatus _status = LocationStatus.unknown;
  LocationStatus get status => _status;

  Position? _lastPosition;
  Position? get lastPosition => _lastPosition;

  StreamSubscription<Position>? _positionSub;

  final _statusController = StreamController<LocationStatus>.broadcast();
  Stream<LocationStatus> get statusStream => _statusController.stream;

  // ── Разрешения ────────────────────────────────────────────────────────────

  /// Проверяет текущее состояние разрешения на геолокацию.
  ///
  /// Для запроса разрешений с Prominent Disclosure используй
  /// [LocationPermissionService.requestAll] — он вызывается при старте приложения.
  /// Этот метод используется только для повторной проверки статуса в сервисах.
  Future<LocationStatus> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _updateStatus(LocationStatus.serviceDisabled);
      return _status;
    }

    // Проверяем текущий статус (без показа системного диалога)
    final geoStatus = await Geolocator.checkPermission();

    if (geoStatus == LocationPermission.always ||
        geoStatus == LocationPermission.whileInUse) {
      _updateStatus(LocationStatus.ready);
    } else if (geoStatus == LocationPermission.deniedForever) {
      _updateStatus(LocationStatus.deniedForever);
    } else {
      // Разрешение ещё не запрошено или отклонено — запрашиваем системно
      final permStatus = await Permission.locationWhenInUse.request();
      if (permStatus.isGranted) {
        _updateStatus(LocationStatus.ready);
      } else if (permStatus.isPermanentlyDenied) {
        _updateStatus(LocationStatus.deniedForever);
      } else {
        _updateStatus(LocationStatus.denied);
      }
    }

    debugPrint('[LocationService] Permission: $_status');
    return _status;
  }

  // ── Разовое получение позиции ─────────────────────────────────────────────

  /// Возвращает текущую позицию или `null` при отказе / ошибке.
  Future<Position?> getCurrentPosition() async {
    if (_status != LocationStatus.ready) {
      final result = await requestPermission();
      if (result != LocationStatus.ready) return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _lastPosition = position;
      MapService.instance.updateUserLocation(
        position.latitude,
        position.longitude,
      );
      return position;
    } on LocationServiceDisabledException {
      _updateStatus(LocationStatus.serviceDisabled);
      return null;
    } on PermissionDeniedException {
      _updateStatus(LocationStatus.denied);
      return null;
    } catch (e, stack) {
      debugPrint('[LocationService] Ошибка: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'LocationService.getCurrentPosition', fatal: false);
      return null;
    }
  }

  // ── Непрерывный трекинг ───────────────────────────────────────────────────

  /// Запускает стрим GPS. Безопасно вызывать повторно.
  Future<void> startTracking() async {
    if (_positionSub != null) return;

    if (_status != LocationStatus.ready) {
      final result = await requestPermission();
      if (result != LocationStatus.ready) return;
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // обновлять при смещении ≥ 5 м
    );

    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen(
          (position) {
            _lastPosition = position;
            MapService.instance.updateUserLocation(
              position.latitude,
              position.longitude,
            );
          },
          onError: (Object error) {
            debugPrint('[LocationService] Stream error: $error');
            _positionSub?.cancel();
            _positionSub = null;
          },
        );
  }

  /// Останавливает стрим GPS.
  void stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  // ── Вспомогательное ───────────────────────────────────────────────────────

  /// Открывает системные настройки приложения.
  /// Используй при [status] == [LocationStatus.deniedForever].
  Future<bool> openSystemSettings() => openAppSettings();

  void _updateStatus(LocationStatus newStatus) {
    _status = newStatus;
    if (!_statusController.isClosed) _statusController.add(newStatus);
  }

  void dispose() {
    stopTracking();
    if (!_statusController.isClosed) {
      _statusController.close();
    }
  }
}


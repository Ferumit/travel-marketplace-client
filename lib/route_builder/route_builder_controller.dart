import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../models/booking_models.dart';
import '../repository/firestore_data_repository.dart';
import '../services/auth_service.dart';
import 'route_builder_step.dart';
import 'route_waypoint.dart';
import 'waypoint_marker_painter.dart';
import 'yandex_directions_service.dart';
import 'route_calculator.dart';

/// Локализованные строки для RouteBuilderController.
class RouteBuilderLabels {
  final String waypointStart;
  final String waypointFinish;
  final String Function(int n) waypointMid;
  final String myLocationLabel;
  final String defaultRouteTitle;
  final String errorFallback;
  final String errorBuild;

  const RouteBuilderLabels({
    required this.waypointStart,
    required this.waypointFinish,
    required this.waypointMid,
    required this.myLocationLabel,
    required this.defaultRouteTitle,
    required this.errorFallback,
    required this.errorBuild,
  });

  static RouteBuilderLabels get defaults => RouteBuilderLabels(
    waypointStart: 'Старт',
    waypointFinish: 'Финиш',
    waypointMid: (n) => 'Точка $n',
    myLocationLabel: 'Моё местоположение',
    defaultRouteTitle: 'Свой маршрут',
    errorFallback: 'Маршрут по дорогам недоступен — показано прямое расстояние',
    errorBuild: 'Ошибка при построении маршрута',
  );
}

/// Управляет состоянием мастера построения маршрута.
/// Хранит точки, результат пасчёта и текущий шаг. Расширяет [ChangeNotifier].
class RouteBuilderController extends ChangeNotifier {
  // Точки маршрута
  final List<RouteWaypoint> _waypoints = [];
  List<RouteWaypoint> get waypoints => List.unmodifiable(_waypoints);

  /// Кэш сгенерированных PNG-маркеров: ключ — '${colorValue}_${number}'
  final Map<String, Uint8List> _markerCache = {};

  static const int maxWaypoints = 10;
  static const int minWaypointsForRoute = 2;

  bool get canAddMore => _waypoints.length < maxWaypoints;
  /// Маршрут можно строить только если >= 2 точек И ни одна не isPending.
  bool get canBuildRoute =>
      _waypoints.length >= minWaypointsForRoute &&
      _waypoints.every((w) => !w.isPending);

  /// true если есть хотя бы один pending-слот.
  bool get hasPendingSlot => _waypoints.any((w) => w.isPending);

  /// Индекс активного pending-слота — именно он заполнится при следующем тапе на карте.
  /// null — нет активных pending-слотов.
  int? _activePendingIndex;
  int? get activePendingIndex => _activePendingIndex;

  // Результат маршрута
  List<Point> _routePolyline = [];
  List<Point> get routePolyline => _routePolyline;

  List<RouteSegment> _routeSegments = [];
  List<RouteSegment> get routeSegments => _routeSegments;

  List<Point>? _greenPolyline;
  List<Point>? get greenPolyline => _greenPolyline;

  double _routeDistanceKm = 0;
  double get routeDistanceKm => _routeDistanceKm;

  int _routeDurationHours = 0;
  int get routeDurationHours => _routeDurationHours;

  /// true — реальный маршрут по дорогам; false — Haversine-fallback.
  bool _isRealRoute = false;
  bool get isRealRoute => _isRealRoute;

  // Текущий шаг и ошибки
  RouteBuilderStep _step = RouteBuilderStep.placePoints;
  RouteBuilderStep get step => _step;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Локализованные метки. Обновляются из build()-метода экрана.
  RouteBuilderLabels _labels = RouteBuilderLabels.defaults;

  void updateLabels(RouteBuilderLabels labels) {
    _labels = labels;
  }

  // в”Ђв”Ђ Управление точками в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

  Future<void> addWaypoint(double latitude, double longitude) async {
    // Если есть активный pending-слот — заполняем именно его.
    if (_activePendingIndex != null) {
      final idx = _activePendingIndex!;
      if (idx < _waypoints.length && _waypoints[idx].isPending) {
        _waypoints[idx] = _waypoints[idx].filledWith(latitude, longitude);
        _routePolyline = [];
        _routeSegments = [];
        _recomputeAll();
        await _precacheAllMarkers();
        // Автоматически переключаемся на следующий pending-слот (if any)
        _activePendingIndex = _nextPendingIndex();
        notifyListeners();
        return;
      }
    }

    // Fallback: если есть любой pending без активного — заполняем первый
    final pendingIndex = _waypoints.indexWhere((w) => w.isPending);
    if (pendingIndex != -1) {
      _waypoints[pendingIndex] = _waypoints[pendingIndex].filledWith(latitude, longitude);
      _routePolyline = [];
      _routeSegments = [];
      _recomputeAll();
      await _precacheAllMarkers();
      _activePendingIndex = _nextPendingIndex();
      notifyListeners();
      return;
    }

    if (!canAddMore) return;

    _waypoints.add(
      RouteWaypoint(
        latitude: latitude,
        longitude: longitude,
        name: '', // заполнит _recomputeAll
        color: RouteWaypoint.colorMid,
      ),
    );

    _routePolyline = [];
    _routeSegments = [];
    _recomputeAll();
    await _precacheAllMarkers();
    notifyListeners();
  }

  /// Возвращает индекс следующего pending-слота после текущего, null если нет.
  int? _nextPendingIndex() {
    for (int i = 0; i < _waypoints.length; i++) {
      if (_waypoints[i].isPending) return i;
    }
    return null;
  }

  Future<void> removeLastWaypoint() async {
    if (_waypoints.isEmpty) return;
    _waypoints.removeLast();
    _routePolyline = [];
    _routeSegments = [];
    _recomputeAll();
    await _precacheAllMarkers();
    notifyListeners();
  }

  /// Помечает точку как «ожидает переназначения».
  /// Слот остаётся в списке с тем же именем/цветом, но isPending = true.
  /// Следующее нажатие на карту заполнит этот слот новыми координатами.
  /// Кнопка «Построить маршрут» блокируется автоматически (canBuildRoute).
  Future<void> markWaypointPending(int index) async {
    if (index < 0 || index >= _waypoints.length) return;
    _waypoints[index] = _waypoints[index].asPending();
    _routePolyline = [];
    _routeSegments = [];
    // Если активного pending нет — автоэти выбираем этот слот
    _activePendingIndex ??= index;
    notifyListeners();
  }

  /// Выбирает конкретный pending-слот как активный.
  /// Следующий тап на карте заполнит именно этот слот.
  void selectPendingSlot(int index) {
    if (index < 0 || index >= _waypoints.length) return;
    if (!_waypoints[index].isPending) return;
    _activePendingIndex = index;
    notifyListeners();
  }

  /// Пересчитывает имя и цвет КАЖДОЙ точки по её позиции в списке.
  /// Вызывать после любого изменения _waypoints.
  void _recomputeAll() {
    final n = _waypoints.length;
    for (var i = 0; i < n; i++) {
      final w = _waypoints[i];
      final Color color;
      final String name;
      if (i == 0) {
        color = RouteWaypoint.colorStart;
        name = _labels.waypointStart;
      } else if (i == n - 1) {
        color = RouteWaypoint.colorEnd;
        name = _labels.waypointFinish;
      } else {
        color = RouteWaypoint.colorMid;
        name = _labels.waypointMid(i);
      }
      _waypoints[i] = RouteWaypoint(
        latitude: w.latitude,
        longitude: w.longitude,
        name: name,
        color: color,
        isPending: w.isPending, // сохраняем флаг pending!
      );
    }
  }

  void clearWaypoints() {
    _waypoints.clear();
    _markerCache.clear();
    _activePendingIndex = null;
    _routePolyline = [];
    _routeSegments = [];
    _greenPolyline = null;
    _routeDistanceKm = 0;
    _routeDurationHours = 0;
    _step = RouteBuilderStep.placePoints;
    _errorMessage = null;
    notifyListeners();
  }

  // в”Ђв”Ђ Построение маршрута в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

  Future<void> buildRoute(Point? userPos) async {
    if (!canBuildRoute) return;

    _step = RouteBuilderStep.buildingRoute;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await YandexDirectionsService.getRoute(_waypoints);
      _routeSegments = result.segments;
      _routePolyline = result.points;
      _routeDistanceKm = result.distanceKm;
      _routeDurationHours = result.durationHours;
      _isRealRoute = result.isRealRoute;

      if (!result.isRealRoute) {
        // Мы больше не показываем ошибку при fallback, маршрут просто отрисуется прямыми линиями.
        // _errorMessage = _labels.errorFallback;
      }

      if (userPos != null && _waypoints.isNotEmpty) {
        final distToStart = RouteCalculator.calculateDistance(
          userPos.latitude,
          userPos.longitude,
          _waypoints.first.latitude,
          _waypoints.first.longitude,
        );

        if (distToStart > 0.1) {
          final greenResult = await YandexDirectionsService.getRoute([
            RouteWaypoint(
              latitude: userPos.latitude,
              longitude: userPos.longitude,
              name: _labels.myLocationLabel,
              color: Colors.green,
            ),
            _waypoints.first,
          ]);
          _greenPolyline = greenResult.points;
        } else {
          _greenPolyline = null;
        }
      } else {
        _greenPolyline = null;
      }
    } catch (e) {
      debugPrint('[RouteBuilderController] Ошибка: $e');
      _errorMessage = _labels.errorBuild;
    }

    _step = RouteBuilderStep.routeReady;
    notifyListeners();
  }

  // в”Ђв”Ђ Навигация по шагам в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

  void proceedToDetails() {
    if (_step != RouteBuilderStep.routeReady) return;
    _step = RouteBuilderStep.fillDetails;
    notifyListeners();
  }

  void backToRouteReady() {
    if (_step != RouteBuilderStep.fillDetails) return;
    _step = RouteBuilderStep.routeReady;
    notifyListeners();
  }

  // в”Ђв”Ђ Сохранение бронирования в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

  /// Создаёт бронирование по текущему маршруту.
  /// Стоимость: 100 в‚ё/км, минимум 500 в‚ё.
  Future<Booking> saveRoute({
    required List<String> waypointDates,
    required int participants,
    String? guideId,
    String? guideName,
    String? driverId,
    String? driverName,
    String? phoneNumber,
    bool insuranceIncluded = false,
    String? customRouteTitle,
    double? driverEarning,
    double? guideEarning,
    List<CompanionInfo> companions = const [],
  }) async {
    if (_waypoints.isEmpty) {
      throw StateError(
        '[RouteBuilderController] saveRoute() called with no waypoints',
      );
    }
    final count = DateTime.now().microsecondsSinceEpoch % 10000;
    final routeTitle = customRouteTitle ?? '${_labels.defaultRouteTitle} #$count';
    final coordinates = _waypoints
        .map((w) => (w.latitude, w.longitude))
        .toList();

    final int D = 1; // Basic assumption for simple custom routes (1 day)

    // Use the pre-computed earnings from booking_screen if provided (they use
    // the driver's real pricePerKm). Fall back to stub only when building
    // a route without a driver selected (rare edge-case).
    double pTransport = driverEarning ?? (_routeDistanceKm * 300.0);
    double pService = guideEarning ?? (guideId != null ? 30000.0 * D : 0.0);

    final ecoPerson = 1000.0;
    final ecoAuto = 2000.0;
    final sIns = insuranceIncluded ? 3000.0 : 0.0;
    double pFixed =
        (ecoPerson * participants) + ecoAuto + (sIns * participants);

    // 15% Platform markup
    final kMargin = 1.15;
    double estimatedTotalPrice = (pTransport + pService) * kMargin + pFixed;
    final totalPrice = estimatedTotalPrice.clamp(500.0, double.infinity);

    final userId =
        AuthService.instance.currentFirebaseUser?.uid ?? 'guest_user';

    final meetingPoints = <MeetingPoint>[];
    for (int i = 0; i < _waypoints.length; i++) {
      meetingPoints.add(
        MeetingPoint(
          address: _waypoints[i].name,
          latitude: _waypoints[i].latitude,
          longitude: _waypoints[i].longitude,
          time: waypointDates.length > i
              ? waypointDates[i]
              : waypointDates.last,
          isConfirmed: false,
        ),
      );
    }

    final booking = Booking(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      routeId: 'custom',
      routeTitle: routeTitle,
      guideId: guideId,
      guideName: guideName,
      driverId: driverId,
      driverName: driverName,
      partnerId: driverId,
      startDate: meetingPoints.first.time,
      endDate: meetingPoints.last.time,
      createdAt: DateTime.now().toIso8601String(),
      participants: participants,
      totalPrice: totalPrice,
      status: BookingStatus.pending, // Starts waiting for the scheduled date
      insuranceIncluded: insuranceIncluded,
      phoneNumber: phoneNumber,
      customRouteCoordinates: coordinates,
      isCustomRoute: true,
      waypoints: meetingPoints,
      driverEarning: driverEarning,
      guideEarning: guideEarning,
    );

    final activeTrip = ActiveTrip(
      id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      driverId: driverId,
      guideId: guideId,
      partnerId: driverId,
      bookingId: booking.id,
      status: 'scheduled',
      createdAt: DateTime.now().toIso8601String(),
      driverLocation: null,
      customName: routeTitle,
      // routeGeometry was previously storing the polyline array in Firebase,
      // but Firebase ActiveTrip updates constantly (with driver GPS),
      // which blew up bandwidth. Now we rebuild dynamically strictly from waypoints!
      routeGeometry: const [],
      waypoints: meetingPoints,
      estimatedArrivalTime: null,
      companions: companions,
      participantIds: [userId, ...companions.map((c) => c.uid)],
    );

    await FirestoreDataRepository.instance.createActiveTrip(activeTrip);
    await FirestoreDataRepository.instance.saveBooking(booking);

    return booking;
  }

  // в”Ђв”Ђ Объекты карты в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

  /// Собирает PlacemarkMapObject для каждой точки и Polyline для маршрута.
  /// Использует кэшированные PNG-маркеры из [_markerCache].
  List<MapObject> buildMapObjects(Point? userPos) {
    final objects = <MapObject>[];

    for (var i = 0; i < _waypoints.length; i++) {
      final w = _waypoints[i];
      final cacheKey = '${w.color.toARGB32()}_${i + 1}';
      final cachedBytes = _markerCache[cacheKey];

      objects.add(
        PlacemarkMapObject(
          mapId: MapObjectId('waypoint_$i'),
          point: Point(latitude: w.latitude, longitude: w.longitude),
          opacity: 1,
          icon: cachedBytes != null
              // Кастомный PNG-маркер
              ? PlacemarkIcon.single(
                  PlacemarkIconStyle(
                    image: BitmapDescriptor.fromBytes(cachedBytes),
                    // Якорь по центру низа пина (хвостик указывает на точку)
                    anchor: const Offset(0.5, 1.0),
                    scale: 1.0,
                  ),
                )
              // Fallback пока маркер не сгенерирован
              : PlacemarkIcon.single(
                  PlacemarkIconStyle(
                    image: BitmapDescriptor.fromAssetImage(
                      'packages/yandex_mapkit/lib/assets/place.png',
                    ),
                    scale: 1.2,
                  ),
                ),
          text: PlacemarkText(
            text: w.name,
            style: PlacemarkTextStyle(
              size: 11,
              color: ui.Color(w.color.toARGB32()),
              outlineColor: const ui.Color(0xFFFFFFFF),
              placement: TextStylePlacement.top,
            ),
          ),
        ),
      );
    }

    // Линия маршрута
    if (_step == RouteBuilderStep.routeReady && _routeSegments.isNotEmpty) {
      for (int i = 0; i < _routeSegments.length; i++) {
        final segment = _routeSegments[i];
        if (segment.points.isEmpty) continue;

        objects.add(
          PolylineMapObject(
            mapId: MapObjectId('route_segment_$i'),
            polyline: Polyline(points: segment.points),
            // 🔵 Blue  = driveable road (YandexDriving succeeded)
            // 🟠 Orange = pedestrian / offroad (no car road — guide walking segment)
            strokeColor: segment.isRealRoute
                ? const Color(0xFF1565C0)
                : const Color(0xFFFF6F00),
            strokeWidth: segment.isRealRoute ? 5.0 : 4.0,
            outlineColor: segment.isRealRoute
                ? const Color(0x441565C0)
                : const Color(0x44FF6F00),
            outlineWidth: 2.0,
            // Dashed orange line makes it immediately clear this part has no road
            dashLength: segment.isRealRoute ? 0.0 : 10.0,
            gapLength: segment.isRealRoute ? 0.0 : 6.0,
          ),
        );
      }
    } else if (_waypoints.length > 1 && _step == RouteBuilderStep.placePoints) {
      objects.add(
        PolylineMapObject(
          mapId: const MapObjectId('route_preview'),
          polyline: Polyline(
            points: _waypoints
                .map((w) => Point(latitude: w.latitude, longitude: w.longitude))
                .toList(),
          ),
          strokeColor: const Color(0xFF90A4AE),
          strokeWidth: 2.5,
          dashLength: 10.0,
          dashOffset: 0,
          gapLength: 6.0,
        ),
      );
    }

    // Зеленая линия транзита
    if (_step == RouteBuilderStep.routeReady &&
        (_greenPolyline?.isNotEmpty ?? false)) {
      objects.add(
        PolylineMapObject(
          mapId: const MapObjectId('route_green_transit'),
          polyline: Polyline(points: _greenPolyline!),
          strokeColor: Colors.green,
          strokeWidth: 4.0,
          outlineColor: Colors.green.withValues(alpha: 0.3),
          outlineWidth: 2.0,
        ),
      );
    } else if (userPos != null &&
        _waypoints.isNotEmpty &&
        _step == RouteBuilderStep.placePoints) {
      objects.add(
        PolylineMapObject(
          mapId: const MapObjectId('route_green_preview'),
          polyline: Polyline(
            points: [
              userPos,
              Point(
                latitude: _waypoints.first.latitude,
                longitude: _waypoints.first.longitude,
              ),
            ],
          ),
          strokeColor: Colors.green.withValues(alpha: 0.7),
          strokeWidth: 2.5,
          dashLength: 8.0,
          dashOffset: 0,
          gapLength: 6.0,
        ),
      );
    }

    return objects;
  }

  // в”Ђв”Ђ Внутренние методы в”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђв”Ђ

  /// Генерирует и кэширует PNG-маркер для каждой точки в списке.
  /// Ключ кэша = '${color.value}_${number}' чтобы один и тот же цвет
  /// с разными номерами рендерился отдельно.
  Future<void> _precacheAllMarkers() async {
    for (var i = 0; i < _waypoints.length; i++) {
      final w = _waypoints[i];
      final number = i + 1;
      final cacheKey = '${w.color.toARGB32()}_$number';
      if (!_markerCache.containsKey(cacheKey)) {
        final bytes = await WaypointMarkerPainter.generate(
          color: w.color,
          number: number,
        );
        _markerCache[cacheKey] = bytes;
      }
    }
  }
}



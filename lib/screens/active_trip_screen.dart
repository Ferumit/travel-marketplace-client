import '../theme/app_colors.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../models/booking_models.dart';
import '../models/user_models.dart';
import '../repository/firestore_data_repository.dart';
import '../route_builder/route_waypoint.dart';
import '../route_builder/yandex_directions_service.dart';
import '../services/auth_service.dart';
import '../theme/theme.dart';
import '../utils/date_formatter.dart';
import '../utils/user_marker_painter.dart';
import '../widgets/navigation_overlay.dart';
import '../l10n/app_localizations.dart';

class ActiveTripScreen extends StatefulWidget {
  final String tripId;
  const ActiveTripScreen({super.key, required this.tripId});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  late YandexMapController _mapController;
  StreamSubscription<ActiveTrip?>? _tripSubscription;
  ActiveTrip? _currentTrip;
  String? _prevDriverId;
  Booking? _booking;
  bool _isCancelled = false;
  bool _isLoading = true;
  bool _isMapCreated = false;
  bool _isTransitioning = false;
  bool _isConfirming = false; // client confirming driver's completion request

  // Dynamic route segments generated explicitly on client, eliminating Firebase payload bloat!
  List<RouteSegment>? _dynamicRouteSegments;

  // Cached marker icon bytes
  Uint8List? _carIconBytes;
  Uint8List? _guideIconBytes;
  Uint8List? _clientIconBytes;

  // Navigation state
  double _currentSpeedKmh = 0.0;
  TurnInstruction? _nextTurn;
  StreamSubscription<Position>? _positionSubscription;
  double _driverHeading = 0.0;
  (double, double)? _prevDriverLocation;

  // Lifecycle stage order
  static const _stages = ['scheduled', 'waiting', 'in_progress', 'completed'];

  // Mapping from status stage to l10n getter will be done inside build methods
  // as AppLocalizations requires BuildContext. We'll use a helper method.

  @override
  void initState() {
    super.initState();
    _initStream();
    _initPositionStream();
    _initCarIcon();
    _initGuideIcon();
    _initClientIcon();
  }

  Future<void> _initCarIcon() async {
    final data = await UserMarkerPainter.driver();
    if (data != null && mounted) setState(() => _carIconBytes = data);
  }

  Future<void> _initGuideIcon() async {
    final data = await UserMarkerPainter.guide();
    if (data != null && mounted) setState(() => _guideIconBytes = data);
  }

  Future<void> _initClientIcon() async {
    final data = await UserMarkerPainter.client();
    if (data != null && mounted) setState(() => _clientIconBytes = data);
  }

  void _initPositionStream() async {
    final perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return;
    }

    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 2,
          ),
        ).listen((pos) {
          if (!mounted) return;
          setState(() {
            _currentSpeedKmh = pos.speed * 3.6; // m/s to km/h
          });
          final uid = AuthService.instance.currentFirebaseUser?.uid;
          if (_currentTrip != null && uid != null) {
            if (_currentTrip!.userId == uid) {
              FirestoreDataRepository.instance.updateClientLocation(
                widget.tripId, pos.latitude, pos.longitude,
              );
            } else if (_currentTrip!.companions.any((c) => c.uid == uid)) {
              FirestoreDataRepository.instance.updateCompanionLocation(
                widget.tripId, uid, pos.latitude, pos.longitude,
              );
            }
          } else {
            // _currentTrip is null during the first async load — skip the write
            // to avoid unnecessary Firestore traffic before the trip is known.
            if (_currentTrip != null) {
              FirestoreDataRepository.instance.updateClientLocation(
                widget.tripId, pos.latitude, pos.longitude,
              );
            }
          }
          _calculateNextTurn(pos.latitude, pos.longitude);
        });
  }

  void _initStream() {
    _tripSubscription = FirestoreDataRepository.instance
        .streamSpecificActiveTrip(widget.tripId)
        .listen((trip) async {
          if (trip != null && _booking == null) {
            final b = await FirestoreDataRepository.instance.getBookingById(
              trip.bookingId,
            );
            if (mounted) setState(() => _booking = b);
          }

          // If the trip is marked as completed (from driver or passenger),
          // immediately navigate to the completion screen.
          if (trip != null && trip.status == 'completed' && mounted) {
            context.go('/trip_completed/${trip.id}');
            return;
          }

          // Detect driver decline
          if (_prevDriverId != null && trip != null && trip.driverId == null && trip.status == 'scheduled') {
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(
                   content: Text('Водитель отказался от заказа. Ищем нового...'),
                   backgroundColor: Colors.orange,
                   duration: Duration(seconds: 5),
                 ),
               );
             }
          }

          // Detect trip cancellation by driver
          if (!_isCancelled && trip != null && trip.status == 'cancelled' && mounted) {
             _isCancelled = true;
             _showCancellationDialog();
             return;
          }

          // Also check booking status as a backup
          if (!_isCancelled && _booking != null && _booking?.status == BookingStatus.cancelled && mounted) {
             _isCancelled = true;
             _showCancellationDialog();
             return;
          }

          if (mounted) {
            if (trip != null) {
              _prevDriverId = trip.driverId;
              if (_prevDriverLocation != null && trip.driverLocation != null) {
                _driverHeading = _calculateBearing(
                  _prevDriverLocation!.$1,
                  _prevDriverLocation!.$2,
                  trip.driverLocation!.$1,
                  trip.driverLocation!.$2,
                );
              }
              if (trip.driverLocation != null) {
                _prevDriverLocation = trip.driverLocation;
              }
            }

            setState(() {
              _currentTrip = trip;
              _isLoading = false;
            });
            
            // Build dynamic high-resolution route locally if not built yet 
            if (_dynamicRouteSegments == null && trip != null && trip.waypoints.isNotEmpty) {
              _fetchDynamicRoute(trip.waypoints);
            }
          }
          if (trip != null && _isMapCreated && trip.status == 'in_progress') {
            _updateMapBounds(trip);
          }
        });
  }

  @override
  void dispose() {
    _tripSubscription?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  void _updateMapBounds(ActiveTrip trip) async {
    if (trip.routeGeometry.isEmpty && trip.driverLocation == null) return;
    final targetPoint = trip.driverLocation != null
        ? Point(
            latitude: trip.driverLocation!.$1,
            longitude: trip.driverLocation!.$2,
          )
        : Point(
            latitude: trip.routeGeometry.first.$1,
            longitude: trip.routeGeometry.first.$2,
          );
    await _mapController.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: targetPoint, zoom: 15.0),
      ),
      animation: const MapAnimation(
        type: MapAnimationType.smooth,
        duration: 1.5,
      ),
    );
  }

  void _showCancellationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Поездка отменена'),
        content: const Text(
            'К сожалению, водитель отменил поездку. Вы можете забронировать новый маршрут.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // dialog
              context.go('/home'); // home
            },
            child: const Text('Вернуться на главную'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchDynamicRoute(List<MeetingPoint> wp) async {
    final routeWaypoints = wp.map((pt) {
      return RouteWaypoint(
        latitude: pt.latitude,
        longitude: pt.longitude,
        name: pt.address,
        color: RouteWaypoint.colorMid,
      );
    }).toList();
    
    // Assign proper start/end colors visually (optional, just for strictness)
    if (routeWaypoints.isNotEmpty) {
      routeWaypoints.first = routeWaypoints.first.withColor(RouteWaypoint.colorStart);
      routeWaypoints.last = routeWaypoints.last.withColor(RouteWaypoint.colorEnd);
    }
    
    final result = await YandexDirectionsService.getRoute(routeWaypoints);
    if (!mounted) return;
    
    setState(() {
      _dynamicRouteSegments = result.segments;
    });
  }

  List<MapObject> _buildMapObjects() {
    if (_currentTrip == null) return [];
    final objects = <MapObject>[];
    final trip = _currentTrip!;
    
    if (_dynamicRouteSegments != null && _dynamicRouteSegments!.isNotEmpty) {
      for (int i = 0; i < _dynamicRouteSegments!.length; i++) {
        final segment = _dynamicRouteSegments![i];
        objects.add(
          PolylineMapObject(
            mapId: MapObjectId('route_segment_$i'),
            polyline: Polyline(points: segment.points),
            // blue for roads, orange dashed for offroad/pedestrian
            strokeColor: segment.isRealRoute
                ? const Color(0xFF1565C0)
                : const Color(0xFFFF6F00),
            strokeWidth: segment.isRealRoute ? 5.0 : 4.0,
            outlineColor: segment.isRealRoute
                ? const Color(0x441565C0)
                : const Color(0x44FF6F00),
            outlineWidth: 2.0,
            dashLength: segment.isRealRoute ? 0.0 : 10.0,
            gapLength: segment.isRealRoute ? 0.0 : 6.0,
          ),
        );
      }
    } else if (trip.routeGeometry.isNotEmpty) {
      // Legacy fallback just in case trip has old geometry 

      objects.add(
        PolylineMapObject(
          mapId: const MapObjectId('route_polyline'),
          polyline: Polyline(
            points: trip.routeGeometry
                .map((p) => Point(latitude: p.$1, longitude: p.$2))
                .toList(),
          ),
          strokeColor: AppColors.accent,
          strokeWidth: 4,
          outlineColor: Colors.white,
          outlineWidth: 1,
        ),
      );
    }
    if (trip.driverLocation != null && _carIconBytes != null) {
      objects.add(
        PlacemarkMapObject(
          mapId: const MapObjectId('driver_location'),
          zIndex: 105,
          point: Point(
            latitude: trip.driverLocation!.$1,
            longitude: trip.driverLocation!.$2,
          ),
          direction: _driverHeading, // Align with movement
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(
              image: BitmapDescriptor.fromBytes(_carIconBytes!),
              scale: 1.0,
              rotationType: RotationType.rotate,
            ),
          ),
        ),
      );
    }
    if (trip.guideLocation != null && _guideIconBytes != null) {
      objects.add(
        PlacemarkMapObject(
          mapId: const MapObjectId('guide_location'),
          zIndex: 100,
          point: Point(
            latitude: trip.guideLocation!.$1,
            longitude: trip.guideLocation!.$2,
          ),
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(
              image: BitmapDescriptor.fromBytes(_guideIconBytes!),
              scale: 1.2,
              rotationType: RotationType.noRotation,
            ),
          ),
        ),
      );
    }
    if (trip.clientLocation != null && _clientIconBytes != null) {
      objects.add(
        PlacemarkMapObject(
          mapId: const MapObjectId('client_location'),
          zIndex: 110,
          point: Point(
            latitude: trip.clientLocation!.$1,
            longitude: trip.clientLocation!.$2,
          ),
          icon: PlacemarkIcon.single(
            PlacemarkIconStyle(
              image: BitmapDescriptor.fromBytes(_clientIconBytes!),
              scale: 1.2,
              rotationType: RotationType.noRotation,
            ),
          ),
        ),
      );
    }
    
    for (var companion in trip.companions) {
      final loc = trip.companionLocations[companion.uid];
      if (loc != null && _clientIconBytes != null) {
        objects.add(
          PlacemarkMapObject(
            mapId: MapObjectId('companion_${companion.uid}'),
            zIndex: 108,
            point: Point(latitude: loc['lat']!, longitude: loc['lng']!),
            icon: PlacemarkIcon.single(
              PlacemarkIconStyle(
                image: BitmapDescriptor.fromBytes(_clientIconBytes!),
                scale: 1.1,
                rotationType: RotationType.noRotation,
              ),
            ),
          ),
        );
      }
    }
    
    return objects;
  }

  // Haversine distance in metres
  double _distanceM(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _toRad(double deg) => deg * math.pi / 180;

  double _calculateBearing(double lat1, double lng1, double lat2, double lng2) {
    final dLon = _toRad(lng2 - lng1);
    final y = math.sin(dLon) * math.cos(_toRad(lat2));
    final x =
        math.cos(_toRad(lat1)) * math.sin(_toRad(lat2)) -
        math.sin(_toRad(lat1)) * math.cos(_toRad(lat2)) * math.cos(dLon);
    var brng = math.atan2(y, x);
    brng = brng * 180 / math.pi;
    return (brng + 360) % 360;
  }

  double _calculateAngle(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
    double lat3,
    double lng3,
  ) {
    final bearing1 = _calculateBearing(lat1, lng1, lat2, lng2);
    final bearing2 = _calculateBearing(lat2, lng2, lat3, lng3);
    var angle = bearing2 - bearing1;
    if (angle > 180) angle -= 360;
    if (angle < -180) angle += 360;
    return angle;
  }

  void _calculateNextTurn(double currentLat, double currentLng) {
    if (_currentTrip == null || _currentTrip!.routeGeometry.isEmpty) return;

    final route = _currentTrip!.routeGeometry;

    // Find closest point on route
    int closestIdx = 0;
    double minDistance = double.infinity;
    for (int i = 0; i < route.length; i++) {
      final dist = _distanceM(currentLat, currentLng, route[i].$1, route[i].$2);
      if (dist < minDistance) {
        minDistance = dist;
        closestIdx = i;
      }
    }

    // Look ahead to find a turn
    TurnInstruction? newInstruction;
    for (int i = closestIdx + 1; i < route.length - 1; i++) {
      final p1 = route[i - 1];
      final p2 = route[i];
      final p3 = route[i + 1];

      final angle = _calculateAngle(p1.$1, p1.$2, p2.$1, p2.$2, p3.$1, p3.$2);
      if (angle.abs() > 25.0) {
        // arbitrary threshold for a turn
        final distToTurn = _distanceM(currentLat, currentLng, p2.$1, p2.$2);

        TurnDirection dir = TurnDirection.straight;
        if (angle > 70) {
          dir = TurnDirection.right;
        } else if (angle < -70) {
          dir = TurnDirection.left;
        } else if (angle > 25) {
          dir = TurnDirection.slightRight;
        } else if (angle < -25) {
          dir = TurnDirection.slightLeft;
        }

        newInstruction = TurnInstruction(dir, distToTurn);
        break;
      }
    }

    // If no sharp turns, maybe just destination
    if (newInstruction == null) {
      final dest = route.last;
      final dist = _distanceM(currentLat, currentLng, dest.$1, dest.$2);
      newInstruction = TurnInstruction(TurnDirection.destination, dist);
    }

    if (mounted) setState(() => _nextTurn = newInstruction);
  }

  /// Check proximity and mark clientReady before allowing in_progress transition.
  /// Returns true if all required parties are ready.
  Future<bool> _checkProximityAndSetReady(ActiveTrip trip) async {
    final mp = _booking?.waypoints.firstOrNull;
    if (mp == null) return true; // no meeting point defined, skip check

    // Check/request location permission
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.activeTripLocationPermError,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    /*
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    );
    final dist = _distanceM(
      pos.latitude,
      pos.longitude,
      mp.latitude,
      mp.longitude,
    );
    */

    /*
    if (dist > 100) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.activeTripProximityError(dist.toStringAsFixed(0)),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return false;
    }
    */

    // Mark ready
    final uid = AuthService.instance.currentFirebaseUser?.uid;
    final isCompanion = uid != null && trip.userId != uid && trip.companions.any((c) => c.uid == uid);
    
    if (isCompanion) {
      await FirestoreDataRepository.instance.setCompanionReady(trip.id, uid);
    } else {
      await FirestoreDataRepository.instance.setClientReady(trip.id);
    }

    // ACTUAL re-read the trip from Firestore to prevent race conditions
    // when both participants press "Я на месте" at the same time.
    final latestTrip = await FirestoreDataRepository.instance.getTripById(trip.id);
    if (latestTrip == null) return false;

    // TODO(temp): Bypass guide wait since test bookings have dummy guides but no 3rd device
    final driverOk = latestTrip.driverReady;
    final guideOk = true; // !hasGuide || latestTrip.guideReady;
    final companionsOk = latestTrip.companions.every((c) => c.ready);

    if (!driverOk || !guideOk || !companionsOk) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        final missing = <String>[];
        if (!driverOk) missing.add(l10n.activeTripDriver);
        // if (!guideOk) missing.add(l10n.activeTripGuide);
        if (!companionsOk) missing.add('других клиентов');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.activeTripWaitingForOthers(missing.join(', ')),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return false;
    }

    // ── Баг-фикс: Если все готовы, клиент тоже может стартовать поездку ──
    // Это предотвращает зависание, если клиент нажал "Я на месте" после водителя.
    await FirestoreDataRepository.instance.startTrip(trip.id, trip.bookingId);

    return true;
  }

  /// Advance to the next lifecycle stage
  Future<void> _advanceStage() async {
    if (_currentTrip == null || _isTransitioning) return;
    final idx = _stages.indexOf(_currentTrip!.status);
    if (idx < 0 || idx >= _stages.length - 1) return;

    final nextTripStatus = _stages[idx + 1];

    // ── Баг-фикс: если водитель ещё не принял заказ, блокируем кнопку ──────
    if (nextTripStatus == 'waiting' && _currentTrip!.driverId != null && !(_currentTrip!.driverAccepted)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏳ Ожидаем подтверждения водителя. Как только он примет заказ, вы сможете отметить прибытие.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    // --- waiting → in_progress: client just marks readiness and waits.
    // The partner app's startTrip() transaction is the SOLE authority that
    // writes status=in_progress (it also initialises waypointCheckIns atomically).
    // Writing in_progress from the client would race against the partner write.
    if (nextTripStatus == 'in_progress') {
      final allowed = await _checkProximityAndSetReady(_currentTrip!);
      if (!mounted) return;
      if (!allowed) return;
      // Client is ready — show a waiting snackbar. The stream listener in
      // _initStream() will navigate when the partner transitions the trip.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Все участники на месте. Начинаем поездку!'),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 4),
        ),
      );
      return; // ← do NOT call _writeBatchWithRetry here
    }

    setState(() => _isTransitioning = true);

    try {
      await _writeBatchWithRetry(nextTripStatus);

      if (nextTripStatus == 'completed') {
        if (_booking != null && _booking!.isCustomRoute) {
          await FirestoreDataRepository.instance.saveCompletedCustomRoute(
            _booking!,
          );
        }
        // Navigation is now handled by the stream listener in _initStream
      }
    } catch (e) {
      debugPrint('[ActiveTripScreen] Ошибка обновления статуса: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.activeTripSaveErrorQuota,
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTransitioning = false);
    }
  }

  /// Single batch write with exponential backoff on RESOURCE_EXHAUSTED
  Future<void> _writeBatchWithRetry(String nextTripStatus) async {
    BookingStatus nextBookingStatus;
    switch (nextTripStatus) {
      case 'waiting':
        nextBookingStatus = BookingStatus.confirmed;
      case 'in_progress':
        nextBookingStatus = BookingStatus.inProgress;
      case 'completed':
        nextBookingStatus = BookingStatus.completed;
      default:
        nextBookingStatus = BookingStatus.pending;
    }

    const maxAttempts = 4;
    var delay = const Duration(seconds: 2);

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        List<dynamic>? initialWaypoints;
        if (nextTripStatus == 'in_progress' && _currentTrip != null) {
          // Reset checkIns on all waypoints to empty maps so each participant
          // can check in fresh. The Map keys are written atomically by checkInAtWaypoint.
          initialWaypoints = _currentTrip!.waypoints.map((wp) {
            return {
              'address': wp.address,
              'latitude': wp.latitude,
              'longitude': wp.longitude,
              'time': wp.time,
              'isConfirmed': wp.isConfirmed,
              'checkIns': <String, dynamic>{},
            };
          }).toList();
        }

        // Combine all writes into ONE batch → single network round-trip
        await FirestoreDataRepository.instance.completeTripBatch(
          tripId: _currentTrip!.id,
          tripStatus: nextTripStatus,
          bookingId: _booking?.id,
          bookingStatus: _booking != null ? nextBookingStatus : null,
          initialWaypoints: initialWaypoints,
        );
        return; // success
      } catch (e) {
        final isExhausted = e.toString().contains('RESOURCE_EXHAUSTED');
        if (!isExhausted || attempt == maxAttempts) rethrow;
        debugPrint(
          '[ActiveTripScreen] RESOURCE_EXHAUSTED (attempt $attempt/$maxAttempts), '
          'retrying in ${delay.inSeconds}s…',
        );
        await Future.delayed(delay);
        delay *= 2; // exponential backoff: 2s → 4s → 8s
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    if (_currentTrip == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.chevronLeft),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(
            l10n.activeTripNotFound,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    final trip = _currentTrip!;
    final isScheduled = trip.status == 'scheduled';
    final isWaiting = trip.status == 'waiting';
    final isInProgress = trip.status == 'in_progress';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Map (always shown as background)
          YandexMap(
            mapObjects: _buildMapObjects(),
            onMapCreated: (controller) async {
              _mapController = controller;
              _isMapCreated = true;
              await controller.toggleUserLayer(visible: true);
              _updateMapBounds(trip);
            },
            nightModeEnabled: true,
          ),

          // Navigation UI overlay (Speedometer and Turn Indicator)
          if (isInProgress)
            NavigationOverlay(speedKmh: _currentSpeedKmh, nextTurn: _nextTurn),

          // Top back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: CircleAvatar(
              backgroundColor: AppColors.surface,
              child: IconButton(
                icon: Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              ),
            ),
          ),
          
          if (trip.userId == AuthService.instance.currentFirebaseUser?.uid)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: CircleAvatar(
                backgroundColor: AppColors.surface,
                child: IconButton(
                  icon: Icon(LucideIcons.userPlus, color: AppColors.accent),
                  onPressed: () => _showAddCompanionSheet(trip, l10n),
                ),
              ),
            ),

          // Draggable Bottom panel
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.15,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 12,
                    bottom: MediaQuery.of(context).padding.bottom + 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary.withValues(alpha: 0.24),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Lifecycle stage indicator
                      _buildStageIndicator(trip.status),
                      const SizedBox(height: 20),

                      if (isInProgress) _buildWaypointCheckIn(trip),

                      // Route title
                      Text(
                        _booking?.routeTitle ?? l10n.activeTripDefaultTitle,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      if (_booking != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                                LucideIcons.calendar,
                                color: AppColors.textSecondary,
                                size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                DateFormatter.formatTripDates(
                                  _booking!.startDate,
                                  _booking!.endDate,
                                ),
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Stage-specific info
                      if (isScheduled) _buildScheduledInfo(l10n),
                      if (isWaiting) _buildWaitingInfo(l10n),

                      // New embedded booking info
                      if (!isInProgress && _booking != null) ...[
                        const SizedBox(height: 24),
                        _buildBookingDetailsCard(l10n),
                      ],

                      if (isInProgress && trip.estimatedArrivalTime != null)
                        Row(
                          children: [
                            Icon(
                                LucideIcons.clock,
                                size: 14,
                                color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.activeTripEta(DateFormatter.formatTimeOnly(trip.estimatedArrivalTime!)),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 20),

                      // ── Three-way completion logic ──────────────────────
                      if (isInProgress) ...[
                        () {
                          final hasGuide = _booking?.guideId != null;
                          final driverDone = trip.driverCompletionRequested;
                          final guideDone = !hasGuide || trip.guideCompletionRequested;
                          final allDone = driverDone && guideDone;
                          // Legacy single-flag fallback
                          final legacyRequested = trip.completionRequested && !driverDone && !guideDone;
                          final anyRequested = driverDone || guideDone || legacyRequested;

                          if (!anyRequested) return const SizedBox.shrink();

                          if (!allDone && !legacyRequested) {
                            // Some but not all parties confirmed — show pending banner
                            final pendingList = [
                              if (!driverDone) 'водитель',
                              if (hasGuide && !guideDone) 'гид',
                            ].join(', ');
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.clock, color: Colors.orange, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Ожидаем подтверждения завершения от: $pendingList',
                                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // All parties confirmed — show client confirm button
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34C759).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF34C759).withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.flag, color: Color(0xFF34C759), size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        l10n.activeTripDriverCompleted,
                                        style: const TextStyle(
                                          color: Color(0xFF34C759),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.activeTripConfirmCompletionDesc,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton.icon(
                                    onPressed: _isConfirming ? null : () => _confirmCompletion(trip),
                                    icon: _isConfirming
                                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : const Icon(LucideIcons.checkCircle, size: 18),
                                    label: Text(
                                      _isConfirming ? l10n.activeTripConfirming : l10n.activeTripConfirmCompletionBtn,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF34C759),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }(),
                        const SizedBox(height: 16),
                      ],

                      // Action button
                      _buildActionButton(trip.status),

                      if (isScheduled || isWaiting || isInProgress) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () => context.push(
                              '/messenger',
                              extra: {
                                'tripId': trip.id,
                                'title':
                                    _booking?.routeTitle ??
                                    trip.customName ??
                                    l10n.activeTripChatDefaultTitle,
                              },
                            ),
                            icon: const Icon(
                              LucideIcons.messageCircle,
                              size: 18,
                            ),
                            label: Text(
                              l10n.activeTripGoToChat,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.background,
                              foregroundColor: AppColors.textPrimary,
                              side: BorderSide(
                                color: AppColors.border,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStageIndicator(String currentStatus) {
    if (!mounted) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final stageLabels = {
      'scheduled': l10n.activeTripStageScheduled,
      'waiting': l10n.activeTripStageWaiting,
      'in_progress': l10n.activeTripStageInProgress,
      'completed': l10n.activeTripStageCompleted,
    };
    final currentIdx = _stages.indexOf(currentStatus).clamp(0, 3);
    return Row(
      children: List.generate(_stages.length, (i) {
        final isDone = i < currentIdx;
        final isActive = i == currentIdx;
        final label = stageLabels[_stages[i]] ?? '';
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isDone || isActive
                            ? AppColors.accent
                            : Colors.white24,
                      ),
                    ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? AppColors.accent
                          : isActive
                          ? AppColors.accent
                          : Colors.white24,
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(
                              LucideIcons.check,
                              size: 12,
                              color: Colors.black,
                            )
                          : isActive
                          ? Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black,
                              ),
                            )
                          : null,
                    ),
                  ),
                  if (i < _stages.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isDone ? AppColors.accent : Colors.white24,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive || isDone
                      ? AppColors.accent
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }

  /// Called when the client taps "Подтвердить завершение" after driver requests it.
  Future<void> _confirmCompletion(ActiveTrip trip) async {
    if (_isConfirming) return;
    setState(() => _isConfirming = true);
    try {
      await FirestoreDataRepository.instance.confirmTripCompletion(
        tripId: trip.id,
        bookingId: trip.bookingId,
      );
      // Navigation is handled automatically by _initStream which
      // detects status == 'completed' and calls context.go('/trip_completed/...')
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.activeTripConfirmError(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  Future<void> _cancelTrip() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          l10n.activeTripCancelTitle,
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n.activeTripCancelDesc,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.activeTripCancelNo),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.activeTripCancelYes,
              style: TextStyle(color: context.errorColor),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (_currentTrip != null && _booking != null) {
      // Atomic batch: cancels both trip and booking in a single Firestore round-trip.
      // Prevents the state where one write succeeds and the other fails mid-cancel.
      await FirestoreDataRepository.instance.cancelTrip(
        tripId: _currentTrip!.id,
        bookingId: _booking!.id,
      );
    } else if (_currentTrip != null) {
      // Fallback: booking not yet loaded — cancel trip only
      await FirestoreDataRepository.instance.updateTripStatus(
        _currentTrip!.id,
        'cancelled',
      );
    }
    if (mounted) context.go('/');
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetailsCard(AppLocalizations l10n) {
    if (_booking == null) return const SizedBox.shrink();

    final startDateStr = DateFormatter.formatNullableDate(_booking!.startDate);
    final endDateStr = DateFormatter.formatNullableDate(_booking!.endDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface, // Changed from surfaceDark
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.activeTripBookingDetails,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            LucideIcons.calendar,
            l10n.activeTripBookingDates,
            '$startDateStr — $endDateStr',
          ),
          _buildStatRow(
            LucideIcons.users,
            l10n.activeTripBookingParticipants,
            l10n.activeTripBookingParticipantsCount(_booking!.participants),
          ),
          if (_booking!.driverName != null)
            _buildStatRow(LucideIcons.car, l10n.activeTripDriver, _booking!.driverName!),
          if (_booking!.guideName != null)
            _buildStatRow(LucideIcons.user, l10n.activeTripGuide, _booking!.guideName!),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.black12, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.activeTripBookingTotal,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              Text(
                '${_booking!.totalPrice.toStringAsFixed(0)} ₸',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledInfo(AppLocalizations l10n) {
    if (_booking == null) return const SizedBox.shrink();
    try {
      final startDt = DateTime.parse(_booking!.startDate);
      final now = DateTime.now();
      final diff = startDt.difference(now);
      final daysLeft = diff.inDays;
      final hoursLeft = diff.inHours % 24;

      // Bug 4: Date has passed — show red expired warning
      if (diff.isNegative) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: context.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.errorColor.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.alertTriangle,
                    color: context.errorColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.activeTripDatePassed,
                      style: TextStyle(
                        color: context.errorColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _isTransitioning ? null : _cancelTrip,
                icon: const Icon(LucideIcons.x, size: 16),
                label: Text(l10n.activeTripCancelAction),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.errorColor,
                  side: BorderSide(
                    color: context.errorColor.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        );
      }

      String timeText;
      if (daysLeft > 0) {
        timeText = l10n.activeTripTimeLeftDaysHours(daysLeft, hoursLeft);
      } else if (hoursLeft > 0) {
        timeText = l10n.activeTripTimeLeftHours(hoursLeft);
      } else {
        timeText = l10n.activeTripStartingSoon;
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.clock,
              color: AppColors.accent,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              timeText,
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildWaitingInfo(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.car, color: Colors.orange, size: 16),
          const SizedBox(width: 8),
          Text(
            l10n.activeTripGroupGathering,
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String status) {
    if (!mounted) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    
    String label;
    Color color;
    IconData icon;
    switch (status) {
      case 'scheduled':
        // Если маршрут уже просрочен — кнопку не показываем.
        // Предупреждение и кнопка отмены уже есть в _buildScheduledInfo.
        if (_booking != null) {
          try {
            final startDt = DateTime.parse(_booking!.startDate);
            if (DateTime.now().isAfter(startDt)) {
              return const SizedBox.shrink();
            }
          } catch (_) {}
        }
        label = l10n.activeTripActionReady;
        color = AppColors.accent;
        icon = LucideIcons.checkCircle;
      case 'waiting':
        final uid = AuthService.instance.currentFirebaseUser?.uid;
        final isCompanion = uid != null && _currentTrip?.userId != uid && (_currentTrip?.companions.any((c) => c.uid == uid) ?? false);
        final currentReady = isCompanion 
            ? (_currentTrip?.companions.firstWhere((c) => c.uid == uid, orElse: () => const CompanionInfo(uid: '', displayName: '', addedAt: '')).ready ?? false)
            : (_currentTrip?.clientReady == true);
            
        if (currentReady) {
          return SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: null, // Disabled
              icon: const Icon(LucideIcons.clock, size: 18),
              label: const Text(
                'Ожидаем остальных...',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          );
        }
        label = 'Я на месте';
        color = AppColors.accent;
        icon = LucideIcons.mapPin;
        break;
      default:
        return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isTransitioning ? null : _advanceStage,
        icon: _isTransitioning
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // Helpers to detect the return-to-start waypoint:
  // startTrip() appends waypoints[0] as the final return point.
  bool _isReturnWaypoint(ActiveTrip trip, int index) {
    final wps = trip.waypoints;
    if (wps.length < 2) return false;
    if (index != wps.length - 1) return false;
    final first = wps.first;
    final last = wps.last;
    return (first.latitude == last.latitude && first.longitude == last.longitude) ||
        (first.address == last.address && first.address.isNotEmpty);
  }

  Widget _buildWaypointCheckIn(ActiveTrip trip) {
    final currentIndex = trip.currentWaypointIndex;
    final totalPoints = trip.waypoints.length;
    final isReturn = _isReturnWaypoint(trip, currentIndex);

    if (currentIndex >= totalPoints) {
       return const SizedBox.shrink(); // All points done, wait for final completion request
    }

    final pointLabel = isReturn
        ? '🏁 ФИНИШ — ВОЗВРАТ НА СТАРТ'
        : 'ТОЧКА ${currentIndex + 1} ИЗ $totalPoints';

    final uid = AuthService.instance.currentFirebaseUser?.uid;
    final isCompanion = uid != null && trip.userId != uid && trip.companions.any((c) => c.uid == uid);
    final String myRole = isCompanion ? 'companion_$uid' : 'client';

    final currentWaypoint = currentIndex < trip.waypoints.length
        ? trip.waypoints[currentIndex]
        : null;
    final Map<String, bool> wpCheckIns = currentWaypoint?.checkIns ?? {};

    final bool meCheckedIn = wpCheckIns[myRole] == true;

    if (meCheckedIn) {
      int checkedInCount = 0;
      if (wpCheckIns['client'] == true) checkedInCount++;
      if (wpCheckIns['driver'] == true) checkedInCount++;
      if (trip.partnerId != null && wpCheckIns['guide'] == true) checkedInCount++;
      
      for (var comp in trip.companions) {
        if (wpCheckIns['companion_${comp.uid}'] == true) checkedInCount++;
      }
      
      int totalRequired = 2 + (trip.partnerId != null ? 1 : 0) + trip.companions.length;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              pointLabel,
              style: TextStyle(color: isReturn ? const Color(0xFF30D158) : AppColors.accent, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'ЖДЕМ ОСТАЛЬНЫХ: $checkedInCount/$totalRequired',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
          ],
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: context.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              pointLabel,
              style: TextStyle(color: isReturn ? const Color(0xFF30D158) : AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  await FirestoreDataRepository.instance.checkInAtWaypoint(trip.id, currentIndex, myRole);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Я НА МЕСТЕ', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showAddCompanionSheet(ActiveTrip trip, AppLocalizations l10n) {
    final currentUid = AuthService.instance.currentFirebaseUser?.uid ?? '';
    final searchController = TextEditingController();
    List<User> searchResults = [];
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          Future<void> doSearch(String q) async {
            if (q.trim().isEmpty) {
              setSheetState(() { searchResults = []; isSearching = false; });
              return;
            }
            setSheetState(() => isSearching = true);
            final results = await FirestoreDataRepository.instance
                .searchUsersByName(q, excludeUid: currentUid);
            setSheetState(() { searchResults = results; isSearching = false; });
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.viewInsetsOf(sheetCtx).bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
                const SizedBox(height: 20),
                Text('Пригласить клиента',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Введите имя пользователя',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 16),

                TextField(
                  controller: searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Имя пользователя...',
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                    suffixIcon: isSearching
                        ? const Padding(padding: EdgeInsets.all(12),
                            child: SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2)))
                        : null,
                    filled: true, fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.border)),
                  ),
                  onChanged: (v) => doSearch(v),
                ),
                const SizedBox(height: 16),

                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: searchResults.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final u = searchResults[i];
                      final displayName = u.name ?? u.firstName ?? 'Без имени';
                      final initials = displayName.split(' ')
                          .where((s) => s.isNotEmpty).take(2)
                          .map((s) => s[0].toUpperCase()).join();
                      final alreadyIn = trip.companions.any((c) => c.uid == u.id);

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                              backgroundImage: u.photoUrl != null ? NetworkImage(u.photoUrl!) : null,
                              child: u.photoUrl == null
                                  ? Text(initials, style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold))
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(displayName, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                Text(u.phoneNumber, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            )),
                            ElevatedButton(
                              onPressed: alreadyIn ? null : () async {
                                final companion = CompanionInfo(
                                  uid: u.id,
                                  displayName: displayName,
                                  photoUrl: u.photoUrl,
                                  addedAt: DateTime.now().toIso8601String(),
                                );
                                await FirestoreDataRepository.instance
                                    .addCompanionToTrip(trip.id, companion);
                                if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('$displayName добавлен в маршрут')));
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: Size.zero),
                              child: Text(alreadyIn ? 'Добавлен' : 'Добавить',
                                style: const TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


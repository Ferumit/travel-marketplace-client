import '../theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../models/tour_models.dart' as app_models;
import '../route_builder/yandex_directions_service.dart';
import '../route_builder/route_waypoint.dart';
import '../services/location_service.dart';
import '../map/yandex_map_config.dart';
import '../widgets/safe_network_image.dart';
import '../l10n/app_localizations.dart';

class RoutePreviewScreen extends StatefulWidget {
  final app_models.Route route;

  const RoutePreviewScreen({super.key, required this.route});

  @override
  State<RoutePreviewScreen> createState() => _RoutePreviewScreenState();
}

class _RoutePreviewScreenState extends State<RoutePreviewScreen> {
  YandexMapController? _mapCtrl;
  Point? _userLocation;
  bool _locationLoading = false;
  bool _routeLoading = false;

  final List<MapObject> _mapObjects = [];

  @override
  void initState() {
    super.initState();
    _initLocationAndRoute();
  }

  @override
  void dispose() {
    _mapCtrl?.dispose();
    super.dispose();
  }

  Future<void> _initLocationAndRoute() async {
    setState(() => _locationLoading = true);
    final status = await LocationService.instance.requestPermission();
    
    Point? userPos;
    if (status == LocationStatus.ready) {
      final pos = await LocationService.instance.getCurrentPosition();
      if (pos != null) {
        userPos = Point(latitude: pos.latitude, longitude: pos.longitude);
      }
    }
    
    userPos ??= YandexMapConfig.defaultPoint;
    
    if (mounted) {
      setState(() {
        _userLocation = userPos;
        _locationLoading = false;
      });
      _buildVisualRoute(userPos);
    }
  }

  Future<void> _buildVisualRoute(Point start) async {
    setState(() => _routeLoading = true);
    
    final end = Point(
      latitude: widget.route.latitude,
      longitude: widget.route.longitude,
    );

    // Initial markers
    _mapObjects.clear();
    _mapObjects.add(
      PlacemarkMapObject(
        mapId: const MapObjectId('start_point'),
        point: start,
        icon: PlacemarkIcon.single(
          PlacemarkIconStyle(
            image: BitmapDescriptor.fromAssetImage('assets/images/user_marker.png'),
            scale: 1,
          ),
        ),
      ),
    );
    _mapObjects.add(
      PlacemarkMapObject(
        mapId: const MapObjectId('end_point'),
        point: end,
        icon: PlacemarkIcon.single(
          PlacemarkIconStyle(
            image: BitmapDescriptor.fromAssetImage('assets/images/route_marker.png'),
            scale: 1,
            anchor: const Offset(0.5, 1.0),
          ),
        ),
      ),
    );

    try {
      final waypoints = [
        RouteWaypoint(latitude: start.latitude, longitude: start.longitude, name: 'Start', color: RouteWaypoint.colorStart),
        RouteWaypoint(latitude: end.latitude, longitude: end.longitude, name: 'End', color: RouteWaypoint.colorEnd),
      ];

      final result = await YandexDirectionsService.getRoute(waypoints);
      
      if (result.points.isNotEmpty) {
        _mapObjects.add(
          PolylineMapObject(
            mapId: const MapObjectId('preview_route'),
            polyline: Polyline(points: result.points),
            strokeColor: YandexMapConfig.routeLineColor,
            strokeWidth: YandexMapConfig.routeLineWidth,
            outlineColor: YandexMapConfig.routeOutlineColor,
            outlineWidth: YandexMapConfig.routeOutlineWidth,
          ),
        );
      }
      
      // Move camera to fit both points
      if (_mapCtrl != null && mounted) {
        final bounds = BoundingBox(
          southWest: Point(
            latitude: start.latitude < end.latitude ? start.latitude : end.latitude,
            longitude: start.longitude < end.longitude ? start.longitude : end.longitude,
          ),
          northEast: Point(
            latitude: start.latitude > end.latitude ? start.latitude : end.latitude,
            longitude: start.longitude > end.longitude ? start.longitude : end.longitude,
          ),
        );
        
        await _mapCtrl!.moveCamera(
          CameraUpdate.newGeometry(Geometry.fromBoundingBox(bounds)),
          animation: const MapAnimation(type: MapAnimationType.smooth, duration: 1.0),
        );
        
        // Zoom out slightly for padding
        await _mapCtrl!.moveCamera(
          CameraUpdate.zoomOut(),
          animation: const MapAnimation(type: MapAnimationType.smooth, duration: 0.5),
        );
      }
    } catch (e) {
      debugPrint('[RoutePreviewScreen] Ошибка построения маршрута: $e');
    }

    if (mounted) {
      setState(() => _routeLoading = false);
    }
  }

  Future<void> _moveToUser() async {
    if (_locationLoading || _mapCtrl == null || _userLocation == null) return;
    await _mapCtrl!.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _userLocation!,
          zoom: YandexMapConfig.defaultZoom,
        ),
      ),
      animation: const MapAnimation(
        type: MapAnimationType.smooth,
        duration: 1.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userLocation == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          YandexMap(
            mapObjects: _mapObjects,
            nightModeEnabled: YandexMapConfig.nightModeEnabled,
            onMapCreated: (YandexMapController controller) async {
              _mapCtrl = controller;
              await controller.toggleUserLayer(visible: true);
              if (_userLocation != null && _mapObjects.length <= 2) {
                 await controller.moveCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: _userLocation!,
                      zoom: YandexMapConfig.overviewZoom,
                    ),
                  ),
                );
              }
            },
          ),

          // Top Gradient & AppBar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                   Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom Sheet with details
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomSheet(l10n),
          ),

          // FAB
          Positioned(
            right: 16,
            bottom: 300, 
            child: FloatingActionButton.small(
              heroTag: 'preview_my_location',
              backgroundColor: Colors.white,
              foregroundColor: AppColors.accent,
              onPressed: _moveToUser,
              child: const Icon(Icons.my_location_rounded),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 280),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                   width: 80,
                   height: 80,
                   child: SafeNetworkImage(
                     url: widget.route.imageUrl,
                     fit: BoxFit.cover,
                   ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.route.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(LucideIcons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.route.rating} (${widget.route.reviewCount} ${l10n.reviewsCount})',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                       '${widget.route.price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} ₸',
                       style: TextStyle(
                         fontSize: 18,
                         fontWeight: FontWeight.w800,
                         color: AppColors.accent,
                       ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_routeLoading) 
            Center(child: LinearProgressIndicator(color: AppColors.accent))
          else 
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  // Pass the predefined route to booking screen
                  context.push('/booking', extra: {'route': widget.route});
                },
                child: Text(
                  l10n.bookTourAction,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


import '../theme/app_colors.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../services/location_service.dart';
import '../services/map_service.dart';
import 'yandex_map_config.dart';

/// Экран карты: Yandex Map с синей точкой пользователя и кнопкой «Найти меня».
///
/// Логика построения маршрутов — в `lib/route_builder/`.
class MapScreen extends StatefulWidget {
  final MapService? mapService;
  final double initialZoom;
  final bool showUserLocationButton;

  const MapScreen({
    super.key,
    this.mapService,
    this.initialZoom = YandexMapConfig.defaultZoom,
    this.showUserLocationButton = true,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapService _mapService;

  StreamSubscription<List<MapObject>>? _objectsSub;
  List<MapObject> _mapObjects = [];

  Point? _userLocation;
  bool _locationLoading = false;

  @override
  void initState() {
    super.initState();
    _mapService = widget.mapService ?? MapService.instance;
    _objectsSub = _mapService.mapObjects.listen((objects) {
      if (mounted) setState(() => _mapObjects = objects);
    });
    _initializeLocation();
  }

  @override
  void dispose() {
    _objectsSub?.cancel();
    _mapService.detachController();
    LocationService.instance.stopTracking();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    final status = await LocationService.instance.requestPermission();
    if (status != LocationStatus.ready) {
      if (mounted) setState(() => _userLocation = YandexMapConfig.defaultPoint);
      return;
    }

    final position = await LocationService.instance.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        _userLocation = Point(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      });
    } else if (mounted) {
      setState(() => _userLocation = YandexMapConfig.defaultPoint);
    }

    await LocationService.instance.startTracking();
  }

  Future<void> _moveToUser() async {
    if (_locationLoading) return;
    setState(() => _locationLoading = true);

    final last = LocationService.instance.lastPosition;
    if (last != null) {
      await _mapService.moveCamera(
        latitude: last.latitude,
        longitude: last.longitude,
        zoom: widget.initialZoom,
      );
    } else {
      final pos = await LocationService.instance.getCurrentPosition();
      if (pos != null) {
        await _mapService.moveCamera(
          latitude: pos.latitude,
          longitude: pos.longitude,
          zoom: widget.initialZoom,
        );
      }
    }

    if (mounted) setState(() => _locationLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_userLocation == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Определяем ваше местоположение...'),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        YandexMap(
          mapObjects: _mapObjects,
          nightModeEnabled: YandexMapConfig.nightModeEnabled,
          onMapCreated: _onMapCreated,
        ),

        if (widget.showUserLocationButton)
          Positioned(
            bottom: 24,
            right: 16,
            child: _MyLocationFab(
              isLoading: _locationLoading,
              onPressed: _moveToUser,
            ),
          ),
      ],
    );
  }

  Future<void> _onMapCreated(YandexMapController controller) async {
    _mapService.attachController(controller);
    await controller.toggleUserLayer(visible: true);
    await _mapService.moveCamera(
      latitude: _userLocation!.latitude,
      longitude: _userLocation!.longitude,
      zoom: widget.initialZoom,
      animated: false,
    );
  }
}

/// FAB «Найти меня» с индикатором загрузки.
class _MyLocationFab extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _MyLocationFab({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: 'map_my_location',
      tooltip: 'Моё местоположение',
      onPressed: isLoading ? null : onPressed,
      backgroundColor: AppColors.surface,
      foregroundColor: Theme.of(context).colorScheme.primary,
      elevation: 4,
      child: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.my_location_rounded),
    );
  }
}


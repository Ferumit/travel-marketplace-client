import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

import '../l10n/app_localizations.dart';
import '../services/location_service.dart';
import '../map/yandex_map_config.dart';
import 'route_builder_controller.dart';
import 'route_builder_panels.dart';
import 'route_builder_step.dart';

/// Экран трёхшагового конструктора маршрутов.
class RouteBuilderScreen extends StatefulWidget {
  const RouteBuilderScreen({super.key});

  @override
  State<RouteBuilderScreen> createState() => _RouteBuilderScreenState();
}

class _RouteBuilderScreenState extends State<RouteBuilderScreen> {
  late final RouteBuilderController _ctrl;
  YandexMapController? _mapCtrl;
  Point? _userLocation;

  @override
  void initState() {
    super.initState();
    _ctrl = RouteBuilderController();
    _ctrl.addListener(_onControllerUpdate);
    _initLocation();
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerUpdate);
    _ctrl.dispose();
    _mapCtrl?.dispose();
    super.dispose();
  }

  bool _locationLoading = false;

  Future<void> _initLocation() async {
    final status = await LocationService.instance.requestPermission();
    if (status != LocationStatus.ready) {
      if (mounted) setState(() => _userLocation = YandexMapConfig.defaultPoint);
      return;
    }

    final pos = await LocationService.instance.getCurrentPosition();
    if (mounted) {
      setState(() {
        if (pos != null) {
          _userLocation = Point(
            latitude: pos.latitude,
            longitude: pos.longitude,
          );
        } else {
          _userLocation = YandexMapConfig.defaultPoint;
        }
      });
    }
  }

  Future<void> _moveToUser() async {
    if (_locationLoading || _mapCtrl == null) return;
    setState(() => _locationLoading = true);

    final status = await LocationService.instance.requestPermission();
    if (status == LocationStatus.ready) {
      final pos = await LocationService.instance.getCurrentPosition();
      if (pos != null) {
        _userLocation = Point(latitude: pos.latitude, longitude: pos.longitude);
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
    }
    if (mounted) setState(() => _locationLoading = false);
  }

  void _onControllerUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    // Push localized strings into the controller so waypoint names,
    // error messages, and route titles always match the current language.
    final l10n = AppLocalizations.of(context)!;
    _ctrl.updateLabels(
      RouteBuilderLabels(
        waypointStart: l10n.rbWaypointStart,
        waypointFinish: l10n.rbWaypointFinish,
        waypointMid: (n) => l10n.rbWaypointMid(n),
        myLocationLabel: l10n.rbMyLocationLabel,
        defaultRouteTitle: l10n.rbDefaultRouteTitle,
        errorFallback: l10n.rbErrorFallback,
        errorBuild: l10n.rbErrorBuild,
      ),
    );

    if (_userLocation == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final step = _ctrl.step;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          YandexMap(
            mapObjects: _ctrl.buildMapObjects(_userLocation),
            nightModeEnabled: YandexMapConfig.nightModeEnabled,
            onMapCreated: _onMapCreated,
            onMapTap: step == RouteBuilderStep.placePoints ? _onMapTap : null,
          ),

          // Градиент чтобы AppBar читался поверх карты
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
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(child: _buildAppBar()),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (step != RouteBuilderStep.fillDetails)
                  Padding(
                    padding: const EdgeInsets.only(right: 16, bottom: 16),
                    child: _MyLocationFab(
                      isLoading: _locationLoading,
                      onPressed: _moveToUser,
                    ),
                  ),
                _buildBottomPanel(step),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final l10n = AppLocalizations.of(context)!;
    final labels = [l10n.rbStepPoints, l10n.rbStepRoute, l10n.rbStepDetails];
    final currentIndex = switch (_ctrl.step) {
      RouteBuilderStep.placePoints => 0,
      RouteBuilderStep.buildingRoute => 1,
      RouteBuilderStep.routeReady => 1,
      RouteBuilderStep.fillDetails => 2,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            tooltip: l10n.rbTooltipBack,
            onPressed: () => context.go('/'),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => _StepDot(
                  index: i,
                  label: labels[i],
                  active: i == currentIndex,
                  done: i < currentIndex,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(RouteBuilderStep step) {
    return switch (step) {
      RouteBuilderStep.placePoints => RouteBuilderPlacePointsPanel(
        waypoints: _ctrl.waypoints,
        canBuildRoute: _ctrl.canBuildRoute,
        canAddMore: _ctrl.canAddMore,
        hasPendingSlot: _ctrl.hasPendingSlot,
        activePendingIndex: _ctrl.activePendingIndex,
        onUndo: _ctrl.removeLastWaypoint,
        onClear: _ctrl.clearWaypoints,
        onBuild: () => _ctrl.buildRoute(_userLocation),
        onAddMyLocation: _onAddMyLocation,
        onRemoveAt: (i) => _ctrl.markWaypointPending(i),
        onSelectPending: (i) => _ctrl.selectPendingSlot(i),
      ),
      RouteBuilderStep.buildingRoute => const RouteBuilderLoadingPanel(),
      RouteBuilderStep.routeReady => RouteBuilderRouteReadyPanel(
        distanceKm: _ctrl.routeDistanceKm,
        durationHours: _ctrl.routeDurationHours,
        isRealRoute: _ctrl.isRealRoute,
        errorMessage: _ctrl.errorMessage,
        onReset: _ctrl.clearWaypoints,
        // Переходим сразу на BookingScreen, передавая контроллер для выполнения saveRoute
        onContinue: () => context.push('/booking', extra: _ctrl),
      ),
      RouteBuilderStep.fillDetails => const SizedBox.shrink(),
    };
  }

  Future<void> _onMapCreated(YandexMapController controller) async {
    _mapCtrl = controller;
    await controller.toggleUserLayer(visible: true);

    if (_userLocation != null) {
      await controller.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _userLocation!,
            zoom: YandexMapConfig.defaultZoom,
          ),
        ),
      );
    }
  }

  Future<void> _onMapTap(Point point) =>
      _ctrl.addWaypoint(point.latitude, point.longitude);

  Future<void> _onAddMyLocation() async {
    if (_userLocation != null) {
      await _ctrl.addWaypoint(
        _userLocation!.latitude,
        _userLocation!.longitude,
      );

      // Выполняем приближение камеры на точку геопозиции
      if (_mapCtrl != null) {
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
    }
  }
}

/// Анимированный индикатор текущего шага в AppBar мастера.
class _StepDot extends StatelessWidget {
  final int index;
  final String label;
  final bool active;
  final bool done;

  const _StepDot({
    required this.index,
    required this.label,
    required this.active,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final color = active || done ? Colors.white : Colors.white38;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: active ? 28 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }
}

/// FAB «Найти меня» с индикатором загрузки для Route Builder Screen.
class _MyLocationFab extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _MyLocationFab({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: 'rb_my_location',
      tooltip: AppLocalizations.of(context)!.rbTooltipMyLocation,
      onPressed: isLoading ? null : onPressed,
      backgroundColor: Colors.white,
      foregroundColor: Theme.of(context).colorScheme.primary,
      elevation: 4,
      child: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.my_location_rounded, color: Colors.blue),
    );
  }
}




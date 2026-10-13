import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'route_builder_controller.dart';

/// Нижняя панель шага 1: список точек и кнопки управления.
class RouteBuilderPlacePointsPanel extends StatelessWidget {
  final List waypoints;
  final bool canBuildRoute;
  final bool canAddMore;
  final bool hasPendingSlot;
  final int? activePendingIndex;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final VoidCallback onBuild;
  final VoidCallback onAddMyLocation;
  final void Function(int index) onRemoveAt;
  final void Function(int index) onSelectPending;

  const RouteBuilderPlacePointsPanel({
    super.key,
    required this.waypoints,
    required this.canBuildRoute,
    required this.canAddMore,
    required this.hasPendingSlot,
    required this.activePendingIndex,
    required this.onUndo,
    required this.onClear,
    required this.onBuild,
    required this.onAddMyLocation,
    required this.onRemoveAt,
    required this.onSelectPending,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  l10n.rbPanelWaypointsTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${waypoints.length} / ${RouteBuilderController.maxWaypoints}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),

          if (waypoints.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.rbPanelTapHint,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onAddMyLocation,
                      icon: const Icon(Icons.my_location_rounded),
                      label: Text(l10n.rbPanelMyLocationStart),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 52.0 * waypoints.length.clamp(1, 4).toDouble(),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const ClampingScrollPhysics(),
                itemCount: waypoints.length,
                itemBuilder: (_, i) {
                  final w = waypoints[i];
                  final isPending = w.isPending as bool;
                  final isActivePending = isPending && i == activePendingIndex;
                  final isInactivePending = isPending && !isActivePending;

                  return GestureDetector(
                    // Тап по inactive pending — выбираем его как активный
                    onTap: isInactivePending ? () => onSelectPending(i) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 50,
                      margin: const EdgeInsets.symmetric(vertical: 1),
                      decoration: BoxDecoration(
                        color: isActivePending
                            ? Colors.orange.withValues(alpha: 0.08)
                            : isInactivePending
                            ? Colors.grey.withValues(alpha: 0.06)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: isActivePending
                            ? Border.all(
                                color: Colors.orange.withValues(alpha: 0.6),
                                width: 1.5,
                              )
                            : isInactivePending
                            ? Border.all(
                                color: Colors.grey.withValues(alpha: 0.3),
                                width: 1.0,
                              )
                            : null,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          // Цветной кружок
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: isActivePending
                                ? Colors.orange
                                : isInactivePending
                                ? Colors.grey.shade400
                                : (i == 0
                                    ? Colors.green
                                    : i == waypoints.length - 1
                                    ? Colors.red
                                    : Theme.of(context).colorScheme.primary),
                            child: isPending
                                ? Icon(
                                    isActivePending
                                        ? Icons.my_location_rounded
                                        : Icons.location_searching_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  )
                                : Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 8),
                          // Текст
                          Expanded(
                            child: isActivePending
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${w.name} — нажмите на карте',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.orange,
                                                fontWeight: FontWeight.w600,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.touch_app_rounded,
                                        color: Colors.orange,
                                        size: 14,
                                      ),
                                    ],
                                  )
                                : isInactivePending
                                ? Text(
                                    '${w.name} — нажмите чтобы выбрать',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : Text(
                                    '${w.name}  (${w.latitude.toStringAsFixed(4)}, ${w.longitude.toStringAsFixed(4)})',
                                    style: Theme.of(context).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                          // ✕ кнопка (только для заполненных слотов)
                          if (!isPending)
                            GestureDetector(
                              onTap: () => onRemoveAt(i),
                              child: Container(
                                width: 28,
                                height: 28,
                                margin: const EdgeInsets.only(left: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Colors.red,
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 32),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // Подсказка если есть pending-слоты
          if (hasPendingSlot)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.touch_app_rounded,
                    color: Colors.orange,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Тапните на серую строку — выбрать пункт. Оранжевый — активный, тапните на карту.',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (!canAddMore)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                l10n.rbPanelMaxPoints,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.orange,
                ),
              ),
            ),

          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Row(
              children: [
                IconButton.outlined(
                  onPressed: waypoints.isEmpty ? null : onUndo,
                  icon: const Icon(Icons.undo_rounded),
                  tooltip: l10n.rbTooltipUndo,
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  onPressed: waypoints.isEmpty ? null : onClear,
                  icon: const Icon(Icons.clear_rounded),
                  tooltip: l10n.rbTooltipClear,
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: canBuildRoute ? onBuild : null,
                  icon: const Icon(Icons.route_rounded),
                  label: Text(l10n.rbBuildRoute),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Нижняя панель-заглушка во время загрузки маршрута.
class RouteBuilderLoadingPanel extends StatelessWidget {
  const RouteBuilderLoadingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Row(
        children: [
          const CircularProgressIndicator.adaptive(),
          const SizedBox(width: 20),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.rbLoadingTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                l10n.rbLoadingSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Нижняя панель шага 2: статистика маршрута и кнопки действий.
class RouteBuilderRouteReadyPanel extends StatelessWidget {
  final double distanceKm;
  final int durationHours;
  final bool isRealRoute;
  final String? errorMessage;
  final VoidCallback onReset;
  final VoidCallback onContinue;

  const RouteBuilderRouteReadyPanel({
    super.key,
    required this.distanceKm,
    required this.durationHours,
    required this.isRealRoute,
    required this.errorMessage,
    required this.onReset,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatCard(
                  icon: Icons.straighten_rounded,
                  label: l10n.rbStatDistance,
                  value: l10n.rbStatDistanceKm(distanceKm.toStringAsFixed(1)),
                  color: const Color(0xFF00BCD4),
                ),
                _StatCard(
                  icon: Icons.access_time_rounded,
                  label: l10n.rbStatTime,
                  value: durationHours == 0
                      ? l10n.rbStatTimeLessHour
                      : l10n.rbStatTimeHours(durationHours.toString()),
                  color: theme.colorScheme.primary,
                ),
                _StatCard(
                  icon: isRealRoute
                      ? Icons.alt_route_rounded
                      : Icons.show_chart_rounded,
                  label: isRealRoute ? l10n.rbStatByRoad : l10n.rbStatStraightLine,
                  value: isRealRoute ? l10n.rbStatYandex : l10n.rbStatEstimate,
                  color: isRealRoute ? Colors.green : Colors.orange,
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.rbReset),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onContinue,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(l10n.rbContinue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Карточка с иконкой, значением и подписью (используется в [RouteBuilderRouteReadyPanel]).
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w700, color: color),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

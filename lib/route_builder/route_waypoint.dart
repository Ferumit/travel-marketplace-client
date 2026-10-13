import 'dart:ui' show Color;

/// Точка маршрута.
///
/// Ограничения:
///   • Максимум **10** точек на маршрут
///   • Минимум **2** точки для построения маршрута
class RouteWaypoint {
  final double latitude;
  final double longitude;
  final String name;

  /// Цвет маркера на карте.
  ///   • Точка 1 (start)  → зелёный
  ///   • Точка N (end)    → красный
  ///   • Промежуточные    → синий
  final Color color;

  /// true — точка очищена и ожидает переназначения касанием на карте.
  /// Кнопка «Построить маршрут» недоступна пока хотя бы одна точка isPending.
  final bool isPending;

  const RouteWaypoint({
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.color,
    this.isPending = false,
  });

  /// Цветовая палитра маркеров.
  static const Color colorStart = Color(0xFF43A047); // green
  static const Color colorEnd   = Color(0xFFE53935); // red
  static const Color colorMid   = Color(0xFF1565C0); // deep blue

  /// Создать точку по позиции в маршруте.
  factory RouteWaypoint.fromIndex(
    double latitude,
    double longitude,
    int index,
    int total,
  ) {
    final Color color;
    if (index == 0) {
      color = colorStart;
    } else if (index == total - 1) {
      color = colorEnd;
    } else {
      color = colorMid;
    }

    return RouteWaypoint(
      latitude: latitude,
      longitude: longitude,
      name: index == 0
          ? 'Старт'
          : (index == total - 1 ? 'Финиш' : 'Точка $index'),
      color: color,
    );
  }

  /// Пересоздаёт точку с обновлённым цветом.
  RouteWaypoint withColor(Color newColor) => RouteWaypoint(
    latitude: latitude,
    longitude: longitude,
    name: name,
    color: newColor,
    isPending: isPending,
  );

  /// Возвращает копию с флагом isPending = true (слот ожидает переназначения).
  RouteWaypoint asPending() => RouteWaypoint(
    latitude: latitude,
    longitude: longitude,
    name: name,
    color: color,
    isPending: true,
  );

  /// Возвращает копию с новыми координатами и isPending = false.
  RouteWaypoint filledWith(double lat, double lng) => RouteWaypoint(
    latitude: lat,
    longitude: lng,
    name: name,
    color: color,
    isPending: false,
  );

  @override
  String toString() =>
      'RouteWaypoint($name${isPending ? " [PENDING]" : ""}: $latitude, $longitude)';
}

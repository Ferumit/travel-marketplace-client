/// Шаги мастера построения маршрута.
///
/// placePoints в†’ buildingRoute в†’ routeReady в†’ fillDetails
enum RouteBuilderStep {
  /// Шаг 1: пользователь расставляет точки на карте.
  placePoints,

  /// Промежуточное состояние: идёт запрос к Yandex Driving API.
  buildingRoute,

  /// Шаг 2: маршрут получен — показываются линия и статистика.
  routeReady,

  /// Шаг 3: форма деталей бронирования.
  fillDetails,
}



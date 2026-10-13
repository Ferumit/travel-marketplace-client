import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис запроса разрешений на геолокацию для клиентского приложения Explora.
///
/// Реализует требования Google Play:
/// 1. Prominent Disclosure — объяснительный диалог ДО запроса разрешений.
/// 2. Foreground location — стандартный системный диалог Android (FINE + COARSE).
///
/// Диалог показывается **один раз** при первом запуске после входа.
/// Повторный запрос производится только если разрешения всё ещё не выданы.
abstract final class LocationPermissionService {
  static const _prefKey = 'location_permission_disclosure_shown';

  /// Запрашивает необходимые разрешения геолокации.
  ///
  /// [context] — BuildContext для показа диалогов.
  /// Безопасно вызывать повторно: если разрешения уже выданы — ничего не делает.
  static Future<void> requestAll(BuildContext context) async {
    // 1. Проверяем, включена ли служба GPS
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    // 2. Проверяем текущее состояние foreground-разрешения
    final currentPerm = await Geolocator.checkPermission();

    // Если уже выдано — ничего не делаем
    if (currentPerm == LocationPermission.always ||
        currentPerm == LocationPermission.whileInUse) {
      return;
    }

    // Если навсегда запрещено — не показываем диалоги
    if (currentPerm == LocationPermission.deniedForever) return;

    // 3. Проверяем, показывали ли уже Prominent Disclosure
    final prefs = await SharedPreferences.getInstance();
    final disclosed = prefs.getBool(_prefKey) ?? false;

    if (!context.mounted) return;

    // 4. Показываем Prominent Disclosure (один раз)
    if (!disclosed) {
      final agreed = await _showProminentDisclosure(context);
      await prefs.setBool(_prefKey, true);
      if (!agreed) return;
    }

    if (!context.mounted) return;

    // 5. Запрашиваем Foreground-разрешение (ACCESS_FINE_LOCATION + ACCESS_COARSE_LOCATION)
    await Geolocator.requestPermission();
  }

  // ── Диалоги ───────────────────────────────────────────────────────────────

  /// Prominent Disclosure — объяснение зачем нужна геолокация.
  static Future<bool> _showProminentDisclosure(BuildContext context) async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Доступ к геолокации'),
        content: const Text(
          'Приложение Explora собирает данные о местоположении для '
          'обеспечения работы следующих функций:\n'
          '• Отображение вашей позиции на карте маршрута\n'
          '• Расчет расстояния до точек маршрута\n'
          '• Экстренный вызов SOS\n'
          '• MESH-сеть для офлайн-связи с группой\n\n'
          'Данные собираются и используются только во время активного '
          'использования приложения (на экране). Данные не передаются третьим лицам.',
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Не сейчас'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Продолжить'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Открывает системные настройки приложения.
  /// Используй когда разрешение навсегда запрещено.
  static Future<bool> openSettings() => openAppSettings();
}

package com.explora.explora_app_client

import android.app.Application
import com.yandex.mapkit.MapKitFactory

/**
 * Точка входа Android-приложения.
 *
 * Здесь выполняется инициализация Яндекс MapKit:
 *   • [MapKitFactory.setApiKey] — устанавливает API-ключ ДО первого создания
 *     экземпляра MapKit. ДОЛЖЕН вызываться в onCreate() до runFlutterEngine.
 *   • [MapKitFactory.setLocale] — необязательно; без этого используется
 *     системный язык.
 *
 * ── КАК ПОДКЛЮЧИТЬ КЛЮЧ ──────────────────────────────────────────────────────
 * 1. Получи ключ на https://developer.tech.yandex.ru/ (тип: MapKit Mobile SDK).
 * 2. Замени строку "YOUR_YANDEX_MAPKIT_API_KEY" ниже своим ключом.
 *    (Ключ также дублируется в lib/map/yandex_map_config.dart для документации.)
 * 3. Убедись, что в AndroidManifest.xml прописано android:name=".MainApplication".
 * ─────────────────────────────────────────────────────────────────────────────
 */
class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        // Устанавливаем API-ключ из BuildConfig, сформированного через local.properties
        MapKitFactory.setApiKey(BuildConfig.YANDEX_MAPKIT_API_KEY)

        // Опционально: принудительно задать язык карты (ru, en и т.д.)
        // MapKitFactory.setLocale("ru")
    }
}

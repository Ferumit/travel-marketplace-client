import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Firebase — Google Services plugin processes google-services.json
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}
val yandexApiKey = localProperties.getProperty("YANDEX_MAPKIT_API_KEY") ?: ""
val bridgefyApiKey = localProperties.getProperty("bridgefy.api.key") ?: "ВСТАВЬТЕ_КЛЮЧ_В_LOCAL_PROPERTIES"

android {
    namespace = "com.explora.explora_app_client"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    
    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.explora.explora_app_client"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26  // Android 8.0+ (API 26); required by Yandex MapKit 4.x
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        buildConfigField("String", "YANDEX_MAPKIT_API_KEY", "\"$yandexApiKey\"")
        manifestPlaceholders["bridgefyApiKey"] = bridgefyApiKey
    }

    signingConfigs {
        create("release") {
            val keystorePropertiesFile = rootProject.file("key.properties")
            if (keystorePropertiesFile.exists()) {
                val keystoreProperties = Properties()
                keystoreProperties.load(keystorePropertiesFile.inputStream())
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = rootProject.file("app/${keystoreProperties.getProperty("storeFile")}")
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Two things are required for MapKit Full routing (YandexDriving, YandexPedestrian):
    // 1. gradle.properties: yandexMapkit.variant=full   — tells the plugin to compile its
    //    Java wrapper against the full SDK (else routing classes are absent at runtime).
    // 2. This explicit dep — the plugin uses 'implementation' (not 'api'), so maps.mobile
    //    is NOT re-exported to the app module; without it MainApplication.kt cannot
    //    resolve MapKitFactory at Kotlin compile time.
    implementation("com.yandex.android:maps.mobile:4.22.0-full")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

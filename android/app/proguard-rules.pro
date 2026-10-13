# Flutter Minification Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase Rules
-keep class com.google.firebase.** { *; }
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses

# Yandex Mapkit Rules
-keep class com.yandex.mapkit.** { *; }
-keep class com.yandex.runtime.** { *; }

# Bridgefy SDK Rules
-keep class com.bridgefy.sdk.** { *; }
-keep interface com.bridgefy.sdk.** { *; }
-dontwarn com.bridgefy.sdk.**

# Google Play Core (needed for Flutter deferred components)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

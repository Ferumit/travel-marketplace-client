import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Цветовая палитра приложения.
class YandexColors {
  // Light Palette
  static const Color background = Color(0xFFF5F5F7);
  static const Color surface = Colors.white;
  static const Color primary = Color(0xFF147EFB);
  static const Color onPrimary = Colors.white;
  static const Color secondary = Color(0xFF1E212A);
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Color(0xFF7A7A7A);
  static const Color error = Color(0xFFDC2626);
  static const Color border = Color(0xFFEAEAEA);

  // Dark Palette
  static const Color backgroundDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF1C1C1E);
  static const Color primaryDark = Color(0xFF0A84FF);
  static const Color onPrimaryDark = Colors.white;
  static const Color secondaryDark = Color(0xFF2C2C2E);
  static const Color textPrimaryDark = Colors.white;
  static const Color textSecondaryDark = Color(0xFF8E8E93);
  static const Color errorDark = Color(0xFFFF453A);
  static const Color borderDark = Color(0xFF38383A);
}

/// Тема приложения Explora.
class AppTheme {
  static ThemeData get lightTheme => _createTheme(Brightness.light);
  static ThemeData get darkTheme => _createTheme(Brightness.dark);

  static ThemeData _createTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final base = ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor:
          isDark ? YandexColors.backgroundDark : YandexColors.background,
      colorScheme: isDark
          ? const ColorScheme.dark(
              primary: YandexColors.primaryDark,
              onPrimary: YandexColors.onPrimaryDark,
              secondary: YandexColors.secondaryDark,
              onSecondary: Colors.white,
              secondaryContainer: Color(0xFF1C1C1E),
              onSecondaryContainer: YandexColors.textSecondaryDark,
              surface: YandexColors.surfaceDark,
              onSurface: YandexColors.textPrimaryDark,
              onSurfaceVariant: YandexColors.textSecondaryDark,
              error: YandexColors.errorDark,
              onError: Colors.white,
              outline: YandexColors.borderDark,
            )
          : const ColorScheme.light(
              primary: YandexColors.primary,
              onPrimary: YandexColors.onPrimary,
              secondary: YandexColors.secondary,
              onSecondary: Colors.white,
              secondaryContainer: Color(0xFFF2F2F7),
              onSecondaryContainer: YandexColors.textSecondary,
              surface: YandexColors.surface,
              onSurface: YandexColors.textPrimary,
              onSurfaceVariant: YandexColors.textSecondary,
              error: YandexColors.error,
              onError: Colors.white,
              outline: YandexColors.border,
            ),
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? YandexColors.backgroundDark : YandexColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: isDark ? YandexColors.textPrimaryDark : YandexColors.textPrimary,
        ),
        titleTextStyle: GoogleFonts.manrope(
          color:
              isDark ? YandexColors.textPrimaryDark : YandexColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? YandexColors.primaryDark : YandexColors.primary,
          foregroundColor:
              isDark ? YandexColors.onPrimaryDark : YandexColors.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? YandexColors.surfaceDark : YandexColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? YandexColors.borderDark : YandexColors.border,
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      useMaterial3: true,
    );

    return base.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme),
    );
  }
}

/// Расширения для удобного доступа к теме через BuildContext.
extension ThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;

  // Удобные геттеры для часто используемых цветов
  Color get primaryColor => colorScheme.primary;
  Color get surfaceColor => colorScheme.surface;
  Color get backgroundColor => theme.scaffoldBackgroundColor;
  Color get textPrimary => colorScheme.onSurface;
  Color get textSecondary => colorScheme.onSurfaceVariant;
  Color get borderColor => colorScheme.outline;
  Color get errorColor => colorScheme.error;
  Color get successColor => const Color(0xFF34C759); // Стандартный iOS успех
  
  // Дополнительные контейнеры
  Color get secondaryContainer => colorScheme.secondaryContainer;
  Color get onSecondaryContainer => colorScheme.onSecondaryContainer;
}


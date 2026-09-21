import 'package:flutter/material.dart';

/// SSM SkipQ brand theme — matches web app tokens.css
class AppTheme {
  static const Color primary = Color(0xFFFE4101);
  static const Color primaryHover = Color(0xFFE53A01);
  static const Color primaryActive = Color(0xFFCC3300);
  static const Color primaryMuted = Color(0xFFFFF0EB);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFCA8A04);
  static const Color error = Color(0xFFDC2626);
  static const Color errorMuted = Color(0xFFFEE2E2);
  static const Color text = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF525252);
  static const Color textMuted = Color(0xFFA3A3A3);
  static const Color border = Color(0xFFE5E5E5);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color bgSubtle = Color(0xFFFAFAFA);

  static TextTheme get _textTheme {
    const display = TextTheme();
    const body = TextTheme();
    return display.copyWith(
      bodyLarge: body.bodyLarge,
      bodyMedium: body.bodyMedium,
      bodySmall: body.bodySmall,
      labelLarge: display.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      textTheme: _textTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: surface,
        error: error,
      ),
      scaffoldBackgroundColor: surface,
      iconTheme: const IconThemeData(color: text),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: text,
        ),
        hintStyle: const TextStyle(color: textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.65),
          disabledForegroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textMuted,
          textStyle: const TextStyle(fontSize: 14),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primaryMuted,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 24);
          }
          return const IconThemeData(color: textSecondary, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primary,
            );
          }
          return const TextStyle(fontSize: 12, color: textMuted);
        }),
      ),
    );
  }
}

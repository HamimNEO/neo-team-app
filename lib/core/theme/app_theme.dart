import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge
          ?.copyWith(fontSize: 34, fontWeight: FontWeight.w700, color: primary),
      displayMedium: base.displayMedium
          ?.copyWith(fontSize: 28, fontWeight: FontWeight.w700, color: primary),
      displaySmall: base.displaySmall
          ?.copyWith(fontSize: 22, fontWeight: FontWeight.w700, color: primary),
      headlineMedium: base.headlineMedium
          ?.copyWith(fontSize: 17, fontWeight: FontWeight.w600, color: primary),
      bodyLarge:
          base.bodyLarge?.copyWith(fontSize: 17, color: primary, height: 1.47),
      bodyMedium:
          base.bodyMedium?.copyWith(fontSize: 15, color: primary, height: 1.47),
      bodySmall: base.bodySmall?.copyWith(
          fontSize: 13, fontWeight: FontWeight.w600, color: secondary),
      labelSmall: base.labelSmall?.copyWith(fontSize: 12, color: secondary),
    );
  }

  static ThemeData light() {
    const bg = AppColors.bgLight;
    const surface = AppColors.surfaceLight;
    const primary = AppColors.brandLight;
    const textPri = AppColors.textPrimaryLight;
    const textSec = AppColors.textSecondaryLight;
    const sep = AppColors.separatorLight;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
          primary: primary, surface: surface, error: AppColors.error),
      scaffoldBackgroundColor: bg,
      textTheme: _buildTextTheme(textPri, textSec),
      dividerColor: sep,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPri,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.inter(
            fontSize: 17, fontWeight: FontWeight.w600, color: textPri),
      ),
      extensions: const [NecColors.light()],
    );
  }

  static ThemeData dark() {
    const bg = AppColors.bgDark;
    const surface = AppColors.surfaceDark;
    const primary = AppColors.brandDark;
    const textPri = AppColors.textPrimaryDark;
    const textSec = AppColors.textSecondaryDark;
    const sep = AppColors.separatorDark;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
          primary: primary, surface: surface, error: AppColors.error),
      scaffoldBackgroundColor: bg,
      textTheme: _buildTextTheme(textPri, textSec),
      dividerColor: sep,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPri,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.inter(
            fontSize: 17, fontWeight: FontWeight.w600, color: textPri),
      ),
      extensions: const [NecColors.dark()],
    );
  }
}

class NecColors extends ThemeExtension<NecColors> {
  final Color brand,
      bg,
      surface,
      surfaceSecondary,
      textPrimary,
      textSecondary,
      textTertiary,
      separator;

  const NecColors(
      {required this.brand,
      required this.bg,
      required this.surface,
      required this.surfaceSecondary,
      required this.textPrimary,
      required this.textSecondary,
      required this.textTertiary,
      required this.separator});

  const NecColors.light()
      : brand = AppColors.brandLight,
        bg = AppColors.bgLight,
        surface = AppColors.surfaceLight,
        surfaceSecondary = AppColors.surfaceSecondaryLight,
        textPrimary = AppColors.textPrimaryLight,
        textSecondary = AppColors.textSecondaryLight,
        textTertiary = AppColors.textTertiaryLight,
        separator = AppColors.separatorLight;

  const NecColors.dark()
      : brand = AppColors.brandDark,
        bg = AppColors.bgDark,
        surface = AppColors.surfaceDark,
        surfaceSecondary = AppColors.surfaceSecondaryDark,
        textPrimary = AppColors.textPrimaryDark,
        textSecondary = AppColors.textSecondaryDark,
        textTertiary = AppColors.textTertiaryDark,
        separator = AppColors.separatorDark;

  @override
  NecColors copyWith(
          {Color? brand,
          Color? bg,
          Color? surface,
          Color? surfaceSecondary,
          Color? textPrimary,
          Color? textSecondary,
          Color? textTertiary,
          Color? separator}) =>
      NecColors(
          brand: brand ?? this.brand,
          bg: bg ?? this.bg,
          surface: surface ?? this.surface,
          surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
          textPrimary: textPrimary ?? this.textPrimary,
          textSecondary: textSecondary ?? this.textSecondary,
          textTertiary: textTertiary ?? this.textTertiary,
          separator: separator ?? this.separator);

  @override
  NecColors lerp(NecColors? other, double t) {
    if (other == null) return this;
    return NecColors(
        brand: Color.lerp(brand, other.brand, t)!,
        bg: Color.lerp(bg, other.bg, t)!,
        surface: Color.lerp(surface, other.surface, t)!,
        surfaceSecondary:
            Color.lerp(surfaceSecondary, other.surfaceSecondary, t)!,
        textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
        textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
        textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
        separator: Color.lerp(separator, other.separator, t)!);
  }
}

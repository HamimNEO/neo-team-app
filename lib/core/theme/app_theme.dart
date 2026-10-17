import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'theme_provider.dart';

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

  static ThemeData light([AppThemeStyle style = AppThemeStyle.defaultMode]) {
    final nec = NecColors.forStyle(style, isDark: false);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: nec.brand,
        surface: nec.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: nec.bg,
      textTheme: _buildTextTheme(nec.textPrimary, nec.textSecondary),
      dividerColor: nec.separator,
      appBarTheme: AppBarTheme(
        backgroundColor: nec.bg,
        foregroundColor: nec.textPrimary,
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
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: nec.textPrimary,
        ),
      ),
      extensions: [nec],
    );
  }

  static ThemeData dark([AppThemeStyle style = AppThemeStyle.defaultMode]) {
    final nec = NecColors.forStyle(style, isDark: true);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: nec.brand,
        surface: nec.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: nec.bg,
      textTheme: _buildTextTheme(nec.textPrimary, nec.textSecondary),
      dividerColor: nec.separator,
      appBarTheme: AppBarTheme(
        backgroundColor: nec.bg,
        foregroundColor: nec.textPrimary,
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
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: nec.textPrimary,
        ),
      ),
      extensions: [nec],
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

  const NecColors({
    required this.brand,
    required this.bg,
    required this.surface,
    required this.surfaceSecondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.separator,
  });

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

  const NecColors.lightBluish()
      : brand = const Color(0xFF0284C7),
        bg = const Color(0xFFEDF4FA),
        surface = const Color(0xFFFFFFFF),
        surfaceSecondary = const Color(0xFFE2EDF8),
        textPrimary = const Color(0xFF0F172A),
        textSecondary = const Color(0xFF475569),
        textTertiary = const Color(0xFF94A3B8),
        separator = const Color(0xFFCBD5E1);

  const NecColors.darkBluish()
      : brand = const Color(0xFF38BDF8),
        bg = const Color(0xFF0A111C),
        surface = const Color(0xFF111E30),
        surfaceSecondary = const Color(0xFF192B45),
        textPrimary = const Color(0xFFF1F5F9),
        textSecondary = const Color(0xFF94A3B8),
        textTertiary = const Color(0xFF64748B),
        separator = const Color(0xFF1E3A5F);

  const NecColors.lightEyeProtect()
      : brand = const Color(0xFFD97706),
        bg = const Color(0xFFFAF6EB),
        surface = const Color(0xFFFFFDF8),
        surfaceSecondary = const Color(0xFFF3ECE0),
        textPrimary = const Color(0xFF292524),
        textSecondary = const Color(0xFF57534E),
        textTertiary = const Color(0xFF8A847C),
        separator = const Color(0xFFE5DDD0);

  const NecColors.darkEyeProtect()
      : brand = const Color(0xFFF59E0B),
        bg = const Color(0xFF181512),
        surface = const Color(0xFF24201A),
        surfaceSecondary = const Color(0xFF322C24),
        textPrimary = const Color(0xFFFDFBF7),
        textSecondary = const Color(0xFFD6CEBE),
        textTertiary = const Color(0xFF8C8476),
        separator = const Color(0xFF3D362C);

  static NecColors forStyle(AppThemeStyle style, {required bool isDark}) {
    if (isDark) {
      switch (style) {
        case AppThemeStyle.bluish:
          return const NecColors.darkBluish();
        case AppThemeStyle.eyeProtect:
          return const NecColors.darkEyeProtect();
        case AppThemeStyle.defaultMode:
          return const NecColors.dark();
      }
    } else {
      switch (style) {
        case AppThemeStyle.bluish:
          return const NecColors.lightBluish();
        case AppThemeStyle.eyeProtect:
          return const NecColors.lightEyeProtect();
        case AppThemeStyle.defaultMode:
          return const NecColors.light();
      }
    }
  }

  @override
  NecColors copyWith({
    Color? brand,
    Color? bg,
    Color? surface,
    Color? surfaceSecondary,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? separator,
  }) =>
      NecColors(
        brand: brand ?? this.brand,
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
        surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textTertiary: textTertiary ?? this.textTertiary,
        separator: separator ?? this.separator,
      );

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
      separator: Color.lerp(separator, other.separator, t)!,
    );
  }
}

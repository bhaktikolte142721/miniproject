import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography hierarchy for SENTINEL-Ward.
/// Senior-Legible & Accessible: Large, stately Times New Roman serif aesthetic.
/// Metric-compatible with Times New Roman & Tinos with tabular figures for telemetry.
class AppTextStyles {
  // ─── Font Resolver Helper ──────────────────────────────────────────────────
  static TextStyle _timesRoman({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double? letterSpacing,
    double? height,
    List<FontFeature>? fontFeatures,
    FontStyle? fontStyle,
  }) {
    return GoogleFonts.tinos(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? AppColors.textPrimary,
      letterSpacing: letterSpacing,
      height: height,
      fontFeatures: fontFeatures,
      fontStyle: fontStyle,
    ).copyWith(
      fontFamilyFallback: const ['Times New Roman', 'Times', 'serif'],
    );
  }

  // ─── Headlines & Display (Significantly Enlarged & High-Contrast) ───────────
  static TextStyle get displayLarge => _timesRoman(
    fontSize: 56,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    letterSpacing: -0.6,
    height: 1.15,
  );

  static TextStyle get headlineMedium => _timesRoman(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.4,
    height: 1.2,
  );

  static TextStyle get headlineSmall => _timesRoman(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  // ─── Subtitles & Section Labels ───────────────────────────────────────────
  static TextStyle get titleLarge => _timesRoman(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get titleMedium => _timesRoman(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get titleSmall => _timesRoman(
    fontSize: 23,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  // ─── Body Content (Senior-Legible, 19.5px - 24px) ─────────────────────────
  static TextStyle get bodyLarge => _timesRoman(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle get bodyMedium => _timesRoman(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static TextStyle get bodySmall => _timesRoman(
    fontSize: 19.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  // ─── Numeric Telemetry (Large, Bold & Tabular) ─────────────────────────────
  static TextStyle get telemetryLarge => _timesRoman(
    fontSize: 56,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle get telemetryMedium => _timesRoman(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle get telemetrySmall => _timesRoman(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // ─── Labels, Chips & Badges ───────────────────────────────────────────────
  static TextStyle get chipText => _timesRoman(
    fontSize: 18.5,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
  );

  static TextStyle get chipTextSelected => _timesRoman(
    fontSize: 18.5,
    fontWeight: FontWeight.w800,
    color: AppColors.textOnDark,
  );

  static TextStyle get buttonText => _timesRoman(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.textOnDark,
    letterSpacing: 0.4,
  );

  static TextStyle get badgeText => _timesRoman(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
  );

  static TextStyle get labelMedium => _timesRoman(
    fontSize: 20.5,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // ─── Form Labels ─────────────────────────────────────────────────────────
  static TextStyle get formLabel => _timesRoman(
    fontSize: 21,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get formHint => _timesRoman(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  // ─── Section Headers ─────────────────────────────────────────────────────
  static TextStyle get sectionLabel => _timesRoman(
    fontSize: 18.5,
    fontWeight: FontWeight.w800,
    color: AppColors.textMuted,
    letterSpacing: 1.2,
  );
}

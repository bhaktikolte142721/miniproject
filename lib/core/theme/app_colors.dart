import 'package:flutter/material.dart';

/// Design system color definitions for SENTINEL-Ward.
/// Strict implementation of the 3D Soft Claymorphic Medical UI Palette.
class AppColors {
  // Surgical Canvas Background (Soft Gradient)
  static const Color backgroundStart = Color(0xFFF5F9FA);
  static const Color backgroundEnd = Color(0xFFEDF4F6);
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundStart, backgroundEnd],
  );

  // Mint / Teal Primary Accents
  static const Color primaryMint = Color(0xFF00BFA5);
  static const Color primaryTeal = Color(0xFF00838F);
  static const Color primaryDark = Color(0xFF004D40);
  static const Color mintLight = Color(0xFFE0F2F1);
  static const Color mintGlow = Color(0x3300BFA5);
  static const Color coralLight = Color(0xFFFFEBEE);
  static const Color scaffoldBg = Color(0xFFF5F9FA);

  static const LinearGradient mintTealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00E5FF), Color(0xFF00BFA5), Color(0xFF00838F)],
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00BFA5), Color(0xFF00838F)],
  );

  // Frosted Pearl & Surfaces
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color cardSurfaceFrosted = Color(0xFAFFFFFF);
  static const Color cardBorder = Color(0xFFE0F2F1);
  static const Color cardBorderSubtle = Color(0x66E0F2F1);
  static const Color chipInactive = Color(0xFFEBF3F5);

  // Clinical Alert & Tri-State Color Palette
  static const Color alertCritical = Color(0xFFFF5252); // Critical Coral
  static const Color alertWarning = Color(0xFFFFB300);  // Warning Amber
  static const Color alertStable = Color(0xFF00C853);   // Stable Emerald
  static const Color alertInfo = Color(0xFF0288D1);     // Diagnostic Blue

  // Alert Background Tints
  static const Color alertCriticalBg = Color(0xFFFFEBEE);
  static const Color alertWarningBg = Color(0xFFFFF8E1);
  static const Color alertStableBg = Color(0xFFE8F5E9);
  static const Color alertInfoBg = Color(0xFFE1F5FE);

  // Typography
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // 3D Claymorphism Lighting Shadows
  static const BoxShadow clayLightShadow = BoxShadow(
    color: Color(0x0F000000),
    blurRadius: 20,
    offset: Offset(0, 10),
    spreadRadius: 0,
  );

  static const BoxShadow claySpecularHighlight = BoxShadow(
    color: Color(0xE6FFFFFF),
    blurRadius: 10,
    offset: Offset(-4, -4),
    spreadRadius: 0,
  );

  static const BoxShadow clayCardSubtleShadow = BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 14,
    offset: Offset(0, 6),
    spreadRadius: 0,
  );

  static const BoxShadow clayPillShadow = BoxShadow(
    color: Color(0x1A00BFA5),
    blurRadius: 16,
    offset: Offset(0, 8),
    spreadRadius: 0,
  );

  static List<BoxShadow> get standardClayShadows => [
    clayLightShadow,
    claySpecularHighlight,
  ];

  static List<BoxShadow> get pressedClayShadows => [
    const BoxShadow(
      color: Color(0x10000000),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
    const BoxShadow(
      color: Color(0x80FFFFFF),
      blurRadius: 4,
      offset: Offset(-1, -1),
    ),
  ];
}

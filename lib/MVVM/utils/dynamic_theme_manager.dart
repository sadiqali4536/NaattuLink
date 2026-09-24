import 'package:flutter/material.dart';

class StoreTheme {
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color cardColor;
  final List<Color> gradientColors;
  final Color textColor;
  final Color secondaryTextColor;
  final Color offerColor;
  final Color sectionBackgroundColor;

  const StoreTheme({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.cardColor,
    required this.gradientColors,
    required this.textColor,
    required this.secondaryTextColor,
    required this.offerColor,
    required this.sectionBackgroundColor,
  });
}

class DynamicThemeManager {
  static final List<StoreTheme> _palettes = [
    const StoreTheme(
      primaryColor: Color(0xFF0F2E5A),
      secondaryColor: Color(0xFF0EA5E9),
      accentColor: Color(0xFF38BDF8),
      backgroundColor: Color(0xFFF8FAFC),
      cardColor: Colors.white,
      gradientColors: [Color(0xFF0F2E5A), Color(0xFF1E40AF)],
      textColor: Color(0xFF0F172A),
      secondaryTextColor: Color(0xFF475569),
      offerColor: Color(0xFFDC2626),
      sectionBackgroundColor: Color(0xFFE0F2FE),
    ),
    const StoreTheme(
      primaryColor: Color(0xFF4C1D95),
      secondaryColor: Color(0xFF7C3AED),
      accentColor: Color(0xFFF97316),
      backgroundColor: Color(0xFFF5F3FF),
      cardColor: Colors.white,
      gradientColors: [Color(0xFF4C1D95), Color(0xFF6D28D9)],
      textColor: Color(0xFF1E1B4B),
      secondaryTextColor: Color(0xFF4C1D95),
      offerColor: Color(0xFFEA580C),
      sectionBackgroundColor: Color(0xFFEDE9FE),
    ),
    const StoreTheme(
      primaryColor: Color(0xFF064E3B),
      secondaryColor: Color(0xFF059669),
      accentColor: Color(0xFF10B981),
      backgroundColor: Color(0xFFF0FDF4),
      cardColor: Colors.white,
      gradientColors: [Color(0xFF064E3B), Color(0xFF047857)],
      textColor: Color(0xFF022C22),
      secondaryTextColor: Color(0xFF065F46),
      offerColor: Color(0xFFDC2626),
      sectionBackgroundColor: Color(0xFFD1FAE5),
    ),
    const StoreTheme(
      primaryColor: Color(0xFF881337),
      secondaryColor: Color(0xFFE11D48),
      accentColor: Color(0xFFFB7185),
      backgroundColor: Color(0xFFFFF1F2),
      cardColor: Colors.white,
      gradientColors: [Color(0xFF881337), Color(0xFFBE123C)],
      textColor: Color(0xFF4C0519),
      secondaryTextColor: Color(0xFF9F1239),
      offerColor: Color(0xFF059669),
      sectionBackgroundColor: Color(0xFFFFE4E6),
    ),
    const StoreTheme(
      primaryColor: Color(0xFF312E81),
      secondaryColor: Color(0xFF4F46E5),
      accentColor: Color(0xFF06B6D4),
      backgroundColor: Color(0xFFEEF2FF),
      cardColor: Colors.white,
      gradientColors: [Color(0xFF312E81), Color(0xFF4338CA)],
      textColor: Color(0xFF1E1B4B),
      secondaryTextColor: Color(0xFF3730A3),
      offerColor: Color(0xFFE11D48),
      sectionBackgroundColor: Color(0xFFE0E7FF),
    ),
    const StoreTheme(
      primaryColor: Color(0xFF78350F),
      secondaryColor: Color(0xFFD97706),
      accentColor: Color(0xFFF59E0B),
      backgroundColor: Color(0xFFFFFBEB),
      cardColor: Colors.white,
      gradientColors: [Color(0xFF78350F), Color(0xFFB45309)],
      textColor: Color(0xFF451A03),
      secondaryTextColor: Color(0xFF92400E),
      offerColor: Color(0xFFDC2626),
      sectionBackgroundColor: Color(0xFFFEF3C7),
    ),
    const StoreTheme(
      primaryColor: Color(0xFF134E4A),
      secondaryColor: Color(0xFF0D9488),
      accentColor: Color(0xFF14B8A6),
      backgroundColor: Color(0xFFF0FDFA),
      cardColor: Colors.white,
      gradientColors: [Color(0xFF134E4A), Color(0xFF0F766E)],
      textColor: Color(0xFF042F2E),
      secondaryTextColor: Color(0xFF115E59),
      offerColor: Color(0xFFE11D48),
      sectionBackgroundColor: Color(0xFFCCFBF1),
    ),
    const StoreTheme(
      primaryColor: Color(0xFF0F172A),
      secondaryColor: Color(0xFF334155),
      accentColor: Color(0xFF3B82F6),
      backgroundColor: Color(0xFFF8FAFC),
      cardColor: Colors.white,
      gradientColors: [Color(0xFF0F172A), Color(0xFF1E293B)],
      textColor: Color(0xFF020617),
      secondaryTextColor: Color(0xFF475569),
      offerColor: Color(0xFFEF4444),
      sectionBackgroundColor: Color(0xFFE2E8F0),
    ),
  ];

  static StoreTheme generateTheme({String? storeId}) {
    final now = DateTime.now();
    final int daysSinceEpoch = now.millisecondsSinceEpoch ~/ (1000 * 60 * 60 * 24);
    final int periodSeed = daysSinceEpoch ~/ 2;
    
    int finalSeed = periodSeed;
    if (storeId != null && storeId.isNotEmpty) {
      finalSeed += storeId.hashCode;
    }
    
    final int paletteIndex = finalSeed.abs() % _palettes.length;
    return _palettes[paletteIndex];
  }
}

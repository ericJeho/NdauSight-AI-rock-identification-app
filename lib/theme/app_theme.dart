import 'package:flutter/material.dart';

/// Central place for NdauSight's colours, typography and component styling.
///
/// The palette leans on earthy geological tones — slate, ochre and a warm
/// gold accent — so the app feels at home in the field.
class AppColors {
  AppColors._();

  static const Color slate = Color(0xFF1F2933);
  static const Color slateLight = Color(0xFF3E4C59);
  static const Color surface = Color(0xFFF5F3EF);
  static const Color card = Color(0xFFFFFFFF);

  static const Color gold = Color(0xFFC9A227);
  static const Color goldDeep = Color(0xFF9C7A10);
  static const Color copper = Color(0xFFB87333);
  static const Color silver = Color(0xFF9AA5B1);
  static const Color lithium = Color(0xFF4C9A8F);
  static const Color ree = Color(0xFF7E57C2);
  static const Color gemstone = Color(0xFFE05263);

  static const Color success = Color(0xFF2E7D5B);
  static const Color warning = Color(0xFFD98324);
  static const Color danger = Color(0xFFC0392B);
  static const Color textPrimary = Color(0xFF1F2933);
  static const Color textMuted = Color(0xFF7B8794);

  /// Colour used for a given mineral-potential key.
  static Color forMineral(String key) {
    switch (key.toLowerCase()) {
      case 'gold':
        return gold;
      case 'silver':
        return silver;
      case 'copper':
        return copper;
      case 'lithium':
        return lithium;
      case 'rare earth elements':
      case 'ree':
        return ree;
      case 'gemstones':
      case 'gemstone':
        return gemstone;
      default:
        return slateLight;
    }
  }

  /// Traffic-light colour for a 0–100 probability/confidence value.
  static Color forScore(double pct) {
    if (pct >= 60) return success;
    if (pct >= 30) return warning;
    return danger;
  }
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.slate,
        secondary: AppColors.gold,
        surface: AppColors.card,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.slate,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 1.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.slate,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: const Color(0xFFEDEAE3),
        labelStyle: const TextStyle(color: AppColors.textPrimary),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
    );
  }
}

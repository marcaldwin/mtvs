import 'package:flutter/material.dart';

/// Brand colors derived from the TMEU Kidapawan logo
class AppColors {
  // Core brand
  static const Color primary = Color(0xFF264C92); // deep blue ring
  static const Color secondary = Color(0xFF2AB6B0); // teal/sea-green
  static const Color accent = Color(0xFFFFC300); // signal yellow
  static const Color danger = Color(0xFFE53935); // safety red

  // Neutrals
  static const Color bg = Color(0xFF1E293B);
  static const Color surface = Color(0xFF1E293B); // card/panel
  static const Color onSurface = Color(0xFFF3F4F6); // text light
  static const Color onSurfaceMuted = Color(0xFF94A3B8); // text muted

  // Success/info
  static const Color success = Color(0xFF22C55E);
  static const Color info = Color(0xFF3B82F6);

  // Decorative gradients
  static const List<Color> brandGradient = [primary, secondary];
}

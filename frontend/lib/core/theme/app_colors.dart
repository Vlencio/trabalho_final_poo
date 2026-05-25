import 'package:flutter/material.dart';

class AppColors {
  // Deep space/obsidian background colors
  static const Color background = Color(0xFF090D16);
  static const Color surface = Color(0xFF131A26);
  static const Color surfaceElevated = Color(0xFF1C2535);

  // Brand colors
  static const Color primary = Color(0xFF0EA5E9); // Modern sky blue
  static const Color secondary = Color(0xFF0D9488); // Teal
  static const Color accent = Color(0xFF38BDF8); // Bright electric cyan

  // Brand gradients
  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient backgroundGradient = LinearGradient(
    colors: [background, Color(0xFF111827)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Status/Semantic colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Text colors
  static const Color textPrimary = Color(0xFFF8FAFC); // Almost white
  static const Color textSecondary = Color(0xFF94A3B8); // Cool grey
  static const Color textMuted = Color(0xFF64748B); // Muted grey

  // Border and Divider colors
  static const Color border = Color(0xFF222F43);
  static const Color divider = Color(0xFF1E293B);

  // Bubble colors
  static const Color bubbleUser = Color(0xFF0EA5E9);
  static const Color bubbleAI = Color(0xFF1E293B);
}

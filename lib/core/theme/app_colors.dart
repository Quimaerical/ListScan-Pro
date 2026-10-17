import 'package:flutter/material.dart';

/// Specification for a pastel glassmorphic palette preset.
class PastelPalette {
  final String name;
  final Color lightBackground;
  final Color darkBackground;
  final Color lightAccent;
  final Color darkAccent;
  final Color lightCardBorder;
  final Color darkCardBorder;

  const PastelPalette({
    required this.name,
    required this.lightBackground,
    required this.darkBackground,
    required this.lightAccent,
    required this.darkAccent,
    required this.lightCardBorder,
    required this.darkCardBorder,
  });

  Color backgroundColor(bool isDark) => isDark ? darkBackground : lightBackground;
  Color accentColor(bool isDark) => isDark ? darkAccent : lightAccent;
  Color borderColor(bool isDark) => isDark ? darkCardBorder : lightCardBorder;
}

/// Central design palette with soft, appetizing pastel glassmorphic tones.
class AppColors {
  const AppColors._();

  // Primary brand accents
  static const Color primaryMint = Color(0xFF2A9D8F);
  static const Color primaryBlue = Color(0xFF3B82F6);

  // Background foundations
  static const Color scaffoldLight = Color(0xFFF7F9FC);
  static const Color scaffoldDark = Color(0xFF101418);

  // Surfaces for glass base
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1A2027);

  // Text colors
  static const Color textPrimaryLight = Color(0xFF1E293B);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Borders
  static final Color borderLight = Colors.white.withValues(alpha: 0.45);
  static final Color borderDark = Colors.white.withValues(alpha: 0.12);

  /// 5 Appetizing Pastel Palettes:
  /// 0: Verdeagua (Mint)
  /// 1: Azul Pastel (Sky)
  /// 2: Rosa Pastel (Strawberry / Blush)
  /// 3: Amarillo Mantequilla (Butter / Vanilla)
  /// 4: Lavanda Suave (Soft Lavender)
  static const List<PastelPalette> palettes = <PastelPalette>[
    // 0: Verdeagua
    PastelPalette(
      name: 'Verdeagua',
      lightBackground: Color(0xFFD8F3DC),
      darkBackground: Color(0xFF16322C),
      lightAccent: Color(0xFF2D6A4F),
      darkAccent: Color(0xFF74C69D),
      lightCardBorder: Color(0xFFB7E4C7),
      darkCardBorder: Color(0xFF234B42),
    ),
    // 1: Azul Pastel
    PastelPalette(
      name: 'Azul Pastel',
      lightBackground: Color(0xFFE0EEFD),
      darkBackground: Color(0xFF192A3E),
      lightAccent: Color(0xFF2563EB),
      darkAccent: Color(0xFF93C5FD),
      lightCardBorder: Color(0xFFBFDBFE),
      darkCardBorder: Color(0xFF2A4365),
    ),
    // 2: Rosa Pastel
    PastelPalette(
      name: 'Rosa Fresa',
      lightBackground: Color(0xFFFDE2E4),
      darkBackground: Color(0xFF381D25),
      lightAccent: Color(0xFFE11D48),
      darkAccent: Color(0xFFFDA4AF),
      lightCardBorder: Color(0xFFFECDD3),
      darkCardBorder: Color(0xFF4C2733),
    ),
    // 3: Amarillo Mantequilla
    PastelPalette(
      name: 'Amarillo Vainilla',
      lightBackground: Color(0xFFFFF1C5),
      darkBackground: Color(0xFF372D16),
      lightAccent: Color(0xFFD97706),
      darkAccent: Color(0xFFFDE68A),
      lightCardBorder: Color(0xFFFDE68A),
      darkCardBorder: Color(0xFF50411F),
    ),
    // 4: Lavanda Suave
    PastelPalette(
      name: 'Lavanda Suave',
      lightBackground: Color(0xFFEDE4FF),
      darkBackground: Color(0xFF281D3B),
      lightAccent: Color(0xFF7C3AED),
      darkAccent: Color(0xFFDDD6FE),
      lightCardBorder: Color(0xFFDDD6FE),
      darkCardBorder: Color(0xFF3F2D5D),
    ),
  ];

  /// Safe accessor to retrieve a palette by index.
  static PastelPalette getPalette(int index) {
    if (index < 0 || index >= palettes.length) {
      return palettes[0];
    }
    return palettes[index];
  }
}

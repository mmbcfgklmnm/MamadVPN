import 'package:flutter/material.dart';

class AppColors {
  // Brand Gradients & Accents
  static const Color neonCyan = Color(0xFF00F2FE);
  static const Color cyberBlue = Color(0xFF4FACFE);
  static const Color electricViolet = Color(0xFF7F00FF);
  static const Color neonPurple = Color(0xFFE100FF);

  // Status Colors
  static const Color connectedGreen = Color(0xFF00E676);
  static const Color connectingYellow = Color(0xFFFFB300);
  static const Color disconnectedRed = Color(0xFFFF5252);
  static const Color pingGood = Color(0xFF00E676);     // < 150ms
  static const Color pingMedium = Color(0xFFFFB300);   // 150ms - 350ms
  static const Color pingBad = Color(0xFFFF5252);      // > 350ms
  static const Color pingTimeout = Color(0xFF757575);  // Failed

  // Dark Theme Palette (Cyberpunk / OLED Futuristic)
  static const Color darkBackground = Color(0xFF0B0E14);
  static const Color darkSurface = Color(0xFF151922);
  static const Color darkCard = Color(0xFF1B202D);
  static const Color darkCardBorder = Color(0xFF2B3345);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Light Theme Palette (Clean Modern Studio)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);
  static const Color lightPrimary = Color(0xFF2563EB);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [neonCyan, cyberBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [electricViolet, neonPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient connectedGradient = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient powerButtonGlow = LinearGradient(
    colors: [Color(0xFF00F2FE), Color(0xFF7F00FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

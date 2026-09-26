import 'package:flutter/material.dart';

/// Design system color palette extracted directly from App_Screen.pdf
class AppColors {
  // Brand & Action Colors
  static const Color primaryTeal = Color(0xFF005C53);
  static const Color primaryTealDark = Color(0xFF044841);
  static const Color primaryTealLight = Color(0xFF0A7B6F);

  // Backgrounds
  static const Color background = Color(0xFFF8F9FD);
  static const Color surfaceWhite = Colors.white;

  // Text Colors
  static const Color textDark = Color(0xFF1E2544);
  static const Color textSubtitle = Color(0xFF7C8BA0);
  static const Color textMuted = Color(0xFF9EA8B6);

  // Accent & Decoration
  static const Color accentSunburst = Color(0xFFFFB800);
  static const Color dividerLine = Color(0xFFE2E8F0);

  // Quiz Option States
  static const Color optionBorder = Color(0xFFE2E8F0);
  static const Color optionBackground = Color(0xFFF8FAFC);
  static const Color optionSelectedBackground = Color(0xFFD6EFE0);
  static const Color optionSelectedBorder = Color(0xFF2E7D32);
  static const Color optionSelectedText = Color(0xFF1B5E20);

  // Result Badge Colors
  static const Color resultSuccessGreen = Color(0xFFA8E6CF);
  static const Color resultSuccessText = Color(0xFF1B5E20);
  static const Color resultFailureOrange = Color(0xFFFF6D60);
  static const Color resultFailureText = Colors.white;

  // Review / View Answers Colors
  static const Color reviewCorrectBg = Color(0xFFE8F5E9);
  static const Color reviewCorrectText = Color(0xFF2E7D32);
  static const Color reviewWrongBg = Color(0xFFFFEBEE);
  static const Color reviewWrongText = Color(0xFFC62828);
  static const Color reviewUnansweredBg = Color(0xFFFFF3E0);
  static const Color reviewUnansweredText = Color(0xFFE65100);

  // Category Pastel Backgrounds
  static const Color catGeneralKnowledge = Color(0xFFE8F4FD);
  static const Color catBooks = Color(0xFFEAF8EE);
  static const Color catHistory = Color(0xFFFFF3E6);
  static const Color catScience = Color(0xFFEFEAFF);
  static const Color catArt = Color(0xFFFFEAEA);
  static const Color catVehicles = Color(0xFFE6F2FF);
  static const Color catEntertainment = Color(0xFFFFF0F5);
  static const Color catGeography = Color(0xFFE0F7FA);

  // Slider & Progress
  static const Color sliderActive = Color(0xFF2979FF);
  static const Color progressTrack = Color(0xFFE2E8F0);
}

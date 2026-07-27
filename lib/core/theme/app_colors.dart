import 'package:flutter/material.dart';

class AppColors {
  // Primary seed color
  static const Color seed = Color(0xFF2196F3);

  // Difficulty colors (consistent in both modes)
  static const Color beginner = Color(0xFF4CAF50);
  static const Color intermediate = Color(0xFFFFA726);
  static const Color advanced = Color(0xFFEF5350);

  // Activity colors
  static const Color gym = Color(0xFF4CAF50);
  static const Color run = Color(0xFF42A5F5);
  static const Color swim = Color(0xFF26C6DA);
  static const Color football = Color(0xFFFF7043);
  static const Color tt = Color(0xFFEC407A);
  static const Color badminton = Color(0xFFAB47BC);
  static const Color hockey = Color(0xFF26A69A);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFEF5350);

  // Category accent colors for exercise cards
  static const Map<String, Color> bodyPartColors = {
    'chest': Color(0xFFE53935),
    'back': Color(0xFF1E88E5),
    'shoulders': Color(0xFFFB8C00),
    'upper arms': Color(0xFF8E24AA),
    'lower arms': Color(0xFFAB47BC),
    'upper legs': Color(0xFF43A047),
    'lower legs': Color(0xFF66BB6A),
    'cardio': Color(0xFFE91E63),
    'waist': Color(0xFF00ACC1),
    'neck': Color(0xFF78909C),
  };

  static Color getBodyPartColor(String bodyPart) {
    return bodyPartColors[bodyPart.toLowerCase()] ?? seed;
  }
}

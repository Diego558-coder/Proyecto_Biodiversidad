import 'package:flutter/material.dart';

class AppColors {
  // Colores primarios
  static const Color primary = Color(0xFF4CAF50);
  static const Color primaryLight = Color(0xFF81C784);
  static const Color primaryDark = Color(0xFF388E3C);
  
  // Colores secundarios
  static const Color secondary = Color(0xFF2196F3);
  static const Color secondaryLight = Color(0xFF64B5F6);
  static const Color secondaryDark = Color(0xFF1976D2);
  
  // Colores de estado
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE91E63);
  static const Color info = Color(0xFF2196F3);
  
  // Colores de fondo
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // Colores de texto
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  // Colores específicos de la app
  static const Color estadoEjecucion = Color(0xFF4CAF50);
  static const Color especieMacho = Color(0xFF2196F3);
  static const Color especieHembra = Color(0xFFE91E63);
  static const Color especieAdulto = Color(0xFF4CAF50);
  static const Color especieJoven = Color(0xFFFF9800);
  static const Color especieIndeterminado = Color(0xFFFFC107);
  
  // Colores de bordes y divisores
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFE0E0E0);
  
  // Colores con opacidad
  static Color primaryWithOpacity(double opacity) => primary.withOpacity(opacity);
  static Color blackWithOpacity(double opacity) => Colors.black.withOpacity(opacity);
  static Color whiteWithOpacity(double opacity) => Colors.white.withOpacity(opacity);
}
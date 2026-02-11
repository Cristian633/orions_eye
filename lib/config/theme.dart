import 'package:flutter/material.dart';

class AppTheme {
  //colores principales de la aplicacion
  static const Color primary = Color(0xFF1E3A5F);
  static const Color secondary = Color(0xFF3498DB);
  static const Color background = Color(0xFF0D1B2A); // Color oscuro para tema oscuro
  static const Color accent = Color(0xFF1B263B); 

  //colores del texto
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFF1B263B);

  //colores de estado
  static const Color success = Color(0xFF27AE60);
  static const Color error = Color(0xFFE74C3C);

  //Metodo que retorna el dato completo

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
        background: background,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        foregroundColor: textPrimary,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
      ),
    );
  }
}
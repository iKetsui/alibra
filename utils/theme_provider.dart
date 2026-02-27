import 'package:flutter/material.dart';

// Theme color definitions
class AppThemeColors {
  final String name;
  final Color primary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color text;
  final Color secondaryText;
  final Color appBar;
  final Color cardBackground;

  const AppThemeColors({
    required this.name,
    required this.primary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.text,
    required this.secondaryText,
    required this.appBar,
    required this.cardBackground,
  });
}

// Available themes
class AppThemes {
  // Blue theme (current)
  static const AppThemeColors blue = AppThemeColors(
    name: 'Blue',
    primary: Color(0xFF3498DB),
    accent: Color(0xFF2980B9),
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF8F9FA),
    text: Color(0xFF2C3E50),
    secondaryText: Color(0xFF7F8C8D),
    appBar: Color(0xFFF8F9FA),
    cardBackground: Color(0xFFF8F9FA),
  );

  // Red theme
  static const AppThemeColors red = AppThemeColors(
    name: 'Red',
    primary: Color(0xFFE74C3C),
    accent: Color(0xFFC0392B),
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF8F9FA),
    text: Color(0xFF2C3E50),
    secondaryText: Color(0xFF7F8C8D),
    appBar: Color(0xFFF8F9FA),
    cardBackground: Color(0xFFF8F9FA),
  );

  // Yellow theme
  static const AppThemeColors yellow = AppThemeColors(
    name: 'Yellow',
    primary: Color(0xFFF1C40F),
    accent: Color(0xFFF39C12),
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF8F9FA),
    text: Color(0xFF2C3E50),
    secondaryText: Color(0xFF7F8C8D),
    appBar: Color(0xFFF8F9FA),
    cardBackground: Color(0xFFF8F9FA),
  );

  // Green theme
  static const AppThemeColors green = AppThemeColors(
    name: 'Green',
    primary: Color(0xFF2ECC71),
    accent: Color(0xFF27AE60),
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF8F9FA),
    text: Color(0xFF2C3E50),
    secondaryText: Color(0xFF7F8C8D),
    appBar: Color(0xFFF8F9FA),
    cardBackground: Color(0xFFF8F9FA),
  );

  // Purple theme
  static const AppThemeColors purple = AppThemeColors(
    name: 'Purple',
    primary: Color(0xFF9B59B6),
    accent: Color(0xFF8E44AD),
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF8F9FA),
    text: Color(0xFF2C3E50),
    secondaryText: Color(0xFF7F8C8D),
    appBar: Color(0xFFF8F9FA),
    cardBackground: Color(0xFFF8F9FA),
  );

  // List of all themes
  static const List<AppThemeColors> allThemes = [
    blue,
    red,
    yellow,
    green,
    purple,
  ];

  // Get theme by name
  static AppThemeColors getTheme(String name) {
    switch (name) {
      case 'Red':
        return red;
      case 'Yellow':
        return yellow;
      case 'Green':
        return green;
      case 'Purple':
        return purple;
      default:
        return blue;
    }
  }
}

// Theme provider class to manage current theme
class ThemeProvider extends ChangeNotifier {
  AppThemeColors _currentTheme = AppThemes.blue;

  AppThemeColors get currentTheme => _currentTheme;

  void setTheme(AppThemeColors theme) {
    _currentTheme = theme;
    notifyListeners();
  }

  void setThemeByName(String name) {
    _currentTheme = AppThemes.getTheme(name);
    notifyListeners();
  }
}
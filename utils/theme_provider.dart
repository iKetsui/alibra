import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme color definitions
class AppThemeColors {
  final String name;
  final Color primary;
  final Color accent;
  final Color appBar;
  final Color background;
  final Color surface;
  final Color text;
  final Color secondaryText;

  const AppThemeColors({
    required this.name,
    required this.primary,
    required this.accent,
    required this.appBar,
    required this.background,
    required this.surface,
    required this.text,
    required this.secondaryText,
  });
}

// Available themes
class AppThemes {
  // Blue theme
  static const AppThemeColors blue = AppThemeColors(
    name: 'Blue',
    primary: Color(0xFF3498DB),
    accent: Color(0xFF2980B9),
    appBar: Color(0xFF3498DB),
    background: Color(0xFFE8F0FE),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF2C3E50),
    secondaryText: Color(0xFF7F8C8D),
  );

  // Red theme
  static const AppThemeColors red = AppThemeColors(
    name: 'Red',
    primary: Color(0xFFE74C3C),
    accent: Color(0xFFC0392B),
    appBar: Color(0xFFE74C3C),
    background: Color(0xFFFDE9E9),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF2C3E50),
    secondaryText: Color(0xFF7F8C8D),
  );

  // Yellow theme
  static const AppThemeColors yellow = AppThemeColors(
    name: 'Yellow',
    primary: Color(0xFFF1C40F),
    accent: Color(0xFFF39C12),
    appBar: Color(0xFFF1C40F),
    background: Color(0xFFFFF2D0),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF2C3E50),
    secondaryText: Color(0xFF7F8C8D),
  );

  // Green theme
  static const AppThemeColors green = AppThemeColors(
    name: 'Green',
    primary: Color(0xFF2ECC71),
    accent: Color(0xFF27AE60),
    appBar: Color(0xFF2ECC71),
    background: Color(0xFFE0F3E4),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF2C3E50),
    secondaryText: Color(0xFF7F8C8D),
  );

  // Purple theme
  static const AppThemeColors purple = AppThemeColors(
    name: 'Purple',
    primary: Color(0xFF9B59B6),
    accent: Color(0xFF8E44AD),
    appBar: Color(0xFF9B59B6),
    background: Color(0xFFF3E5F7),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF2C3E50),
    secondaryText: Color(0xFF7F8C8D),
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

// Theme provider class to manage current theme with persistence
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  
  AppThemeColors _currentTheme = AppThemes.blue;

  AppThemeColors get currentTheme => _currentTheme;

  ThemeProvider() {
    _loadSavedTheme();
  }

  // Load saved theme from SharedPreferences
  Future<void> _loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeName = prefs.getString(_themeKey);
      
      if (savedThemeName != null) {
        _currentTheme = AppThemes.getTheme(savedThemeName);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading saved theme: $e');
    }
  }

  // Save theme to SharedPreferences and update
  Future<void> setTheme(AppThemeColors theme) async {
    _currentTheme = theme;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, theme.name);
    } catch (e) {
      print('Error saving theme: $e');
    }
    
    notifyListeners();
  }

  // Save theme by name
  Future<void> setThemeByName(String name) async {
    final theme = AppThemes.getTheme(name);
    await setTheme(theme);
  }
}
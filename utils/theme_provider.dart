// ==================== theme_provider.dart ====================
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
  // ===== EXISTING THEMES =====

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

  // ==================== theme_provider.dart (Updated Themes) ====================

// Dracula Light Theme (with slight purple-tinted background)
  static const AppThemeColors dracula = AppThemeColors(
    name: 'Dracula',
    primary: Color(0xFFBD93F9), // Purple
    accent: Color(0xFF50FA7B), // Green
    appBar: Color(0xFFF0E6FF), // Light lavender
    background: Color(0xFFF5F0FF), // Very light purple-tinted (not plain white)
    surface: Color(0xFFFFFFFF), // White surface for cards
    text: Color(0xFF282A36), // Dark text
    secondaryText: Color(0xFF6272A4), // Soft purple-gray
  );


// ==================== theme_provider.dart (Fixed - Keep both) ====================

// Gruvbox Brown/Orange Theme (original)
  static const AppThemeColors gruvbox = AppThemeColors(
    name: 'Gruvbox',
    primary: Color(0xFFB57614), // Orange/Yellow
    accent: Color(0xFF79740E), // Green
    appBar: Color(0xFFFDF4E3), // Light background (matches theme)
    background: Color(0xFFFDF4E3), // Light background (gruvbox light)
    surface: Color(0xFFFFFFFF), // White surface
    text: Color(0xFF3C3836), // Dark brown text
    secondaryText: Color(0xFF7C6F64), // Gray-brown
  );

// Gruvbox Green Theme (new - based on Gruvbox but green primary)
  static const AppThemeColors gruvboxGreen = AppThemeColors(
    name: 'Gruvbox Green',
    primary: Color(0xFF8F9A4D), // Muted sage green
    accent: Color(0xFF79740E), // Olive green (same accent)
    appBar: Color(0xFFFDF4E3), // Light background
    background: Color(0xFFFDF4E3), // Light background (gruvbox light)
    surface: Color(0xFFFFFFFF), // White surface
    text: Color(0xFF3C3836), // Dark brown text
    secondaryText: Color(0xFF7C6F64), // Gray-brown
  );

// Update allThemes list - BOTH themes included
  static const List<AppThemeColors> allThemes = [
    blue,
    red,
    yellow,
    green,
    purple,
    dracula,
    gruvbox, // Original brown/orange Gruvbox
    gruvboxGreen, // New green Gruvbox
  ];

// Update getTheme method
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
      case 'Dracula':
        return dracula;
      case 'Gruvbox':
        return gruvbox; // Original brown
      case 'Gruvbox Green':
        return gruvboxGreen; // New green
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

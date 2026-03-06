import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _selectedTheme;
  String? _tempSelectedTheme;

  @override
  void initState() {
    super.initState();
    // Load current theme on init
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _selectedTheme = themeProvider.currentTheme.name;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    
    return Container(
      color: theme.background,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          
          // Settings header
          Row(
            children: [
              Icon(Icons.settings, color: theme.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.text,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // Theme selection card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.color_lens,
                  color: theme.primary,
                ),
              ),
              title: const Text(
                'Theme Color',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _selectedTheme != null
                    ? 'Current: $_selectedTheme'
                    : 'Choose your accent color',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showThemePicker,
            ),
          ),
        ],
      ),
    );
  }

  void _showThemePicker() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _tempSelectedTheme = _selectedTheme;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Choose Theme Color',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        _buildDialogThemeOption(AppThemes.blue, setState),
                        _buildDialogThemeOption(AppThemes.red, setState),
                        _buildDialogThemeOption(AppThemes.yellow, setState),
                        _buildDialogThemeOption(AppThemes.green, setState),
                        _buildDialogThemeOption(AppThemes.purple, setState),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _tempSelectedTheme != null
                                ? () async {
                                    setState(() {
                                      _selectedTheme = _tempSelectedTheme;
                                    });
                                    // Save theme with persistence
                                    await themeProvider.setThemeByName(_tempSelectedTheme!);
                                    Navigator.pop(context);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _tempSelectedTheme != null
                                  ? _getThemeColor(_tempSelectedTheme)
                                  : Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Choose',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogThemeOption(AppThemeColors appTheme, Function setState) {
    final isSelected = _tempSelectedTheme == appTheme.name;
    final color = appTheme.primary;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _tempSelectedTheme = appTheme.name;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              appTheme.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getThemeColor(String? themeName) {
    switch (themeName) {
      case 'Red':
        return Colors.red;
      case 'Yellow':
        return Colors.amber;
      case 'Green':
        return Colors.green;
      case 'Purple':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }
}
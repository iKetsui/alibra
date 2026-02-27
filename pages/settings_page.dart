import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _selectedTheme;
  String? _tempSelectedTheme; // Temporary selection in dialog

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFFFF),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          
          // Settings header
          const Row(
            children: [
              Icon(Icons.settings, color: Color(0xFF3498DB), size: 28),
              SizedBox(width: 12),
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
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
                  color: const Color(0xFF3498DB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.color_lens,
                  color: Color(0xFF3498DB),
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
    _tempSelectedTheme = _selectedTheme; // Initialize with current selection
    
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
                    // Title
                    const Text(
                      'Choose Theme Color',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Color grid - smaller and centered
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        _buildDialogThemeOption(Colors.blue, 'Blue', setState),
                        _buildDialogThemeOption(Colors.red, 'Red', setState),
                        _buildDialogThemeOption(Colors.amber, 'Yellow', setState),
                        _buildDialogThemeOption(Colors.green, 'Green', setState),
                        _buildDialogThemeOption(Colors.purple, 'Purple', setState),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Action buttons
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
                                ? () {
                                    setState(() {
                                      _selectedTheme = _tempSelectedTheme;
                                    });
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

  Widget _buildDialogThemeOption(Color color, String name, Function setState) {
    final isSelected = _tempSelectedTheme == name;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _tempSelectedTheme = name;
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
            // Color circle - smaller
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 8),
            // Theme name
            Text(
              name,
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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../database/hive.dart'; // Add this import

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _selectedTheme;
  String? _tempSelectedTheme;
  String _dbPath = 'Loading...';
  bool _usingCustomPath = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Load current theme
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    setState(() {
      _selectedTheme = themeProvider.currentTheme.name;
    });
    
    // Load database info
    await _loadDbInfo();
  }

  Future<void> _loadDbInfo() async {
    final path = HiveService.currentPath;
    if (path != null) {
      setState(() {
        _dbPath = path;
      });
    }
    
    // Check if using custom path
    final customPath = await HiveService.getSetting('hive_custom_path');
    setState(() {
      _usingCustomPath = customPath != null;
    });
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
          
          const SizedBox(height: 20),
          
          // Database Information Card
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
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.storage,
                      color: theme.primary,
                    ),
                  ),
                  title: const Text(
                    'Database Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    _dbPath,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_usingCustomPath)
                  Padding(
                    padding: const EdgeInsets.only(left: 72, right: 16, bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Using custom path',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.primary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await HiveService.resetToDefaultPath();
                            await _loadDbInfo();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Reset to default database location'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: const Text('Reset to Default'),
                        ),
                      ],
                    ),
                  ),
                
                // Export/Import buttons
                Padding(
                  padding: const EdgeInsets.only(left: 72, right: 16, bottom: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _exportDatabase,
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Export'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.primary,
                            side: BorderSide(color: theme.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showImportDialog,
                          icon: const Icon(Icons.upload, size: 18),
                          label: const Text('Import'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.primary,
                            side: BorderSide(color: theme.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Debug section (optional - remove in production)
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.bug_report,
                      color: Colors.grey,
                    ),
                  ),
                  title: const Text(
                    'Debug',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _printDatabaseContents,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[700],
                          ),
                          child: const Text('Print DB to Console'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                                    await themeProvider.setThemeByName(_tempSelectedTheme!);
                                    if (mounted) Navigator.pop(context);
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

  // Database utility functions
  Future<void> _exportDatabase() async {
    // This would need a file picker to choose export location
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export feature coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showImportDialog() async {
    // This would need a file picker to choose import file
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Database'),
        content: const Text('This will replace your current database. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Import feature coming soon'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _printDatabaseContents() {
    HiveService.printAllData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Database contents printed to console'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
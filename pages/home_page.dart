import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_provider.dart';
import '../pages/ai_page.dart'; // Add this import

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    
    return Scaffold(
      body: Container(
        color: theme.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.menu_book,
                size: 80,
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome to E-Reader',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.text,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your personal digital library',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.secondaryText,
                ),
              ),
              const SizedBox(height: 40),
              
              // Regular Browse Library button
              ElevatedButton(
                onPressed: () {
                  // Navigate to library (this will be handled by main.dart)
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text(
                  'Browse Library',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // AI Chat Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AIChatPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.auto_awesome, color: Colors.white),
                label: const Text(
                  'Ask Librarian AI',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
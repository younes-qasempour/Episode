import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/main_navigation_screen.dart';

void main() {
  runApp(const EpisodeApp());
}

class EpisodeApp extends StatefulWidget {
  const EpisodeApp({super.key});

  @override
  State<EpisodeApp> createState() => _EpisodeAppState();
}

class _EpisodeAppState extends State<EpisodeApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _handleThemeModeChanged(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Episode',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: MainNavigationScreen(
        currentThemeMode: _themeMode,
        onThemeModeChanged: _handleThemeModeChanged,
      ),
    );
  }
}

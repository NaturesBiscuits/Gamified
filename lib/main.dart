import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/run_setup_screen.dart';
import 'screens/active_run_screen.dart';
import 'screens/run_summary_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'providers/run_provider.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    runApp(const RunningApp());
  } catch (e) {
    print('Error initializing app: $e');
    // You could show an error screen here instead of crashing
  }
}

class RunningApp extends StatelessWidget {
  const RunningApp({super.key});

  ThemeData _buildTheme(Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        primary: Colors.blue,
        secondary: Colors.orange,
        tertiary: Colors.green,
        brightness: brightness,
        surface:
            brightness == Brightness.light ? Colors.white : Colors.grey[900],
      ),
      fontFamily: 'Montserrat',
      useMaterial3: true,
      // Add consistent text styles
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16),
      ),
      // Add card theme
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RunProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'Chase Runner',
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false, // Remove debug banner
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/setup': (context) => const RunSetupScreen(),
          '/active_run': (context) => const ActiveRunScreen(),
          '/summary': (context) => const RunSummaryScreen(),
          '/history': (context) => const HistoryScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}

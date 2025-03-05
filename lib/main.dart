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

void main() {
  runApp(const RunningApp());
}

class RunningApp extends StatelessWidget {
  const RunningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RunProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'Chase Runner',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            primary: Colors.blue,
            secondary: Colors.orange,
            tertiary: Colors.green,
            surface: Colors.white,
          ),
          fontFamily: 'Montserrat',
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            primary: Colors.blue,
            secondary: Colors.orange,
            tertiary: Colors.green,
            brightness: Brightness.dark,
          ),
          fontFamily: 'Montserrat',
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
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

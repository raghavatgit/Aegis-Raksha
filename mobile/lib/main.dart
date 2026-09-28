import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/local/hive_storage_service.dart';
import 'services/firebase_sync_service.dart';
import 'services/notification_service.dart';
import 'views/dashboard/home_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Offline Local Hive Database
  await HiveStorageService.initBoxes();

  // Initialize System Notifications & Audio
  await NotificationService.init();

  // Initialize Firebase (if online)
  await FirebaseSyncService.initFirebase();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: const HomeDashboardScreen(title: AppConstants.appTitle),
    );
  }
}
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:habiter_/providers/habit_provider.dart';
import 'package:habiter_/providers/notification_service.dart';
import 'package:habiter_/providers/preferences_service.dart';
import 'package:habiter_/screens/starting/splash.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  final preferencesProvider = PreferencesProvider();
  await preferencesProvider.init();
  final NotificationService notificationService = NotificationService();
  // Initialize notifications
  await notificationService.initNotification();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        ChangeNotifierProvider.value(value: preferencesProvider),
      ],
      child: const MyApp(), 
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitProvider>(context,listen: false);
    habitProvider.initializeCache();
    return MaterialApp(
      title: 'Habiter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(),
      home: const SplashScreen(),
    );
  }
} 
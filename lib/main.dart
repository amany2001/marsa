// main.dart
import 'package:firebase_core/firebase_core.dart' ;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marsa/fierbase/fire_base_services.dart';
import 'package:marsa/screens/on_boarding_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  MarsaFirebaseService.configureOffline();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const GetMaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale('ar'),
      home: OnboardingScreen(),
    );
  }
}

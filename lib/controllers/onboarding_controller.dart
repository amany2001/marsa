// lib/controllers/onboarding_controller.dart  (new file)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/auth_screen.dart';

class OnboardingController extends GetxController {
  final isArabic = true.obs;

  @override
  void onInit() {
    super.onInit();
    isArabic.value = (Get.locale?.languageCode ?? 'ar') != 'en';
  }

  void toggleLanguage() {
    final toEnglish = isArabic.value;
    Get.updateLocale(Locale(toEnglish ? 'en' : 'ar'));
    isArabic.value = !toEnglish;
  }

  void start() => Get.to(() => const AuthScreen());
}
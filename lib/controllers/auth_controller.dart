// lib/controllers/auth_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../fierbase/fire_base_services.dart';
import '../screens/patient_dashboard_screen.dart';
import '../bindings/app_bindings.dart';
import '../fierbase/fire_base_ext.dart';
import '../screens/consultant_dashboard_screen.dart';

class AuthController extends GetxController {
  final role = 0.obs;
  final tab = 0.obs;
  final contact = TextEditingController();
  final otp = TextEditingController();

  bool get isPhone => tab.value == 0;

  void login() => Get.offAll(() => const PatientDashboard());

  @override
  void onClose() {
    contact.dispose();
    otp.dispose();
    super.onClose();
  }


  Future<void> _goHome() async {
    if (await MarsaFirebaseService.instance.isConsultant()) {
      Get.offAll(
            () => const ConsultantDashboardScreen(),
        binding: ConsultantDashboardBinding(),
      );
    } else {
      Get.offAll(() => const PatientDashboard());
    }
  }
}

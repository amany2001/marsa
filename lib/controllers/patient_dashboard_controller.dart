// lib/controllers/patient_dashboard_controller.dart
import 'package:get/get.dart';
import '../screens/booking_consultation_screens/consultants_directory_screen.dart';
import '../screens/settings_screen.dart';

import '../bindings/app_bindings.dart';
import '../screens/sos_crisis_screen.dart';
import '../screens/resources_library_screen.dart';

class PatientDashboardController extends GetxController {
  final index = 0.obs;
  final isOffline = true.obs;

  void onNav(int i) {
    if (i == 3) {
      Get.to(() => const SettingsScreen());
      return;
    }
    index.value = i;
  }

  void openDirectory() => Get.to(() => const ConsultantsDirectoryScreen());
}

void sos() => Get.to(() => const SosCrisisScreen(), binding: SosCrisisBinding());

void openResources() =>
    Get.to(() => const ResourcesLibraryScreen(), binding: ResourcesLibraryBinding());
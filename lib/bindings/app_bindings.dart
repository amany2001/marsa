// lib/bindings/app_bindings.dart  (new file)
import 'package:get/get.dart';
import '../controllers/consultant_client_notes_controller.dart';
import '../controllers/consultant_dashboard_controller.dart';
import '../controllers/resources_library_controller.dart';
import '../controllers/sos_crisis_controller.dart';

class SosCrisisBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut<SosCrisisController>(() => SosCrisisController());
}

class ConsultantDashboardBinding extends Bindings {
  @override
  void dependencies() =>
      Get.lazyPut<ConsultantDashboardController>(() => ConsultantDashboardController());
}

class ConsultantClientNotesBinding extends Bindings {
  final String patientId;
  final String? sessionId;
  ConsultantClientNotesBinding(this.patientId, this.sessionId);

  @override
  void dependencies() => Get.lazyPut<ConsultantClientNotesController>(
          () => ConsultantClientNotesController(patientId, sessionId));
}

class ResourcesLibraryBinding extends Bindings {
  @override
  void dependencies() =>
      Get.lazyPut<ResourcesLibraryController>(() => ResourcesLibraryController());
}
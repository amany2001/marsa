// lib/controllers/feedback_controller.dart  (new file)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../fierbase/fire_base_ext.dart';
import '../fierbase/fire_base_services.dart';
import '../screens/patient_dashboard_screen.dart';

class FeedbackController extends GetxController {
  FeedbackController(this.sessionId);

  static const tags = [
    'شعرت بالأمان',
    'مستشار متفهم',
    'ساعدتني الجلسة',
    'جودة الاتصال جيدة',
    'أحتاج متابعة',
  ];
  static const labels = ['', 'سيئة', 'مقبولة', 'جيدة', 'ممتازة', 'رائعة'];

  final String sessionId;
  final _service = MarsaFirebaseService.instance;
  final note = TextEditingController();
  final rating = 0.obs;
  final selected = <String>{}.obs;
  final loading = false.obs;

  void setRating(int v) => rating.value = v;

  void toggleTag(String t, bool on) {
    if (on) {
      selected.add(t);
    } else {
      selected.remove(t);
    }
  }

  void toDashboard() => Get.offAll(() => const PatientDashboard());

  Future<void> submit() async {
    if (rating.value == 0 || loading.value) return;
    loading.value = true;
    try {
      try {
        await _service.submitFeedback(
          sessionId: sessionId,
          rating: rating.value,
          comment: note.text,
        );
      } on FirebaseServiceException catch (e) {
        if (e.code != 'already-submitted') rethrow;
      }
      if (selected.isNotEmpty) {
        try {
          await _service.attachFeedbackTags(sessionId, selected.toList());
        } on FirebaseServiceException {}
      }
      Get.rawSnackbar(message: 'شكراً لك، تم إرسال تقييمك');
      toDashboard();
    } on FirebaseServiceException {
      loading.value = false;
      Get.rawSnackbar(message: 'تعذر إرسال التقييم، تحقق من الاتصال');
    }
  }

  @override
  void onClose() {
    note.dispose();
    super.onClose();
  }
}
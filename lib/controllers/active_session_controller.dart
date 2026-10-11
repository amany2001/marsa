// lib/controllers/active_session_controller.dart  (new file)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../component/colors.dart';
import '../fierbase/fire_base_ext.dart';
import '../fierbase/fire_base_services.dart';
import '../screens/booking_consultation_screens/feedback_screen.dart';

class ActiveSessionController extends GetxController {
  ActiveSessionController(this.sessionId);

  final String sessionId;
  final _service = MarsaFirebaseService.instance;
  final input = TextEditingController();

  final session = Rxn<Session>();
  final messages = <ChatMessage>[].obs;
  final e2e = false.obs;
  final consultantName = ''.obs;
  final loading = true.obs;
  final hasError = false.obs;
  final sending = false.obs;
  final closing = false.obs;

  final _subs = <StreamSubscription<dynamic>>[];
  bool _navigated = false;
  bool _consultantRequested = false;

  String? get myId => _service.currentUser?.uid;

  bool get canSend {
    final s = session.value;
    return s != null && s.status != SessionStatus.ended && !closing.value;
  }

  @override
  void onInit() {
    super.onInit();
    _subs.add(_service.streamSession(sessionId).listen(
          (s) {
        session.value = s;
        loading.value = false;
        if (s == null) return;
        _loadConsultant(s.consultantId);
        if (s.status == SessionStatus.ended) _goToFeedback();
      },
      onError: (_) {
        hasError.value = true;
        loading.value = false;
      },
    ));
    _subs.add(_service
        .streamMessages(sessionId)
        .listen(messages.assignAll, onError: (_) {}));
    _subs.add(_service
        .streamSessionEncryption(sessionId)
        .listen((v) => e2e.value = v, onError: (_) {}));
  }

  Future<void> _loadConsultant(String consultantId) async {
    if (_consultantRequested) return;
    _consultantRequested = true;
    try {
      final c = await _service.fetchConsultant(consultantId);
      if (c != null) consultantName.value = c.name;
    } on FirebaseServiceException {
      _consultantRequested = false;
    }
  }

  void _goToFeedback() {
    if (_navigated) return;
    _navigated = true;
    Get.off(() => FeedbackScreen(
      sessionId: sessionId,
      consultantName: consultantName.value,
    ));
  }

  Future<void> send() async {
    final text = input.text.trim();
    if (text.isEmpty || sending.value || !canSend) return;
    sending.value = true;
    input.clear();
    try {
      await _service.sendMessage(sessionId, text);
    } on FirebaseServiceException {
      input.text = text;
      Get.rawSnackbar(message: 'تعذر إرسال الرسالة');
    } finally {
      sending.value = false;
    }
  }

  Future<void> endSession() async {
    final confirm = await Get.dialog<bool>(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إنهاء الجلسة'),
          content: const Text('هل تريد إنهاء الجلسة الآن؟'),
          actions: [
            TextButton(
                onPressed: () => Get.back(result: false), child: const Text('إلغاء')),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('إنهاء', style: TextStyle(color: AppColors.coral)),
            ),
          ],
        ),
      ),
    );
    if (confirm != true) return;
    closing.value = true;
    try {
      await _service.endSession(sessionId);
      _goToFeedback();
    } on FirebaseServiceException {
      closing.value = false;
      Get.rawSnackbar(message: 'تعذر إنهاء الجلسة، حاول مجدداً');
    }
  }

  String statusLabel(SessionStatus s) => switch (s) {
    SessionStatus.waiting => 'بانتظار المستشار',
    SessionStatus.active => 'الجلسة جارية',
    SessionStatus.ended => 'انتهت الجلسة',
  };

  String timeLabel(DateTime? t) => t == null
      ? ''
      : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void onClose() {
    for (final s in _subs) {
      s.cancel();
    }
    input.dispose();
    super.onClose();
  }
}
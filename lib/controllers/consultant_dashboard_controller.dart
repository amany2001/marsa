// lib/controllers/consultant_dashboard_controller.dart  (new file)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../bindings/app_bindings.dart';
import '../fierbase/fire_base_ext.dart';
import '../fierbase/fire_base_services.dart';
import '../screens/consultant_client_notes_screen.dart';
import '../screens/on_boarding_screen.dart';

class ConsultantDashboardController extends GetxController {
  final _service = MarsaFirebaseService.instance;

  final name = ''.obs;
  final sosOnline = false.obs;
  final pending = <ConsultantRequest>[].obs;
  final upcoming = <ConsultantRequest>[].obs;
  final today = <ConsultantRequest>[].obs;
  final loading = true.obs;
  final hasError = false.obs;
  final showUpcoming = false.obs;
  final togglingSos = false.obs;
  final busyId = RxnString();
  final _subs = <StreamSubscription<dynamic>>[];

  int get todayTotal =>
      today.where((b) => b.status != BookingStatus.cancelled).length;
  int get todayCompleted =>
      today.where((b) => b.status == BookingStatus.completed).length;

  @override
  void onInit() {
    super.onInit();
    _listen();
  }

  void _fail(Object _) {
    hasError.value = true;
    loading.value = false;
  }

  void _listen() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    hasError.value = false;
    loading.value = true;
    if (_service.currentUser == null) {
      _fail('unauthenticated');
      return;
    }
    _subs.addAll([
      _service.streamConsultantProfile().listen((p) {
        name.value = (p?['name'] as String?) ?? '';
        sosOnline.value = p?['sosOnline'] == true;
      }, onError: _fail),
      _service.streamConsultantBookings(BookingStatus.pending).listen((l) {
        pending.assignAll(l);
        loading.value = false;
      }, onError: _fail),
      _service
          .streamConsultantBookings(BookingStatus.confirmed)
          .listen(upcoming.assignAll, onError: _fail),
      _service.streamTodayBookings().listen(today.assignAll, onError: _fail),
    ]);
  }

  void retry() => _listen();

  Future<void> toggleSos(bool v) async {
    if (togglingSos.value) return;
    togglingSos.value = true;
    sosOnline.value = v;
    try {
      await _service.setSosOnline(v);
    } on TimeoutException {
      Get.rawSnackbar(message: 'ستُحدَّث الحالة فور عودة الاتصال');
    } on FirebaseServiceException {
      sosOnline.value = !v;
      Get.rawSnackbar(message: 'تعذر تحديث حالة الطوارئ');
    } finally {
      togglingSos.value = false;
    }
  }

  Future<void> accept(ConsultantRequest r) async {
    if (busyId.value != null) return;
    busyId.value = r.id;
    try {
      await _service.acceptBooking(r.id);
      Get.rawSnackbar(message: 'تم قبول الحجز');
    } on FirebaseServiceException catch (e) {
      Get.rawSnackbar(
        message: e.code == 'invalid-state' ? 'تمت معالجة هذا الطلب مسبقاً' : 'تعذر قبول الحجز',
      );
    } finally {
      busyId.value = null;
    }
  }

  Future<void> reschedule(ConsultantRequest r) async {
    final ctx = Get.context;
    if (ctx == null || busyId.value != null) return;
    final now = DateTime.now();
    final last = now.add(const Duration(days: 30));
    final initial =
    (r.scheduledAt.isAfter(now) && r.scheduledAt.isBefore(last)) ? r.scheduledAt : now;
    final date = await showDatePicker(
      context: ctx,
      initialDate: initial,
      firstDate: now,
      lastDate: last,
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: Get.context ?? ctx,
      initialTime: TimeOfDay.fromDateTime(r.scheduledAt),
    );
    if (time == null) return;
    final target = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    busyId.value = r.id;
    try {
      await _service.rescheduleBooking(r.id, target);
      Get.rawSnackbar(message: 'تمت إعادة الجدولة');
    } on FirebaseServiceException catch (e) {
      Get.rawSnackbar(
        message: switch (e.code) {
          'slot-taken' => 'هذا الموعد محجوز، اختر وقتاً آخر',
          'invalid-time' => 'اختر وقتاً في المستقبل',
          _ => 'تعذر إعادة الجدولة',
        },
      );
    } finally {
      busyId.value = null;
    }
  }

  void openNotes(ConsultantRequest r) => Get.to(
        () => const ConsultantClientNotesScreen(),
    binding: ConsultantClientNotesBinding(r.patientId, r.id),
  );

  Future<void> logout() async {
    try {
      await _service.signOut();
      Get.offAll(() => const OnboardingScreen());
    } on FirebaseServiceException {
      Get.rawSnackbar(message: 'تعذر تسجيل الخروج');
    }
  }

  String typeLabel(SessionType t) => switch (t) {
    SessionType.video => 'فيديو',
    SessionType.audio => 'صوت',
    SessionType.chat => 'محادثة',
  };

  String timeLabel(DateTime d) {
    final t = d.toLocal();
    return '${t.day}/${t.month} — ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  void onClose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.onClose();
  }
}
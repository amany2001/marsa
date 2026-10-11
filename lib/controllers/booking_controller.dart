// lib/controllers/booking_controller.dart  (new file)
import 'package:get/get.dart';
import '../fierbase/fire_base_ext.dart';
import '../fierbase/fire_base_services.dart';
import '../screens/patient_dashboard_screen.dart';

class BookingController extends GetxController {
  BookingController({
    required this.consultant,
    required SessionType initialType,
  }) : type = initialType.obs;

  static const dayNames = {1: 'الاثنين', 2: 'الثلاثاء', 6: 'السبت', 7: 'الأحد'};
  static const hours = [16, 17, 18, 19, 20, 21];

  final Consultant consultant;
  final _service = MarsaFirebaseService.instance;

  late final List<DateTime> days = _buildDays();
  late final Rx<DateTime> date = days.first.obs;
  final Rx<SessionType> type;
  final taken = Rx<Set<int>>({});
  final hour = RxnInt();
  final loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadTaken();
  }

  List<DateTime> _buildDays() {
    final now = DateTime.now();
    var d = DateTime(now.year, now.month, now.day);
    final result = <DateTime>[];
    while (result.length < 4) {
      if (dayNames.containsKey(d.weekday)) result.add(d);
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return result;
  }

  Future<void> loadTaken() async {
    final requested = date.value;
    try {
      final result = await _service.fetchTakenSlotHours(consultant.id, requested);
      if (requested == date.value) taken.value = result;
    } on FirebaseServiceException {
      if (requested == date.value) taken.value = <int>{};
    }
  }

  bool isDisabled(int h) {
    if (taken.value.contains(h)) return true;
    final now = DateTime.now();
    final d = date.value;
    final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
    return isToday && h <= now.hour;
  }

  void selectDate(DateTime d) {
    date.value = d;
    hour.value = null;
    taken.value = <int>{};
    loadTaken();
  }

  void selectHour(int h) => hour.value = h;
  void selectType(SessionType t) => type.value = t;

  String _errorText(FirebaseServiceException e) => switch (e.code) {
    'slot-taken' => 'هذا الموعد محجوز، اختر موعداً آخر',
    'unauthenticated' => 'يرجى تسجيل الدخول أولاً',
    'invalid-time' => 'الموعد المختار انتهى، اختر موعداً آخر',
    _ => 'تعذر إتمام الحجز، تحقق من الاتصال وحاول مجدداً',
  };

  Future<void> confirm() async {
    final h = hour.value;
    if (h == null || loading.value) return;
    loading.value = true;
    final d = date.value;
    try {
      await _service.bookSession(
        consultantId: consultant.id,
        scheduledAt: DateTime(d.year, d.month, d.day, h),
        type: type.value,
      );
      Get.rawSnackbar(message: 'تم تأكيد الحجز بنجاح');
      Get.offAll(() => const PatientDashboard());
    } on FirebaseServiceException catch (e) {
      loading.value = false;
      if (e.code == 'slot-taken') {
        hour.value = null;
        loadTaken();
      }
      Get.rawSnackbar(message: _errorText(e));
    }
  }
}
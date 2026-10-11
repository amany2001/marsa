// lib/controllers/sos_crisis_controller.dart  (new file)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../component/hotlines_sheet.dart';
import '../fierbase/fire_base_ext.dart';
import '../fierbase/fire_base_services.dart';

class SelfHelpTool {
  final String title;
  final IconData icon;
  final List<String> steps;
  const SelfHelpTool(this.title, this.icon, this.steps);
}

class SosCrisisController extends GetxController with GetSingleTickerProviderStateMixin {
  static const groundingTitle = 'تأريض 1-4-2-3-1';
  static const tools = [
    SelfHelpTool(groundingTitle, Icons.spa_rounded, [
      'سمِّ 5 أشياء تراها حولك',
      'لاحظ 4 أشياء يمكنك لمسها',
      'أنصت إلى 3 أصوات',
      'التقط رائحتين',
      'تذوّق شيئاً واحداً أو خذ نفساً عميقاً',
    ]),
    SelfHelpTool('ماء بارد', Icons.water_drop_rounded, [
      'اشرب ماءً بارداً ببطء على رشفات صغيرة',
      'اغسل يديك ومعصميك بماء بارد',
      'ركّز على إحساس الماء حتى يهدأ جسمك',
    ]),
  ];

  static const _inhale = 4, _hold = 7, _exhale = 8, _total = 19;

  final _service = MarsaFirebaseService.instance;
  late final AnimationController anim;
  final phase = 'شهيق'.obs;
  final secondsLeft = 4.obs;
  final running = true.obs;
  final isOnline = true.obs;
  final requesting = false.obs;
  StreamSubscription<bool>? _netSub;

  @override
  void onInit() {
    super.onInit();
    anim = AnimationController(vsync: this, duration: const Duration(seconds: _total))
      ..addListener(_tick)
      ..repeat();
    _netSub = _service.streamIsOnline().listen(
          (v) => isOnline.value = v,
      onError: (_) => isOnline.value = false,
    );
  }

  void _tick() {
    final t = anim.value * _total;
    final String p;
    final double end;
    if (t < _inhale) {
      p = 'شهيق';
      end = _inhale.toDouble();
    } else if (t < _inhale + _hold) {
      p = 'احبس نفسك';
      end = (_inhale + _hold).toDouble();
    } else {
      p = 'زفير';
      end = _total.toDouble();
    }
    if (phase.value != p) phase.value = p;
    final s = (end - t).ceil().clamp(1, 8).toInt();
    if (secondsLeft.value != s) secondsLeft.value = s;
  }

  double scaleOf(double v) {
    final t = v * _total;
    if (t < _inhale) return Curves.easeInOut.transform(t / _inhale);
    if (t < _inhale + _hold) return 1;
    return 1 - Curves.easeInOut.transform((t - _inhale - _hold) / _exhale);
  }

  void toggleBreathing() {
    if (running.value) {
      anim.stop();
    } else {
      anim.repeat();
    }
    running.value = !running.value;
  }

  Future<void> requestHelp() async {
    if (requesting.value) return;
    requesting.value = true;
    try {
      await _service.createSosRequest();
      Get.rawSnackbar(message: 'تم تسجيل طلب المساعدة');
    } on TimeoutException {
      Get.rawSnackbar(message: 'سيُرسل الطلب فور عودة الاتصال');
    } on FirebaseServiceException {
      Get.rawSnackbar(message: 'تعذر إرسال الطلب');
    } finally {
      requesting.value = false;
    }
    showHotlinesSheet();
  }

  void openHotlines() => showHotlinesSheet();

  @override
  void onClose() {
    _netSub?.cancel();
    anim.dispose();
    super.onClose();
  }
}
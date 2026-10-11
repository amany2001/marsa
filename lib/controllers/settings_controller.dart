// lib/controllers/settings_controller.dart  (new file)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../component/colors.dart';
import '../fierbase/fire_base_services.dart';

import '../screens/on_boarding_screen.dart';
import '../bindings/app_bindings.dart';
import '../screens/resources_library_screen.dart';


class SettingsController extends GetxController {
  final _service = MarsaFirebaseService.instance;

  final name = 'مستخدم مرسى'.obs;
  final role = 'مستفيد'.obs;
  final night = false.obs;
  final notifications = true.obs;
  final offline = false.obs;
  final nameInput = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    night.value = Get.isDarkMode;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (_service.currentUser == null) return;
    try {
      final p = await _service.fetchUserProfile();
      if (p == null) return;
      final n = (p['name'] as String?)?.trim();
      if (n != null && n.isNotEmpty) name.value = n;
      role.value = p['role'] == 'consultant' ? 'مستشار متطوع' : 'مستفيد';
      notifications.value = p['notificationsEnabled'] as bool? ?? true;
    } on FirebaseServiceException {
      return;
    }
  }

  void toggleNight(bool v) {
    night.value = v;
    Get.changeThemeMode(v ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> toggleNotifications(bool v) async {
    notifications.value = v;
    try {
      await _service.updateUserProfile({'notificationsEnabled': v});
    } on FirebaseServiceException {
      notifications.value = !v;
      Get.rawSnackbar(message: 'تعذر حفظ الإعداد');
    }
  }

  Future<void> toggleOffline(bool v) async {
    offline.value = v;
    try {
      if (v) {
        await FirebaseFirestore.instance.disableNetwork();
      } else {
        await FirebaseFirestore.instance.enableNetwork();
      }
    } on FirebaseException {
      offline.value = !v;
      Get.rawSnackbar(message: 'تعذر تغيير وضع الاتصال');
    }
  }

  Future<void> editName() async {
    nameInput.text = name.value;
    final result = await Get.dialog<String>(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تعديل الاسم'),
          content: TextField(
            controller: nameInput,
            autofocus: true,
            maxLength: 40,
            decoration: const InputDecoration(hintText: 'اسمك'),
          ),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('إلغاء')),
            TextButton(
              onPressed: () => Get.back(result: nameInput.text),
              child: const Text('حفظ', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
    final v = result?.trim();
    if (v == null || v.isEmpty || v == name.value) return;
    final old = name.value;
    name.value = v;
    try {
      await _service.updateUserProfile({'name': v});
    } on FirebaseServiceException {
      name.value = old;
      Get.rawSnackbar(message: 'تعذر حفظ الاسم');
    }
  }

  void showPrivacy() => Get.dialog(
    Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('الخصوصية والأمان'),
        content: const Text(
            'يمكنك مراجعة سياسة الخصوصية وشروط الاستخدام الخاصة بالتطبيق هنا.'),
        actions: [TextButton(onPressed: Get.back, child: const Text('حسناً'))],
      ),
    ),
  );

  void onNav(int i) {
    switch (i) {
      case 0:
        Get.back();
      case 1:
        // Get.off(() => const MyBookingsScreen());
      case 2:
        Get.off(() => const ResourcesLibraryScreen(), binding: ResourcesLibraryBinding());
    }
  }

  Future<void> logout() async {
    try {
      await _service.signOut();
      Get.offAll(() => const OnboardingScreen());
    } on FirebaseServiceException {
      Get.rawSnackbar(message: 'تعذر تسجيل الخروج');
    }
  }

  @override
  void onClose() {
    nameInput.dispose();
    super.onClose();
  }
}
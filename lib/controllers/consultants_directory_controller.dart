// lib/controllers/consultants_directory_controller.dart  (new file)
import 'dart:async';
import 'package:get/get.dart';
import '../fierbase/fire_base_ext.dart';
import '../fierbase/fire_base_services.dart';
import '../screens/booking_consultation_screens/booking_screen.dart';
import 'package:flutter/material.dart';

class ConsultantsDirectoryController extends GetxController {
  static const filters = ['الكل', 'صدمات', 'أطفال', 'متاح الآن'];

  final _service = MarsaFirebaseService.instance;
  final searchCtrl = TextEditingController();
  final filter = 0.obs;
  final query = ''.obs;
  final consultants = <Consultant>[].obs;
  final loading = true.obs;
  final hasError = false.obs;
  StreamSubscription<List<Consultant>>? _sub;

  List<Consultant> get filtered => consultants.where(_matches).toList();

  @override
  void onInit() {
    super.onInit();
    _listen();
  }

  void _listen() {
    _sub?.cancel();
    loading.value = true;
    hasError.value = false;
    _sub = _service
        .streamConsultants(onlyAvailable: filter.value == 3, limit: 100)
        .listen(
          (list) {
        consultants.assignAll(list);
        loading.value = false;
      },
      onError: (_) {
        hasError.value = true;
        loading.value = false;
      },
    );
  }

  bool _matches(Consultant c) {
    final s = c.specialty.toLowerCase();
    final byFilter = switch (filter.value) {
      1 => s.contains('صدم') || s.contains('trauma'),
      2 => s.contains('طفل') || s.contains('أطفال') || s.contains('children'),
      _ => true,
    };
    final q = query.value.trim().toLowerCase();
    return byFilter && (q.isEmpty || c.name.toLowerCase().contains(q) || s.contains(q));
  }

  void setFilter(int i) {
    if (filter.value == i) return;
    filter.value = i;
    _listen();
  }

  void onSearch(String v) => query.value = v;

  void clearSearch() {
    searchCtrl.clear();
    query.value = '';
  }

  void retry() => _listen();

  void openBooking(Consultant c, SessionType type) =>
      Get.to(() => BookingScreen(consultant: c, initialType: type));

  @override
  void onClose() {
    _sub?.cancel();
    searchCtrl.dispose();
    super.onClose();
  }
}
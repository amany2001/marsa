// lib/controllers/resources_library_controller.dart  (new file)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../component/app_components.dart';
import '../component/colors.dart';
import '../fierbase/fire_base_ext.dart';
import '../fierbase/fire_base_services.dart';

class ResourcesLibraryController extends GetxController {
  static const categories = <(String, String?)>[
    ('الكل', null),
    ('مقالات', 'article'),
    ('صوتيات', 'audio'),
    ('أطفال', 'kids'),
  ];

  final items = <LibraryResource>[].obs;
  final category = 0.obs;
  final query = ''.obs;
  final loading = true.obs;
  final hasError = false.obs;
  final fromCache = false.obs;
  final searchCtrl = TextEditingController();
  StreamSubscription<({List<LibraryResource> items, bool fromCache})>? _sub;

  List<LibraryResource> get featured => items.where((r) => r.featured).toList();

  bool get showFeatured =>
      category.value == 0 && query.value.trim().isEmpty && featured.isNotEmpty;

  List<LibraryResource> get filtered {
    final cat = categories[category.value].$2;
    final q = query.value.trim().toLowerCase();
    return items
        .where((r) =>
    (cat == null || r.category == cat) &&
        (q.isEmpty ||
            r.title.toLowerCase().contains(q) ||
            r.body.toLowerCase().contains(q)))
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    _listen();
  }

  void _listen() {
    _sub?.cancel();
    loading.value = true;
    hasError.value = false;
    _sub = MarsaFirebaseService.instance.streamLibrary().listen(
          (s) {
        items.assignAll(s.items);
        fromCache.value = s.fromCache;
        loading.value = false;
      },
      onError: (_) {
        hasError.value = true;
        loading.value = false;
      },
    );
  }

  void retry() => _listen();
  void setCategory(int i) => category.value = i;
  void onSearch(String v) => query.value = v;

  void clearSearch() {
    searchCtrl.clear();
    query.value = '';
  }

  IconData iconOf(String cat) => switch (cat) {
    'audio' => Icons.headphones_rounded,
    'kids' => Icons.child_care_rounded,
    _ => Icons.article_rounded,
  };

  Future<void> listen(LibraryResource r) async {
    final uri = Uri.tryParse(r.audioUrl ?? '');
    if (uri == null) {
      Get.rawSnackbar(message: 'رابط الصوت غير صالح');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) Get.rawSnackbar(message: 'تعذر فتح الملف الصوتي');
  }

  void open(LibraryResource r) => Get.bottomSheet(
    Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.8),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.sand,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Text(r.body,
                    style: const TextStyle(height: 1.7, color: AppColors.textDark)),
              ),
            ),
            if (r.audioUrl != null) ...[
              const SizedBox(height: 14),
              AppButton(
                label: 'استماع',
                icon: Icons.play_arrow_rounded,
                onPressed: () => listen(r),
              ),
            ],
          ],
        ),
      ),
    ),
    isScrollControlled: true,
  );

  @override
  void onClose() {
    _sub?.cancel();
    searchCtrl.dispose();
    super.onClose();
  }
}
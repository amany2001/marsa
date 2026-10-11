// lib/screens/resources_library_screen.dart  (new file)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../component/app_components.dart';
import '../component/colors.dart';
import '../controllers/resources_library_controller.dart';
import '../fierbase/fire_base_ext.dart';

class ResourcesLibraryScreen extends StatelessWidget {
  const ResourcesLibraryScreen({super.key});

  Widget _featured(ResourcesLibraryController c, LibraryResource r) => SizedBox(
    width: 260,
    child: AppCard(
      color: AppColors.primary,
      borderColor: AppColors.primary,
      onTap: () => c.open(r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(c.iconOf(r.category), color: AppColors.sand, size: 20),
              const SizedBox(width: 6),
              const Text('دليل مميّز',
                  style: TextStyle(color: AppColors.sandDark, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(r.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
          ),
          const Text('اقرأ الآن',
              style: TextStyle(color: AppColors.sand, fontWeight: FontWeight.w700)),
        ],
      ),
    ),
  );

  Widget _tile(ResourcesLibraryController c, LibraryResource r) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: AppCard(
      onTap: () => c.open(r),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.sand,
            child: Icon(c.iconOf(r.category), color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(r.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_left_rounded, color: AppColors.textMuted),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ResourcesLibraryController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.sand,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.primary,
          title: const Text('مكتبة المصادر', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Obx(
                    () => TextField(
                  controller: c.searchCtrl,
                  onChanged: c.onSearch,
                  decoration: InputDecoration(
                    hintText: 'ابحث في المقالات والصوتيات',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                    suffixIcon: c.query.value.isEmpty
                        ? null
                        : IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      onPressed: c.clearSearch,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 42,
              child: Obx(
                    () => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: ResourcesLibraryController.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final active = i == c.category.value;
                    return ChoiceChip(
                      label: Text(ResourcesLibraryController.categories[i].$1),
                      selected: active,
                      showCheckmark: false,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      side: BorderSide(color: active ? AppColors.primary : AppColors.border),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : AppColors.primary,
                      ),
                      onSelected: (_) => c.setCategory(i),
                    );
                  },
                ),
              ),
            ),
            Obx(
                  () => (c.loading.value || c.hasError.value || c.items.isEmpty)
                  ? const SizedBox(height: 8)
                  : Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                child: Row(
                  children: [
                    Icon(
                      c.fromCache.value
                          ? Icons.cloud_off_rounded
                          : Icons.cloud_done_rounded,
                      size: 16,
                      color: c.fromCache.value ? AppColors.coral : AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      c.fromCache.value
                          ? 'نسخة محفوظة — غير متصل'
                          : 'محدّث ومحفوظ للاستخدام دون اتصال',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (c.hasError.value) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('تعذر تحميل المصادر',
                            style: TextStyle(color: AppColors.textMuted)),
                        TextButton(
                          onPressed: c.retry,
                          child: const Text('إعادة المحاولة',
                              style: TextStyle(
                                  color: AppColors.coral, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                }
                if (c.loading.value) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary));
                }
                final list = c.filtered;
                final showFeatured = c.showFeatured;
                if (list.isEmpty && !showFeatured) {
                  return const Center(
                    child: Text('لا توجد نتائج مطابقة',
                        style: TextStyle(color: AppColors.textMuted)),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    if (showFeatured) ...[
                      const Text('أدلة مميّزة',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark)),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 150,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: c.featured.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, i) => _featured(c, c.featured[i]),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('كل المصادر',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark)),
                      const SizedBox(height: 10),
                    ],
                    for (final r in list) _tile(c, r),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
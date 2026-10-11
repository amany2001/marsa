// lib/screens/booking_consultation_screens/consultants_directory_screen.dart
// replace everything from line 1 down to (NOT including) "class _ConsultantCard extends StatelessWidget"
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../component/app_components.dart';
import '../../component/colors.dart';
import '../../controllers/consultants_directory_controller.dart';
import '../../fierbase/fire_base_ext.dart';
import '../../fierbase/fire_base_services.dart';

class ConsultantsDirectoryScreen extends StatelessWidget {
  const ConsultantsDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ConsultantsDirectoryController());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.sand,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.primary,
          title: const Text('المستشارون', style: TextStyle(fontWeight: FontWeight.w800)),
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
                    hintText: 'ابحث بالاسم أو التخصص',
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
                  itemCount: ConsultantsDirectoryController.filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final active = i == c.filter.value;
                    return ChoiceChip(
                      label: Text(ConsultantsDirectoryController.filters[i]),
                      selected: active,
                      showCheckmark: false,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      side: BorderSide(color: active ? AppColors.primary : AppColors.border),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : AppColors.primary,
                      ),
                      onSelected: (_) => c.setFilter(i),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Obx(() {
                if (c.hasError.value) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('تعذر تحميل القائمة، تحقق من الاتصال',
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
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                final list = c.filtered;
                if (list.isEmpty) {
                  return const Center(
                    child: Text('لا يوجد مستشارون مطابقون',
                        style: TextStyle(color: AppColors.textMuted)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, i) {
                    // _ConsultantCard(
                    //   consultant: list[i],
                    //   onChat: () => c.openBooking(list[i], SessionType.chat),
                    //   onBook: () => c.openBooking(list[i], SessionType.video),
                    // );
                  }

                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// keep the existing _ConsultantCard class below this line exactly as it is
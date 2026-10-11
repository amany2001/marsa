// lib/screens/booking_consultation_screens/feedback_screen.dart  (replace the whole file)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../component/app_components.dart';
import '../../component/colors.dart';
import '../../controllers/feedback_controller.dart';

class FeedbackScreen extends StatelessWidget {
  final String sessionId;
  final String consultantName;

  const FeedbackScreen({
    super.key,
    required this.sessionId,
    this.consultantName = '',
  });

  @override
  Widget build(BuildContext context) {
    final c = Get.put(FeedbackController(sessionId), tag: sessionId);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.sand,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Obx(
                      () => TextButton(
                    onPressed: c.loading.value ? null : c.toDashboard,
                    child: const Text(
                      'تخطي',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.favorite_rounded, size: 34, color: AppColors.sand),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'كيف كانت جلستك؟',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              if (consultantName.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'مع $consultantName',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
              const SizedBox(height: 22),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                child: Obx(
                      () => Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 1; i <= 5; i++)
                            IconButton(
                              onPressed: () => c.setRating(i),
                              padding: EdgeInsets.zero,
                              constraints:
                              const BoxConstraints(minWidth: 50, minHeight: 50),
                              icon: Icon(
                                Icons.star_rounded,
                                size: 42,
                                color: i <= c.rating.value
                                    ? AppColors.coral
                                    : AppColors.border,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        FeedbackController.labels[c.rating.value],
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'ما الذي ساعدك؟',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Obx(
                    () => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in FeedbackController.tags)
                      FilterChip(
                        label: Text(t),
                        selected: c.selected.contains(t),
                        showCheckmark: false,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        side: BorderSide(
                          color: c.selected.contains(t)
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: c.selected.contains(t)
                              ? Colors.white
                              : AppColors.primary,
                        ),
                        onSelected: (v) => c.toggleTag(t, v),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'ملاحظة مجهولة (اختياري)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: c.note,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'شاركنا ما تودّ قوله...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Obx(
                    () => AppButton(
                  label: c.loading.value ? 'جارٍ الإرسال...' : 'إرسال التقييم',
                  icon: Icons.send_rounded,
                  onPressed: (c.rating.value == 0 || c.loading.value) ? null : c.submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// lib/screens/on_boarding_screen.dart  (replace the whole file)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../component/app_components.dart';
import '../component/colors.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const _features = [
    (Icons.lock_rounded, 'خصوصية وأمان', 'محادثاتك مشفرة وسرية بالكامل'),
    (Icons.volunteer_activism_rounded, 'دعم مجاني', 'مختصون متطوعون بجانبك دائماً'),
    (Icons.wifi_off_rounded, 'يعمل دون اتصال', 'مصمم لظروف الاتصال الضعيف'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = Get.put(OnboardingController());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.sand,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Obx(
                        () => TextButton.icon(
                      onPressed: c.toggleLanguage,
                      icon: const Icon(Icons.language, color: AppColors.primary, size: 20),
                      label: Text(
                        c.isArabic.value ? 'English' : 'العربية',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                AppCard(
                  color: AppColors.primary,
                  padding: const EdgeInsets.all(32),
                  child: const Icon(Icons.anchor_rounded, size: 64, color: AppColors.sand),
                ),
                const SizedBox(height: 24),
                const Text(
                  'مرسى',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'مساحتك الآمنة للدعم النفسي الأولي',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppColors.textMuted),
                ),
                const Spacer(),
                for (final f in _features)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.sand,
                            child: Icon(f.$1, color: AppColors.primary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f.$2,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Text(
                                  f.$3,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'ابدأ الآن',
                  icon: Icons.arrow_back_rounded,
                  onPressed: c.start,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
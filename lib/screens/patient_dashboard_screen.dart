// lib/screens/patient_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../component/app_components.dart';
import '../component/colors.dart';
import '../controllers/patient_dashboard_controller.dart';

class PatientDashboard extends StatelessWidget {
  const PatientDashboard({super.key});

  Widget _tile(
      String title,
      IconData icon, {
        bool sos = false,
        VoidCallback? onTap,
      }) {
    return AppCard(
      onTap: onTap ?? () {},
      color: sos ? AppColors.coral : AppColors.surface,
      borderColor: sos ? AppColors.coral : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: sos ? Colors.white : AppColors.primary),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: sos ? Colors.white : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.put(PatientDashboardController());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.sand,
        bottomNavigationBar: Obx(
              () => AppBottomNav(currentIndex: c.index.value, onTap: c.onNav),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, color: AppColors.sand),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مرحباً، أحمد',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'كيف تشعر اليوم؟',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Obx(
                    () => c.isOffline.value
                    ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.sandDark,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        size: 18,
                        color: AppColors.coral,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'وضع عدم الاتصال مفعّل — المحتوى المحفوظ متاح',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              AppCard(
                color: AppColors.primary,
                borderColor: AppColors.primary,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'جلستك القادمة',
                      style: TextStyle(color: AppColors.sandDark, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'د. ليلى — دعم نفسي أولي',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 18,
                          color: AppColors.sand,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'غداً، 4:00 مساءً',
                          style: TextStyle(color: AppColors.sand),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AppButton(
                      label: 'انضم للجلسة',
                      type: AppButtonType.secondary,
                      icon: Icons.videocam_rounded,
                      onPressed: c.openDirectory,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.1,
                children: [
                  _tile('طوارئ SOS', Icons.sos_rounded, sos: true),
                  _tile(
                    'احجز جلسة',
                    Icons.event_available_rounded,
                    onTap: c.openDirectory,
                  ),
                  _tile('المصادر', Icons.menu_book_rounded),
                  _tile('تمارين التنفس', Icons.air_rounded),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
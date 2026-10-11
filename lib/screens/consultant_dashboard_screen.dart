// lib/screens/consultant_dashboard_screen.dart  (new file)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../component/app_components.dart';
import '../component/colors.dart';
import '../controllers/consultant_dashboard_controller.dart';
import '../fierbase/fire_base_ext.dart';

class ConsultantDashboardScreen extends StatelessWidget {
  const ConsultantDashboardScreen({super.key});

  Widget _stat(String label, String value, IconData icon) => Expanded(
    child: AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    ),
  );

  Widget _request(ConsultantDashboardController c, ConsultantRequest r, bool busy) {
    final isPending = !c.showUpcoming.value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.sand,
                  child: Icon(Icons.person_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('مستفيد ${r.anon}',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text('${c.timeLabel(r.scheduledAt)} • ${c.typeLabel(r.type)}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: isPending
                      ? AppButton(
                    label: 'قبول',
                    icon: Icons.check_rounded,
                    onPressed: busy ? null : () => c.accept(r),
                  )
                      : AppButton(
                    label: 'ملاحظات الجلسة',
                    icon: Icons.edit_note_rounded,
                    onPressed: () => c.openNotes(r),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: 'إعادة جدولة',
                    type: AppButtonType.secondary,
                    icon: Icons.event_repeat_rounded,
                    onPressed: busy ? null : () => c.reschedule(r),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ConsultantDashboardController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.sand,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.medical_services_rounded, color: AppColors.sand),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(
                          () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.name.value.isEmpty ? 'مرحباً' : 'مرحباً، د. ${c.name.value}',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary),
                          ),
                          const Text('شكراً لتطوعك اليوم',
                              style: TextStyle(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: c.logout,
                    icon: const Icon(Icons.logout_rounded, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Row(
                  children: [
                    const Icon(Icons.sos_rounded, color: AppColors.coral, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('استقبال طلبات الطوارئ',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                          Obx(
                                () => Text(
                              c.sosOnline.value ? 'أنت متاح الآن' : 'غير متاح',
                              style: TextStyle(
                                fontSize: 13,
                                color: c.sosOnline.value
                                    ? AppColors.success
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Obx(
                          () => Switch(
                        value: c.sosOnline.value,
                        activeColor: AppColors.coral,
                        onChanged: c.togglingSos.value ? null : c.toggleSos,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Obx(
                    () => Row(
                  children: [
                    _stat('جلسات اليوم', '${c.todayTotal}', Icons.event_available_rounded),
                    const SizedBox(width: 10),
                    _stat('مكتملة', '${c.todayCompleted}', Icons.task_alt_rounded),
                    const SizedBox(width: 10),
                    _stat('طلبات معلّقة', '${c.pending.length}', Icons.pending_actions_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                    () => Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'طلبات الحجز (${c.pending.length})',
                        type: c.showUpcoming.value
                            ? AppButtonType.secondary
                            : AppButtonType.primary,
                        onPressed: () => c.showUpcoming.value = false,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        label: 'الجلسات القادمة (${c.upcoming.length})',
                        type: c.showUpcoming.value
                            ? AppButtonType.primary
                            : AppButtonType.secondary,
                        onPressed: () => c.showUpcoming.value = true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Obx(() {
                if (c.hasError.value) {
                  return Center(
                    child: Column(
                      children: [
                        const Text('تعذر تحميل البيانات',
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
                final busy = c.busyId.value != null;
                final list = c.showUpcoming.value ? c.upcoming : c.pending;
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      c.showUpcoming.value ? 'لا توجد جلسات قادمة' : 'لا توجد طلبات معلّقة',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }
                return Column(
                  children: [for (final r in list) _request(c, r, busy)],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
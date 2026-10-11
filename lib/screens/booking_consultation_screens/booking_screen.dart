// lib/screens/booking_consultation_screens/booking_screen.dart  (replace the whole file)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../component/app_components.dart';
import '../../component/colors.dart';
import '../../controllers/booking_controller.dart';
import '../../fierbase/fire_base_ext.dart';
import '../../fierbase/fire_base_services.dart';

class BookingScreen extends StatelessWidget {
  final Consultant consultant;
  final SessionType initialType;

  const BookingScreen({
    super.key,
    required this.consultant,
    this.initialType = SessionType.video,
  });

  static const _types = [
    (SessionType.video, 'فيديو', Icons.videocam_rounded),
    (SessionType.audio, 'صوت', Icons.mic_rounded),
    (SessionType.chat, 'محادثة', Icons.chat_bubble_rounded),
  ];

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = Get.put(
      BookingController(consultant: consultant, initialType: initialType),
      tag: consultant.id,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.sand,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.primary,
          title: const Text('حجز جلسة', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.sand,
                    backgroundImage:
                    consultant.photoUrl != null ? NetworkImage(consultant.photoUrl!) : null,
                    child: consultant.photoUrl == null
                        ? const Icon(Icons.person_rounded, size: 32, color: AppColors.primary)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          consultant.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          consultant.specialty,
                          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 18, color: AppColors.coral),
                            const SizedBox(width: 4),
                            Text(
                              consultant.ratingAvg.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _sectionTitle('اختر اليوم'),
            Obx(() {
              final selected = c.date.value;
              return Row(
                children: [
                  for (final d in c.days)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: GestureDetector(
                          onTap: () => c.selectDate(d),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: d == selected ? AppColors.primary : AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: d == selected ? AppColors.primary : AppColors.border,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  BookingController.dayNames[d.weekday]!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: d == selected
                                        ? AppColors.sand
                                        : AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${d.day}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: d == selected ? Colors.white : AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
            _sectionTitle('اختر الوقت'),
            Obx(() {
              final selected = c.hour.value;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final h in BookingController.hours)
                    Builder(builder: (_) {
                      final disabled = c.isDisabled(h);
                      return ChoiceChip(
                        label: Text('$h:00'),
                        selected: selected == h,
                        showCheckmark: false,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        disabledColor: AppColors.sandDark,
                        side: BorderSide(
                          color: selected == h ? AppColors.primary : AppColors.border,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          decoration: disabled ? TextDecoration.lineThrough : null,
                          color: disabled
                              ? AppColors.textMuted
                              : (selected == h ? Colors.white : AppColors.primary),
                        ),
                        onSelected: disabled ? null : (_) => c.selectHour(h),
                      );
                    }),
                ],
              );
            }),
            _sectionTitle('نوع الجلسة'),
            Obx(() {
              final selected = c.type.value;
              return Row(
                children: [
                  for (final t in _types)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: GestureDetector(
                          onTap: () => c.selectType(t.$1),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: selected == t.$1 ? AppColors.primary : AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected == t.$1
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  t.$3,
                                  color: selected == t.$1 ? Colors.white : AppColors.primary,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  t.$2,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: selected == t.$1
                                        ? Colors.white
                                        : AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
            const SizedBox(height: 28),
            Obx(
                  () => AppButton(
                label: c.loading.value ? 'جارٍ الحجز...' : 'تأكيد الحجز',
                icon: Icons.check_circle_rounded,
                onPressed: (c.hour.value == null || c.loading.value) ? null : c.confirm,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
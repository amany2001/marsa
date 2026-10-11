// lib/screens/sos_crisis_screen.dart  (new file)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../component/app_components.dart';
import '../component/colors.dart';
import '../controllers/sos_crisis_controller.dart';

class SosCrisisScreen extends StatelessWidget {
  const SosCrisisScreen({super.key});

  Widget _tool(SelfHelpTool t) => AppCard(
    padding: EdgeInsets.zero,
    child: Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(t.icon, color: AppColors.primary),
        title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < t.steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('${i + 1}. ${t.steps[i]}',
                  style: const TextStyle(color: AppColors.textDark, height: 1.5)),
            ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = Get.find<SosCrisisController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.sand,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.coral,
          title: const Text('مساعدة عاجلة', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Obx(
                  () => c.isOnline.value
                  ? const SizedBox.shrink()
                  : Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.sandDark,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 18, color: AppColors.coral),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('أنت غير متصل — الأدوات أدناه تعمل دون إنترنت',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
            const Text('تنفّس معي',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary)),
            const SizedBox(height: 4),
            const Text('تمرين 4-7-8: شهيق 4، حبس 7، زفير 8',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 24),
            Center(
              child: AnimatedBuilder(
                animation: c.anim,
                builder: (_, __) {
                  final s = c.scaleOf(c.anim.value);
                  return Container(
                    width: 150 + 110 * s,
                    height: 150 + 110 * s,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.18 + 0.32 * s),
                      border: Border.all(color: AppColors.primary, width: 3),
                    ),
                    child: Obx(
                          () => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(c.phase.value,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary)),
                          Text('${c.secondsLeft.value}',
                              style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Obx(
                  () => AppButton(
                label: c.running.value ? 'إيقاف مؤقت' : 'متابعة التنفس',
                type: AppButtonType.secondary,
                icon: c.running.value ? Icons.pause_rounded : Icons.play_arrow_rounded,
                onPressed: c.toggleBreathing,
              ),
            ),
            const SizedBox(height: 12),
            Obx(
                  () => AppButton(
                label: c.requesting.value ? 'جارٍ الإرسال...' : 'أحتاج مساعدة الآن',
                type: AppButtonType.sos,
                icon: Icons.sos_rounded,
                onPressed: c.requesting.value ? null : c.requestHelp,
              ),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'خطوط الطوارئ',
              type: AppButtonType.secondary,
              icon: Icons.phone_in_talk_rounded,
              onPressed: c.openHotlines,
            ),
            const SizedBox(height: 24),
            const Text('أدوات المساعدة الذاتية',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const SizedBox(height: 10),
            for (final t in SosCrisisController.tools) ...[
              _tool(t),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}
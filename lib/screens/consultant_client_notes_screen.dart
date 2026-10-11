// lib/screens/consultant_client_notes_screen.dart  (new file)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../component/app_components.dart';
import '../component/colors.dart';
import '../controllers/consultant_client_notes_controller.dart';

class ConsultantClientNotesScreen extends StatelessWidget {
  const ConsultantClientNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ConsultantClientNotesController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.sand,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.primary,
          title: Text('مستفيد ${c.anon}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            const Row(
              children: [
                Icon(Icons.lock_rounded, size: 16, color: AppColors.primary),
                SizedBox(width: 6),
                Expanded(
                  child: Text('تُشفَّر الملاحظة على هذا الجهاز قبل رفعها',
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text('ملاحظات الجلسة الحالية',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const SizedBox(height: 10),
            TextField(
              controller: c.noteCtrl,
              minLines: 6,
              maxLines: 10,
              maxLength: 4000,
              decoration: InputDecoration(
                hintText: 'اكتب ملاحظاتك السريرية هنا...',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 100),
                  child: Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                ),
                filled: true,
                fillColor: AppColors.surface,
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
            const SizedBox(height: 10),
            Obx(
                  () => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in ConsultantClientNotesController.quickTags)
                    FilterChip(
                      avatar: t == ConsultantClientNotesController.dictationTag
                          ? Icon(
                        c.listening.value ? Icons.stop_rounded : Icons.mic_rounded,
                        size: 18,
                        color: c.listening.value ? Colors.white : AppColors.primary,
                      )
                          : null,
                      label: Text(t),
                      selected: c.selectedTags.contains(t) ||
                          (t == ConsultantClientNotesController.dictationTag &&
                              c.listening.value),
                      showCheckmark: false,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      side: BorderSide(
                        color: c.selectedTags.contains(t) ? AppColors.primary : AppColors.border,
                      ),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: (c.selectedTags.contains(t) ||
                            (t == ConsultantClientNotesController.dictationTag &&
                                c.listening.value))
                            ? Colors.white
                            : AppColors.primary,
                      ),
                      onSelected: (v) => c.toggleTag(t, v),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Obx(
                  () => AppButton(
                label: c.saving.value ? 'جارٍ التشفير والحفظ...' : 'حفظ الملاحظة المشفّرة',
                icon: Icons.lock_rounded,
                onPressed: c.saving.value ? null : c.save,
              ),
            ),
            const SizedBox(height: 26),
            const Text('سجل الجلسات السابقة',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            const SizedBox(height: 10),
            Obx(() {
              if (c.hasError.value) {
                return Center(
                  child: TextButton(
                    onPressed: c.retry,
                    child: const Text('تعذر تحميل السجل، إعادة المحاولة',
                        style: TextStyle(color: AppColors.coral)),
                  ),
                );
              }
              if (c.loading.value) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary));
              }
              if (c.history.isEmpty) {
                return const Center(
                  child: Text('لا توجد ملاحظات سابقة',
                      style: TextStyle(color: AppColors.textMuted)),
                );
              }
              return Column(
                children: [
                  for (final n in c.history)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        padding: EdgeInsets.zero,
                        child: Theme(
                          data: ThemeData(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            title: Text(c.dateLabel(n.createdAt),
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: n.tags.isEmpty
                                ? null
                                : Text(n.tags.join(' • '),
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.primary)),
                            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            expandedCrossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.text ?? 'تعذر فك التشفير على هذا الجهاز',
                                style: TextStyle(
                                  height: 1.6,
                                  color: n.text == null
                                      ? AppColors.coral
                                      : AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
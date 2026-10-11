// lib/screens/booking_consultation_screens/active_session_room.dart  (replace the whole file)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../component/colors.dart';
import '../../controllers/active_session_controller.dart';
import '../../fierbase/fire_base_ext.dart';

class ActiveSessionRoom extends StatelessWidget {
  final String sessionId;

  const ActiveSessionRoom({super.key, required this.sessionId});

  Widget _shell(Widget body) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: AppColors.sand,
      body: SafeArea(child: body),
    ),
  );
// Widget _header(ActiveSessionController c, Session session)
  Widget _header(ActiveSessionController c, Session session) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: Get.back,
                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ),
              const CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.sand,
                child: Icon(Icons.person_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                          () => Text(
                        c.consultantName.value.isEmpty ? 'المستشار' : c.consultantName.value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      c.statusLabel(session.status),
                      style: const TextStyle(color: AppColors.sandDark, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Obx(
                    () => TextButton(
                  onPressed: (c.closing.value || session.status == SessionStatus.ended)
                      ? null
                      : c.endSession,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    c.closing.value ? '...' : 'إنهاء الجلسة',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Obx(() {
            final on = c.e2e.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    on ? Icons.lock_rounded : Icons.lock_open_rounded,
                    size: 14,
                    color: AppColors.sand,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    on ? 'مشفّرة من طرف إلى طرف' : 'جلسة خاصة',
                    style: const TextStyle(color: AppColors.sand, fontSize: 12),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _bubble(ActiveSessionController c, ChatMessage m, bool mine) {
    return Align(
      alignment: mine ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
      child: Container(
        constraints: BoxConstraints(maxWidth: Get.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: mine ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m.text,
              style: TextStyle(
                fontSize: 15,
                color: mine ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              c.timeLabel(m.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: mine ? AppColors.sandDark : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ActiveSessionController(sessionId), tag: sessionId);

    return Obx(() {
      if (c.hasError.value) {
        return _shell(const Center(child: Text('تعذر تحميل الجلسة')));
      }
      final session = c.session.value;
      if (session == null) {
        return _shell(
          c.loading.value
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : const Center(child: Text('الجلسة غير متاحة')),
        );
      }

      return _shell(
        Column(
          children: [
            _header(c, session),
            Expanded(
              child: Obx(() {
                final msgs = c.messages;
                if (msgs.isEmpty) {
                  return const Center(
                    child: Text(
                      'ابدأ المحادثة بكتابة رسالتك',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) => _bubble(c, msgs[i], msgs[i].senderId == c.myId),
                );
              }),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Obx(() {
                final canSend = c.canSend;
                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: c.input,
                        enabled: canSend,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => c.send(),
                        decoration: InputDecoration(
                          hintText: 'اكتب رسالتك...',
                          hintStyle: const TextStyle(color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.sand,
                          contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: canSend ? AppColors.primary : AppColors.border,
                      child: IconButton(
                        onPressed: canSend ? c.send : null,
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      );
    });
  }
}
// lib/controllers/consultant_client_notes_controller.dart  (new file)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../fierbase/fire_base_ext.dart';
import '../fierbase/fire_base_services.dart';
import '../fierbase/note_crypto.dart';

class ClinicalNote {
  final String id;
  final DateTime? createdAt;
  final String? text;
  final List<String> tags;
  const ClinicalNote({required this.id, this.createdAt, this.text, this.tags = const []});
}

class ConsultantClientNotesController extends GetxController {
  ConsultantClientNotesController(this.patientId, this.sessionId);

  static const dictationTag = 'إملاء صوتي';
  static const quickTags = ['تحسن طفيف', 'خطر منخفض', dictationTag];

  final String patientId;
  final String? sessionId;
  String get anon => anonId(patientId);

  final _service = MarsaFirebaseService.instance;
  final _crypto = NoteCrypto.instance;
  final _speech = stt.SpeechToText();
  final noteCtrl = TextEditingController();

  final selectedTags = <String>{}.obs;
  final history = <ClinicalNote>[].obs;
  final loading = true.obs;
  final hasError = false.obs;
  final saving = false.obs;
  final listening = false.obs;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _listen();
  }

  void _listen() {
    _sub?.cancel();
    loading.value = true;
    hasError.value = false;
    if (_service.currentUser == null) {
      hasError.value = true;
      loading.value = false;
      return;
    }
    _sub = _service.streamClinicalNotes(patientId).listen(
          (raw) async {
        final uid = _service.currentUser?.uid ?? '';
        final out = <ClinicalNote>[];
        for (final r in raw) {
          final data = await _crypto.decryptJson(
            uid,
            r['cipher'] as String? ?? '',
            r['iv'] as String? ?? '',
          );
          out.add(ClinicalNote(
            id: r['id'] as String,
            createdAt: r['createdAt'] as DateTime?,
            text: data?['text'] as String?,
            tags: List<String>.from(data?['tags'] as List? ?? const []),
          ));
        }
        history.assignAll(out);
        loading.value = false;
      },
      onError: (_) {
        hasError.value = true;
        loading.value = false;
      },
    );
  }

  void retry() => _listen();

  void toggleTag(String tag, bool on) {
    if (tag == dictationTag) {
      toggleDictation();
      return;
    }
    if (on) {
      selectedTags.add(tag);
    } else {
      selectedTags.remove(tag);
    }
  }

  Future<void> toggleDictation() async {
    if (listening.value) {
      await _speech.stop();
      listening.value = false;
      return;
    }
    final ok = await _speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') listening.value = false;
      },
      onError: (_) {
        listening.value = false;
        Get.rawSnackbar(message: 'الإملاء المحلي غير متاح أو حزمة اللغة العربية غير مثبّتة');
      },
    );
    if (!ok) {
      Get.rawSnackbar(message: 'الإملاء الصوتي غير متاح على هذا الجهاز');
      return;
    }
    listening.value = true;
    await _speech.listen(
      localeId: 'ar_SA',
      listenOptions: stt.SpeechListenOptions(onDevice: true, partialResults: false),
      onResult: (r) {
        if (!r.finalResult || r.recognizedWords.isEmpty) return;
        final cur = noteCtrl.text;
        noteCtrl.text = cur.isEmpty ? r.recognizedWords : '$cur ${r.recognizedWords}';
        selectedTags.add(dictationTag);
      },
    );
  }

  Future<void> save() async {
    final text = noteCtrl.text.trim();
    if (saving.value) return;
    if (text.isEmpty) {
      Get.rawSnackbar(message: 'اكتب الملاحظة أولاً');
      return;
    }
    final uid = _service.currentUser?.uid;
    if (uid == null) {
      Get.rawSnackbar(message: 'يرجى تسجيل الدخول أولاً');
      return;
    }
    saving.value = true;
    try {
      final sealed = await _crypto.encryptJson(uid, {
        'text': text,
        'tags': selectedTags.toList(),
      });
      await _service.saveClinicalNote(
        patientId: patientId,
        sessionId: sessionId,
        cipher: sealed['cipher']!,
        iv: sealed['iv']!,
      );
      _reset();
      Get.rawSnackbar(message: 'تم حفظ الملاحظة مشفّرة');
    } on TimeoutException {
      _reset();
      Get.rawSnackbar(message: 'ستُحفظ الملاحظة فور عودة الاتصال');
    } on FirebaseServiceException {
      Get.rawSnackbar(message: 'تعذر حفظ الملاحظة');
    } catch (_) {
      Get.rawSnackbar(message: 'تعذر تشفير الملاحظة على هذا الجهاز');
    } finally {
      saving.value = false;
    }
  }

  void _reset() {
    noteCtrl.clear();
    selectedTags.clear();
  }

  String dateLabel(DateTime? d) {
    if (d == null) return 'الآن';
    final t = d.toLocal();
    return '${t.day}/${t.month}/${t.year} — ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  void onClose() {
    _sub?.cancel();
    _speech.cancel();
    noteCtrl.dispose();
    super.onClose();
  }
}
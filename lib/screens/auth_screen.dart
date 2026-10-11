// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../component/app_components.dart';
import '../component/colors.dart';
import '../controllers/auth_controller.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  Widget _segment(
      List<String> labels,
      int selected,
      ValueChanged<int> onChanged,
      ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.sandDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.put(AuthController());

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.sand,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.primary,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تسجيل الدخول',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'اختر نوع حسابك للمتابعة',
                  style: TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                Obx(
                      () => _segment(
                    ['مستفيد', 'مستشار متطوع'],
                    c.role.value,
                        (i) => c.role.value = i,
                  ),
                ),
                const SizedBox(height: 20),
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Obx(
                            () => _segment(
                          ['رقم الهاتف', 'البريد الإلكتروني'],
                          c.tab.value,
                              (i) => c.tab.value = i,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Obx(
                            () => AppInputField(
                          label: c.isPhone ? 'رقم الهاتف' : 'البريد الإلكتروني',
                          hint: c.isPhone ? '05X XXX XXXX' : 'name@example.com',
                          controller: c.contact,
                          icon: c.isPhone
                              ? Icons.phone_rounded
                              : Icons.email_rounded,
                          keyboardType: c.isPhone
                              ? TextInputType.phone
                              : TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppInputField(
                        label: 'رمز التحقق',
                        hint: '------',
                        controller: c.otp,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        centered: true,
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            'إرسال الرمز',
                            style: TextStyle(
                              color: AppColors.coral,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'تسجيل دخول آمن',
                  icon: Icons.lock_rounded,
                  onPressed: c.login,
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'بياناتك محمية ومشفرة بالكامل',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// settings_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:marsa/component/colors.dart';
import 'package:marsa/screens/on_boarding_screen.dart';
import '../component/app_components.dart';
import '../fierbase/fire_base_services.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _night = false;
  bool _notifications = true;
  bool _offline = true;

  Widget _toggle(String title, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      secondary: Icon(icon, color: AppColors.primary),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
    );
  }

  Widget _link(String title, IconData icon, {Color color = AppColors.textDark}) {
    return ListTile(
      onTap: () {},
      leading: Icon(icon, color: color == AppColors.coral ? color : AppColors.primary),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      trailing: const Icon(Icons.chevron_left_rounded, color: AppColors.textMuted),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.sand,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.primary,
          title: const Text('حسابي', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: 3,
          onTap: (i) {
            if (i != 3) Navigator.of(context).pop();
          },
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppCard(
              color: AppColors.primary,
              borderColor: AppColors.primary,
              padding: const EdgeInsets.all(20),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.sand,
                    child: Icon(Icons.person, size: 32, color: AppColors.primary),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('أحمد',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                        SizedBox(height: 4),
                        Text('مستفيد',
                            style: TextStyle(color: AppColors.sandDark)),
                      ],
                    ),
                  ),
                  Icon(Icons.edit_rounded, color: AppColors.sand),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _toggle('الوضع الليلي', Icons.dark_mode_rounded, _night,
                          (v) => setState(() => _night = v)),
                  const Divider(height: 1, color: AppColors.border),
                  _toggle('الإشعارات', Icons.notifications_rounded, _notifications,
                          (v) => setState(() => _notifications = v)),
                  const Divider(height: 1, color: AppColors.border),
                  _toggle('وضع عدم الاتصال', Icons.wifi_off_rounded, _offline,
                          (v) => setState(() => _offline = v)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _link('الخصوصية والأمان', Icons.shield_rounded),
                  const Divider(height: 1, color: AppColors.border),
                  _link('خطوط الطوارئ SOS', Icons.phone_in_talk_rounded,
                      color: AppColors.coral),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'تسجيل الخروج',
              type: AppButtonType.secondary,
              icon: Icons.logout_rounded,
              onPressed: () async {
                await MarsaFirebaseService.instance.signOut();
                Get.offAll(() => const OnboardingScreen());
              },
            ),
          ],
        ),
      ),
    );
  }
}
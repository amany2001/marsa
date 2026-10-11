// app_components.dart
import 'package:flutter/material.dart';
import 'package:marsa/component/colors.dart';


enum AppButtonType { primary, secondary, sos }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bg = switch (type) {
      AppButtonType.primary => AppColors.primary,
      AppButtonType.secondary => AppColors.sand,
      AppButtonType.sos => AppColors.coral,
    };
    final fg = type == AppButtonType.secondary ? AppColors.primary : Colors.white;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: type == AppButtonType.secondary
                ? const BorderSide(color: AppColors.primary, width: 1.2)
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class AppInputField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final IconData? icon;
  final int? maxLength;
  final bool centered;

  const AppInputField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.icon,
    this.maxLength,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(
              fontSize: 16,
              letterSpacing: centered ? 8 : 0,
              color: AppColors.textDark),
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted, letterSpacing: 0),
            prefixIcon: icon != null ? Icon(icon, color: AppColors.primary) : null,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      ],
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;
  final Color? borderColor;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.surface,
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor ?? AppColors.border.withOpacity(0.6)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: AppColors.surface,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_rounded), label: 'جلساتي'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'المصادر'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'حسابي'),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import '../models/models.dart';

class CosAnimate {
  static fadeInUp({required Widget child, int delay = 0}) =>
      child.animate().fadeIn(duration: 450.ms, delay: delay.ms).moveY(begin: 16, end: 0, duration: 450.ms, delay: delay.ms, curve: Curves.easeOutCubic);
  static scaleIn(Widget child, {int delay = 0}) =>
      child.animate().scale(duration: 400.ms, delay: delay.ms, curve: Curves.easeOutBack);
}

class CosCard extends StatelessWidget {
  const CosCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.margin});
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsetsGeometry? margin;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding, margin: margin,
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.hairline)),
    child: child,
  );
}

class CosPrimaryButton extends StatelessWidget {
  const CosPrimaryButton({super.key, required this.label, required this.onPressed, this.icon, this.enabled = true, this.width = double.infinity});
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool enabled;
  final double width;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width, height: 56,
    child: ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(backgroundColor: enabled ? AppColors.gold : AppColors.surfaceHi, disabledBackgroundColor: AppColors.surfaceHi),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
        Text(label, style: AppText.display(16, const Color(0xFF1A1407))),
      ]),
    ),
  );
}

class CosTextField extends StatelessWidget {
  const CosTextField({super.key, required this.controller, required this.label, this.hint, this.icon, this.obscure = false, this.keyboard, this.suffix, this.onChanged});
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final bool obscure;
  final TextInputType? keyboard;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller, obscureText: obscure, keyboardType: keyboard, onChanged: onChanged,
    style: const TextStyle(color: AppColors.ink),
    decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: icon == null ? null : Icon(icon, color: AppColors.muted, size: 20), suffixIcon: suffix),
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    final map = {'booked': AppColors.gold, 'picked_up': AppColors.warning, 'washing': AppColors.gold, 'out_for_delivery': AppColors.warning, 'delivered': AppColors.success};
    final c = map[status] ?? AppColors.gold;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: c.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999)), child: Text(statusLabel[status] ?? status, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)));
  }
}

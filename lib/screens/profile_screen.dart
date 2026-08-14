import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import '../services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '', _email = '', _phone = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SupabaseService().getProfile();
    if (mounted) setState(() { _name = p?['full_name'] ?? 'User'; _email = p?['email'] ?? ''; _phone = p?['phone'] ?? ''; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile', style: AppText.display(22, AppColors.ink))),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const SizedBox(height: 8),
        Column(children: [
          Container(width: 84, height: 84, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [AppColors.gold, AppColors.goldDeep]), boxShadow: [BoxShadow(color: AppColors.goldGlow, blurRadius: 18, spreadRadius: 3)]), child: const Center(child: Text('C', style: {FontWeight: FontWeight.w700, FontSize: 34, Color: Color(0xFF1A1407)} as TextStyle))),
          const SizedBox(height: 14), Text(_name, style: AppText.display(20)), const SizedBox(height: 2), Text(_email, style: const TextStyle(color: AppColors.ink2, fontSize: 13)),
        ]),
        const SizedBox(height: 28),
        ..._rows(),
        const SizedBox(height: 22),
        GestureDetector(
          onTap: () async { await SupabaseService().signOut(); if (mounted) context.go('/auth'); },
          child: Container(height: 54, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.hairline)), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.logout_rounded, color: AppColors.danger, size: 20), SizedBox(width: 8), Text('Log Out', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600))])),
        ),
      ]),
    );
  }

  List<Widget> _rows() {
    final items = [
      ('Addresses', Icons.location_on_outlined, () {}),
      ('My Orders', Icons.receipt_long_rounded, () => context.go('/orders')),
      ('Payment Methods', Icons.credit_card_rounded, () {}),
      ('Wallet', Icons.account_balance_wallet_rounded, () => context.go('/wallet')),
      ('Notifications', Icons.notifications_none_rounded, () {}),
      ('Help & Support', Icons.help_outline_rounded, () {}),
      ('Settings', Icons.settings_outlined, () {}),
    ];
    return items.asMap().entries.map((e) {
      final x = e.value;
      return Padding(padding: const EdgeInsets.only(bottom: 10), child: GestureDetector(onTap: x.$3, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.hairline)), child: Row(children: [Icon(x.$2, color: AppColors.gold, size: 21), const SizedBox(width: 14), Expanded(child: Text(x.$1, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: AppColors.ink))), const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 21)]))));
    }).toList();
  }
}

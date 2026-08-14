import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import '../services/supabase_service.dart';
import '../widgets/common.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _balance = 0;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final b = await SupabaseService().getWalletBalance();
    if (mounted) setState(() { _balance = b; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Wallet', style: AppText.display(22, AppColors.ink))),
      body: RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(20), children: [
        CosAnimate.fadeInUp(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.gold, AppColors.goldDeep], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.3), blurRadius: 24, spreadRadius: 2, offset: const Offset(0, 10))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Available Balance', style: TextStyle(color: Color(0x991A1407), fontSize: 13)),
              const SizedBox(height: 8),
              _loading
                  ? Container(width: 130, height: 30, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8)))
                  : TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: _balance), duration: 900.ms, curve: Curves.easeOutCubic, builder: (_, v, __) => Text('₦${v.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.w700, fontSize: 34, color: Color(0xFF1A1407)))),
              const SizedBox(height: 18),
              FilledButton(onPressed: () {}, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1A1407), foregroundColor: AppColors.gold), child: const Text('Top Up')),
            ]),
          ),
        ),
        const SizedBox(height: 26),
        CosAnimate.fadeInUp(delay: 120, child: Text('Payment Methods', style: AppText.display(17))),
        const SizedBox(height: 12),
        _method('Visa •••• 4242', Icons.credit_card_rounded, true),
        _method('Wallet', Icons.account_balance_wallet_rounded, false),
        _method('Bank Transfer', Icons.account_balance_rounded, false),
        const SizedBox(height: 14),
        GestureDetector(onTap: () {}, child: Container(height: 56, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.hairline, style: BorderStyle.solid)), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_circle_outline_rounded, color: AppColors.gold, size: 20), SizedBox(width: 8), Text('Add Payment Method', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600))]))),
      ])),
    );
  }

  Widget _method(String t, IconData i, bool isDefault) {
    return CosAnimate.fadeInUp(delay: 200 + (isDefault ? 0 : 40), child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.hairline)), child: Row(children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.goldGlow, borderRadius: BorderRadius.circular(12)), child: Icon(i, color: AppColors.gold, size: 21)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.ink)), if (isDefault) ...[const SizedBox(height: 2), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColors.goldGlow, borderRadius: BorderRadius.circular(999)), child: const Text('Default', style: TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.w600)))]])),
      const Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 20),
    ])));
  }
}

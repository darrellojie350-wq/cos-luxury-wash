import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _balance = 0;
  bool _loading = true;
  String _name = '';
  List<ServiceItem> _services = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final p = await SupabaseService().getProfile();
    final bal = await SupabaseService().getWalletBalance();
    final svcs = await SupabaseService().getServices();
    if (mounted) setState(() {
      _name = p?['full_name']?.toString().split(' ').first ?? '';
      _balance = bal.toDouble();
      _services = svcs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                CosAnimate.fadeInUp(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Hello, $_name', style: AppText.display(26)),
                  const SizedBox(height: 4), Row(children: [const Icon(Icons.location_on_outlined, color: AppColors.muted, size: 16), const SizedBox(width: 4), const Text('Lagos, Nigeria', style: TextStyle(color: AppColors.ink2))]),
                ])),
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [AppColors.gold, AppColors.goldDeep]), boxShadow: [BoxShadow(color: AppColors.goldGlow, blurRadius: 14, spreadRadius: 2)]),
                  child: const Center(child: Text('C', style: TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.w700, fontSize: 20, color: Color(0xFF1A1407)))),
                ),
              ]),
              const SizedBox(height: 22),
              CosAnimate.fadeInUp(
                delay: 80,
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.gold, AppColors.goldDeep], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.3), blurRadius: 24, spreadRadius: 2, offset: const Offset(0, 8))],
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Wallet Balance', style: TextStyle(color: Color(0x991A1407), fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 7),
                      _loading
                          ? Container(width: 110, height: 26, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8)))
                          : TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: _balance), duration: 900.ms, curve: Curves.easeOutCubic, builder: (_, v, __) => Text('₦${v.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.w700, fontSize: 30, color: Color(0xFF1A1407)))),
                    ]),
                    FilledButton(onPressed: () => context.go('/wallet'), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1A1407), foregroundColor: AppColors.gold), child: const Text('Top Up')),
                  ]),
                ),
              ),
              const SizedBox(height: 26),
              CosAnimate.fadeInUp(delay: 160, child: Text('Our Services', style: AppText.display(20))),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 1.05,
                children: [for (var i = 0; i < _services.length; i++) _serviceTile(_services[i], i)],
              ),
              const SizedBox(height: 20),
              CosAnimate.fadeInUp(delay: 400, child: const _PromoCard()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _serviceTile(ServiceItem s, int i) {
    final icons = {'laundry': Icons.local_laundry_service_rounded, 'shoe': Icons.directions_run_rounded, 'bed': Icons.king_bed_rounded, 'bag': Icons.backpack_rounded};
    return CosAnimate.fadeInUp(
      delay: 200 + i * 60,
      child: GestureDetector(
        onTap: () => context.go('/book'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.hairline)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.goldGlow, borderRadius: BorderRadius.circular(13)), child: Icon(icons[s.category] ?? Icons.cleaning_services_rounded, color: AppColors.gold, size: 22)),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.ink)),
              const SizedBox(height: 3),
              Text('From ₦${s.pricePerBag.toStringAsFixed(0)}', style: AppText.monoNum(12).copyWith(color: AppColors.muted)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.hairline)),
    child: Row(children: [
      Container(width: 50, height: 50, decoration: BoxDecoration(color: AppColors.goldGlow, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.delivery_dining_rounded, color: AppColors.gold, size: 26)),
      const SizedBox(width: 15),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Pickup & Delivery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.ink)), SizedBox(height: 4), Text("We'll pick up and deliver your items safely", style: TextStyle(color: AppColors.ink2, fontSize: 13))])),
    ]),
  );
}

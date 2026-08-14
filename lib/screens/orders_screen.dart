import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _filter = 'all';
  List<WashOrder> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final o = await SupabaseService().getOrders();
    if (mounted) setState(() { _orders = o; _loading = false; });
  }

  List<WashOrder> get _filtered {
    if (_filter == 'all') return _orders;
    if (_filter == 'progress') return _orders.where((o) => o.status != 'delivered').toList();
    return _orders.where((o) => o.status == 'delivered').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Orders', style: AppText.display(22, AppColors.ink)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: AppColors.ink2), onPressed: _load)],
      ),
      body: Column(children: [
        _tabs(),
        Expanded(child: _loading ? _shimmerList() : _filtered.isEmpty ? _empty() : ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
          itemCount: _filtered.length,
          itemBuilder: (_, i) => _card(_filtered[i], i),
        )),
      ]),
    );
  }

  Widget _tabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(children: ['all', 'progress', 'completed'].map((f) {
        final on = _filter == f;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _filter = f),
              child: AnimatedContainer(
                duration: 250.ms,
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(color: on ? AppColors.gold : AppColors.surfaceHi, borderRadius: BorderRadius.circular(13)),
                child: Center(child: Text(f[0].toUpperCase() + f.substring(1), style: TextStyle(color: on ? const Color(0xFF1A1407) : AppColors.ink2, fontWeight: FontWeight.w600, fontSize: 13.5))),
              ),
            ),
          ),
        );
      }).toList()),
    );
  }

  Widget _card(WashOrder o, int i) {
    return CosAnimate.fadeInUp(
      delay: i * 40,
      child: GestureDetector(
        onTap: () => context.go('/track/${o.id}'),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.hairline)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(o.id?.substring(0, 12) ?? '', style: AppText.monoNum(13).copyWith(color: AppColors.muted)), StatusPill(o.status ?? '')]),
            const SizedBox(height: 12),
            Text(o.serviceName ?? 'Laundry', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.ink)),
            const SizedBox(height: 4),
            Text('${o.bags} bag(s)  ·  Pickup ${o.pickupDate}', style: const TextStyle(color: AppColors.ink2, fontSize: 13)),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(o.status == 'delivered' ? 'View Details' : 'Track Order', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600, fontSize: 13)), const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.gold, size: 14)]),
          ]),
        ),
      ),
    );
  }

  Widget _shimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 130,
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18)),
      ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 900.ms, color: AppColors.surfaceHi),
    );
  }

  Widget _empty() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.inbox_outlined, size: 52, color: AppColors.muted.withValues(alpha: 0.5)),
      const SizedBox(height: 12),
      const Text('No orders yet', style: TextStyle(color: AppColors.ink2)),
      const SizedBox(height: 8),
      CosPrimaryButton(label: 'Book a Service', onPressed: () => context.go('/book')),
    ]));
  }
}

import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key, required this.orderId});
  final String orderId;
  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  String _status = 'booked';
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final h = await SupabaseService().getOrderHistory(widget.orderId);
    if (mounted) setState(() { _history = h; _status = h.isNotEmpty ? h.last['status'] : 'booked'; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Track Order', style: AppText.display(20, AppColors.ink)), leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.ink2, size: 18), onPressed: () => context.go('/orders'))),
      body: _loading ? const Center(child: CircularProgressIndicator(color: AppColors.gold)) : ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          CosAnimate.fadeInUp(child: _liveBanner()),
          const SizedBox(height: 20),
          CosAnimate.fadeInUp(delay: 80, child: _mapCard()),
          const SizedBox(height: 20),
          CosAnimate.fadeInUp(delay: 160, child: _riderCard()),
          const SizedBox(height: 24),
          Text('Order Status', style: AppText.display(17)),
          const SizedBox(height: 14),
          ...orderStatuses.asMap().entries.map((e) {
            final i = e.value;
            final done = orderStatuses.indexOf(_status) >= orderStatuses.indexOf(i);
            final current = i == _status;
            return _timelineRow(i, done, current, _history.where((h) => h['status'] == i).toList());
          }),
        ],
      ),
    );
  }

  Widget _liveBanner() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.hairline)),
    child: Row(children: [
      Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.rideGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.delivery_dining_rounded, color: AppColors.rideGreen, size: 24)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_statusText(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.ink)),
        const SizedBox(height: 3),
        Text('Order #${widget.orderId.substring(0, 12)}', style: AppText.monoNum(12).copyWith(color: AppColors.muted)),
      ])),
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: AppColors.rideGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)), child: const Text('LIVE', style: TextStyle(color: AppColors.rideGreen, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 1))),
    ]),
  );

  String _statusText() => switch (_status) {
    'booked' => 'Order booked · Preparing pickup',
    'picked_up' => 'Picked up · Heading to facility',
    'washing' => 'Being cleaned with care',
    'out_for_delivery' => 'Out for delivery · Arriving soon',
    'delivered' => 'Delivered · Enjoy your clean clothes!',
    _ => 'Order in progress',
  };

  Widget _mapCard() => Container(
    height: 160,
    decoration: BoxDecoration(color: AppColors.surfaceHi, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.hairline)),
    child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Stack(children: [
      Center(child: Icon(Icons.map_rounded, size: 50, color: AppColors.muted.withValues(alpha: 0.4))),
      Positioned(bottom: 14, left: 14, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(999)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.navigation_rounded, color: AppColors.gold, size: 14), SizedBox(width: 5), Text('Live route tracking', style: TextStyle(color: AppColors.ink, fontSize: 12))]))),
    ])),
  );

  Widget _riderCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.hairline)),
    child: Row(children: [
      Container(width: 48, height: 48, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.gold, AppColors.goldDeep])), child: const Center(child: Text('T', style: TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.w700, color: Color(0xFF1A1407), fontSize: 18)))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_status == 'delivered' ? 'Delivered by' : 'Your Rider', style: const TextStyle(color: AppColors.muted, fontSize: 12)), const Text('Tunde Okoye', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.ink)), const SizedBox(height: 2), Row(children: [const Icon(Icons.star_rounded, color: AppColors.gold, size: 15), const SizedBox(width: 3), Text('4.9', style: AppText.monoNum(13))])])),
      IconButton(onPressed: () {}, icon: Icon(Icons.phone_rounded, color: AppColors.gold)),
    ]),
  );

  Widget _timelineRow(String status, bool done, bool current, List history) {
    final ts = history.isNotEmpty ? (history.first['created_at'] ?? '').toString().substring(11, 16) : '';
    return IntrinsicHeight(child: Row(crossAxisAlignment: Alignment.center, children: [
      Column(children: [
        Container(width: 22, height: 22, decoration: BoxDecoration(shape: BoxShape.circle, color: done ? AppColors.gold : Colors.transparent, border: Border.all(color: done ? AppColors.gold : AppColors.muted, width: 2.5)), child: done ? const Icon(Icons.check_rounded, size: 13, color: Color(0xFF1A1407)) : null),
        if (status != 'delivered') Expanded(child: Container(width: 2, color: done ? AppColors.gold : AppColors.surfaceHi)),
      ]),
      const SizedBox(width: 14),
      Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(statusLabel[status] ?? status, style: TextStyle(fontWeight: current ? FontWeight.w700 : FontWeight.w500, fontSize: 14.5, color: done ? AppColors.ink : AppColors.muted)),
        if (ts.isNotEmpty) Text(ts, style: AppText.monoNum(12).copyWith(color: AppColors.muted)),
      ]))),
    ]));
  }
}

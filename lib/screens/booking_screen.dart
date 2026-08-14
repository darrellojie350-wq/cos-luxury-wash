import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import '../services/supabase_service.dart';
import '../models/models.dart';
import '../widgets/common.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _step = 0;
  ServiceItem? _service;
  int _bags = 1;
  DateTime _pickupDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _pickupTime = const TimeOfDay(hour: 10, minute: 0);
  DateTime _readyDate = DateTime.now().add(const Duration(days: 2));
  DateTime _deliveryDate = DateTime.now().add(const Duration(days: 3));
  TimeOfDay _deliveryTime = const TimeOfDay(hour: 14, minute: 0);
  String _paymentMethod = 'wallet';
  String _laundryPayChoice = 'later';
  bool _busy = false;
  List<ServiceItem> _services = [];
  String _pickupAddr = '14 Admiralty Way, Lekki Phase 1, Lagos';
  double _balance = 0;

  @override
  void initState() {
    super.initState();
    _loadServices();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final b = await SupabaseService().getWalletBalance();
    if (mounted) setState(() => _balance = b);
  }

  Future<void> _loadServices() async {
    final s = await SupabaseService().getServices();
    if (mounted) setState(() {
      _services = s;
      _service = s.isNotEmpty ? s[0] : null;
    });
  }

  double get _rideFee => 1500;
  double get _laundryTotal => (_service?.pricePerBag ?? 0) * _bags;
  double get _totalNow => _laundryPayChoice == 'now' ? _rideFee + _laundryTotal : _rideFee;

  Future<void> _pickDate(bool pickup, ValueChanged<DateTime> set) async {
    final d = await showDatePicker(
      context: context,
      initialDate: pickup ? _pickupDate : _deliveryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (d != null) set(d);
  }

  Future<void> _pickTime(bool pickup, ValueChanged<TimeOfDay> set) async {
    final t = await showTimePicker(context: context, initialTime: pickup ? _pickupTime : _deliveryTime);
    if (t != null) set(t);
  }

  Future<void> _readyDatePick() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _readyDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (d != null) setState(() => _readyDate = d);
  }

  Future<void> _confirm() async {
    if (_service == null) return;
    setState(() => _busy = true);
    final o = WashOrder(
      serviceId: _service!.id,
      serviceName: _service!.name,
      bags: _bags,
      pickupAddress: _pickupAddr,
      pickupDate: DateFormat('yyyy-MM-dd').format(_pickupDate),
      pickupTime: _pickupTime.format(context),
      deliveryAddress: _pickupAddr,
      deliveryDate: DateFormat('yyyy-MM-dd').format(_deliveryDate),
      deliveryTime: _deliveryTime.format(context),
      rideFee: _rideFee,
      laundryTotal: _laundryTotal,
      paymentMethod: _paymentMethod,
      laundryPaymentStatus: _laundryPayChoice == 'now' ? 'paid' : 'unpaid',
    );
    try {
      final created = await SupabaseService().createOrder(o);
      await SupabaseService().updateOrderStatus(created.id!, 'booked', note: 'Order placed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Booking confirmed!', style: TextStyle(color: Color(0xFF1A1407))), backgroundColor: AppColors.gold),
        );
        context.go('/track/${created.id}');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book a Service', style: AppText.display(20, AppColors.ink)),
        leading: _step == 0 ? null : IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.ink2, size: 18), onPressed: () => setState(() => _step--)),
      ),
      body: Column(children: [
        _stepper(),
        Expanded(
          child: AnimatedSwitcher(
            duration: 300,
            child: [
              _serviceStep(),
              _pickupStep(),
              _deliveryStep(),
              _paymentStep(),
            ][_step],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          child: CosPrimaryButton(
            label: _step < 3 ? 'Continue' : (_busy ? 'Confirming...' : 'Confirm Booking'),
            enabled: !_busy,
            onPressed: _step < 3 ? () => setState(() => _step++) : _confirm,
          ),
        ),
      ]),
    );
  }

  Widget _stepper() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      child: Row(children: List.generate(4, (i) {
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
            decoration: BoxDecoration(
              color: i <= _step ? AppColors.gold : AppColors.surfaceHi,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      })),
    );
  }

  Widget _serviceStep() {
    return ListView(
      key: const ValueKey('svc'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      children: [
        Text('What do you need cleaned?', style: AppText.display(19)),
        const SizedBox(height: 16),
        ..._services.map((s) {
          final on = _service?.id == s.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 13),
            child: GestureDetector(
              onTap: () => setState(() => _service = s),
              child: AnimatedContainer(
                duration: 250,
                curve: Curves.easeOut,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: on ? AppColors.surfaceHi : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: on ? AppColors.gold : AppColors.hairline, width: on ? 1.4 : 1),
                ),
                child: Row(children: [
                  Container(width: 46, height: 46, decoration: BoxDecoration(color: on ? AppColors.goldGlow : AppColors.base, borderRadius: BorderRadius.circular(13)), child: Icon(Icons.local_laundry_service_rounded, color: on ? AppColors.gold : AppColors.muted)),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.ink)), const SizedBox(height: 3), Text(s.description, style: const TextStyle(color: AppColors.ink2, fontSize: 12.5))])),
                  Text('₦${s.pricePerBag.toStringAsFixed(0)}', style: AppText.monoNum(14).copyWith(color: on ? AppColors.gold : AppColors.ink2)),
                ]),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('How many bags?', style: TextStyle(color: AppColors.ink2)),
          const SizedBox(width: 18),
          _qtyBtn(false),
          const SizedBox(width: 18),
          Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(13), border: Border.all(color: AppColors.hairline)), child: Center(child: Text('$_bags', style: AppText.display(18)))),
          const SizedBox(width: 18),
          _qtyBtn(true),
        ]),
      ],
    );
  }

  Widget _qtyBtn(bool add) {
    return GestureDetector(
      onTap: () => setState(() => _bags = (_bags + (add ? 1 : -1)).clamp(1, 99)),
      child: Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.hairline)), child: Icon(add ? Icons.add : Icons.remove, size: 18, color: AppColors.ink)),
    );
  }

  Widget _dateCard(String label, String value, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.hairline)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.ink))]),
          const Icon(Icons.calendar_today_rounded, color: AppColors.gold, size: 18),
        ]),
      ),
    );
  }

  Widget _timeCard(String label, String value, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.hairline)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)), const SizedBox(height: 4), Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.ink))]),
          const Icon(Icons.access_time_rounded, color: AppColors.gold, size: 18),
        ]),
      ),
    );
  }

  Widget _addressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.hairline)),
      child: Row(children: [
        const Icon(Icons.location_on_outlined, color: AppColors.gold, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(_pickupAddr, style: const TextStyle(color: AppColors.ink2, fontSize: 13.5))),
        TextButton(onPressed: () {}, child: const Text('Change', style: TextStyle(color: AppColors.gold))),
      ]),
    );
  }

  Widget _pickupStep() {
    return ListView(
      key: const ValueKey('pup'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      children: [
        Text('Schedule Pickup', style: AppText.display(19)),
        const SizedBox(height: 16),
        _dateCard('Pickup Date', DateFormat('EEE, MMM d').format(_pickupDate), () => _pickDate(true, (d) => setState(() => _pickupDate = d))),
        const SizedBox(height: 12),
        _timeCard('Pickup Time Window', _pickupTime.format(context), () => _pickTime(true, (t) => setState(() => _pickupTime = t))),
        const SizedBox(height: 12),
        _addressCard(),
        const SizedBox(height: 12),
        const Text('Our rider will arrive within the selected time window.', style: TextStyle(color: AppColors.muted, fontSize: 13)),
      ],
    );
  }

  Widget _deliveryStep() {
    return ListView(
      key: const ValueKey('del'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      children: [
        Text('Schedule Delivery', style: AppText.display(19)),
        const SizedBox(height: 16),
        _dateCard('When do you need it ready?', DateFormat('EEE, MMM d').format(_readyDate), _readyDatePick),
        const SizedBox(height: 12),
        _dateCard('Delivery Date', DateFormat('EEE, MMM d').format(_deliveryDate), () => _pickDate(false, (d) => setState(() => _deliveryDate = d))),
        const SizedBox(height: 12),
        _timeCard('Delivery Time Window', _deliveryTime.format(context), () => _pickTime(false, (t) => setState(() => _deliveryTime = t))),
        const SizedBox(height: 12),
        _addressCard(),
        const SizedBox(height: 12),
        const Text('We will deliver within the selected time window.', style: TextStyle(color: AppColors.muted, fontSize: 13)),
      ],
    );
  }

  Widget _paymentStep() {
    return ListView(
      key: const ValueKey('pay'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      children: [
        Text('Payment', style: AppText.display(19)),
        const SizedBox(height: 16),
        _summaryRow('Ride Fee', '₦${_rideFee.toStringAsFixed(2)}'),
        _summaryRow('Laundry (${_service?.name ?? ''} x$_bags)', '₦${_laundryTotal.toStringAsFixed(2)}'),
        const Divider(color: AppColors.hairline, height: 28),
        _summaryRow('Total Now', '₦${_totalNow.toStringAsFixed(2)}', bold: true),
        const SizedBox(height: 20),
        const Text('Laundry Payment', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.ink)),
        const SizedBox(height: 10),
        _payOption('now', 'Pay Now', 'Process laundry payment immediately'),
        _payOption('later', 'Pay Later', 'Pay when items are ready for delivery'),
        const SizedBox(height: 16),
        const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.ink)),
        const SizedBox(height: 10),
        _methodOption('wallet', Icons.account_balance_wallet_rounded, 'Wallet', '₦${_balance.toStringAsFixed(2)}'),
        _methodOption('card', Icons.credit_card_rounded, 'Card', 'Visa •••• 4242'),
        _methodOption('bank', Icons.account_balance_rounded, 'Bank Transfer', 'Transfer directly'),
      ],
    );
  }

  Widget _summaryRow(String l, String r, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l, style: TextStyle(color: AppColors.ink2, fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
        Text(r, style: AppText.monoNum(14).copyWith(color: bold ? AppColors.gold : AppColors.ink, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
      ]),
    );
  }

  Widget _payOption(String v, String t, String s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => setState(() => _laundryPayChoice = v),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: _laundryPayChoice == v ? AppColors.gold : AppColors.hairline, width: _laundryPayChoice == v ? 1.4 : 1)),
          child: Row(children: [
            Icon(_laundryPayChoice == v ? Icons.radio_button_checked : Icons.radio_button_off, color: _laundryPayChoice == v ? AppColors.gold : AppColors.muted, size: 20),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.ink)), const SizedBox(height: 2), Text(s, style: const TextStyle(color: AppColors.ink2, fontSize: 12))])),
          ]),
        ),
      ),
    );
  }

  Widget _methodOption(String v, IconData i, String t, String s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => setState(() => _paymentMethod = v),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: _paymentMethod == v ? AppColors.gold : AppColors.hairline, width: _paymentMethod == v ? 1.4 : 1)),
          child: Row(children: [
            Icon(i, color: AppColors.gold, size: 21),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.ink)), const SizedBox(height: 2), Text(s, style: const TextStyle(color: AppColors.ink2, fontSize: 12))])),
          ]),
        ),
      ),
    );
  }
}

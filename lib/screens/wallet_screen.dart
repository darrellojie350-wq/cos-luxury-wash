import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../services/supabase_service.dart';
import '../theme/colors.dart';
import '../widgets/common.dart';

/// CO's Luxury Wash — Wallet.
///
/// Large gold gradient balance card (Supabase-backed, shimmer while loading,
/// count-up on load/refresh), saved payment methods with staggered entrance,
/// pull-to-refresh, top-up and add-method bottom sheets.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  // ── state ────────────────────────────────────────────────────────────────
  double _balance = 0;
  bool _loading = true;
  bool _refreshing = false;

  final List<_PaymentMethod> _methods = [
    const _PaymentMethod(
      name: 'Card',
      detail: 'Visa •••• 4242',
      icon: Iconsax.card,
      isDefault: true,
    ),
    const _PaymentMethod(
      name: 'Wallet',
      detail: "CO's Wallet · Instant",
      icon: Iconsax.wallet_2,
    ),
    const _PaymentMethod(
      name: 'Bank Transfer',
      detail: '1–2 business days',
      icon: Iconsax.bank,
    ),
  ];

  int _selected = 0;

  // ── lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  // ── data ─────────────────────────────────────────────────────────────────
  Future<void> _loadBalance() async {
    if (mounted && _balance == 0 && !_loading) {
      setState(() => _loading = true);
    }
    try {
      final raw = await SupabaseService.getWalletBalance();
      final value = raw is num ? raw.toDouble() : 0.0;
      if (!mounted) return;
      setState(() {
        _balance = value;
        _loading = false;
        _refreshing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
      });
      _toast('Could not refresh balance — pull down to retry');
    }
  }

  // ── formatting ───────────────────────────────────────────────────────────
  String _naira(double v) => NumberFormat('#,##0.00').format(v);

  TextStyle _display(double size, {Color? color, FontWeight? weight}) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        color: color ?? AppColors.ink,
        fontWeight: weight,
      );

  TextStyle _monoNum({double size = 16, Color? color, FontWeight? weight}) =>
      GoogleFonts.ibmPlexMono(
        fontSize: size,
        color: color ?? AppColors.ink,
        fontWeight: weight,
        fontFeatures: [FontFeature.tabularFigures()],
      );

  TextStyle _inter(
          {double size = 14, Color? color, FontWeight? weight, double? spacing}) =>
      GoogleFonts.inter(
        fontSize: size,
        color: color ?? AppColors.ink,
        fontWeight: weight,
        letterSpacing: spacing,
      );

  TextStyle _capsLabel() => _inter(
        size: 11,
        color: AppColors.muted,
        weight: FontWeight.w600,
        spacing: 2.4,
      );

  // ── ui helpers ───────────────────────────────────────────────────────────
  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceHi,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.hairline),
          ),
          content: Row(
            children: [
              const Icon(Iconsax.tick_circle, size: 18, color: AppColors.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(msg, style: _inter(size: 13, color: AppColors.ink)),
              ),
            ],
          ),
        ),
      );
  }

  void _showTopUp() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _TopUpSheet(
        onConfirm: (amount) {
          Navigator.of(sheetCtx).pop();
          HapticFeedback.mediumImpact();
          setState(() => _balance += amount);
          _toast('₦${_naira(amount)} added to your wallet');
        },
      ),
    );
  }

  void _showAddMethod() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<_PaymentMethod>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddMethodSheet(),
    ).then((added) {
      if (added == null || !mounted) return;
      setState(() => _methods.add(added));
      _toast('${added.name} added to your wallet');
    });
  }

  // ── build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.base,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // soft champagne glow, top-right
            Positioned(
              top: -140,
              right: -120,
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.goldGlow,
                      AppColors.goldGlow.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            RefreshIndicator(
              onRefresh: _loadBalance,
              color: AppColors.gold,
              backgroundColor: AppColors.surfaceHi,
              displacement: 28,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildBalanceCard()),
                  SliverToBoxAdapter(child: _buildMethodsSection()),
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CosAnimate.fadeInUp(
                  delay: const Duration(milliseconds: 40),
                  child: Row(
                    children: [
                      const Icon(Iconsax.wallet_1,
                          size: 15, color: AppColors.gold),
                      const SizedBox(width: 8),
                      Text("CO'S LUXURY WASH", style: _capsLabel()),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                CosAnimate.fadeInUp(
                  delay: const Duration(milliseconds: 110),
                  child: Text(
                    'Wallet',
                    style: _display(34, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          CosAnimate.fadeInUp(
            delay: const Duration(milliseconds: 160),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () =>
                    _toast('Your balance updates in real time'),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceHi,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Iconsax.info_circle,
                      size: 20, color: AppColors.ink2),
                ),
              ),
            ).animate().fadeIn(duration: 500.ms).scale(
                begin: const Offset(0.7, 0.7),
                end: const Offset(1, 1),
                curve: Curves.easeOutBack),
          ),
        ],
      ),
    );
  }

  // ── balance card ─────────────────────────────────────────────────────────
  Widget _buildBalanceCard() {
    const goldInk = Color(0xFF17130B);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: CosAnimate.fadeInUp(
        delay: const Duration(milliseconds: 180),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _showTopUp,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.gold, AppColors.goldDeep],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.goldGlow,
                    blurRadius: 42,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // decorative arcs
                  Positioned(
                    top: -58,
                    right: -46,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.14),
                          width: 18,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -70,
                    left: 100,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                          width: 22,
                        ),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'AVAILABLE BALANCE',
                            style: _inter(
                              size: 11,
                              color: goldInk.withOpacity(0.65),
                              weight: FontWeight.w700,
                              spacing: 1.8,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Iconsax.shield_tick,
                              size: 17, color: goldInk),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 450),
                        transitionBuilder: (child, anim) =>
                            FadeTransition(opacity: anim, child: child),
                        child: _loading
                            ? const Padding(
                                key: ValueKey('balance-shimmer'),
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Shimmer.fromColors(
                                  baseColor: Color(0x55FFFFFF),
                                  highlightColor: Color(0xCCFFFFFF),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      width: 210,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : TweenAnimationBuilder<double>(
                                key: ValueKey('balance-${_balance}'),
                                tween: Tween(begin: 0, end: _balance),
                                duration: 950.ms,
                                curve: Curves.easeOutCubic,
                                builder: (_, value, __) => Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '₦',
                                        style: _display(30,
                                            color: goldInk,
                                            weight: FontWeight.w700),
                                      ),
                                      TextSpan(
                                        text: _naira(value),
                                        style: _monoNum(
                                          size: 40,
                                          color: goldInk,
                                          weight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: _showTopUp,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 11),
                                decoration: BoxDecoration(
                                  color: goldInk.withOpacity(0.92),
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: goldInk.withOpacity(0.28),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Iconsax.add,
                                        size: 16, color: AppColors.gold),
                                    const SizedBox(width: 7),
                                    Text(
                                      'Top Up',
                                      style: _inter(
                                        size: 13,
                                        color: AppColors.gold,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Iconsax.lock,
                              size: 12, color: goldInk),
                          const SizedBox(width: 5),
                          Text(
                            'Secured',
                            style: _inter(
                              size: 11,
                              color: goldInk.withOpacity(0.7),
                              weight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── payment methods ──────────────────────────────────────────────────────
  Widget _buildMethodsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CosAnimate.fadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Payment Methods',
                  style: _display(22, weight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '${_methods.length} saved',
                  style:
                      _monoNum(size: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // staggered method list
          for (var i = 0; i < _methods.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CosAnimate.fadeInUp(
                delay: Duration(milliseconds: 240 + i * 70),
                child: _MethodTile(
                  method: _methods[i],
                  selected: _selected == i,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selected = i);
                  },
                ),
              ),
            ),
          // add method
          CosAnimate.fadeInUp(
            delay: Duration(milliseconds: 240 + _methods.length * 70),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _showAddMethod,
                child: CosCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppColors.goldGlow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.gold.withOpacity(0.4)),
                        ),
                        child: const Icon(Iconsax.add_square,
                            size: 18, color: AppColors.gold),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Add Payment Method',
                        style: _inter(
                          size: 14,
                          color: AppColors.ink2,
                          weight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Iconsax.arrow_right_3,
                          size: 18, color: AppColors.muted),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: CosAnimate.fadeInUp(
              delay: const Duration(milliseconds: 560),
              child: Text(
                'Top ups settle instantly · funds are fully secure',
                style: _inter(size: 11.5, color: AppColors.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── payment method model ──────────────────────────────────────────────────
class _PaymentMethod {
  final String name, detail;
  final IconData icon;
  final bool isDefault;
  const _PaymentMethod({
    required this.name,
    required this.detail,
    required this.icon,
    this.isDefault = false,
  });
}

// ── method tile ───────────────────────────────────────────────────────────
class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final _PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.015 : 1.0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: CosCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.goldGlow
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? AppColors.gold.withOpacity(0.55)
                          : AppColors.hairline,
                    ),
                  ),
                  child: Icon(
                    method.icon,
                    size: 20,
                    color: selected ? AppColors.gold : AppColors.ink2,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            method.name,
                            style: _inter(
                              size: 14.5,
                              weight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          if (method.isDefault) ...[
                            const SizedBox(width: 9),
                            const StatusPill(
                              label: 'Default',
                              tone: StatusTone.gold,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        method.detail,
                        style:
                            _monoNum(size: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: selected
                      ? const Icon(Iconsax.tick_circle,
                          key: ValueKey('tick'),
                          size: 19,
                          color: AppColors.gold)
                      : const Icon(Iconsax.arrow_right_3,
                          key: ValueKey('chev'),
                          size: 18,
                          color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── top up sheet ──────────────────────────────────────────────────────────
class _TopUpSheet extends StatefulWidget {
  const _TopUpSheet({required this.onConfirm});

  final ValueChanged<double> onConfirm;

  @override
  State<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends State<_TopUpSheet> {
  static const _quick = [5000.0, 10000.0, 20000.0];
  int _chip = 0;
  final _customCtrl = TextEditingController();

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  double get _amount =>
      double.tryParse(_customCtrl.text.trim().replaceAll(',', '')) ??
      _quick[_chip];

  void _confirm() {
    final amt = _amount;
    if (amt <= 0) return;
    widget.onConfirm(amt);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.hairline,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Top Up Wallet',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose an amount to add to your balance',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < _quick.length; i++)
                  _AmountChip(
                    label: '₦${NumberFormat('#,##0').format(_quick[i])}',
                    selected: _chip == i,
                    onTap: () {
                      _customCtrl.clear();
                      setState(() => _chip = i);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 14),
            CosTextField(
              controller: _customCtrl,
              hint: 'Or enter a custom amount (₦)',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 18),
            CosPrimaryButton(
              label: 'Add Funds',
              onPressed: _confirm,
            ),
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Iconsax.lock,
                      size: 12, color: AppColors.gold),
                  const SizedBox(width: 6),
                  Text(
                    'Instant settlement on all top ups',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── amount chip ───────────────────────────────────────────────────────────
class _AmountChip extends StatelessWidget {
  const _AmountChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.goldGlow : AppColors.surfaceHi,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.gold.withOpacity(0.7)
                  : AppColors.hairline,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? AppColors.gold : AppColors.ink2,
            ),
          ),
        ),
      ),
    );
  }
}

// ── add method sheet ──────────────────────────────────────────────────────
class _AddMethodSheet extends StatelessWidget {
  const _AddMethodSheet();

  static const _options = [
    _PaymentMethod(name: 'Card', detail: 'Visa, Mastercard, Verve', icon: Iconsax.card),
    _PaymentMethod(name: 'Wallet', detail: "CO's Wallet balance", icon: Iconsax.wallet_2),
    _PaymentMethod(name: 'Bank Transfer', detail: 'Pay via your bank app', icon: Iconsax.bank),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Add Payment Method',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'How would you like to pay?',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          for (final option in _options)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(option),
                  behavior: HitTestBehavior.opaque,
                  child: CosCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHi,
                            borderRadius: BorderRadius.circular(13),
                            border: const BorderSide(
                                color: AppColors.hairline),
                          ),
                          child: Icon(option.icon,
                              size: 19, color: AppColors.ink2),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.name,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                option.detail,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Iconsax.arrow_right_3,
                            size: 18, color: AppColors.muted),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

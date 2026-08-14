import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/supabase_service.dart';
import '../theme/colors.dart';
import '../widgets/common.dart';

/// CO's Luxury Wash — Profile.
/// Premium dark-luxury account screen: gold-ring avatar header, staggered
/// menu list with gold chevrons, and a destructive log-out action.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final p = await SupabaseService.getProfile();
    if (!mounted) return;
    setState(() {
      _profile = p;
      _loading = false;
    });
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    await SupabaseService.signOut();
    if (!mounted) return;
    context.go('/auth');
  }

  String get _name => (_profile?['full_name'] ?? '').toString().isEmpty
      ? 'Guest'
      : _profile!['full_name'];
  String get _email => (_profile?['email'] ?? '').toString();
  String get _avatarUrl => (_profile?['avatar_url'] ?? '').toString();

  String get _initials {
    final parts = _name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts.last.isNotEmpty) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return _name.isNotEmpty ? _name[0].toUpperCase() : 'C';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            const SizedBox(height: 8),
            _sectionLabel('ACCOUNT'),
            const SizedBox(height: 14),
            _buildHeader(),
            const SizedBox(height: 28),
            _buildMenu(),
            const SizedBox(height: 32),
            _buildLogout(),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.4,
        color: AppColors.muted,
      ),
    );
  }

  Widget _buildHeader() {
    if (_loading) return _headerSkeleton();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _email.isEmpty ? 'No email on file' : _email,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.ink2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceHi,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.hairline),
            ),
            child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.muted),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .moveY(begin: 18, end: 0, duration: 400.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildAvatar() {
    final hasImage = _avatarUrl.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.gold, AppColors.goldDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(color: AppColors.goldGlow, blurRadius: 16, spreadRadius: 1),
        ],
      ),
      child: CircleAvatar(
        radius: 30,
        backgroundColor: AppColors.surfaceHi,
        backgroundImage: hasImage ? NetworkImage(_avatarUrl) : null,
        onBackgroundImageError: hasImage
            ? (_, __) {
                setState(() => _profile?['avatar_url'] = null);
              }
            : null,
        child: hasImage
            ? null
            : Text(
                _initials,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gold,
                ),
              ),
      ),
    );
  }

  Widget _headerSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 33, backgroundColor: AppColors.surfaceHi),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 140, height: 18, color: AppColors.surfaceHi),
                const SizedBox(height: 10),
                Container(width: 90, height: 12, color: AppColors.surfaceHi),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu() {
    final items = <_MenuItem>[
      _MenuItem(Icons.location_on_outlined, 'Addresses', route: null),
      _MenuItem(Icons.receipt_long_outlined, 'My Orders', route: '/orders'),
      _MenuItem(Icons.credit_card_outlined, 'Payment Methods', route: null),
      _MenuItem(Icons.account_balance_wallet_outlined, 'Wallet', route: '/wallet'),
      _MenuItem(Icons.notifications_outlined, 'Notifications', route: null),
      _MenuItem(Icons.help_outline, 'Help & Support', route: null),
      _MenuItem(Icons.settings_outlined, 'Settings', route: null),
    ];

    return CosCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            CosAnimate.fadeInUp(
              child: _menuRow(items[i]),
              delay: Duration(milliseconds: 70 * i),
            ),
            if (i != items.length - 1)
              Divider(height: 1, thickness: 1, color: AppColors.hairline, indent: 64),
          ],
        ],
      ),
    );
  }

  Widget _menuRow(_MenuItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onMenuTap(item),
        splashColor: AppColors.goldGlow,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHi,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(item.icon, size: 19, color: AppColors.ink2),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, size: 22, color: AppColors.gold),
            ],
          ),
        ),
      ),
    );
  }

  void _onMenuTap(_MenuItem item) {
    final route = item.route;
    if (route != null) {
      context.go(route);
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceHi,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            '${item.label} — coming soon',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink2),
          ),
        ),
      );
  }

  Widget _buildLogout() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: _signingOut ? null : _signOut,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.danger, width: 1.4),
          foregroundColor: AppColors.danger,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _signingOut
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.danger,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_outlined, size: 19),
                  const SizedBox(width: 10),
                  Text(
                    'Log Out',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 520.ms).moveY(begin: 16, end: 0);
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String? route;
  const _MenuItem(this.icon, this.label, {this.route});
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../services/supabase_service.dart';
import '../theme/colors.dart';
import '../widgets/common.dart';

/// Guards the one-shot boot redirect so rebuilds/hot-reload never stack timers.
bool _bootRedirectScheduled = false;

/// SplashScreen — animated boot for CO's Luxury Wash.
///
/// Centered gold laundry-basket mark (traced 1:1 from `web/favicon.svg`)
/// scales in over a pulsing gold glow, the wordmark shimmers in with a
/// staggered fade/rise, and after 1.8s the app redirects to `/home` when a
/// Supabase session exists, otherwise `/auth`.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const Duration _bootDuration = Duration(milliseconds: 1800);

  @override
  Widget build(BuildContext context) {
    _scheduleBootRedirect(context);
    return Scaffold(
      backgroundColor: AppColors.base,
      body: ColoredBox(
        color: AppColors.base,
        child: Stack(
          children: [
            const Positioned.fill(child: _AmbientBackdrop()),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    _buildLogo(),
                    const SizedBox(height: 44),
                    _buildWordmark(),
                    const SizedBox(height: 16),
                    _buildTagline(),
                    const Spacer(flex: 2),
                    _buildFooter(),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleBootRedirect(BuildContext context) {
    if (_bootRedirectScheduled) return;
    _bootRedirectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Timer(_bootDuration, () {
        if (!context.mounted) return;
        context.go(SupabaseService.isLoggedIn ? '/home' : '/auth');
      });
    });
  }

  Widget _buildLogo() {
    return SizedBox(
      width: 176,
      height: 176,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient gold glow that breathes behind the mark.
          const Positioned.fill(
            child: _BreathingGlow(),
          ),
          // Entrance: one-shot spring-like scale-in from the shared widget.
          CosAnimate.scaleIn(
            delay: const Duration(milliseconds: 120),
            duration: const Duration(milliseconds: 900),
            child: const _LogoMark(),
          ),
        ],
      ),
    );
  }

  Widget _buildWordmark() {
    return Shimmer.fromColors(
      baseColor: AppColors.gold,
      highlightColor: const Color(0xFFEBD9A6),
      period: const Duration(milliseconds: 2600),
      child: Text(
        "CO's Luxury Wash",
        textAlign: TextAlign.center,
        style: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: AppColors.gold,
        ),
      ),
    )
        .animate(
          delay: const Duration(milliseconds: 150),
          onComplete: (_) {},
        )
        .fadeIn(duration: const Duration(milliseconds: 800), curve: Curves.easeOut)
        .moveY(begin: 18, end: 0, duration: const Duration(milliseconds: 800), curve: Curves.easeOutCubic);
  }

  Widget _buildTagline() {
    return Text(
      'Laundry, elevated.',
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: AppColors.ink2,
      ),
    )
        .animate(delay: const Duration(milliseconds: 320))
        .fadeIn(duration: const Duration(milliseconds: 700))
        .moveY(begin: 14, end: 0, duration: const Duration(milliseconds: 700), curve: Curves.easeOutCubic);
  }

  Widget _buildFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 120, height: 1, color: AppColors.hairline),
        const SizedBox(height: 18),
        Text(
          'PREMIUM ON-DEMAND LAUNDRY & DRY CLEANING',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.6,
            color: AppColors.muted,
          ),
        ),
      ],
    )
        .animate(delay: const Duration(milliseconds: 460))
        .fadeIn(duration: const Duration(milliseconds: 800))
        .moveY(begin: 12, end: 0, duration: const Duration(milliseconds: 800), curve: Curves.easeOutCubic);
  }
}

/// Soft dark vignette with a faint gold wash near the top — depth, no noise.
class _AmbientBackdrop extends StatelessWidget {
  const _AmbientBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.55),
          radius: 1.25,
          colors: [
            AppColors.goldGlow.withValues(alpha: 0.55),
            AppColors.base.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.surface.withValues(alpha: 0.35),
              AppColors.base,
              AppColors.base,
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Pulsing radial gold halo behind the logo mark.
class _BreathingGlow extends StatelessWidget {
  const _BreathingGlow();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.goldGlow.withValues(alpha: 0.9),
            AppColors.goldGlow.withValues(alpha: 0.0),
          ],
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: const Duration(milliseconds: 1800), curve: Curves.easeInOut);
  }
}

/// The favicon mark: rounded surface tile, hairline gold border, soft glow,
/// and the laundry basket drawn from `web/favicon.svg` path data.
class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldGlow,
            blurRadius: 34,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(26),
        child: SizedBox(
          width: 80,
          height: 80,
          child: CustomPaint(painter: _LaundryMarkPainter()),
        ),
      ),
    );
  }
}

/// Traces the favicon's laundry basket 1:1 in gold stroke:
/// basket body, handle arc, and the folded-laundry glyph circle.
class _LaundryMarkPainter extends CustomPainter {
  const _LaundryMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 36.0;
    canvas.save();
    canvas.scale(scale, scale);

    final stroke = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    // Basket body: M4 5h28l-3 24H7L4 5z
    final body = Path()
      ..moveTo(4, 5)
      ..lineTo(32, 5)
      ..lineTo(29, 29)
      ..lineTo(7, 29)
      ..close();
    canvas.drawPath(body, stroke);

    // Handle: M12 5V3a3 3 0 013-3h10a3 3 0 013 3v2
    final handle = Path()
      ..moveTo(12, 5)
      ..lineTo(12, 3)
      ..arcToPoint(const Offset(15, 0), radius: const Radius.circular(3))
      ..lineTo(25, 0)
      ..arcToPoint(const Offset(28, 3), radius: const Radius.circular(3))
      ..lineTo(28, 5);
    canvas.drawPath(handle, stroke);

    // Laundry glyph: circle cx=18 cy=20 r=5
    canvas.drawCircle(const Offset(18, 20), 5, stroke);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LaundryMarkPainter oldDelegate) => false;
}

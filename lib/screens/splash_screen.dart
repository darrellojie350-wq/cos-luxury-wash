import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../services/supabase_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1900), () {
      if (mounted) context.go(SupabaseService().isLoggedIn ? '/home' : '/auth');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.gold, AppColors.goldDeep], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 4)],
          ),
          child: const Icon(Icons.local_laundry_service_rounded, color: Color(0xFF1A1407), size: 44),
        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 26),
        Text("CO's Luxury Wash", style: GoogleFonts.playfairDisplay(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.ink)).animate().fadeIn(delay: 400.ms).moveY(begin: 12, end: 0, delay: 400.ms),
        const SizedBox(height: 6),
        Text('Clean Clothes, Easy Life', style: GoogleFonts.inter(fontSize: 14, color: AppColors.muted)).animate().fadeIn(delay: 700.ms),
      ])),
    );
  }
}

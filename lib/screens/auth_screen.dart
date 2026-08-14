import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/colors.dart';
import '../services/supabase_service.dart';
import '../widgets/common.dart';

/// AuthScreen — Login / Signup for CO's Luxury Wash.
///
/// A gold pill toggle switches between the two modes on the same screen for a
/// smooth, stateless-feeling transition. Each form is built from the shared
/// `common.dart` widgets (CosCard, CosTextField, CosAnimate) and enters with a
/// fade-in-rise. Supabase auth calls delegate to [SupabaseService]; on success
/// the router hands off to `/home`.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.isLogin = true});

  /// True → Login form, False → Signup form. Drives the default toggle state.
  final bool isLogin;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _isLogin = widget.isLogin;

  // ---- form state -----------------------------------------------------------
  final _auth = SupabaseService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();

  bool _obscure = true;
  bool _agreeTerms = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _fullName.dispose();
    _phone.dispose();
    super.dispose();
  }

  // ---- theme helpers (mirror splash_screen's proven font idiom) --------------
  TextStyle _display(double size, Color color) => GoogleFonts.playfairDisplay(
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      );

  TextStyle _inter({
    double size = 14,
    Color? color,
    FontWeight weight = FontWeight.w400,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: letterSpacing,
      );

  // ---- actions --------------------------------------------------------------
  Future<void> _submit() async {
    setState(() {
      _error = null;
      _loading = true;
    });

    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Please fill in all required fields.';
      });
      return;
    }

    try {
      if (_isLogin) {
        await _auth.signInEmail(email, password);
      } else {
        if (!_agreeTerms) {
          setState(() {
            _loading = false;
            _error = 'Please accept the terms to continue.';
          });
          return;
        }
        await _auth.signUpEmail(
          email,
          password,
          fullName: _fullName.text.trim(),
          phone: _phone.text.trim(),
        );
      }
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      setState(() {
        _loading = false;
        _error = _friendlyError(e.toString());
      });
    }
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('invalid login') || lower.contains('invalid credentials')) {
      return 'Incorrect email or password.';
    }
    if (lower.contains('email') && lower.contains('already')) {
      return 'An account with this email already exists.';
    }
    if (lower.contains('password') && lower.contains('weak')) {
      return 'Choose a stronger password (8+ chars).';
    }
    return 'Something went wrong. Please try again.';
  }

  void _showForgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceHi,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.hairline),
        ),
        content: Text('A reset link will be sent to your email.',
            style: _inter(color: AppColors.ink2)),
      ),
    );
  }

  // ---- build ----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.base,
      body: Stack(
        children: [
          const Positioned.fill(child: _AmbientBackdrop()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBackArrow(),
                  const SizedBox(height: 24),
                  _buildLogo(),
                  const SizedBox(height: 32),
                  _buildFormCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackArrow() {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: () => context.go('/splash'),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        style: IconButton.styleFrom(
          foregroundColor: AppColors.ink2,
          backgroundColor: AppColors.surface.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.hairline),
          ),
        ),
        tooltip: 'Back',
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.gold.withOpacity(0.4), width: 1),
            boxShadow: [
              BoxShadow(color: AppColors.goldGlow, blurRadius: 28, spreadRadius: 6),
              BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 12)),
            ],
          ),
          child: const Icon(Icons.local_laundry_service_rounded, color: AppColors.gold, size: 40),
        ),
        const SizedBox(height: 22),
        Shimmer.fromColors(
          baseColor: AppColors.gold,
          highlightColor: const Color(0xFFEBD9A6),
          period: const Duration(milliseconds: 2600),
          child: Text("CO's Luxury Wash", textAlign: TextAlign.center, style: _display(26, AppColors.gold)),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return CosAnimate.fadeInUp(
      _formCard(),
      delay: 80,
    );
  }

  Widget _formCard() {
    return CosCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildModeToggle(),
          const SizedBox(height: 28),
          if (_error != null) ...[
            _buildErrorBanner(),
            const SizedBox(height: 20),
          ],
          ..._buildFields(),
          const SizedBox(height: 24),
          _buildSubmitButton(),
          const SizedBox(height: 22),
          _buildDivider(),
          const SizedBox(height: 22),
          _buildSocialButtons(),
          const SizedBox(height: 26),
          _buildSwitchLink(),
        ],
      ),
    );
  }

  // ---- mode toggle ----------------------------------------------------------
  Widget _buildModeToggle() {
    return LayoutBuilder(builder: (context, constraints) {
      final pillWidth = (constraints.maxWidth - 8) / 2;
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.base,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubic,
              top: 4,
              bottom: 4,
              left: _isLogin ? 4 : null,
              right: _isLogin ? null : 4,
              width: pillWidth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gold, AppColors.goldDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: AppColors.goldGlow, blurRadius: 16, spreadRadius: 2),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(child: _toggleOption('Login', true)),
                Expanded(child: _toggleOption('Sign Up', false)),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _toggleOption(String label, bool loginMode) {
    final active = _isLogin == loginMode;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _isLogin = loginMode),
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: _inter(size: 15, weight: FontWeight.w600, color: active ? AppColors.base : AppColors.muted),
          child: Text(label),
        ),
      ),
    );
  }

  // ---- fields ---------------------------------------------------------------
  List<Widget> _buildFields() {
    if (_isLogin) {
      return [
        CosTextField(
          controller: _email,
          label: 'Email address',
          hint: 'you@example.com',
          icon: Icons.mail_outline_rounded,
          keyboard: TextInputType.emailAddress,
        ),
        const SizedBox(height: 18),
        CosTextField(
          controller: _password,
          label: 'Password',
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          obscure: true,
          suffix: IconButton(
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
            color: AppColors.muted,
            tooltip: _obscure ? 'Show password' : 'Hide password',
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _showForgotPassword,
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: Text('Forgot password?', style: _inter(size: 13, color: AppColors.gold, weight: FontWeight.w500)),
          ),
        ),
      ];
    }

    return [
      CosTextField(
        controller: _fullName,
        label: 'Full name',
        hint: 'Jane Doe',
        icon: Icons.person_outline_rounded,
      ),
      const SizedBox(height: 18),
      CosTextField(
        controller: _email,
        label: 'Email address',
        hint: 'you@example.com',
        icon: Icons.mail_outline_rounded,
        keyboard: TextInputType.emailAddress,
      ),
      const SizedBox(height: 18),
      CosTextField(
        controller: _phone,
        label: 'Phone number',
        hint: '+234 800 000 0000',
        icon: Icons.phone_outlined,
        keyboard: TextInputType.phone,
      ),
      const SizedBox(height: 18),
      CosTextField(
        controller: _password,
        label: 'Password',
        hint: 'Min. 8 characters',
        icon: Icons.lock_outline_rounded,
        obscure: true,
        suffix: IconButton(
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
          color: AppColors.muted,
          tooltip: _obscure ? 'Show password' : 'Hide password',
        ),
      ),
      const SizedBox(height: 16),
      _buildTermsCheckbox(),
    ];
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreeTerms,
            onChanged: (v) => setState(() => _agreeTerms = v ?? false),
            activeColor: AppColors.gold,
            checkColor: AppColors.base,
            side: const BorderSide(color: AppColors.muted, width: 1.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'I agree to the Terms of Service and Privacy Policy.',
            style: _inter(size: 13, color: AppColors.ink2),
          ),
        ),
      ],
    );
  }

  // ---- submit + social + link ----------------------------------------------
  Widget _buildSubmitButton() {
    final label = _isLogin ? 'Log In' : 'Create Account';
    return _GlowButton(
      loading: _loading,
      onPressed: _submit,
      label: label,
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppColors.hairline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('or continue with', style: _inter(size: 12, color: AppColors.muted)),
        ),
        Expanded(child: Container(height: 1, color: AppColors.hairline)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Column(
      children: [
        _SocialButton(
          label: 'Continue with Google',
          icon: Icons.g_mobiledata,
          onPressed: () => _socialToast('Google'),
        ),
        const SizedBox(height: 14),
        _SocialButton(
          label: 'Continue with Apple',
          icon: Icons.apple,
          onPressed: () => _socialToast('Apple'),
        ),
      ],
    );
  }

  void _socialToast(String brand) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1600),
        backgroundColor: AppColors.surfaceHi,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.hairline)),
        content: Text('$brand sign-in coming soon.', style: _inter(color: AppColors.ink2)),
      ),
    );
  }

  Widget _buildSwitchLink() {
    final question = _isLogin ? "Don't have an account?" : 'Already have an account?';
    final action = _isLogin ? 'Sign Up' : 'Log In';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(question, style: _inter(size: 14, color: AppColors.ink2)),
        GestureDetector(
          onTap: () => setState(() {
            _error = null;
            _isLogin = !_isLogin;
          }),
          child: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text(action, style: _inter(size: 14, color: AppColors.gold, weight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  // ---- error banner ---------------------------------------------------------
  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: BorderSide(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(_error!, style: _inter(size: 13, color: AppColors.danger, weight: FontWeight.w500))),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 250)).shakeX(amount: 4, duration: const Duration(milliseconds: 350));
  }
}

// =============================================================================
// Private premium primitives — visual layer for the auth screen only.
// =============================================================================

/// Soft dark vignette with a faint gold wash up top. Reused from the splash
/// aesthetic so every screen shares the same depth.
class _AmbientBackdrop extends StatelessWidget {
  const _AmbientBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.55),
          radius: 1.3,
          colors: [AppColors.goldGlow.withOpacity(0.5), AppColors.base.withOpacity(0)],
          stops: const [0.0, 1.0],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surface.withOpacity(0.3), AppColors.base, AppColors.base],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Gold CTA with a soft glow halo. Shows a spinner while [loading] and a
/// spring-like press scale micro-interaction.
class _GlowButton extends StatefulWidget {
  const _GlowButton({required this.label, required this.onPressed, required this.loading});
  final String label;
  final VoidCallback onPressed;
  final bool loading;

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton> with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 120), lowerBound: 0.96, upperBound: 1);

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _press,
      builder: (context, child) => Transform.scale(scale: _press.value, child: child),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [AppColors.gold, AppColors.goldDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: AppColors.gold.withOpacity(0.45), blurRadius: 22, spreadRadius: 2, offset: const Offset(0, 8)),
            BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTapDown: (_) => _press.reverse(),
            onTapUp: (_) => _press.forward(),
            onTapCancel: () => _press.forward(),
            onTap: widget.loading ? null : widget.onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: widget.loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.base),
                    )
                  : Text(widget.label,
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.base, letterSpacing: 0.4)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined brand pill for social sign-in.
class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.icon, required this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22, color: AppColors.ink),
        label: Text(label, style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w500, color: AppColors.ink)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.hairline, width: 1.2),
          backgroundColor: AppColors.surface.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}

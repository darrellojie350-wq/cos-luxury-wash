import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../theme/theme.dart';
import '../services/supabase_service.dart';
import '../widgets/common.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.isLogin = true});
  final bool isLogin;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _isLogin = widget.isLogin;
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _obscure = true;
  bool _terms = false;
  bool _busy = false;
  String? _err;

  @override
  void dispose() { _email.dispose(); _pass.dispose(); _name.dispose(); _phone.dispose(); super.dispose(); }

  Future<void> _submit() async {
    setState(() { _err = null; _busy = true; });
    final api = SupabaseService();
    try {
      if (_isLogin) {
        await api.signInEmail(_email.text.trim(), _pass.text);
      } else {
        if (!_terms) { setState(() { _err = 'Please agree to Terms & Conditions'; _busy = false; }); return; }
        await api.signUpEmail(_email.text.trim(), _pass.text, fullName: _name.text.trim(), phone: _phone.text.trim());
      }
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) setState(() => _err = e.toString().replaceFirst('Exception: ', ''));
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.ink2, size: 18), onPressed: () => context.go('/splash'))),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _toggle(),
        const SizedBox(height: 22),
        if (_err != null) Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.error_outline, color: AppColors.danger, size: 18), const SizedBox(width: 8), Expanded(child: Text(_err!, style: const TextStyle(color: AppColors.danger, fontSize: 13)))])),
        if (!_isLogin) ...[
          CosTextField(controller: _name, label: 'Full Name', icon: Icons.person_outline_rounded),
          const SizedBox(height: 14),
        ],
        CosTextField(controller: _email, label: 'Email or Phone', icon: Icons.alternate_email_rounded, keyboard: TextInputType.emailAddress),
        const SizedBox(height: 14),
        CosTextField(controller: _pass, label: 'Password', icon: Icons.lock_outline_rounded, obscure: _obscure, suffix: IconButton(icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.muted, size: 20), onPressed: () => setState(() => _obscure = !_obscure))),
        if (_isLogin) ...[
          const SizedBox(height: 8), Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: const Text('Forgot Password?', style: TextStyle(color: AppColors.gold, fontSize: 13)))),
        ],
        if (!_isLogin) ...[
          const SizedBox(height: 14),
          Row(children: [Checkbox(value: _terms, onChanged: (v) => setState(() => _terms = v ?? false), activeColor: AppColors.gold), Expanded(child: Text('I agree to the Terms & Conditions and Privacy Policy', style: const TextStyle(color: AppColors.ink2, fontSize: 13)))]),
        ],
        const SizedBox(height: 24),
        CosPrimaryButton(label: _busy ? 'Please wait...' : (_isLogin ? 'Login' : 'Create Account'), enabled: !_busy, onPressed: _submit),
        const SizedBox(height: 20), const Row(children: [Expanded(child: Divider(color: AppColors.hairline)), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('or', style: TextStyle(color: AppColors.muted))), Expanded(child: Divider(color: AppColors.hairline))]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _social(Icons.g_mobiledata_rounded, 'Google')),
          const SizedBox(width: 12),
          Expanded(child: _social(Icons.apple_rounded, 'Apple')),
        ]),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_isLogin ? "Don't have an account?" : 'Already have an account?', style: const TextStyle(color: AppColors.ink2, fontSize: 13)), TextButton(onPressed: () => setState(() => _isLogin = !_isLogin), child: Text(_isLogin ? 'Sign Up' : 'Login', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600)))]),
      ]))),
    );
  }

  Widget _toggle() {
    return Container(
      height: 52, decoration: BoxDecoration(color: AppColors.surfaceHi, borderRadius: BorderRadius.circular(14)),
      child: Stack(children: [
        AnimatedPositioned(left: _isLogin ? 0 : MediaQuery.of(context).size.width / 2 - 22, duration: 280.ms, curve: Curves.easeOut, top: 0, bottom: 0, width: (MediaQuery.of(context).size.width - 44) / 2, child: Container(margin: const EdgeInsets.all(4), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.gold, AppColors.goldDeep]), borderRadius: BorderRadius.circular(11)),)),
        Row(children: [
          Expanded(child: GestureDetector(onTap: () => setState(() => _isLogin = true), child: Center(child: Text('Login', style: TextStyle(fontWeight: FontWeight.w600, color: _isLogin ? const Color(0xFF1A1407) : AppColors.ink2))))),
          Expanded(child: GestureDetector(onTap: () => setState(() => _isLogin = false), child: Center(child: Text('Sign Up', style: TextStyle(fontWeight: FontWeight.w600, color: !_isLogin ? const Color(0xFF1A1407) : AppColors.ink2))))),
        ]),
      ]),
    );
  }

  Widget _social(IconData i, String l) => Container(height: 52, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.hairline)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(i, size: 22, color: AppColors.ink), const SizedBox(width: 8), Text(l, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w500))]));
}

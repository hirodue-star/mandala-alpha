import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'character_select_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メールアドレスとパスワードを入力してください')),
      );
      return;
    }
    setState(() => _isLoading = true);
    // TODO: Firebase Auth 連携
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) _goHome();
  }

  Future<void> _loginWithApple() async {
    setState(() => _isLoading = true);
    // TODO: Apple Sign-In 連携
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) _goHome();
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    // TODO: Google Sign-In 連携
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) _goHome();
  }

  void _loginAsGuest() => _goHome();

  void _goHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const CharacterSelectScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            children: [
              // ロゴ
              _Logo().animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),
              const SizedBox(height: 48),

              // メール入力フォーム
              _EmailForm(
                emailController: _emailController,
                passwordController: _passwordController,
                isLoading: _isLoading,
                onLogin: _loginWithEmail,
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 500.ms)
                  .slideY(begin: 0.1),

              const SizedBox(height: 24),
              _Divider().animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 24),

              // ソーシャルログイン
              _SocialLoginButtons(
                isLoading: _isLoading,
                onApple: _loginWithApple,
                onGoogle: _loginWithGoogle,
              )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 500.ms),

              const SizedBox(height: 20),

              // ゲストログイン（開発・テスト用）
              _GuestLoginButton(
                isLoading: _isLoading,
                onTap: _loginAsGuest,
              ).animate().fadeIn(delay: 650.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── ロゴ ──────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C4DFF), Color(0xFFB47FFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C4DFF).withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text('✨', style: TextStyle(fontSize: 44)),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'マンダラα',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A4A6A),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'こどもの力を育てる 曼荼羅チャート',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }
}

// ─── メールフォーム ─────────────────────────────────────────

class _EmailForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onLogin;

  const _EmailForm({
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        children: [
          _InputField(
            controller: emailController,
            hint: 'メールアドレスを入力',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _InputField(
            controller: passwordController,
            hint: 'パスワードを入力',
            icon: Icons.lock_outline,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onLogin(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: isLoading ? null : onLogin,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('ログイン'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 入力フィールド ─────────────────────────────────────────

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF9E9EBE), size: 20),
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBBBBCC), fontSize: 15),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8E4FF), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ─── 区切り線 ───────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('または',
              style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ),
        Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
      ],
    );
  }
}

// ─── ソーシャルログイン ─────────────────────────────────────

class _SocialLoginButtons extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onApple;
  final VoidCallback onGoogle;

  const _SocialLoginButtons({
    required this.isLoading,
    required this.onApple,
    required this.onGoogle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SocialButton(
          label: 'Appleでログイン',
          icon: '🍎',
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          onTap: isLoading ? null : onApple,
        ),
        const SizedBox(height: 12),
        _SocialButton(
          label: 'Googleでログイン',
          icon: 'G',
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF4A4A6A),
          borderColor: const Color(0xFFE0D7FF),
          onTap: isLoading ? null : onGoogle,
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final String icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: BorderSide(color: borderColor ?? backgroundColor, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon,
                style: TextStyle(
                    fontSize: icon.length == 1 && icon == 'G' ? 16 : 18,
                    color: icon == 'G'
                        ? const Color(0xFF4285F4)
                        : foregroundColor,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            Text(label),
          ],
        ),
      ),
    );
  }
}

// ─── ゲストログイン（開発・テスト用） ──────────────────────

class _GuestLoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _GuestLoginButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Colors.grey[300],
                thickness: 1,
                endIndent: 12,
              ),
            ),
            Text(
              'または',
              style: TextStyle(color: Colors.grey[400], fontSize: 11),
            ),
            Expanded(
              child: Divider(
                color: Colors.grey[300],
                thickness: 1,
                indent: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF7C4DFF),
              side: const BorderSide(
                  color: Color(0xFFD0C4FF), width: 1.5,
                  style: BorderStyle.solid),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
            onPressed: isLoading ? null : onTap,
            icon: const Text('🐣', style: TextStyle(fontSize: 18)),
            label: const Text('ゲストとして開始（テスト用）'),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '※ アカウントなしでプピィを試せます',
          style: TextStyle(color: Colors.grey[400], fontSize: 11),
        ),
      ],
    );
  }
}

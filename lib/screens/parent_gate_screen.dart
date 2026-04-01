import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ─────────────────────────────────────────────────────────
// ParentGateScreen — 保護者認証ゲート
//
// 2つの認証方式:
//   A) 3秒間 長押し（プレスホールド）
//   B) 簡単な計算問題（掛け算）
// ─────────────────────────────────────────────────────────

class ParentGateScreen extends StatefulWidget {
  const ParentGateScreen({super.key});
  @override
  State<ParentGateScreen> createState() => _ParentGateScreenState();
}

class _ParentGateScreenState extends State<ParentGateScreen>
    with SingleTickerProviderStateMixin {
  bool _showMath = false;

  late final AnimationController _holdCtrl;
  bool _isHolding = false;
  bool _unlocked = false;

  // 計算問題
  late int _a, _b;
  final _mathCtrl = TextEditingController();
  String? _mathError;

  @override
  void initState() {
    super.initState();
    _regenerateMath();
    _holdCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _holdCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && !_unlocked) {
        setState(() => _unlocked = true);
        Future.delayed(500.ms, () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    });
  }

  void _regenerateMath() {
    final rng = Random();
    _a = rng.nextInt(9) + 2;
    _b = rng.nextInt(9) + 2;
  }

  @override
  void dispose() {
    _holdCtrl.dispose();
    _mathCtrl.dispose();
    super.dispose();
  }

  void _startHold() {
    setState(() => _isHolding = true);
    _holdCtrl.forward();
  }

  void _cancelHold() {
    if (_unlocked) return;
    setState(() => _isHolding = false);
    _holdCtrl.reverse();
  }

  void _checkMath() {
    final answer = int.tryParse(_mathCtrl.text.trim());
    if (answer == _a * _b) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _mathError = 'ちがいます。もう一度。';
        _mathCtrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050D1A),
      body: SafeArea(
        child: Stack(
          children: [
            // 背景
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF050D1A), Color(0xFF0A0520)],
                ),
              ),
            ),

            Column(
              children: [
                // ヘッダー
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white54),
                        onPressed: () => Navigator.pop(context, false),
                      ),
                      const Spacer(),
                      const Text('保護者確認', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: AnimatedSwitcher(
                    duration: 400.ms,
                    child: _showMath ? _buildMathGate() : _buildHoldGate(),
                  ),
                ),

                // 切り替えリンク
                TextButton(
                  onPressed: () => setState(() {
                    _showMath = !_showMath;
                    _mathError = null;
                    _mathCtrl.clear();
                    if (!_showMath) _holdCtrl.reset();
                  }),
                  child: Text(
                    _showMath ? '長押しで確認する' : '計算で確認する',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── 長押しゲート ─────────────────────────────────────────

  Widget _buildHoldGate() {
    return Center(
      key: const ValueKey('hold'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔐', style: TextStyle(fontSize: 64))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(end: 1.08, duration: 1200.ms),
          const SizedBox(height: 24),
          const Text(
            '保護者の方へ',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'ボタンを3秒間\n長押ししてください',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 15, height: 1.6),
          ),
          const SizedBox(height: 40),

          // 長押しボタン
          GestureDetector(
            onTapDown: (_) => _startHold(),
            onTapUp: (_) => _cancelHold(),
            onTapCancel: _cancelHold,
            child: AnimatedBuilder(
              animation: _holdCtrl,
              builder: (_, __) {
                final progress = _holdCtrl.value;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120, height: 120,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 5,
                        backgroundColor: Colors.white12,
                        color: _unlocked
                            ? const Color(0xFF69F0AE)
                            : const Color(0xFF7C4DFF),
                      ),
                    ),
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isHolding
                            ? const Color(0xFF7C4DFF).withOpacity(0.5)
                            : const Color(0xFF1A0A3D),
                        border: Border.all(color: const Color(0xFF7C4DFF), width: 2),
                        boxShadow: _isHolding
                            ? [BoxShadow(color: const Color(0xFF7C4DFF).withOpacity(0.6), blurRadius: 20, spreadRadius: 5)]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          _unlocked ? '✓' : _isHolding ? '${((1 - progress) * 3).ceil()}' : '🔒',
                          style: TextStyle(
                            fontSize: _unlocked || _isHolding ? 32 : 28,
                            color: _unlocked ? const Color(0xFF69F0AE) : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _holdCtrl,
            builder: (_, __) => Text(
              _unlocked ? '認証できました！' : _isHolding ? 'そのまま押し続けて…' : '押し続けてください',
              style: TextStyle(
                color: _unlocked ? const Color(0xFF69F0AE) : Colors.white54,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 計算ゲート ────────────────────────────────────────────

  Widget _buildMathGate() {
    return Center(
      key: const ValueKey('math'),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🧮', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 20),
              const Text('保護者の方へ',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('答えを入力してください',
                  style: TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.5)),
                ),
                child: Text(
                  '$_a × $_b = ?',
                  style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Color(0xFF7FDBFF)),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _mathCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 28),
                onSubmitted: (_) => _checkMath(),
                decoration: InputDecoration(
                  errorText: _mathError,
                  errorStyle: const TextStyle(color: Color(0xFFFF5252)),
                  hintText: '答えを入力',
                  hintStyle: const TextStyle(color: Colors.white24),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFFF5252)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFFF5252), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _checkMath,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C4DFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('確認する', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

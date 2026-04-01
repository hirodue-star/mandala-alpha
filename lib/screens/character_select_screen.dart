import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/character.dart';
import '../providers/character_providers.dart';
import 'age_select_screen.dart';

class CharacterSelectScreen extends ConsumerStatefulWidget {
  const CharacterSelectScreen({super.key});
  @override
  ConsumerState<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends ConsumerState<CharacterSelectScreen> {
  bool _showStars = false;
  bool _whiteOut = false;
  Offset _starOrigin = Offset.zero;

  Future<void> _selectAndGo(CharacterId id, Offset tapPosition) async {
    HapticFeedback.heavyImpact();
    ref.read(characterProvider.notifier).select(id);

    // ピコーン音
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('audio/select.mp3')).catchError((_) {});
    } catch (_) {}

    // パステル星エフェクト
    setState(() { _showStars = true; _starOrigin = tapPosition; });
    await Future.delayed(600.ms);

    // ホワイトアウト
    if (!mounted) return;
    setState(() => _whiteOut = true);
    await Future.delayed(500.ms);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AgeSelectScreen(),
        transitionDuration: 400.ms,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 30),
                const Text('どっちと あそぶ？',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF5A4A3A)))
                    .animate().fadeIn(duration: 500.ms),
                const SizedBox(height: 6),
                const Text('すきなキャラクターを えらんでね！',
                    style: TextStyle(fontSize: 13, color: Color(0xFF9A8A7A)))
                    .animate().fadeIn(delay: 200.ms, duration: 500.ms),
                const SizedBox(height: 30),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(child: _CharacterCard(
                          def: puppyDef,
                          onTapWithPosition: (pos) => _selectAndGo(CharacterId.puppy, pos),
                        ).animate()
                            .fadeIn(delay: 300.ms, duration: 500.ms)
                            .slideX(begin: -0.15, duration: 500.ms, curve: Curves.easeOutBack)),
                        const SizedBox(width: 14),
                        Expanded(child: _CharacterCard(
                          def: gaogaoDef,
                          onTapWithPosition: (pos) => _selectAndGo(CharacterId.gaogao, pos),
                        ).animate()
                            .fadeIn(delay: 450.ms, duration: 500.ms)
                            .slideX(begin: 0.15, duration: 500.ms, curve: Curves.easeOutBack)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('※ あとからでも かえられるよ',
                    style: TextStyle(fontSize: 11, color: Colors.brown[300]))
                    .animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 24),
              ],
            ),
          ),
          // パステル星エフェクト
          if (_showStars) _PastelStarBurst(origin: _starOrigin),
          // ホワイトアウト
          if (_whiteOut)
            AnimatedContainer(
              duration: 500.ms,
              color: Colors.white,
            ).animate().fadeIn(duration: 500.ms),
        ],
      ),
    );
  }
}

// ── パステル星バースト ──────────────────────────────────

class _PastelStarBurst extends StatelessWidget {
  final Offset origin;
  const _PastelStarBurst({required this.origin});

  static const _starEmojis = ['⭐', '✨', '🌟', '💫', '⭐', '✨', '🌟', '💫', '⭐', '✨', '🌟', '💫'];
  static const _colors = [
    Color(0xFFFFB3DE), Color(0xFFFFCC80), Color(0xFF81D4FA),
    Color(0xFFC5E1A5), Color(0xFFCE93D8), Color(0xFFFFF176),
  ];

  @override
  Widget build(BuildContext context) {
    final rng = math.Random(42);
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: List.generate(12, (i) {
            final angle = i * math.pi * 2 / 12 + rng.nextDouble() * 0.3;
            final dist = 80.0 + rng.nextDouble() * 80;
            return Positioned(
              left: origin.dx - 10,
              top: origin.dy - 10,
              child: Text(_starEmojis[i],
                  style: TextStyle(fontSize: 16 + rng.nextDouble() * 14,
                      color: _colors[i % _colors.length]))
                  .animate()
                  .move(begin: Offset.zero,
                      end: Offset(math.cos(angle) * dist, math.sin(angle) * dist),
                      duration: 700.ms, delay: Duration(milliseconds: i * 30),
                      curve: Curves.easeOut)
                  .scaleXY(begin: 0.3, end: 1.2, duration: 400.ms)
                  .then()
                  .fadeOut(duration: 300.ms),
            );
          }),
        ),
      ),
    );
  }
}

// ── キャラカード ─────────────────────────────────────────

class _CharacterCard extends StatefulWidget {
  final CharacterDef def;
  final void Function(Offset tapPosition) onTapWithPosition;
  const _CharacterCard({required this.def, required this.onTapWithPosition});
  @override
  State<_CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends State<_CharacterCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 300.ms);
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0)
          .chain(CurveTween(curve: Curves.elasticOut)), weight: 70),
    ]).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final d = widget.def;
    return GestureDetector(
      onTapDown: (details) {
        _ctrl.forward(from: 0);
        widget.onTapWithPosition(details.globalPosition);
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [d.bgGradient[0], d.bgGradient[1]]),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: d.primaryColor.withOpacity(0.5), width: 2),
            boxShadow: [BoxShadow(
              color: d.primaryColor.withOpacity(0.25),
              blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // キャラクター
              Image.asset('assets/images/${d.id.name}.png', height: 120, width: 120)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(end: 1.08, duration: 1200.ms)
                  .moveY(begin: 0, end: -6, duration: 1200.ms),
              const SizedBox(height: 12),
              // 名前
              Text(d.name,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                      color: d.id == CharacterId.puppy
                          ? const Color(0xFFE91E63) : const Color(0xFF4CAF50))),
              const SizedBox(height: 4),
              Text(d.desc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF8A7A6A))),
              const SizedBox(height: 16),
              // テーマプレビュー
              Wrap(
                spacing: 4, runSpacing: 4,
                alignment: WrapAlignment.center,
                children: d.stageThemes.take(4).map((t) =>
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8)),
                      child: Text('${t.emoji} ${t.name}',
                          style: const TextStyle(fontSize: 8, color: Color(0xFF6A5A4A))),
                    )).toList(),
              ),
              const SizedBox(height: 14),
              // マシュマロ「えらぶ！」ボタン
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [
                      d.primaryColor.withOpacity(0.6),
                      d.primaryColor.withOpacity(0.9),
                    ]),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(color: d.primaryColor.withOpacity(0.35),
                        blurRadius: 12, offset: const Offset(0, 5)),
                    BoxShadow(color: Colors.white.withOpacity(0.5),
                        blurRadius: 4, spreadRadius: -2, offset: const Offset(0, -2)),
                  ],
                ),
                child: const Text('えらぶ！',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900,
                        color: Colors.white, letterSpacing: 1)),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(end: 1.05, duration: 1400.ms, curve: Curves.easeInOut),
            ],
          ),
        ),
      ),
    );
  }
}

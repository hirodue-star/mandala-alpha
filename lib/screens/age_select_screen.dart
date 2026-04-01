import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mandala_state.dart';
import '../providers/mandala_providers.dart';
import 'player_home_screen.dart';

class AgeSelectScreen extends ConsumerWidget {
  const AgeSelectScreen({super.key});

  static const _cards = [
    (mode: AgeMode.age3, emoji: '🌱', color: Color(0xFFFFD6E0), desc: '4マス・はっけん'),
    (mode: AgeMode.age4, emoji: '🌿', color: Color(0xFFD6F5D6), desc: '6マス・つながり'),
    (mode: AgeMode.age5, emoji: '🌳', color: Color(0xFFD6E8FF), desc: '9マス・ぶんるい'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text('🐣', style: TextStyle(fontSize: 64))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(end: 1.08, duration: 1200.ms),
              const SizedBox(height: 16),
              const Text(
                'おともだちは なんさい？',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF5A4A3A)),
              ).animate().fadeIn(duration: 500.ms),
              const SizedBox(height: 6),
              const Text(
                'プピィが ぴったりの あそびを よういするよ！',
                style: TextStyle(fontSize: 13, color: Color(0xFF9A8A7A)),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
              const SizedBox(height: 40),
              ..._cards.asMap().entries.map((e) {
                final i = e.key;
                final c = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _AgeCard(
                    mode: c.mode,
                    emoji: c.emoji,
                    color: c.color,
                    desc: c.desc,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      ref.read(mandalaProvider.notifier).setAge(c.mode);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const PlayerHomeScreen()),
                      );
                    },
                  ).animate()
                      .fadeIn(delay: Duration(milliseconds: 300 + i * 150), duration: 500.ms)
                      .slideX(begin: i.isEven ? -0.15 : 0.15, end: 0, duration: 500.ms,
                          curve: Curves.easeOutBack),
                );
              }),
              const Spacer(),
              Text(
                '※ あとからでも かえられるよ',
                style: TextStyle(fontSize: 11, color: Colors.brown[300]),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgeCard extends StatefulWidget {
  final AgeMode mode;
  final String emoji;
  final Color color;
  final String desc;
  final VoidCallback onTap;

  const _AgeCard({
    required this.mode, required this.emoji, required this.color,
    required this.desc, required this.onTap,
  });

  @override
  State<_AgeCard> createState() => _AgeCardState();
}

class _AgeCardState extends State<_AgeCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 300.ms);
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.92), weight: 30),
      TweenSequenceItem(
        tween: Tween(begin: 0.92, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(from: 0),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: widget.color.withOpacity(0.5), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.mode.label,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF4A3A2A)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.desc,
                      style: TextStyle(fontSize: 13, color: Colors.brown[500], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.brown[300], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

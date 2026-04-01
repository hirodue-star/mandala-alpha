import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/character.dart';
import '../providers/character_providers.dart';
import 'age_select_screen.dart';

class CharacterSelectScreen extends ConsumerWidget {
  const CharacterSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      body: SafeArea(
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
                    // プピィ
                    Expanded(child: _CharacterCard(
                      def: puppyDef,
                      onTap: () => _selectAndGo(context, ref, CharacterId.puppy),
                    ).animate()
                        .fadeIn(delay: 300.ms, duration: 500.ms)
                        .slideX(begin: -0.15, duration: 500.ms, curve: Curves.easeOutBack)),
                    const SizedBox(width: 14),
                    // ガオガオ
                    Expanded(child: _CharacterCard(
                      def: gaogaoDef,
                      onTap: () => _selectAndGo(context, ref, CharacterId.gaogao),
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
    );
  }

  void _selectAndGo(BuildContext ctx, WidgetRef ref, CharacterId id) {
    HapticFeedback.mediumImpact();
    ref.read(characterProvider.notifier).select(id);
    Navigator.of(ctx).pushReplacement(
      MaterialPageRoute(builder: (_) => const AgeSelectScreen()),
    );
  }
}

class _CharacterCard extends StatefulWidget {
  final CharacterDef def;
  final VoidCallback onTap;
  const _CharacterCard({required this.def, required this.onTap});
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
      onTapDown: (_) => _ctrl.forward(from: 0),
      onTap: widget.onTap,
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

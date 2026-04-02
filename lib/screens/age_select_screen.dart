import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mandala_state.dart';
import '../providers/mandala_providers.dart';
import '../providers/character_providers.dart';
import '../providers/daily_cycle_providers.dart';
import 'player_home_screen.dart';
import 'daily_diary_screen.dart';

class AgeSelectScreen extends ConsumerWidget {
  const AgeSelectScreen({super.key});

  static const _cards = [
    (mode: AgeMode.age3, emoji: '🐤', color: Color(0xFFFFF3D6), desc: 'こころのカメラ', sub: 'おともだちの きもちを かんがえよう'),
    (mode: AgeMode.age4, emoji: '🐧', color: Color(0xFFD6EFFF), desc: 'カテゴリー連鎖', sub: 'なかまわけ＆もしも〜なら？'),
    (mode: AgeMode.age5, emoji: '🦁', color: Color(0xFFFFE0C0), desc: 'マンダラ完全開放', sub: 'ぜんぶ じぶんで かんがえる'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailySeed = ref.watch(dailyCycleProvider);
    final phaseInfo = ref.watch(phaseInfoProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              const Text('🐣', style: TextStyle(fontSize: 56))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(end: 1.08, duration: 1200.ms),
              const SizedBox(height: 12),
              const Text(
                'レベルを えらぼう！',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF5A4A3A)),
              ).animate().fadeIn(duration: 500.ms),
              const SizedBox(height: 4),
              Text(
                '${ref.watch(characterProvider).def.name}が ぴったりの あそびを よういするよ！',
                style: const TextStyle(fontSize: 13, color: Color(0xFF9A8A7A)),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
              // 時間帯バッジ
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8C0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(phaseInfo.emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text('いま ${phaseInfo.label} → ${phaseInfo.mode.label}級が おすすめ！',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                          color: Color(0xFF8A6A3A))),
                ]),
              ),
              const SizedBox(height: 20),
              ..._cards.asMap().entries.map((e) {
                final i = e.key;
                final c = e.value;
                final isLocked = dailySeed.isLocked(c.mode);
                final isRecommended = c.mode == phaseInfo.mode;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Stack(
                    children: [
                      _AgeCard(
                        mode: c.mode,
                        emoji: c.emoji,
                        color: isLocked ? const Color(0xFFE8E0D5) : c.color,
                        desc: c.desc,
                        sub: c.sub,
                        onTap: isLocked ? () {
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('🔒 この レベルは ${_lockTimeLabel(c.mode)} に あくよ！'),
                            backgroundColor: const Color(0xFF8A6A3A),
                          ));
                        } : () {
                          HapticFeedback.mediumImpact();
                          ref.read(dailyCycleProvider.notifier).ensureToday();
                          ref.read(mandalaProvider.notifier).setAge(c.mode);
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const PlayerHomeScreen()),
                          );
                        },
                      ),
                      // ロックオーバーレイ
                      if (isLocked)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Center(
                              child: Text('🔒', style: TextStyle(fontSize: 32)),
                            ),
                          ),
                        ),
                      // おすすめバッジ
                      if (isRecommended && !isLocked)
                        Positioned(top: 8, right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8A65),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('おすすめ',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                    ],
                  ).animate()
                      .fadeIn(delay: Duration(milliseconds: 300 + i * 150), duration: 500.ms)
                      .slideX(begin: i.isEven ? -0.15 : 0.15, end: 0, duration: 500.ms,
                          curve: Curves.easeOutBack),
                );
              }),
              const Spacer(),
              // 冒険日記ボタン + 時間ロックトグル
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const DailyDiaryScreen())),
                  child: Row(children: [
                    const Text('📔', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 4),
                    Text('きょうの にっき',
                        style: TextStyle(fontSize: 11, color: Colors.brown[400], fontWeight: FontWeight.w600)),
                  ]),
                ),
                Row(children: [
                  Text('🔒 じかんロック',
                      style: TextStyle(fontSize: 10, color: Colors.brown[300])),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 24,
                    child: Switch(
                      value: dailySeed.timeLockEnabled,
                      onChanged: (v) => ref.read(dailyCycleProvider.notifier).toggleTimeLock(v),
                      activeColor: const Color(0xFFFF8A65),
                    ),
                  ),
                ]),
              ]),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _lockTimeLabel(AgeMode mode) => switch (mode) {
    AgeMode.age3 => 'あさ(6じ〜)',
    AgeMode.age4 => 'ひる(11じ〜)',
    AgeMode.age5 => 'よる(17じ〜)',
  };
}

class _AgeCard extends StatefulWidget {
  final AgeMode mode;
  final String emoji;
  final Color color;
  final String desc;
  final String? sub;
  final VoidCallback onTap;

  const _AgeCard({
    required this.mode, required this.emoji, required this.color,
    required this.desc, this.sub, required this.onTap,
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
                    if (widget.sub != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.sub!,
                        style: TextStyle(fontSize: 10, color: Colors.brown[300], fontStyle: FontStyle.italic),
                      ),
                    ],
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

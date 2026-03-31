import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mandala_state.dart';
import '../providers/mandala_providers.dart';
import '../widgets/egg_widget.dart';
import '../widgets/resonance_cell.dart';

// ─────────────────────────────────────────────────────────
// ResonanceScreen — 音とたまごの共鳴システム
//
// グリッド配置:
//   [7, 0, 1]
//   [6, 🥚, 2]   ← 中央 = たまご
//   [5, 4, 3]
// ─────────────────────────────────────────────────────────

class ResonanceScreen extends ConsumerWidget {
  const ResonanceScreen({super.key});

  static const List<int?> _gridMap = [7, 0, 1, 6, null, 2, 5, 4, 3];

  // 波紋遅延（cellIndex 0〜7）
  static const List<int> _waveDelay = [0, 100, 200, 300, 200, 100, 0, 100];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mandalaProvider);
    final notifier = ref.read(mandalaProvider.notifier);

    // 孵化アニメーション完了を監視
    ref.listen<MandalaState>(mandalaProvider, (prev, next) {
      if (prev?.phase != ResonancePhase.hatching &&
          next.phase == ResonancePhase.hatching) {
        // 孵化アニメーション時間後に hatched へ
        Future.delayed(const Duration(milliseconds: 1400), () {
          notifier.onHatchAnimationDone();
        });
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF1A0533),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '音とたまごの共鳴',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        actions: [
          if (state.phase != ResonancePhase.locked) ...[
            _StageIndicator(stage: state.eggStage),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white54, size: 20),
              tooltip: 'リセット',
              onPressed: () => _showResetDialog(context, notifier),
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          // 背景：星空グラデーション
          _StarBackground(doneCount: state.doneCount),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: [
                _HintBanner(state: state),
                const SizedBox(height: 10),

                // 9マスグリッド
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: 9,
                      itemBuilder: (context, gridIndex) {
                        final cellIndex = _gridMap[gridIndex];
                        if (cellIndex == null) {
                          // 中央：たまご
                          return _CenterEggCell(
                            state: state,
                            onTap: () => _onCenterTap(context, state, notifier),
                          );
                        }
                        return ResonanceCell(
                          cellIndex: cellIndex,
                          label: state.labels[cellIndex],
                          completed: state.completed[cellIndex],
                          phase: state.phase,
                          waveDelayMs: _waveDelay[cellIndex],
                          onTap: () => _onCellTap(
                              context, state, notifier, cellIndex),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                if (state.phase == ResonancePhase.activated)
                  _InstrumentBar(completed: state.completed),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // 祝福オーバーレイ
          if (state.phase == ResonancePhase.hatched)
            _HatchedOverlay(
              goal: state.goal,
              onClose: notifier.reset,
            ),
        ],
      ),
    );
  }

  // ── タップハンドラ ────────────────────────────────────

  void _onCenterTap(
    BuildContext context,
    MandalaState state,
    MandalaNotifier notifier,
  ) {
    HapticFeedback.mediumImpact();
    if (state.phase == ResonancePhase.locked) {
      _showGoalDialog(context, notifier, isFirst: true);
    } else if (state.phase == ResonancePhase.activated) {
      _showGoalDialog(context, notifier, isFirst: false);
    }
  }

  void _onCellTap(
    BuildContext context,
    MandalaState state,
    MandalaNotifier notifier,
    int cellIndex,
  ) {
    if (state.phase != ResonancePhase.activated) return;
    HapticFeedback.selectionClick();
    _showCellDialog(context, state, notifier, cellIndex);
  }

  // ── ダイアログ ────────────────────────────────────────

  void _showGoalDialog(
    BuildContext context,
    MandalaNotifier notifier, {
    required bool isFirst,
  }) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFF2D0A5C),
        title: Row(children: [
          const Text('🥚', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Text(
            isFirst ? 'ゴールを設定してスタート' : 'ゴールを変更',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ]),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 30,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '例：英検2級に合格する',
            hintStyle: const TextStyle(color: Colors.white38),
            counterStyle: const TextStyle(color: Colors.white38),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF7C4DFF), width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル',
                style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isNotEmpty) {
                if (isFirst) {
                  notifier.activate(text);
                } else {
                  notifier.updateGoal(text);
                }
              }
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7C4DFF),
            ),
            child: Text(isFirst ? 'スタート！🥚' : '更新'),
          ),
        ],
      ),
    );
  }

  void _showCellDialog(
    BuildContext context,
    MandalaState state,
    MandalaNotifier notifier,
    int cellIndex,
  ) {
    final ctrl = TextEditingController(text: state.labels[cellIndex]);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFF2D0A5C),
        title: Text(
          '♪ アクションを入力',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ゴール: ${state.goal}',
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white54,
                  fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLength: 20,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'ゴールへの行動',
                hintStyle: const TextStyle(color: Colors.white38),
                counterStyle: const TextStyle(color: Colors.white38),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFFFFD700), width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル',
                style: TextStyle(color: Colors.white54)),
          ),
          if (state.completed[cellIndex])
            OutlinedButton(
              onPressed: () {
                notifier.resetCell(cellIndex);
                Navigator.pop(ctx);
              },
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white38)),
              child: const Text('未完了に戻す',
                  style: TextStyle(color: Colors.white54)),
            ),
          FilledButton(
            onPressed: () {
              notifier
                  .completeCell(cellIndex, label: ctrl.text.trim())
                  .then((_) => HapticFeedback.heavyImpact());
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black87,
            ),
            child: const Text('完了！♪'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, MandalaNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D0A5C),
        title: const Text('リセット確認',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text('最初からやり直しますか？',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('いいえ', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            onPressed: () {
              notifier.reset();
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent),
            child: const Text('リセット'),
          ),
        ],
      ),
    );
  }
}

// ─── サブウィジェット ──────────────────────────────────

class _CenterEggCell extends StatelessWidget {
  final MandalaState state;
  final VoidCallback onTap;
  const _CenterEggCell({required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: RadialGradient(
            colors: [
              const Color(0xFF4A1080).withOpacity(0.9),
              const Color(0xFF1A0533).withOpacity(0.95),
            ],
          ),
          border: Border.all(
            color: state.eggStage >= 7
                ? const Color(0xFFFFD700)
                : const Color(0xFF7C4DFF),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: state.eggStage >= 5
                  ? const Color(0xFFFFD700).withOpacity(0.4)
                  : const Color(0xFF7C4DFF).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Center(
          child: EggWidget(
            stage: state.eggStage,
            phase: state.phase,
            onTap: null, // GestureDetector の onTap で処理
          ),
        ),
      ),
    );
  }
}

class _HintBanner extends StatelessWidget {
  final MandalaState state;
  const _HintBanner({required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 400.ms,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      decoration: BoxDecoration(
        color: state.phase == ResonancePhase.locked
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              _hintText(state),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _hintText(MandalaState s) {
    switch (s.phase) {
      case ResonancePhase.locked:
        return '🥚 中央のたまごをタップしてゴールを設定しよう';
      case ResonancePhase.activated:
        if (s.doneCount == 0) return '🎵 マスをタップすると楽器が響く';
        if (s.doneCount < 4) return '🎵 ${s.doneCount} 楽器が鳴り響いている…';
        if (s.doneCount < 8) return '✨ たまごが震えてきた！あと ${8 - s.doneCount} マス';
        return '🥚 たまごが孵化する瞬間へ…';
      case ResonancePhase.hatching:
        return '🌟 孵化中…！';
      case ResonancePhase.hatched:
        return '🐥 おめでとう！全ての楽器が合奏した！';
    }
  }
}

class _StageIndicator extends StatelessWidget {
  final int stage;
  const _StageIndicator({required this.stage});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: stage >= 7
              ? const Color(0xFFFFD700)
              : const Color(0xFF7C4DFF),
        ),
      ),
      child: Text(
        '🥚 $stage/8',
        style: TextStyle(
          color: stage >= 7 ? const Color(0xFFFFD700) : Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InstrumentBar extends StatelessWidget {
  final List<bool> completed;
  const _InstrumentBar({required this.completed});

  static const _emojis = ['🎹','🎻','🎵','🎸','🥁','🎺','🎸','🎼'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(8, (i) {
        final on = completed[i];
        return AnimatedContainer(
          duration: 300.ms,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: on
                ? const Color(0xFFFFD700).withOpacity(0.2)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: on
                  ? const Color(0xFFFFD700)
                  : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Text(
            _emojis[i],
            style: TextStyle(
              fontSize: 14,
              color: on ? null : Colors.grey,
            ),
          ),
        )
            .animate(target: on ? 1.0 : 0.0)
            .scaleXY(end: 1.2, duration: 300.ms);
      }),
    );
  }
}

class _StarBackground extends StatelessWidget {
  final int doneCount;
  const _StarBackground({required this.doneCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(
              const Color(0xFF1A0533),
              const Color(0xFF3D1177),
              doneCount / 8,
            )!,
            const Color(0xFF0D0020),
          ],
        ),
      ),
    );
  }
}

class _HatchedOverlay extends StatelessWidget {
  final String goal;
  final VoidCallback onClose;
  const _HatchedOverlay({required this.goal, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D0A5C), Color(0xFF1A0533)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.6),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.35),
                  blurRadius: 40,
                  spreadRadius: 8,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🐥', style: TextStyle(fontSize: 72))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(end: 1.1, duration: 700.ms)
                    .moveY(begin: 0, end: -8, duration: 700.ms),
                const SizedBox(height: 16),
                const Text(
                  'フルオーケストラ\n達成！',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFFD700),
                    height: 1.3,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .shimmer(duration: 1400.ms, color: Colors.white),
                const SizedBox(height: 10),
                Text(
                  'ゴール: $goal',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
                const Text(
                  '8つの楽器が響き合い\nたまごが生まれました！',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: Colors.white54, height: 1.6),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onClose,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black87,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'もう一度挑戦する',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOutBack)
              .fadeIn(duration: 400.ms),
        ),
      ),
    );
  }
}

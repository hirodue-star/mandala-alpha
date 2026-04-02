import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mandala_state.dart';
import '../providers/mandala_providers.dart';
import '../widgets/puppy_character.dart';
import '../widgets/resonance_cell.dart';
import '../widgets/particle_effect.dart';
import '../l10n/strings.dart';
import '../providers/context_providers.dart';
import '../providers/suggestion_providers.dart';
import '../services/suggestion_service.dart';
import 'parent_gate_screen.dart';
import 'character_select_screen.dart';
import 'parent_dashboard_screen.dart';
import 'reward_room_screen.dart';
import 'gacha_screen.dart';
import '../models/gacha_collection.dart';
import '../models/character.dart';
import '../providers/gacha_providers.dart';
import '../providers/character_providers.dart';
import '../widgets/gaogao_character.dart';
import '../services/learning_log_service.dart';
import '../services/thinking_framework_service.dart';
import '../providers/daily_cycle_providers.dart';
import '../services/coaching_phrase_service.dart';
import 'share_report_screen.dart';
import 'daily_diary_screen.dart';
import 'image_mandala_screen.dart';
import 'social_screen.dart';

// ─────────────────────────────────────────────────────────
// PlayerHomeScreen — 子供向けメイン画面（年齢別グリッド）
// ─────────────────────────────────────────────────────────

class PlayerHomeScreen extends ConsumerStatefulWidget {
  const PlayerHomeScreen({super.key});
  @override
  ConsumerState<PlayerHomeScreen> createState() => _PlayerHomeScreenState();
}

class _PlayerHomeScreenState extends ConsumerState<PlayerHomeScreen> {
  int _squashTrigger = 0;
  int _particleTrigger = 0;
  int _acornBounceTrigger = 0;

  // 黄金比ベースのマージン定数 (φ = 1.618)
  static const _goldenUnit = 8.0;
  static const _goldenSmall = _goldenUnit * 1.0;       // 8
  static const _goldenMed   = _goldenUnit * 1.618;     // ~13
  static const _goldenLarge = _goldenUnit * 2.618;     // ~21

  void _onCellComplete() {
    setState(() { _squashTrigger++; _particleTrigger++; _acornBounceTrigger++; });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mandalaProvider);
    final notifier = ref.read(mandalaProvider.notifier);
    final gridMap = state.ageMode.gridMap;
    final suggestions = ref.watch(suggestionsProvider);
    final charDef = ref.watch(characterProvider).def;

    ref.listen<MandalaState>(mandalaProvider, (prev, next) {
      if (prev?.phase != ResonancePhase.hatching && next.phase == ResonancePhase.hatching) {
        Future.delayed(1400.ms, () {
          if (mounted) notifier.onHatchAnimationDone();
        });
      }
      // 孵化完了→どんぐり+ガチャチケット+装備付与+デイリー種保存+学習ログ保存
      if (prev?.phase != ResonancePhase.hatched && next.phase == ResonancePhase.hatched) {
        ref.read(rewardProvider.notifier).earnAcorn();
        ref.read(collectionProvider.notifier).addTicket();
        ref.read(characterProvider.notifier).awardLevelEquip(next.ageMode);
        ref.read(dailyCycleProvider.notifier).onSessionComplete(
          next.ageMode, next.goal,
          next.labels.take(next.activeCellCount).toList(),
        );
        LearningLogService.saveSession(next);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      body: Stack(
        children: [
          _WarmBackground(doneCount: state.doneCount, activeCells: state.activeCellCount,
              currentStage: state.currentStage),
          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  doneCount: state.doneCount,
                  activeCells: state.activeCellCount,
                  phase: state.phase,
                  ageMode: state.ageMode,
                  currentStage: state.currentStage,
                  onParentTap: () => _goToParent(context),
                  onRewardTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RewardRoomScreen())),
                  charEmoji: charDef.emoji,
                  charName: charDef.name,
                  equippedEmojis: ref.watch(characterProvider).equippedEmojis,
                ),
                const SizedBox(height: _goldenSmall),
                // プピィ自律挨拶（常時表示）
                _PuppyGreetingBubble(),
                if (state.phase != ResonancePhase.locked)
                  _HintBanner(state: state),
                const SizedBox(height: _goldenSmall),

                // コーチング吹き出し（ゴール設定直後）
                if (state.phase == ResonancePhase.activated && state.doneCount == 0)
                  _CoachingBubble(goal: state.goal, ageMode: state.ageMode),

                Expanded(
                  child: ParticleOverlay(
                    trigger: _particleTrigger,
                    origin: Offset(
                      MediaQuery.of(context).size.width / 2,
                      MediaQuery.of(context).size.height * 0.38,
                    ),
                    child: _buildLevelLayout(context, state, notifier, gridMap, suggestions),
                  ),
                ),
                const SizedBox(height: _goldenSmall),
                if (state.phase == ResonancePhase.activated)
                  _ProgressStars(doneCount: state.doneCount, total: state.activeCellCount),
                // おまかせボタン（AI提案で全マス自動入力）※ライオン級では非表示
                if (state.phase == ResonancePhase.activated &&
                    !state.ageMode.isFreeInputMode &&
                    suggestions.isNotEmpty &&
                    state.doneCount < state.activeCellCount)
                  _OmakaseButton(
                    suggestions: suggestions,
                    activeCells: state.activeCellCount,
                    completed: state.completed,
                    onTap: () => _autoFillAll(notifier, state, suggestions),
                  ),
                const SizedBox(height: _goldenMed),
              ],
            ),
          ),
          // どんぐりバウンス演出
          if (_acornBounceTrigger > 0)
            _AcornRainOverlay(key: ValueKey(_acornBounceTrigger)),
          if (state.phase == ResonancePhase.hatched)
            _HatchedOverlay(
              goal: state.goal,
              currentStage: state.currentStage,
              isLionLevel: state.ageMode.isFreeInputMode,
              charEmoji: charDef.emoji,
              charFullDisplay: ref.watch(characterProvider).fullEquipDisplay,
              onClose: notifier.reset,
              onNextStage: notifier.advanceStage,
              onGacha: () {
                notifier.advanceStage();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GachaScreen()));
              },
              onShareReport: state.ageMode.isFreeInputMode
                  ? () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ShareReportScreen()))
                  : null,
            ),
        ],
      ),
    );
  }

  // ── 級別レイアウト分岐 ─────────────────────────────────
  Widget _buildLevelLayout(BuildContext context, MandalaState state,
      MandalaNotifier notifier, List<int?> gridMap, List<String> suggestions) {
    return switch (state.ageMode) {
      AgeMode.age3 => _buildHiyokoLayout(context, state, notifier, suggestions),
      AgeMode.age4 => _buildPenguinLayout(context, state, notifier, suggestions),
      AgeMode.age5 => _buildLionLayout(context, state, notifier, gridMap, suggestions),
    };
  }

  // ── ひよこ級: 2つの大きな円レイアウト ────────────────────
  Widget _buildHiyokoLayout(BuildContext context, MandalaState state,
      MandalaNotifier notifier, List<String> suggestions) {
    final w = MediaQuery.of(context).size.width;
    final circleSize = w * 0.35; // 黄金比的にバランスの良い大きさ
    final active = state.ageMode.activeCells; // 3

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _goldenLarge),
      child: Column(
        children: [
          const Spacer(flex: 2),
          // パステル装飾背景
          Stack(
            alignment: Alignment.center,
            children: [
              // 背景の装飾円
              ...[0.6, 0.45, 0.3].asMap().entries.map((e) => Container(
                width: w * e.value, height: w * e.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: [
                    const Color(0xFFFFF3D6),
                    const Color(0xFFFFE8C0),
                    const Color(0xFFFFF8EE),
                  ][e.key].withOpacity(0.4),
                ),
              )),
              // メイン: 中央（プピィ）と右（アクションセル）
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 中央のプピィ
                  SizedBox(
                    width: circleSize, height: circleSize,
                    child: _PuppyCell(
                      state: state,
                      squashTrigger: _squashTrigger,
                      onTap: () => _onCenterTap(context, state, notifier),
                    ),
                  ),
                  SizedBox(width: _goldenMed),
                  // セル0（1対1の課題）
                  SizedBox(
                    width: circleSize, height: circleSize,
                    child: _ElasticCell(
                      cellIndex: 0,
                      label: state.labels[0],
                      completed: state.completed[0],
                      phase: state.phase,
                      waveDelayMs: 0,
                      onTap: () => _onCellTap(context, state, notifier, 0),
                      suggestion: suggestions.isNotEmpty ? suggestions[0] : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: _goldenLarge),
          // 下段: 残り2セル（横並び）
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(2, (i) {
              final ci = i + 1;
              if (ci >= active) return const SizedBox.shrink();
              return SizedBox(
                width: circleSize * 0.85, height: circleSize * 0.85,
                child: _ElasticCell(
                  cellIndex: ci,
                  label: state.labels[ci],
                  completed: state.completed[ci],
                  phase: state.phase,
                  waveDelayMs: ci * 150,
                  onTap: () => _onCellTap(context, state, notifier, ci),
                  suggestion: ci < suggestions.length ? suggestions[ci] : null,
                ),
              );
            }),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  // ── ペンギン級: ルート型レイアウト（線で繋ぐ） ───────────
  Widget _buildPenguinLayout(BuildContext context, MandalaState state,
      MandalaNotifier notifier, List<String> suggestions) {
    final w = MediaQuery.of(context).size.width;
    final circleSize = w * 0.25;
    final active = state.ageMode.activeCells; // 5

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _goldenMed),
      child: Column(
        children: [
          const Spacer(flex: 1),
          // プピィ（スタート地点）
          SizedBox(
            width: circleSize * 1.1, height: circleSize * 1.1,
            child: _PuppyCell(
              state: state,
              squashTrigger: _squashTrigger,
              onTap: () => _onCenterTap(context, state, notifier),
            ),
          ),
          // 接続線（上→中）
          _RoutePath(
            done: state.completed[0],
            color: const Color(0xFF90CAF9),
          ),
          // 第1行: セル0 → セル1（くの字の上段）
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(2, (i) => SizedBox(
              width: circleSize, height: circleSize,
              child: _ElasticCell(
                cellIndex: i,
                label: state.labels[i],
                completed: state.completed[i],
                phase: state.phase,
                waveDelayMs: i * 150,
                onTap: () => _onCellTap(context, state, notifier, i),
                suggestion: i < suggestions.length ? suggestions[i] : null,
              ),
            )),
          ),
          // 接続線
          _RoutePath(
            done: state.doneCount >= 2,
            color: const Color(0xFFCE93D8),
          ),
          // 第2行: セル2（中央）
          SizedBox(
            width: circleSize * 1.05, height: circleSize * 1.05,
            child: _ElasticCell(
              cellIndex: 2,
              label: state.labels[2],
              completed: state.completed[2],
              phase: state.phase,
              waveDelayMs: 300,
              onTap: () => _onCellTap(context, state, notifier, 2),
              suggestion: 2 < suggestions.length ? suggestions[2] : null,
            ),
          ),
          // 接続線
          _RoutePath(
            done: state.doneCount >= 3,
            color: const Color(0xFF80CBC4),
          ),
          // 第3行: セル3 → セル4（くの字の下段）
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(2, (i) {
              final ci = i + 3;
              if (ci >= active) return SizedBox(width: circleSize);
              return SizedBox(
                width: circleSize, height: circleSize,
                child: _ElasticCell(
                  cellIndex: ci,
                  label: state.labels[ci],
                  completed: state.completed[ci],
                  phase: state.phase,
                  waveDelayMs: ci * 150,
                  onTap: () => _onCellTap(context, state, notifier, ci),
                  suggestion: ci < suggestions.length ? suggestions[ci] : null,
                ),
              );
            }),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  // ── ライオン級: 3x3グリッド（既存） ─────────────────────
  Widget _buildLionLayout(BuildContext context, MandalaState state,
      MandalaNotifier notifier, List<int?> gridMap, List<String> suggestions) {
    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _goldenMed),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
          itemCount: 9,
          itemBuilder: (ctx, gi) {
            final ci = gridMap[gi];
            if (ci == null) {
              return _PuppyCell(
                state: state,
                squashTrigger: _squashTrigger,
                onTap: () => _onCenterTap(context, state, notifier),
              );
            }
            if (ci == -1) return const SizedBox.shrink();
            final thinkingFrame = state.ageMode.isFreeInputMode
                ? ThinkingFrameworkService.getFrames(state.goal)[ci.clamp(0, 7)]
                : null;
            return _ElasticCell(
              cellIndex: ci,
              label: state.labels[ci],
              completed: state.completed[ci],
              phase: state.phase,
              waveDelayMs: ci * 100,
              onTap: () => _onCellTap(context, state, notifier, ci),
              suggestion: ci < suggestions.length ? suggestions[ci] : null,
              thinkingFrame: thinkingFrame,
            );
          },
        ),
      ),
    );
  }

  void _onCenterTap(BuildContext ctx, MandalaState s, MandalaNotifier n) {
    HapticFeedback.mediumImpact();
    if (s.phase == ResonancePhase.locked) {
      _showGoalDialog(ctx, s, n, isFirst: true);
    } else if (s.phase == ResonancePhase.activated) {
      _showGoalDialog(ctx, s, n, isFirst: false);
    }
  }

  void _onCellTap(BuildContext ctx, MandalaState s, MandalaNotifier n, int ci) {
    if (s.phase != ResonancePhase.activated) return;
    HapticFeedback.selectionClick();
    _showCellDialog(ctx, s, n, ci);
  }

  void _showGoalDialog(BuildContext ctx, MandalaState s, MandalaNotifier n, {required bool isFirst}) {
    final ctrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => _NeonDialog(
        icon: '🥚',
        title: isFirst ? s.ageMode.centerLabel : AppStrings.current.goalDialogTitleEdit,
        hintText: AppStrings.current.goalDialogHint,
        maxLength: 25,
        confirmLabel: isFirst ? AppStrings.current.goalDialogConfirmFirst : AppStrings.current.goalDialogConfirmEdit,
        onConfirm: (text) {
          if (isFirst) { n.activate(text); } else { n.updateGoal(text); }
        },
        controller: ctrl,
      ),
    );
  }

  void _showCellDialog(BuildContext ctx, MandalaState s, MandalaNotifier n, int ci) {
    // ひよこ級 → こころのカメラ（メタ認知の基礎）
    if (s.ageMode == AgeMode.age3) {
      showDialog(
        context: ctx,
        builder: (_) => _HeartCameraDialog(
          goal: s.goal,
          cellIndex: ci,
          onSelect: (label) {
            n.completeCell(ci, label: label).then((_) {
              HapticFeedback.heavyImpact();
              _onCellComplete();
            });
          },
          onReset: s.completed[ci] ? () { n.resetCell(ci); Navigator.pop(ctx); } : null,
        ),
      );
    } else if (s.ageMode.isFreeInputMode) {
      // ライオン級 → 思考フレームワーク付きダイアログ
      final ctrl = TextEditingController();
      final frames = ThinkingFrameworkService.getFrames(s.goal);
      final frame = frames[ci.clamp(0, frames.length - 1)];
      final layerColor = Color(
          ThinkingFrameworkService.layerAccents[frame.layer] ?? 0xFFFF9800);
      showDialog(
        context: ctx,
        builder: (_) => _LionThinkingDialog(
          frame: frame,
          layerColor: layerColor,
          completed: s.completed[ci],
          onConfirm: (text) {
            n.completeCell(ci, label: text).then((_) {
              HapticFeedback.heavyImpact();
              _onCellComplete();
            });
          },
          onReset: s.completed[ci]
              ? () { n.resetCell(ci); Navigator.pop(ctx); }
              : null,
          controller: ctrl,
        ),
      );
    } else {
      // ペンギン級 → カテゴリー連鎖＆もしも思考
      showDialog(
        context: ctx,
        builder: (_) => _PenguinCategoryDialog(
          goal: s.goal,
          cellIndex: ci,
          prevLabel: ci > 0 && s.completed[ci - 1] ? s.labels[ci - 1] : null,
          onSelect: (label) {
            n.completeCell(ci, label: label).then((_) {
              HapticFeedback.heavyImpact();
              _onCellComplete();
            });
          },
          onReset: s.completed[ci] ? () { n.resetCell(ci); Navigator.pop(ctx); } : null,
        ),
      );
    }
  }

  Future<void> _autoFillAll(MandalaNotifier n, MandalaState s, List<String> suggestions) async {
    for (int i = 0; i < s.activeCellCount && i < suggestions.length; i++) {
      if (!s.completed[i]) {
        await n.completeCell(i, label: suggestions[i]);
        _onCellComplete();
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
  }

  Future<void> _goToParent(BuildContext ctx) async {
    final ok = await Navigator.push<bool>(
      ctx, MaterialPageRoute(builder: (_) => const ParentGateScreen()));
    if (ok == true && ctx.mounted) {
      Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ParentDashboardScreen()));
    }
  }
}

// ─── プピィ自律挨拶 ───────────────────────────────────────

class _PuppyGreetingBubble extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greeting = ref.watch(puppyGreetingProvider);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Text(ref.watch(characterProvider).def.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(greeting,
                style: const TextStyle(fontSize: 12, color: Color(0xFF5A4A3A), fontWeight: FontWeight.w500, height: 1.5)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.15, duration: 500.ms);
  }
}

// ─── コーチング吹き出し ───────────────────────────────────

class _CoachingBubble extends ConsumerWidget {
  final String goal;
  final AgeMode ageMode;
  const _CoachingBubble({required this.goal, required this.ageMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final charState = ref.watch(characterProvider);
    final charDef = charState.def;
    final isGentle = charState.guideTone == 'gentle';
    final dailySeed = ref.watch(dailyCycleProvider);
    final inherited = dailySeed.inheritedItems;

    // キャラ別セリフ: gentle=応援、bold=鼓舞
    final prompt = isGentle
        ? '「$goal」${ageMode.coachingPrompt}'
        : switch (ageMode) {
            AgeMode.age3 => '「$goal」に チャレンジだ！ やってみよう！',
            AgeMode.age4 => '「$goal」を どんどん つなげるぞ！',
            AgeMode.age5 => '「$goal」を ぜんぶ うめてやるぜ！',
          };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(charDef.emoji, style: const TextStyle(fontSize: 22)),
              if (charState.equippedEmojis.isNotEmpty)
                Text(charState.equippedEmojis.last, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(prompt,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF5A4A3A), fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          // 前フェーズからの引き継ぎ表示
          if (inherited.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Text('🌱', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'ひきつぎ: ${inherited.take(3).join(", ")}${inherited.length > 3 ? "..." : ""}',
                  style: TextStyle(fontSize: 10, color: Colors.brown[300], fontStyle: FontStyle.italic),
                ),
              ),
            ]),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2, duration: 400.ms);
  }
}

// ─── サブウィジェット ──────────────────────────────────────

class _PuppyCell extends ConsumerStatefulWidget {
  final MandalaState state;
  final int squashTrigger;
  final VoidCallback onTap;
  const _PuppyCell({required this.state, required this.squashTrigger, required this.onTap});
  @override
  ConsumerState<_PuppyCell> createState() => _PuppyCellState();
}

class _PuppyCellState extends ConsumerState<_PuppyCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _jiggle;
  int _tapCount = 0;

  @override
  void initState() {
    super.initState();
    _jiggle = AnimationController(vsync: this, duration: 500.ms);
  }

  @override
  void dispose() { _jiggle.dispose(); super.dispose(); }

  void _onInteractiveTap() {
    HapticFeedback.lightImpact();
    _jiggle.forward(from: 0);
    setState(() => _tapCount++);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final equipped = ref.watch(collectionProvider).equippedCostume;
    final costumeEmoji = equipped != null
        ? allCostumes.where((c) => c.id == equipped).firstOrNull?.emoji
        : null;

    // 冒険背景カラー
    final stageIdx = (widget.state.currentStage - 1).clamp(0, adventureStages.length - 1);
    final adventure = adventureStages[stageIdx];

    // 選択キャラに応じて動的にウィジェットを切り替え
    final charId = ref.watch(characterProvider).selected;
    Widget characterWidget = charId == CharacterId.puppy
        ? PuppyCharacter(
            stage: widget.state.eggStage,
            phase: widget.state.phase,
            squashTrigger: widget.squashTrigger,
          )
        : GaogaoCharacter(
            stage: widget.state.eggStage,
            phase: widget.state.phase,
            squashTrigger: widget.squashTrigger,
          );

    // ぷるぷるアニメーション
    if (_jiggle.isAnimating) {
      characterWidget = AnimatedBuilder(
        animation: _jiggle,
        builder: (_, child) {
          final shake = math.sin(_jiggle.value * math.pi * 6) * 4;
          return Transform.translate(offset: Offset(shake, 0), child: child);
        },
        child: characterWidget,
      );
    }

    // お着替え演出: ひよこが「その気になって賢くなる」
    final ageMode = widget.state.ageMode;
    final levelAccessory = switch (ageMode) {
      AgeMode.age3 => '🐤',          // ひよこ: そのまま
      AgeMode.age4 => '🎩',          // ペンギンの帽子
      AgeMode.age5 => '🦁',          // ライオンのタテガミ
    };
    final levelCostumeBadge = switch (ageMode) {
      AgeMode.age3 => null,
      AgeMode.age4 => '🐧ぼうし',
      AgeMode.age5 => '🦁タテガミ',
    };
    // 級別ボーダーカラー
    final levelBorder = switch (ageMode) {
      AgeMode.age3 => const Color(0xFFFFD54F),  // 黄
      AgeMode.age4 => const Color(0xFF64B5F6),  // 青
      AgeMode.age5 => const Color(0xFFFF8A65),  // オレンジ
    };

    return GestureDetector(
      onTap: _onInteractiveTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: RadialGradient(colors: [
            Color(adventure.bgColors[0].toInt()).withOpacity(0.95),
            Color(adventure.bgColors[1].toInt()).withOpacity(0.9),
          ]),
          border: Border.all(
            color: widget.state.eggStage >= 7 ? levelBorder : const Color(0xFFE0D5C0),
            width: widget.state.eggStage >= 5 ? 2.5 : 2),
          boxShadow: [BoxShadow(
            color: (widget.state.eggStage >= 5
                ? levelBorder
                : const Color(0xFFE0D5C0)).withOpacity(0.3),
            blurRadius: 16, spreadRadius: 3)],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 冒険背景アイコン
            if (widget.state.currentStage > 1)
              Positioned(right: 4, top: 4,
                child: Text(adventure.emoji, style: const TextStyle(fontSize: 14))),
            characterWidget,
            // お着替えアクセサリー（頭上）
            Positioned(top: 0, right: 2,
              child: Text(levelAccessory, style: const TextStyle(fontSize: 16))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(begin: 0, end: -2, duration: 1200.ms)),
            // お着替えバッジ（左下）
            if (levelCostumeBadge != null)
              Positioned(bottom: 1, left: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: levelBorder.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(levelCostumeBadge, style: const TextStyle(fontSize: 7,
                      fontWeight: FontWeight.bold, color: Color(0xFF5A4A3A))),
                ),
              ),
            // きせかえ
            if (costumeEmoji != null)
              Positioned(top: 4, left: 4,
                child: Text(costumeEmoji, style: const TextStyle(fontSize: 16))),
          ],
        ),
      ),
    );
  }
}

class _ElasticCell extends StatefulWidget {
  final int cellIndex;
  final String label;
  final bool completed;
  final ResonancePhase phase;
  final int waveDelayMs;
  final VoidCallback onTap;
  final String? suggestion; // AI連想候補
  final ThinkingFrame? thinkingFrame; // ライオン級思考フレーム
  const _ElasticCell({
    required this.cellIndex, required this.label, required this.completed,
    required this.phase, required this.waveDelayMs, required this.onTap,
    this.suggestion, this.thinkingFrame,
  });
  @override
  State<_ElasticCell> createState() => _ElasticCellState();
}

class _ElasticCellState extends State<_ElasticCell> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 350.ms);
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.82), weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 0.82, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 70),
    ]).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  // ヒントイラスト（セルの背景に薄く表示して連想を助ける）
  static const _hintEmojis = ['🎨', '🌟', '🎵', '🦋', '🌈', '🍀', '💡', '🌺'];

  // パステルカラー（温かみ）
  static const _pastelBg = [
    Color(0xFFFFF0E0), Color(0xFFF5E0FF), Color(0xFFE0FFF0), Color(0xFFFFF5D0),
    Color(0xFFFFE0E0), Color(0xFFFFE8D0), Color(0xFFE8FFD0), Color(0xFFE0F0FF),
  ];
  static const _pastelBorder = [
    Color(0xFFFFCC80), Color(0xFFCE93D8), Color(0xFF80CBC4), Color(0xFFFFD54F),
    Color(0xFFEF9A9A), Color(0xFFFFAB91), Color(0xFFA5D6A7), Color(0xFF90CAF9),
  ];

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.phase == ResonancePhase.locked;
    // 色付け演出: 未完了はモノクロ、完了でパステルカラーが広がる
    final coloredBg = _pastelBg[widget.cellIndex % 8];
    final bg = widget.completed ? coloredBg : const Color(0xFFF0EDEA);
    final border = _pastelBorder[widget.cellIndex % 8];
    final emoji = ResonanceCell.instrumentEmojis[widget.cellIndex % 8];

    Widget cell = GestureDetector(
      onTapDown: isLocked ? null : (_) => _ctrl.forward(from: 0),
      onTap: isLocked ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: 300.ms,
          decoration: BoxDecoration(
            color: isLocked ? const Color(0xFFF5F0E8) : bg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isLocked ? const Color(0xFFE8E0D5)
                  : widget.completed ? border : border.withOpacity(0.4),
              width: widget.completed ? 2.5 : 1.0,
            ),
            boxShadow: isLocked ? [] : [
              // 柔らかい陰影（3Dぷっくり感）
              BoxShadow(color: border.withOpacity(widget.completed ? 0.35 : 0.12),
                  blurRadius: widget.completed ? 16 : 10, spreadRadius: widget.completed ? 2 : 0,
                  offset: const Offset(0, 3)),
              // 内側ハイライト風
              BoxShadow(color: Colors.white.withOpacity(0.5),
                  blurRadius: 6, spreadRadius: -2, offset: const Offset(0, -2)),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.completed) ...[
                // 完了済み → 入力ラベル表示
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      SuggestionService.emojiFor(widget.label),
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(widget.label,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: border),
                          textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    Text('♪', style: TextStyle(fontSize: 11, color: border, fontWeight: FontWeight.bold))
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .shimmer(duration: 800.ms, color: Colors.white)
                        .scaleXY(end: 1.2, duration: 400.ms),
                  ],
                ),
                CellBurstEffect(trigger: widget.cellIndex + 1),
              ] else if (!isLocked && widget.suggestion != null) ...[
                // 未完了 + AI候補あり → 3Dぷっくりアイコン表示
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ぷっくりアイコン（影付き大きな絵文字）
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: border.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3)),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          SuggestionService.emojiFor(widget.suggestion!),
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(widget.suggestion!,
                        style: TextStyle(fontSize: 10, color: border.withOpacity(0.7),
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center),
                  ],
                ),
              ] else if (isLocked) ...[
                // ロック中 → 薄い絵文字
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Opacity(opacity: 0.2, child: Text(emoji, style: const TextStyle(fontSize: 28))),
                  ],
                ),
              ] else if (widget.thinkingFrame != null) ...[
                // ライオン級: 思考フレームガイド表示
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.thinkingFrame!.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(
                        color: Color(ThinkingFrameworkService.layerColors[widget.thinkingFrame!.layer] ?? 0xFFFFE0B2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(widget.thinkingFrame!.layer,
                          style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold,
                              color: Color(ThinkingFrameworkService.layerAccents[widget.thinkingFrame!.layer] ?? 0xFFFF9800))),
                    ),
                    const SizedBox(height: 2),
                    Text('タップ！', style: TextStyle(fontSize: 9, color: border.withOpacity(0.6),
                        fontWeight: FontWeight.w600)),
                  ],
                ),
              ] else ...[
                // 候補なし＋未ロック → マイク誘導
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: border.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(child: Text('🎤', style: TextStyle(fontSize: 24))),
                    ),
                    const SizedBox(height: 4),
                    Text('タップ！', style: TextStyle(fontSize: 9, color: border.withOpacity(0.5),
                        fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!isLocked) {
      cell = cell.animate()
          .slideY(begin: 0.2, end: 0,
              delay: Duration(milliseconds: widget.waveDelayMs), duration: 500.ms,
              curve: Curves.easeOutBack)
          .fadeIn(delay: Duration(milliseconds: widget.waveDelayMs), duration: 400.ms);
    }
    return cell;
  }
}

// ── ペンギン級接続パス ──────────────────────────────────

class _RoutePath extends StatelessWidget {
  final bool done;
  final Color color;
  const _RoutePath({required this.done, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 400.ms,
      height: 24,
      width: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: done
              ? [color, color.withOpacity(0.5)]
              : [const Color(0xFFE0E0E0), const Color(0xFFE0E0E0)],
        ),
        boxShadow: done ? [
          BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, spreadRadius: 1),
        ] : [],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final int doneCount;
  final int activeCells;
  final ResonancePhase phase;
  final AgeMode ageMode;
  final int currentStage;
  final VoidCallback onParentTap;
  final VoidCallback onRewardTap;
  final String charEmoji;
  final String charName;
  final List<String> equippedEmojis;
  const _TopBar({
    required this.doneCount, required this.activeCells, required this.phase,
    required this.ageMode, required this.currentStage,
    required this.onParentTap, required this.onRewardTap,
    required this.charEmoji, required this.charName,
    this.equippedEmojis = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // スタート画面に戻る
          GestureDetector(
            onTap: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const CharacterSelectScreen()),
              (_) => false),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EBE0), shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD0C8B8))),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Color(0xFF8A7A6A)),
            ),
          ),
          const SizedBox(width: 6),
          Text(charEmoji, style: const TextStyle(fontSize: 22)),
          if (equippedEmojis.isNotEmpty)
            Text(equippedEmojis.join(''), style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Text(charName, style: const TextStyle(
            color: Color(0xFF5A4A3A), fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE0B2), borderRadius: BorderRadius.circular(8)),
            child: Text('${ageMode.emoji} ${ageMode.label} Lv.$currentStage',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8A6A3A))),
          ),
          const Spacer(),
          if (phase != ResonancePhase.locked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0C0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCC80)),
              ),
              child: Text('⭐ $doneCount / $activeCells',
                  style: const TextStyle(color: Color(0xFFE8A030), fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(width: 8),
          // 🤝 ソーシャルボタン
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SocialScreen())),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0E0), shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFCC80), width: 1.5)),
              child: const Text('🤝', style: TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 6),
          // 📷 画像マンダラボタン
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ImageMandalaScreen())),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD), shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF90CAF9), width: 1.5)),
              child: const Text('📷', style: TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 6),
          // おへやボタン
          GestureDetector(
            onTap: onRewardTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: doneCount > 0 ? const Color(0xFFFFE0A0) : const Color(0xFFFFF0D0),
                shape: BoxShape.circle,
                border: Border.all(color: doneCount > 0 ? const Color(0xFFFFB74D) : const Color(0xFFE0D0B0), width: 1.5),
                boxShadow: doneCount > 0
                    ? [BoxShadow(color: const Color(0xFFFFB74D).withOpacity(0.5), blurRadius: 10, spreadRadius: 1)]
                    : [],
              ),
              child: const Text('🏠', style: TextStyle(fontSize: 15)),
            ),
          ),
          const SizedBox(width: 6),
          // 保護者ゲート
          GestureDetector(
            onTap: onParentTap,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EBE0), shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD0C8B8)),
              ),
              child: const Text('🔒', style: TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HintBanner extends StatelessWidget {
  final MandalaState state;
  const _HintBanner({required this.state});

  String get _text {
    final s = AppStrings.current;
    return switch (state.phase) {
      ResonancePhase.locked    => s.hintLocked,
      ResonancePhase.activated => state.doneCount == 0
          ? s.hintStart
          : state.doneCount < state.activeCellCount ~/ 2
              ? s.hintProgress(state.doneCount)
              : state.doneCount < state.activeCellCount
                  ? s.hintAlmost(state.activeCellCount - state.doneCount)
                  : s.hintAllDone,
      ResonancePhase.hatching  => s.hintHatching,
      ResonancePhase.hatched   => s.hintHatched,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DCC8)),
      ),
      child: Text(_text,
          style: const TextStyle(color: Color(0xFF7A6A5A), fontSize: 12, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center),
    );
  }
}

class _ProgressStars extends StatelessWidget {
  final int doneCount;
  final int total;
  const _ProgressStars({required this.doneCount, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final on = i < doneCount;
        return AnimatedContainer(
          duration: 300.ms,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          child: Text(on ? '⭐' : '☆',
              style: TextStyle(fontSize: on ? 20 : 16, color: on ? const Color(0xFFFFB74D) : const Color(0xFFD0C8B8)))
              .animate(target: on ? 1.0 : 0.0).scaleXY(end: 1.3, duration: 300.ms),
        );
      }),
    );
  }
}

// ─── どんぐりバウンス（セル完了時） ──────────────────────

class _AcornRainOverlay extends StatelessWidget {
  const _AcornRainOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final rng = math.Random();
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: List.generate(4, (i) {
            final startX = 60.0 + rng.nextDouble() * (w - 120);
            final delay = Duration(milliseconds: i * 150);
            return Positioned(
              left: startX, top: -30,
              child: const Text('🌰', style: TextStyle(fontSize: 26))
                  .animate()
                  .moveY(begin: 0, end: h * 0.7,
                      duration: 1000.ms, delay: delay, curve: Curves.bounceOut)
                  .moveX(begin: 0, end: (i.isEven ? 25.0 : -25.0),
                      duration: 1000.ms, delay: delay, curve: Curves.easeInOut)
                  .rotate(end: i.isEven ? 0.6 : -0.6, duration: 1000.ms, delay: delay)
                  .then(delay: 50.ms)
                  .scaleXY(end: 0.2, duration: 350.ms, curve: Curves.easeIn)
                  .fadeOut(duration: 300.ms),
            );
          }),
        ),
      ),
    );
  }
}

class _OmakaseButton extends StatelessWidget {
  final List<String> suggestions;
  final int activeCells;
  final List<bool> completed;
  final VoidCallback onTap;
  const _OmakaseButton({
    required this.suggestions, required this.activeCells,
    required this.completed, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = Iterable<int>.generate(activeCells).where((i) => !completed[i]).length;
    if (remaining == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFCC80), Color(0xFFFFAB40)]),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: const Color(0xFFFFAB40).withOpacity(0.35),
                blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✨', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text('おまかせ（のこり$remaining）',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 800.ms, duration: 400.ms).slideY(begin: 0.2);
  }
}

class _WarmBackground extends StatelessWidget {
  final int doneCount;
  final int activeCells;
  final int currentStage;
  const _WarmBackground({required this.doneCount, required this.activeCells, required this.currentStage});

  @override
  Widget build(BuildContext context) {
    final stageIdx = (currentStage - 1).clamp(0, adventureStages.length - 1);
    final adventure = adventureStages[stageIdx];
    final topColor = Color(adventure.bgColors[0].toInt());
    final botColor = Color(adventure.bgColors[1].toInt());

    return AnimatedContainer(
      duration: 800.ms,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [topColor, botColor],
        ),
      ),
    );
  }
}

class _HatchedOverlay extends StatelessWidget {
  final String goal;
  final int currentStage;
  final bool isLionLevel;
  final String charEmoji;
  final String charFullDisplay;
  final VoidCallback onClose;
  final VoidCallback onNextStage;
  final VoidCallback onGacha;
  final VoidCallback? onShareReport;
  const _HatchedOverlay({
    required this.goal, required this.currentStage, this.isLionLevel = false,
    required this.charEmoji, required this.charFullDisplay,
    required this.onClose, required this.onNextStage, required this.onGacha,
    this.onShareReport,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withOpacity(0.55),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF8E7), Color(0xFFFFF0D0)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.7), width: 2),
              boxShadow: [BoxShadow(
                color: const Color(0xFFFFB74D).withOpacity(0.3), blurRadius: 30, spreadRadius: 6)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(charFullDisplay, style: const TextStyle(fontSize: 72))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(end: 1.12, duration: 700.ms)
                    .moveY(begin: 0, end: -8, duration: 700.ms),
                const SizedBox(height: 14),
                Text('$charEmoji が うまれたよ！', textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFE8A030)))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .shimmer(duration: 1200.ms, color: Colors.white),
                const SizedBox(height: 4),
                // ステージクリア表示
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB74D).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('🏆 ステージ $currentStage クリア！',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFE8A030))),
                ),
                const SizedBox(height: 4),
                const Text('🌰 どんぐり ゲット！',
                    style: TextStyle(fontSize: 14, color: Color(0xFF8A6A3A), fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(AppStrings.current.goalLabel(goal), textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Color(0xFFA09080), fontStyle: FontStyle.italic)),
                const SizedBox(height: 16),
                // 次のステージへ（メインボタン）
                FilledButton(
                  onPressed: onNextStage,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB74D), foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('ステージ ${currentStage + 1} へ！🚀',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                // ガチャボタン
                FilledButton.icon(
                  onPressed: onGacha,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63), foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  icon: const Text('🎰', style: TextStyle(fontSize: 18)),
                  label: const Text('びっくらポン！🎫', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
                // ライオン級: SNSシェアボタン
                if (onShareReport != null) ...[
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: onShareReport,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7C4DFF), foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    icon: const Text('📸', style: TextStyle(fontSize: 18)),
                    label: const Text('成長レポートをシェア！', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ],
                const SizedBox(height: 6),
                // 冒険日記
                TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const DailyDiaryScreen())),
                  child: const Text('📔 きょうの ぼうけん にっき',
                      style: TextStyle(fontSize: 12, color: Color(0xFFB09060))),
                ),
                // おへやへ行く（サブ）
                TextButton(
                  onPressed: onClose,
                  child: const Text('おへやを みにいく 🏠',
                      style: TextStyle(fontSize: 12, color: Color(0xFFA09080))),
                ),
              ],
            ),
          ).animate().slideY(begin: 0.3, duration: 600.ms, curve: Curves.easeOutBack).fadeIn(duration: 400.ms),
        ),
      ),
    );
  }
}

// ── ひよこ級【こころのカメラ】メタ認知ダイアログ ──────────

class _HeartCameraDialog extends StatelessWidget {
  final String goal;
  final int cellIndex;
  final void Function(String) onSelect;
  final VoidCallback? onReset;

  const _HeartCameraDialog({
    required this.goal, required this.cellIndex,
    required this.onSelect, this.onReset,
  });

  // 「お友達の気持ち」選択肢
  static const _feelings = [
    ('😊', 'うれしい', 'どんなとき うれしい？'),
    ('😢', 'かなしい', 'なにが かなしかった？'),
    ('😠', 'おこった', 'どうして おこったの？'),
    ('😲', 'びっくり', 'なにに びっくりした？'),
    ('🥰', 'だいすき', 'なにが だいすき？'),
    ('😰', 'こわい',   'なにが こわかった？'),
    ('🤔', 'かんがえ中', 'なにを かんがえてる？'),
    ('😄', 'たのしい', 'なにが たのしかった？'),
  ];

  // やさしい問いかけ（セルごとに変わる）
  static const _prompts = [
    '📷 こころのカメラ！ きもちを パシャリ！',
    '📷 おともだちは どんな きもち？',
    '📷 いま どんな きぶん？',
  ];

  @override
  Widget build(BuildContext context) {
    final prompt = _prompts[cellIndex % _prompts.length];
    return Dialog(
      backgroundColor: const Color(0xFFFFF8EE),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // カメラ演出ヘッダー
            const Text('📷', style: TextStyle(fontSize: 48))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(end: 1.1, duration: 800.ms),
            const SizedBox(height: 8),
            Text(prompt, style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF5A4A3A)),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('「$goal」で おともだちは…', style: const TextStyle(
                fontSize: 12, color: Color(0xFFA09080), fontStyle: FontStyle.italic)),
            const SizedBox(height: 14),

            // 気持ちグリッド（2列×4行）
            SizedBox(
              height: 220,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8,
                    childAspectRatio: 0.85),
                itemCount: _feelings.length,
                itemBuilder: (ctx, i) {
                  final f = _feelings[i];
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onSelect(f.$2);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFD6E0)),
                        boxShadow: [BoxShadow(color: const Color(0xFFFFD6E0).withOpacity(0.3),
                            blurRadius: 6, offset: const Offset(0, 3))],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(f.$1, style: const TextStyle(fontSize: 30)),
                          const SizedBox(height: 2),
                          Text(f.$2, style: const TextStyle(fontSize: 9,
                              fontWeight: FontWeight.bold, color: Color(0xFF8A6A7A))),
                        ],
                      ),
                    ),
                  ).animate()
                      .fadeIn(delay: Duration(milliseconds: i * 60), duration: 300.ms)
                      .scaleXY(begin: 0.8, end: 1.0, delay: Duration(milliseconds: i * 60),
                          duration: 300.ms, curve: Curves.easeOutBack);
                },
              ),
            ),

            const SizedBox(height: 8),
            // やさしい問いかけテキスト
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD6E0).withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                const Text('🐤', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'きもちを えらぶと じぶんの こころが みえるよ！',
                    style: TextStyle(fontSize: 10, color: Colors.brown[400],
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (onReset != null)
                  TextButton(onPressed: onReset,
                    child: const Text('もどす', style: TextStyle(color: Color(0xFFB0A090), fontSize: 12)))
                else const SizedBox.shrink(),
                TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text('とじる', style: TextStyle(color: Color(0xFFB0A090), fontSize: 12))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── ペンギン級【カテゴリー連鎖】ダイアログ ──────────────

class _PenguinCategoryDialog extends StatefulWidget {
  final String goal;
  final int cellIndex;
  final String? prevLabel;
  final void Function(String) onSelect;
  final VoidCallback? onReset;

  const _PenguinCategoryDialog({
    required this.goal, required this.cellIndex,
    this.prevLabel, required this.onSelect, this.onReset,
  });

  @override
  State<_PenguinCategoryDialog> createState() => _PenguinCategoryDialogState();
}

class _PenguinCategoryDialogState extends State<_PenguinCategoryDialog> {
  int _mode = 0; // 0=カテゴリー分け, 1=もしも思考

  // カテゴリー切り口
  static const _categories = [
    ('🎨', 'いろ',   ['あか', 'あお', 'きいろ', 'みどり', 'ピンク', 'むらさき', 'オレンジ', 'しろ']),
    ('🔷', 'かたち', ['まる', 'さんかく', 'しかく', 'ほし', 'ハート', 'ひしがた']),
    ('🛠️', 'つかいかた', ['たべる', 'あそぶ', 'のる', 'きる', 'つくる', 'まなぶ']),
    ('📍', 'ばしょ', ['おうち', 'こうえん', 'がっこう', 'おみせ', 'やま', 'うみ']),
  ];

  // もしも〜なら カード
  static const _ifThenCards = [
    ('☀️ もし はれたら…',  ['おさんぽ', 'プール', 'ピクニック', 'おにごっこ']),
    ('☔ もし あめなら…',   ['おえかき', 'えほん', 'ねんど', 'おうちあそび']),
    ('🎄 もし クリスマスなら…', ['プレゼント', 'ケーキ', 'おほしさま', 'サンタさん']),
    ('🚀 もし うちゅうにいったら…', ['ほし', 'ちきゅう', 'ロケット', 'うちゅうじん']),
  ];

  @override
  Widget build(BuildContext context) {
    final ifThen = _ifThenCards[widget.cellIndex % _ifThenCards.length];
    final category = _categories[widget.cellIndex % _categories.length];

    return Dialog(
      backgroundColor: const Color(0xFFE8F4FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダー
            Row(
              children: [
                const Text('🐧', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.prevLabel != null
                            ? '「${widget.prevLabel}」の つぎは？'
                            : '「${widget.goal}」を しらべよう！',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900,
                            color: Color(0xFF2A4A6A)),
                      ),
                      const Text('カテゴリー連鎖おもしろい！',
                          style: TextStyle(fontSize: 10, color: Color(0xFF6A8AAA))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // モード切替タブ
            Row(children: [
              Expanded(child: _ModeTab(
                label: '🎨 なかまわけ', selected: _mode == 0,
                onTap: () => setState(() => _mode = 0),
              )),
              const SizedBox(width: 8),
              Expanded(child: _ModeTab(
                label: '🤔 もしも…', selected: _mode == 1,
                onTap: () => setState(() => _mode = 1),
              )),
            ]),
            const SizedBox(height: 12),

            if (_mode == 0) ...[
              // カテゴリー分けモード
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Text(category.$1, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 6),
                  Text('「${category.$2}」で わけると…',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                          color: Color(0xFF2A4A6A))),
                ]),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: category.$3.map((item) => GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    widget.onSelect(item);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF90CAF9)),
                      boxShadow: [BoxShadow(color: const Color(0xFF90CAF9).withOpacity(0.2),
                          blurRadius: 6, offset: const Offset(0, 3))],
                    ),
                    child: Text(item, style: const TextStyle(fontSize: 14,
                        fontWeight: FontWeight.bold, color: Color(0xFF2A4A6A))),
                  ),
                )).toList(),
              ),
            ] else ...[
              // もしも〜なら？ モード
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    const Color(0xFF90CAF9).withOpacity(0.2),
                    const Color(0xFFCE93D8).withOpacity(0.2),
                  ]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(ifThen.$1,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900,
                        color: Color(0xFF4A3A6A)),
                    textAlign: TextAlign.center),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: ifThen.$2.map((item) => GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    widget.onSelect(item);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFCE93D8)),
                      boxShadow: [BoxShadow(color: const Color(0xFFCE93D8).withOpacity(0.2),
                          blurRadius: 6, offset: const Offset(0, 3))],
                    ),
                    child: Text(item, style: const TextStyle(fontSize: 14,
                        fontWeight: FontWeight.bold, color: Color(0xFF4A3A6A))),
                  ),
                )).toList(),
              ),
            ],

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.onReset != null)
                  TextButton(onPressed: widget.onReset,
                    child: const Text('もどす', style: TextStyle(color: Color(0xFFB0A090), fontSize: 12)))
                else const SizedBox.shrink(),
                TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text('とじる', style: TextStyle(color: Color(0xFFB0A090), fontSize: 12))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF64B5F6) : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xFF42A5F5) : const Color(0xFFBBDEFB)),
        ),
        child: Center(
          child: Text(label, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold,
              color: selected ? Colors.white : const Color(0xFF64B5F6))),
        ),
      ),
    );
  }
}

// ── ライオン級 思考フレームダイアログ ─────────────────────

class _LionThinkingDialog extends StatelessWidget {
  final ThinkingFrame frame;
  final Color layerColor;
  final bool completed;
  final void Function(String) onConfirm;
  final VoidCallback? onReset;
  final TextEditingController controller;

  const _LionThinkingDialog({
    required this.frame, required this.layerColor, required this.completed,
    required this.onConfirm, this.onReset, required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: const Color(0xFFFFF8EE),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // レイヤーバッジ
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: layerColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: layerColor.withOpacity(0.4)),
              ),
              child: Text(
                '🦁 ${frame.layer}',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: layerColor),
              ),
            ),
            const Spacer(),
            Text(frame.emoji, style: const TextStyle(fontSize: 28)),
          ]),
          const SizedBox(height: 10),
          // ガイド質問
          Text(
            frame.prompt,
            style: const TextStyle(
              color: Color(0xFF4A3A2A), fontWeight: FontWeight.bold, fontSize: 15, height: 1.4),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'じぶんの ことばで こたえてね！',
            style: TextStyle(fontSize: 11, color: Colors.brown[400], fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            autofocus: true,
            maxLength: 20,
            style: const TextStyle(color: Color(0xFF4A3A2A), fontSize: 16),
            decoration: InputDecoration(
              hintText: 'かんがえて かいてみよう',
              hintStyle: const TextStyle(color: Color(0xFFCCC0B0)),
              counterStyle: const TextStyle(color: Color(0xFFCCC0B0)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.6),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: layerColor.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: layerColor, width: 2),
              ),
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        Row(
          children: [
            if (onReset != null)
              TextButton(
                onPressed: onReset,
                child: const Text('もどす', style: TextStyle(color: Color(0xFFB0A090), fontSize: 12)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('キャンセル', style: TextStyle(color: Color(0xFFB0A090))),
            ),
          ],
        ),
        FilledButton(
          onPressed: () {
            final t = controller.text.trim();
            if (t.isNotEmpty) onConfirm(t);
            Navigator.pop(context);
          },
          style: FilledButton.styleFrom(
            backgroundColor: layerColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 4,
            shadowColor: layerColor.withOpacity(0.5),
          ),
          child: const Text('できた！♪', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ],
    );
  }
}

// ── ネオンダイアログ（ペンギン級テキスト入力） ────────────────

class _NeonDialog extends StatelessWidget {
  final String icon;
  final String title;
  final String? subtitle;
  final String hintText;
  final int maxLength;
  final String confirmLabel;
  final void Function(String) onConfirm;
  final List<Widget> extraActions;
  final TextEditingController controller;

  const _NeonDialog({
    required this.icon, required this.title, this.subtitle,
    required this.hintText, required this.maxLength, required this.confirmLabel,
    required this.onConfirm, this.extraActions = const [], required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: const Color(0xFFFFF0E0), // パステル・サンセットオレンジ
      title: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 8),
        Flexible(child: Text(title, style: const TextStyle(
            color: Color(0xFF5A4A3A), fontWeight: FontWeight.bold, fontSize: 16))),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle != null) ...[
            Text(subtitle!, style: const TextStyle(fontSize: 11, color: Color(0xFFA09080), fontStyle: FontStyle.italic)),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: controller,
            autofocus: true,
            maxLength: maxLength,
            style: const TextStyle(color: Color(0xFF4A3A2A), fontSize: 16),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Color(0xFFCCC0B0)),
              counterStyle: const TextStyle(color: Color(0xFFCCC0B0)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.6),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFE8D5C0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: Color(0xFFFFB74D), width: 2),
              ),
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        Row(
          children: [
            ...extraActions,
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: const Text('キャンセル', style: TextStyle(color: Color(0xFFB0A090))),
            ),
          ],
        ),
        // ぷっくりボタン
        FilledButton(
          onPressed: () {
            final t = controller.text.trim();
            if (t.isNotEmpty) onConfirm(t);
            Navigator.pop(context);
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFFB74D),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 4,
            shadowColor: const Color(0xFFFFB74D).withOpacity(0.5),
          ),
          child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ],
    );
  }
}

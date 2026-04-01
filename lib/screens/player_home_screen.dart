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
      // 孵化完了→どんぐり+ガチャチケット獲得
      if (prev?.phase != ResonancePhase.hatched && next.phase == ResonancePhase.hatched) {
        ref.read(rewardProvider.notifier).earnAcorn();
        ref.read(collectionProvider.notifier).addTicket();
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
                ),
                const SizedBox(height: 4),
                // プピィ自律挨拶（常時表示）
                _PuppyGreetingBubble(),
                if (state.phase != ResonancePhase.locked)
                  _HintBanner(state: state),
                const SizedBox(height: 6),

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
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                          itemCount: 9,
                          itemBuilder: (ctx, gi) {
                            final ci = gridMap[gi];
                            if (ci == null) {
                              // Center puppy
                              return _PuppyCell(
                                state: state,
                                squashTrigger: _squashTrigger,
                                onTap: () => _onCenterTap(context, state, notifier),
                              );
                            }
                            if (ci == -1) {
                              // Empty hidden slot
                              return const SizedBox.shrink();
                            }
                            return _ElasticCell(
                              cellIndex: ci,
                              label: state.labels[ci],
                              completed: state.completed[ci],
                              phase: state.phase,
                              waveDelayMs: ci * 100,
                              onTap: () => _onCellTap(context, state, notifier, ci),
                              suggestion: ci < suggestions.length ? suggestions[ci] : null,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (state.phase == ResonancePhase.activated)
                  _ProgressStars(doneCount: state.doneCount, total: state.activeCellCount),
                // おまかせボタン（AI提案で全マス自動入力）
                if (state.phase == ResonancePhase.activated &&
                    suggestions.isNotEmpty &&
                    state.doneCount < state.activeCellCount)
                  _OmakaseButton(
                    suggestions: suggestions,
                    activeCells: state.activeCellCount,
                    completed: state.completed,
                    onTap: () => _autoFillAll(notifier, state, suggestions),
                  ),
                const SizedBox(height: 12),
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
              onClose: notifier.reset,
              onNextStage: notifier.advanceStage,
              onGacha: () {
                notifier.advanceStage();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GachaScreen()));
              },
            ),
        ],
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
    // 3歳モード → スタンプ＆音声入力ダイアログ
    if (s.ageMode == AgeMode.age3) {
      showDialog(
        context: ctx,
        builder: (_) => _StampDialog(
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
    } else {
      // 4-5歳モード → テキスト入力ダイアログ
      final ctrl = TextEditingController();
      showDialog(
        context: ctx,
        builder: (_) => _NeonDialog(
          icon: ResonanceCell.instrumentEmojis[ci % 8],
          title: AppStrings.current.cellDialogTitle,
          subtitle: AppStrings.current.goalSubtitle(s.goal),
          hintText: AppStrings.current.cellDialogHint,
          maxLength: 20,
          confirmLabel: AppStrings.current.cellDialogConfirm,
          onConfirm: (text) {
            n.completeCell(ci, label: text).then((_) {
              HapticFeedback.heavyImpact();
              _onCellComplete();
            });
          },
          extraActions: s.completed[ci] ? [
            TextButton(
              onPressed: () { n.resetCell(ci); Navigator.pop(ctx); },
              child: Text(AppStrings.current.cellDialogReset,
                  style: const TextStyle(color: Color(0xFFB0A090), fontSize: 12)),
            ),
          ] : [],
          controller: ctrl,
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

class _CoachingBubble extends StatelessWidget {
  final String goal;
  final AgeMode ageMode;
  const _CoachingBubble({required this.goal, required this.ageMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          const Text('🐰', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '「$goal」${ageMode.coachingPrompt}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF5A4A3A), fontWeight: FontWeight.w500),
            ),
          ),
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

    Widget puppyWidget = PuppyCharacter(
      stage: widget.state.eggStage,
      phase: widget.state.phase,
      squashTrigger: widget.squashTrigger,
    );

    // ぷるぷるアニメーション
    if (_jiggle.isAnimating) {
      puppyWidget = AnimatedBuilder(
        animation: _jiggle,
        builder: (_, child) {
          final shake = math.sin(_jiggle.value * math.pi * 6) * 4;
          return Transform.translate(offset: Offset(shake, 0), child: child);
        },
        child: puppyWidget,
      );
    }

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
            color: widget.state.eggStage >= 7 ? const Color(0xFFFFB74D) : const Color(0xFFE0D5C0),
            width: 2),
          boxShadow: [BoxShadow(
            color: (widget.state.eggStage >= 5
                ? const Color(0xFFFFB74D)
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
            puppyWidget,
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
  const _ElasticCell({
    required this.cellIndex, required this.label, required this.completed,
    required this.phase, required this.waveDelayMs, required this.onTap,
    this.suggestion,
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
    final bg = _pastelBg[widget.cellIndex % 8];
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

class _TopBar extends StatelessWidget {
  final int doneCount;
  final int activeCells;
  final ResonancePhase phase;
  final AgeMode ageMode;
  final int currentStage;
  final VoidCallback onParentTap;
  final VoidCallback onRewardTap;
  const _TopBar({
    required this.doneCount, required this.activeCells, required this.phase,
    required this.ageMode, required this.currentStage,
    required this.onParentTap, required this.onRewardTap,
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
          const Text('🐰', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 6),
          Text(AppStrings.current.characterName, style: const TextStyle(
            color: Color(0xFF5A4A3A), fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE0B2), borderRadius: BorderRadius.circular(8)),
            child: Text('${ageMode.label} Lv.$currentStage',
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
          // プピィの家（おへやボタン）
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
  final VoidCallback onClose;
  final VoidCallback onNextStage;
  final VoidCallback onGacha;
  const _HatchedOverlay({
    required this.goal, required this.currentStage,
    required this.onClose, required this.onNextStage, required this.onGacha,
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
                const Text('🐰', style: TextStyle(fontSize: 72))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(end: 1.12, duration: 700.ms)
                    .moveY(begin: 0, end: -8, duration: 700.ms),
                const SizedBox(height: 14),
                Text(AppStrings.current.hatchedTitle, textAlign: TextAlign.center,
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
                const SizedBox(height: 6),
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

// ── スタンプ入力ダイアログ（3歳モード） ────────────────────

class _StampDialog extends StatelessWidget {
  final String goal;
  final int cellIndex;
  final void Function(String) onSelect;
  final VoidCallback? onReset;

  const _StampDialog({
    required this.goal, required this.cellIndex,
    required this.onSelect, this.onReset,
  });

  // テーマに応じた絵スタンプカード
  static const _stamps = [
    ('🐕', 'いぬ'), ('🐈', 'ねこ'), ('🐰', 'うさぎ'), ('🐻', 'くま'),
    ('🌸', 'おはな'), ('⭐', 'ほし'), ('🌈', 'にじ'), ('🎵', 'おんがく'),
    ('🍎', 'りんご'), ('🚗', 'くるま'), ('🏠', 'おうち'), ('☀️', 'おひさま'),
    ('🎈', 'ふうせん'), ('🦋', 'ちょうちょ'), ('🐟', 'さかな'), ('🍦', 'アイス'),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFFF0E0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダー
            Text('「$goal」に つながるもの', style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF5A4A3A))),
            const SizedBox(height: 4),
            const Text('えを えらんでね！', style: TextStyle(fontSize: 12, color: Color(0xFFA09080))),
            const SizedBox(height: 14),

            // マイクボタン（音声入力）
            GestureDetector(
              onTap: () {
                // TODO: Whisper音声入力連携
                HapticFeedback.mediumImpact();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB74D), Color(0xFFFF8A65)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: const Color(0xFFFFB74D).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🎤', style: TextStyle(fontSize: 28)),
                    SizedBox(width: 8),
                    Text('こえで おしえて！', style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text('または えを タップ！', style: TextStyle(fontSize: 11, color: Color(0xFFB0A090))),
            const SizedBox(height: 8),

            // スタンプグリッド
            SizedBox(
              height: 200,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: _stamps.length,
                itemBuilder: (ctx, i) {
                  final stamp = _stamps[i];
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onSelect(stamp.$2);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8D5C0)),
                        boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(stamp.$1, style: const TextStyle(fontSize: 26)),
                          Text(stamp.$2, style: const TextStyle(fontSize: 8, color: Color(0xFF8A7A6A))),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),
            // フッター
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (onReset != null)
                  TextButton(
                    onPressed: onReset,
                    child: const Text('もどす', style: TextStyle(color: Color(0xFFB0A090), fontSize: 12)),
                  )
                else const SizedBox.shrink(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('とじる', style: TextStyle(color: Color(0xFFB0A090), fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── ネオンダイアログ（4-5歳テキスト入力） ─────────────────

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

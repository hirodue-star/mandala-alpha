import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/chart_cell.dart';

// ─────────────────────────────────────────────
// マンダラチャートMVP
// ・起動時: 中央Goalのみ表示、周囲8マスはロック状態
// ・中央タップ: 波紋アニメーションで8マスが展開
// ・各マスタップ: 行動入力 → 完了で金色発光
// ・全完了: 祝福オーバーレイ
// ─────────────────────────────────────────────

enum _ChartPhase { locked, activated, celebrating }

class MandalaChartScreen extends StatefulWidget {
  const MandalaChartScreen({super.key});

  @override
  State<MandalaChartScreen> createState() => _MandalaChartScreenState();
}

class _MandalaChartScreenState extends State<MandalaChartScreen>
    with TickerProviderStateMixin {
  _ChartPhase _phase = _ChartPhase.locked;
  String _goal = 'ゴールを\n設定する';

  late final AnimationController _rippleController;
  late final AnimationController _celebrateController;

  // 8マス（時計回り: 上→右上→右→右下→下→左下→左→左上）
  static const List<String> _icons = ['📝', '💡', '💪', '🎯', '🔑', '⭐', '🌟', '🏆'];
  final List<String> _labels = [
    'アクション①', 'アクション②', 'アクション③', 'アクション④',
    'アクション⑤', 'アクション⑥', 'アクション⑦', 'アクション⑧',
  ];
  final List<CellStatus> _statuses = List.filled(8, CellStatus.empty);

  // グリッド配置 (null = 中央)
  static const List<int?> _gridMap = [7, 0, 1, 6, null, 2, 5, 4, 3];

  // 各セルのアニメーション遅延（中央から波紋状に）
  static const List<int> _waveDelay = [
    100, // 右上(1)
    200, // 右(2)
    300, // 右下(3)
    200, // 下(4)
    100, // 左下(5)
    0,   // 左(6) ← 最初
    100, // 左上(7)
    0,   // 上(0) ← 最初
  ];

  int get _doneCount => _statuses.where((s) => s == CellStatus.done).length;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _celebrateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _celebrateController.dispose();
    super.dispose();
  }

  void _onCenterTap() {
    if (_phase == _ChartPhase.locked) {
      HapticFeedback.mediumImpact();
      _showGoalInputDialog(onSet: () {
        setState(() => _phase = _ChartPhase.activated);
        _rippleController.forward(from: 0);
      });
    } else {
      _showGoalInputDialog();
    }
  }

  void _showGoalInputDialog({VoidCallback? onSet}) {
    final controller = TextEditingController(
      text: _goal.replaceAll('\n', ' '),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: const [
            Text('🎯', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text('ゴールを設定', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(
            hintText: '例：英検2級に合格する',
            border: OutlineInputBorder(),
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) setState(() => _goal = text);
              Navigator.pop(ctx);
              onSet?.call();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7C4DFF),
            ),
            child: const Text('スタート！'),
          ),
        ],
      ),
    );
  }

  void _onCellTap(int cellIndex) {
    if (_phase != _ChartPhase.activated) return;
    HapticFeedback.selectionClick();

    final controller = TextEditingController(text: _labels[cellIndex]);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          '${_icons[cellIndex]} アクションを入力',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ゴール: $_goal',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 20,
              decoration: const InputDecoration(
                hintText: 'ゴールに向けた行動',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          if (_statuses[cellIndex] == CellStatus.done)
            OutlinedButton(
              onPressed: () {
                setState(() => _statuses[cellIndex] = CellStatus.empty);
                Navigator.pop(ctx);
              },
              child: const Text('未完了に戻す'),
            ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              setState(() {
                if (text.isNotEmpty) _labels[cellIndex] = text;
                _statuses[cellIndex] = CellStatus.done;
              });
              Navigator.pop(ctx);
              HapticFeedback.heavyImpact();
              if (_doneCount == 8) _startCelebration();
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black87,
            ),
            child: const Text('完了！✓'),
          ),
        ],
      ),
    );
  }

  void _startCelebration() {
    setState(() => _phase = _ChartPhase.celebrating);
    _celebrateController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF4A4A6A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'マンダラチャート',
          style: TextStyle(
            color: Color(0xFF4A4A6A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_phase != _ChartPhase.locked)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '$_doneCount / 8',
                  style: const TextStyle(
                    color: Color(0xFF7C4DFF),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _PhaseHint(phase: _phase, doneCount: _doneCount),
                const SizedBox(height: 12),
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
                          return _CenterCell(
                            goal: _goal,
                            phase: _phase,
                            onTap: _onCenterTap,
                          );
                        }
                        return _SurroundingCell(
                          icon: _icons[cellIndex],
                          label: _labels[cellIndex],
                          status: _statuses[cellIndex],
                          phase: _phase,
                          waveDelayMs: _waveDelay[cellIndex],
                          onTap: () => _onCellTap(cellIndex),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_phase == _ChartPhase.activated)
                  _ProgressRow(doneCount: _doneCount),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // 祝福オーバーレイ
          if (_phase == _ChartPhase.celebrating)
            _CelebrationOverlay(
              onClose: () {
                setState(() => _phase = _ChartPhase.activated);
                _celebrateController.reset();
              },
            ),
        ],
      ),
    );
  }
}

// ─── ウィジェット群 ────────────────────────────────────────

class _PhaseHint extends StatelessWidget {
  final _ChartPhase phase;
  final int doneCount;
  const _PhaseHint({required this.phase, required this.doneCount});

  String get _text {
    switch (phase) {
      case _ChartPhase.locked:
        return '🎯 中央のゴールをタップしてスタート！';
      case _ChartPhase.activated:
        if (doneCount == 0) return '💡 各マスをタップしてアクションを入力しよう';
        if (doneCount < 4) return '💪 いい調子！続けよう ($doneCount/8)';
        if (doneCount < 8) return '🌟 もう少し！あと ${8 - doneCount} マス';
        return '🏆 全マス完了！すごい！';
      case _ChartPhase.celebrating:
        return '🎉 マンダラチャート完成！';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: phase == _ChartPhase.locked
            ? const Color(0xFFEDE7FF)
            : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              _text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterCell extends StatelessWidget {
  final String goal;
  final _ChartPhase phase;
  final VoidCallback onTap;
  const _CenterCell({required this.goal, required this.phase, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLocked = phase == _ChartPhase.locked;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLocked
                ? [const Color(0xFF9C6FFF), const Color(0xFF7C4DFF)]
                : [const Color(0xFF7C4DFF), const Color(0xFF5E35B1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C4DFF)
                  .withOpacity(isLocked ? 0.35 : 0.55),
              blurRadius: isLocked ? 10 : 18,
              spreadRadius: isLocked ? 0 : 3,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLocked ? '🎯' : '✨',
              style: const TextStyle(fontSize: 22),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(end: 1.12, duration: 900.ms, curve: Curves.easeInOut),
            const SizedBox(height: 3),
            if (!isLocked) ...[
              const Text(
                'GOAL',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.white60,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                isLocked ? 'タップして\nスタート' : goal,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(end: 1.03, duration: 1800.ms, curve: Curves.easeInOut),
    );
  }
}

class _SurroundingCell extends StatelessWidget {
  final String icon;
  final String label;
  final CellStatus status;
  final _ChartPhase phase;
  final int waveDelayMs;
  final VoidCallback onTap;
  const _SurroundingCell({
    required this.icon,
    required this.label,
    required this.status,
    required this.phase,
    required this.waveDelayMs,
    required this.onTap,
  });

  Color get _bgColor {
    if (phase == _ChartPhase.locked) return const Color(0xFFEEEEEE);
    switch (status) {
      case CellStatus.done:
        return const Color(0xFFFFD700);
      case CellStatus.trying:
        return const Color(0xFFFFE082);
      case CellStatus.empty:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = phase == _ChartPhase.locked;
    final isDone = status == CellStatus.done;

    Widget cell_ = GestureDetector(
      onTap: isLocked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone
                ? const Color(0xFFFFD700)
                : isLocked
                    ? Colors.grey.shade300
                    : const Color(0xFFE0D7FF),
            width: isDone ? 2 : 1.5,
          ),
          boxShadow: isDone
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(isLocked ? 0.03 : 0.07),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedOpacity(
              opacity: isLocked ? 0.3 : 1.0,
              duration: const Duration(milliseconds: 400),
              child: Text(
                icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedOpacity(
              opacity: isLocked ? 0.3 : 1.0,
              duration: const Duration(milliseconds: 400),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDone
                        ? const Color(0xFF5D4037)
                        : const Color(0xFF4A4A6A),
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (isDone)
              const Text('✓', style: TextStyle(fontSize: 14, color: Color(0xFF5D4037)))
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .shimmer(duration: 1400.ms),
          ],
        ),
      ),
    );

    // ロック解除時の波紋アニメーション
    if (phase != _ChartPhase.locked) {
      cell_ = cell_
          .animate()
          .slideY(
            begin: 0.3,
            end: 0,
            delay: Duration(milliseconds: waveDelayMs),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
          )
          .fadeIn(
            delay: Duration(milliseconds: waveDelayMs),
            duration: const Duration(milliseconds: 400),
          );
    }

    return cell_;
  }
}

class _ProgressRow extends StatelessWidget {
  final int doneCount;
  const _ProgressRow({required this.doneCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '達成マス',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              '$doneCount / 8',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7C4DFF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: doneCount / 8,
            minHeight: 10,
            backgroundColor: const Color(0xFFE0D7FF),
            valueColor: AlwaysStoppedAnimation(
              doneCount == 8 ? const Color(0xFFFFD700) : const Color(0xFF7C4DFF),
            ),
          ),
        ),
      ],
    );
  }
}

class _CelebrationOverlay extends StatelessWidget {
  final VoidCallback onClose;
  const _CelebrationOverlay({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 64))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(end: 1.15, duration: 600.ms),
                const SizedBox(height: 16),
                const Text(
                  'マンダラチャート\n完成！',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4A4A6A),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '8つのアクションをすべて\n設定しました！',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onClose,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C4DFF),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '閉じる',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .slideY(begin: 0.3, duration: 500.ms, curve: Curves.easeOutBack)
              .fadeIn(duration: 400.ms),
        ),
      ),
    );
  }
}

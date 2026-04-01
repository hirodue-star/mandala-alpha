import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mandala_providers.dart';
import '../providers/context_providers.dart';
import '../providers/character_providers.dart';
import '../models/mandala_state.dart';
import '../l10n/strings.dart';

// ─────────────────────────────────────────────────────────
// ParentDashboardScreen — 保護者用 知育レポート
//
// Nine Matrix Method™ ダッシュボード
// 3指標: メタ認知・集中力・論理的思考
// ─────────────────────────────────────────────────────────

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mandalaProvider);
    final analytics = ref.watch(analyticsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF060E1F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppStrings.current.dashTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nine Matrix Method バナー
            _NineMatrixBanner(),
            const SizedBox(height: 16),

            // 今日のトピック入力（親 → プピィ連携）
            _ParentTopicCard(ref: ref),
            const SizedBox(height: 16),

            // 今日のゴール
            if (state.goal.isNotEmpty) _GoalCard(goal: state.goal),
            const SizedBox(height: 16),

            // 3指標レーダー
            _MetricsRadarCard(
              metacognition: analytics.metacognition,
              focus: analytics.focus,
              logicalThinking: analytics.logicalThinking,
              doneCount: state.doneCount,
            ),
            const SizedBox(height: 16),

            // 完了マス一覧
            if (state.logs.isNotEmpty) _CompletionLog(state: state),
            const SizedBox(height: 16),

            // キャラクター興味分析
            _InterestAnalysis(ref: ref),
            const SizedBox(height: 16),

            // 学術的根拠セクション
            _EvidenceSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Nine Matrix Method バナー ─────────────────────────────

class _NineMatrixBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0A3D), Color(0xFF0A1A3D)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.6), width: 1.5),
        boxShadow: [BoxShadow(
          color: const Color(0xFF7C4DFF).withOpacity(0.2),
          blurRadius: 20, spreadRadius: 2,
        )],
      ),
      child: Row(
        children: [
          const Text('✦', style: TextStyle(fontSize: 28, color: Color(0xFF7FDBFF))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.current.methodName,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  AppStrings.current.methodSubtitle,
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: -0.1, end: 0, duration: 500.ms);
  }
}

// ─── ゴールカード ──────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  final String goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.current.todayGoal, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                const SizedBox(height: 3),
                Text(goal, style: const TextStyle(
                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 3指標レーダーチャート ─────────────────────────────────

class _MetricsRadarCard extends StatelessWidget {
  final double metacognition;
  final double focus;
  final double logicalThinking;
  final int doneCount;

  const _MetricsRadarCard({
    required this.metacognition, required this.focus,
    required this.logicalThinking, required this.doneCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.current.metricsTitle,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            doneCount == 0 ? AppStrings.current.metricsEmpty : AppStrings.current.metricsAnalyzed,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 16),

          if (doneCount > 0) ...[
            // レーダーチャート
            Center(
              child: SizedBox(
                width: 200, height: 200,
                child: CustomPaint(
                  painter: _RadarChartPainter(
                    values: [metacognition, focus, logicalThinking],
                    labels: AppStrings.current.radarLabels,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // バー指標（常に表示）
          _MetricBar(label: AppStrings.current.metaLabel, value: metacognition,
              color: const Color(0xFF7FDBFF), desc: AppStrings.current.metaDesc),
          const SizedBox(height: 10),
          _MetricBar(label: AppStrings.current.focusLabel, value: focus,
              color: const Color(0xFFFFD740), desc: AppStrings.current.focusDesc),
          const SizedBox(height: 10),
          _MetricBar(label: AppStrings.current.logicLabel, value: logicalThinking,
              color: const Color(0xFF69F0AE), desc: AppStrings.current.logicDesc),
        ],
      ),
    );
  }
}

class _MetricBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String desc;
  const _MetricBar({required this.label, required this.value, required this.color, required this.desc});

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            Text('$pct%', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 2),
        Text(desc, style: const TextStyle(color: Colors.white24, fontSize: 10)),
      ],
    );
  }
}

// ─── RadarChart CustomPainter ─────────────────────────────

class _RadarChartPainter extends CustomPainter {
  final List<double> values; // 0.0〜1.0 × 3
  final List<String> labels;
  _RadarChartPainter({required this.values, required this.labels});

  static const _colors = [Color(0xFF7FDBFF), Color(0xFFFFD740), Color(0xFF69F0AE)];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 24;
    const n = 3;

    // グリッド線（3段階）
    for (int r = 1; r <= 3; r++) {
      final rf = radius * r / 3;
      final gridPath = Path();
      for (int i = 0; i < n; i++) {
        final angle = -math.pi / 2 + i * 2 * math.pi / n;
        final pt = center + Offset(math.cos(angle) * rf, math.sin(angle) * rf);
        i == 0 ? gridPath.moveTo(pt.dx, pt.dy) : gridPath.lineTo(pt.dx, pt.dy);
      }
      gridPath.close();
      canvas.drawPath(gridPath, Paint()
        ..color = Colors.white.withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
    }

    // 軸線
    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / n;
      final end = center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      canvas.drawLine(center, end, Paint()..color = Colors.white12..strokeWidth = 1);
    }

    // 値のポリゴン
    final dataPath = Path();
    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / n;
      final r = radius * values[i];
      final pt = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      i == 0 ? dataPath.moveTo(pt.dx, pt.dy) : dataPath.lineTo(pt.dx, pt.dy);
    }
    dataPath.close();
    canvas.drawPath(dataPath, Paint()
      ..color = const Color(0xFF7C4DFF).withOpacity(0.3)
      ..style = PaintingStyle.fill);
    canvas.drawPath(dataPath, Paint()
      ..color = const Color(0xFF7C4DFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    // 頂点の点
    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / n;
      final r = radius * values[i];
      final pt = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      canvas.drawCircle(pt, 5, Paint()..color = _colors[i]);
    }

    // ラベル
    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / n;
      final labelR = radius + 18.0;
      final pt = center + Offset(math.cos(angle) * labelR, math.sin(angle) * labelR);
      final tp = TextPainter(
        text: TextSpan(text: labels[i], style: const TextStyle(color: Colors.white60, fontSize: 11)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pt - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_RadarChartPainter old) =>
      old.values[0] != values[0] || old.values[1] != values[1] || old.values[2] != values[2];
}

// ─── 完了ログ ─────────────────────────────────────────────

class _CompletionLog extends StatelessWidget {
  final MandalaState state;
  const _CompletionLog({required this.state});

  static const _neonAccents = [
    Color(0xFF40C4FF), Color(0xFFCE93D8), Color(0xFF69F0AE), Color(0xFFFFD740),
    Color(0xFFFF5252), Color(0xFFFF6D00), Color(0xFF76FF03), Color(0xFF18FFFF),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.current.logCount(state.logs.length),
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...state.logs.asMap().entries.map((e) {
            final log = e.value;
            final accent = _neonAccents[log.cellIndex % 8];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      log.enteredLabel,
                      style: TextStyle(color: log.labelCustomized ? Colors.white : Colors.white54, fontSize: 12),
                    ),
                  ),
                  if (log.labelCustomized)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF69F0AE).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF69F0AE).withOpacity(0.4)),
                      ),
                      child: Text(AppStrings.current.logCustomTag, style: const TextStyle(color: Color(0xFF69F0AE), fontSize: 9)),
                    ),
                  const SizedBox(width: 6),
                  Text(
                    AppStrings.current.logTime(log.elapsedSinceStart.inMinutes, log.elapsedSinceStart.inSeconds % 60),
                    style: const TextStyle(color: Colors.white24, fontSize: 10),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── 学術的根拠セクション ─────────────────────────────────

class _EvidenceSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0A1A3D).withOpacity(0.8),
            const Color(0xFF1A0A3D).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF40C4FF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📖', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(AppStrings.current.evidenceTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.current.evidenceBody,
            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.7),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12),
          const SizedBox(height: 10),
          ...AppStrings.current.evidenceItems.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title.split(' ')[0], style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title.split(' ').skip(1).join(' '),
                          style: const TextStyle(color: Color(0xFF7FDBFF), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(item.body, style: const TextStyle(color: Colors.white38, fontSize: 11, height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ─── キャラクター興味分析 ─────────────────────────────────

class _InterestAnalysis extends StatelessWidget {
  final WidgetRef ref;
  const _InterestAnalysis({required this.ref});

  @override
  Widget build(BuildContext context) {
    final charState = ref.watch(characterProvider);
    final total = charState.puppyPlayCount + charState.gaogaoPlayCount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Text('🎭', style: TextStyle(fontSize: 18)),
            SizedBox(width: 8),
            Text('キャラクター興味分析',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          // バー
          Row(children: [
            const Text('🐰', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: total > 0 ? 1.0 - charState.interestRatio : 0.5,
                  minHeight: 10,
                  backgroundColor: const Color(0xFF4CAF50).withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFFFFB3DE)),
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Text('🦕', style: TextStyle(fontSize: 16)),
          ]),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('プピィ ${charState.puppyPlayCount}回',
                style: const TextStyle(color: Color(0xFFFFB3DE), fontSize: 11)),
            Text(charState.preferenceLabel,
                style: const TextStyle(color: Colors.white54, fontSize: 10)),
            Text('ガオガオ ${charState.gaogaoPlayCount}回',
                style: const TextStyle(color: Color(0xFF81C784), fontSize: 11)),
          ]),
        ],
      ),
    );
  }
}

// ─── 今日のトピック入力 ──────────────────────────────────

class _ParentTopicCard extends StatefulWidget {
  final WidgetRef ref;
  const _ParentTopicCard({required this.ref});
  @override
  State<_ParentTopicCard> createState() => _ParentTopicCardState();
}

class _ParentTopicCardState extends State<_ParentTopicCard> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final current = widget.ref.read(parentTopicProvider);
    _ctrl = TextEditingController(text: current ?? '');
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final current = widget.ref.watch(parentTopicProvider);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('💬', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text('今日のトピック',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'プピィが子供に話しかける内容に反映されます',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _ctrl,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: '例：おばあちゃんが来る、動物園に行く',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFFB74D), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send_rounded, color: Color(0xFFFFB74D), size: 20),
                onPressed: () {
                  widget.ref.read(parentTopicProvider.notifier).setTopic(_ctrl.text);
                  FocusScope.of(context).unfocus();
                },
              ),
            ),
            onSubmitted: (val) {
              widget.ref.read(parentTopicProvider.notifier).setTopic(val);
            },
          ),
          if (current != null && current.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB74D).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('🐰', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'プピィ: 「きょうは「$current」だって！たのしみだね！」',
                      style: const TextStyle(color: Color(0xFFFFB74D), fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _ctrl.clear();
                      widget.ref.read(parentTopicProvider.notifier).clear();
                    },
                    child: const Icon(Icons.close, color: Colors.white38, size: 16),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

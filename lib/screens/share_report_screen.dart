import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/mandala_state.dart';
import '../providers/mandala_providers.dart';
import '../providers/character_providers.dart';
import '../models/character.dart';
import '../services/thinking_framework_service.dart';
import '../services/learning_log_service.dart';

// ─────────────────────────────────────────────────────────
// ShareReportScreen — SNSシェア用・思考力成長レポート
//
// ライオン級クリア時に自動表示。
// Instagram/X向けの美しいビジュアルカードを生成。
// ─────────────────────────────────────────────────────────

class ShareReportScreen extends ConsumerStatefulWidget {
  const ShareReportScreen({super.key});

  @override
  ConsumerState<ShareReportScreen> createState() => _ShareReportScreenState();
}

class _ShareReportScreenState extends ConsumerState<ShareReportScreen> {
  final GlobalKey _captureKey = GlobalKey();
  WeeklyGrowthSummary? _growth;

  @override
  void initState() {
    super.initState();
    _loadGrowth();
  }

  Future<void> _loadGrowth() async {
    final g = await LearningLogService.weeklyGrowth();
    if (mounted) setState(() => _growth = g);
  }

  Future<void> _captureAndShare() async {
    try {
      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/mandala_report.png');
      await file.writeAsBytes(pngBytes);

      // クリップボードに画像パスをコピー（実機ではShare APIを使用）
      await Clipboard.setData(ClipboardData(text: file.path));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📸 レポート画像を保存しました！'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mandalaProvider);
    final charDef = ref.watch(characterProvider).def;
    final analytics = ref.watch(analyticsProvider);

    // 思考力評価
    final answers = List.generate(8, (i) =>
        state.completed[i] ? state.labels[i] : '');
    final assessment = ThinkingFrameworkService.assess(answers);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('知恵の冒険・達成証明書',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: _captureAndShare,
            icon: const Icon(Icons.share, color: Color(0xFFFFB74D), size: 18),
            label: const Text('シェア', style: TextStyle(color: Color(0xFFFFB74D), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // キャプチャ対象のカード
            RepaintBoundary(
              key: _captureKey,
              child: _ReportCard(
                state: state,
                charEmoji: charDef.emoji,
                charName: charDef.name,
                fullEquipDisplay: ref.watch(characterProvider).fullEquipDisplay,
                equippedEmojis: ref.watch(characterProvider).equippedEmojis,
                analytics: analytics,
                assessment: assessment,
                growth: _growth,
              ),
            ),
            const SizedBox(height: 20),

            // シェアボタン
            Row(
              children: [
                Expanded(
                  child: _ShareButton(
                    icon: '📸',
                    label: 'Instagram',
                    color: const Color(0xFFE1306C),
                    onTap: _captureAndShare,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ShareButton(
                    icon: '𝕏',
                    label: 'X (Twitter)',
                    color: const Color(0xFF1DA1F2),
                    onTap: _captureAndShare,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
            const SizedBox(height: 12),

            Text(
              '画像を保存して、SNSでシェアしよう！',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── レポートカード（キャプチャ対象） ───────────────────────

class _ReportCard extends StatelessWidget {
  final MandalaState state;
  final String charEmoji;
  final String charName;
  final String fullEquipDisplay;
  final List<String> equippedEmojis;
  final ({double metacognition, double focus, double logicalThinking}) analytics;
  final ThinkingAssessment assessment;
  final WeeklyGrowthSummary? growth;

  const _ReportCard({
    required this.state, required this.charEmoji, required this.charName,
    required this.fullEquipDisplay, required this.equippedEmojis,
    required this.analytics, required this.assessment, this.growth,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = '${now.year}.${now.month}.${now.day}';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0A3D), Color(0xFF0D1F33), Color(0xFF0A2818)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFFFB74D).withOpacity(0.4), width: 2),
        boxShadow: [BoxShadow(
          color: const Color(0xFFFFB74D).withOpacity(0.15),
          blurRadius: 30, spreadRadius: 5,
        )],
      ),
      child: Column(
        children: [
          // ヘッダー: フル装備キャラ
          Row(
            children: [
              // フル装備キャラクター表示
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    const Color(0xFFFFB74D).withOpacity(0.3),
                    Colors.transparent,
                  ]),
                ),
                child: Center(
                  child: Text(fullEquipDisplay, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🏆 知恵の冒険・達成証明書',
                        style: TextStyle(color: Color(0xFFFFD740), fontSize: 16,
                            fontWeight: FontWeight.w900)),
                    Text('$charName が ライオン級を クリア！',
                        style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    if (equippedEmojis.isNotEmpty)
                      Text('装備: ${equippedEmojis.join(' ')}',
                          style: const TextStyle(color: Colors.white30, fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // テーマ
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Text('テーマ', style: TextStyle(color: Colors.white38, fontSize: 10)),
                const SizedBox(height: 2),
                Text('「${state.goal}」',
                    style: const TextStyle(color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 受験準備スコア（大きく）
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFB74D).withOpacity(0.15),
                  const Color(0xFFFF8A65).withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Text('思考力スコア',
                    style: TextStyle(color: Color(0xFFFFB74D), fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  '${assessment.examReadyScore}',
                  style: const TextStyle(
                    color: Color(0xFFFFD740),
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(assessment.examReadyLabel,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3指標バー
          _ReportMetricBar(label: 'メタ認知', value: analytics.metacognition,
              color: const Color(0xFF7FDBFF)),
          const SizedBox(height: 8),
          _ReportMetricBar(label: '集中力', value: analytics.focus,
              color: const Color(0xFFFFD740)),
          const SizedBox(height: 8),
          _ReportMetricBar(label: '論理的思考', value: analytics.logicalThinking,
              color: const Color(0xFF69F0AE)),
          const SizedBox(height: 16),

          // 3レイヤー達成
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _LayerBadge(emoji: '🔍', label: 'かんさつ',
                  count: assessment.analysisCount, total: 3,
                  color: const Color(0xFFFF9800)),
              _LayerBadge(emoji: '💭', label: 'かんがえる',
                  count: assessment.reasoningCount, total: 3,
                  color: const Color(0xFF03A9F4)),
              _LayerBadge(emoji: '🌟', label: 'きめる',
                  count: assessment.decisionCount, total: 2,
                  color: const Color(0xFF4CAF50)),
            ],
          ),
          const SizedBox(height: 16),

          // 成長データ
          if (growth != null && growth!.totalSessions > 1)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _GrowthStat(label: '累計', value: '${growth!.totalSessions}回'),
                  _GrowthStat(label: '今週', value: '${growth!.thisWeekSessions}回'),
                  if (growth!.sessionsDelta > 0)
                    _GrowthStat(label: '前週比', value: '+${growth!.sessionsDelta}',
                        color: const Color(0xFF69F0AE)),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // メタ認知スコア（裏側集計）
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF7FDBFF).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF7FDBFF).withOpacity(0.2)),
            ),
            child: Row(children: [
              const Text('🧠', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('メタ認知スコア',
                        style: TextStyle(color: Color(0xFF7FDBFF), fontSize: 10,
                            fontWeight: FontWeight.w600)),
                    Text('${(analytics.metacognition * 100).toInt()}点 — 自分の考えを客観視する力',
                        style: const TextStyle(color: Colors.white54, fontSize: 9)),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // 達成証明スタンプ
          Center(
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFF5252), width: 3),
              ),
              child: const Center(
                child: Text('認定', style: TextStyle(
                  color: Color(0xFFFF5252), fontSize: 22, fontWeight: FontWeight.w900)),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // フッター
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateStr, style: const TextStyle(color: Colors.white24, fontSize: 10)),
              const Text('マンダラα — 知恵の冒険',
                  style: TextStyle(color: Colors.white24, fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, duration: 500.ms);
  }
}

class _ReportMetricBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _ReportMetricBar({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).toInt();
    return Row(
      children: [
        SizedBox(width: 70, child: Text(label,
            style: const TextStyle(color: Colors.white60, fontSize: 11))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value, minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 35, child: Text('$pct%',
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right)),
      ],
    );
  }
}

class _LayerBadge extends StatelessWidget {
  final String emoji;
  final String label;
  final int count;
  final int total;
  final Color color;
  const _LayerBadge({
    required this.emoji, required this.label,
    required this.count, required this.total, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final done = count == total;
    return Column(
      children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
            border: Border.all(color: done ? color : Colors.white12, width: 2),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9)),
        Text('$count/$total',
            style: TextStyle(color: done ? color : Colors.white30,
                fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _GrowthStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _GrowthStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(
            color: color ?? Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white30, fontSize: 9)),
      ],
    );
  }
}

class _ShareButton extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ShareButton({
    required this.icon, required this.label, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: TextStyle(fontSize: 20, color: color)),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

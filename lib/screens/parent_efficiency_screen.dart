import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mandala_providers.dart';
import '../providers/character_providers.dart';
import '../providers/daily_cycle_providers.dart';
import '../services/coaching_phrase_service.dart';
import '../services/portfolio_service.dart';
import '../services/learning_log_service.dart';

// ─────────────────────────────────────────────────────────
// ParentEfficiencyScreen — 親の低負荷・高効率UX
// ─────────────────────────────────────────────────────────

class ParentEfficiencyScreen extends ConsumerStatefulWidget {
  const ParentEfficiencyScreen({super.key});

  @override
  ConsumerState<ParentEfficiencyScreen> createState() => _ParentEfficiencyScreenState();
}

class _ParentEfficiencyScreenState extends ConsumerState<ParentEfficiencyScreen> {
  PortfolioReport? _portfolio;
  bool _generating = false;
  final _nameCtrl = TextEditingController(text: 'おこさま');

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _generatePortfolio() async {
    setState(() => _generating = true);
    final now = DateTime.now();
    final report = await PortfolioService.generate(
      childName: _nameCtrl.text.trim(),
      from: now.subtract(const Duration(days: 30)),
      to: now,
    );
    setState(() { _portfolio = report; _generating = false; });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mandalaProvider);
    final charDef = ref.watch(characterProvider).def;
    final dailySeed = ref.watch(dailyCycleProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF060E1F),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('⚡ 親タイパMAX',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 成長ニュース（音声ダイジェスト）
            _GrowthNewsCard(
              charName: charDef.name,
              goals: dailySeed.allGoals,
              answers: dailySeed.allItems,
              sessionCount: dailySeed.equipStage,
            ),
            const SizedBox(height: 16),

            // 2. 3秒声かけフレーズ
            _CoachingPhraseCard(state: state, goal: state.goal),
            const SizedBox(height: 16),

            // 3. ポートフォリオ生成
            _PortfolioCard(
              nameCtrl: _nameCtrl,
              portfolio: _portfolio,
              generating: _generating,
              onGenerate: _generatePortfolio,
            ),
            const SizedBox(height: 16),

            // 4. ウィジェット設定
            _WidgetSettingsCard(dailySeed: dailySeed),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── 成長ニュース ──────────────────────────────────────────

class _GrowthNewsCard extends StatelessWidget {
  final String charName;
  final List<String> goals;
  final List<String> answers;
  final int sessionCount;

  const _GrowthNewsCard({
    required this.charName, required this.goals,
    required this.answers, required this.sessionCount,
  });

  @override
  Widget build(BuildContext context) {
    final summary = CoachingPhraseService.growthNewsSummary(
      charName: charName, goals: goals,
      answers: answers, sessionCount: sessionCount,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFF0D2818).withOpacity(0.8),
          const Color(0xFF0A1A3D).withOpacity(0.8),
        ]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF69F0AE).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Text('🎙️', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('30秒 成長ニュース',
                style: TextStyle(color: Color(0xFF69F0AE), fontSize: 15, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 4),
          const Text('お子さまの今日の成長を音声でお届け',
              style: TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(summary,
                style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.6)),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Clipboard.setData(ClipboardData(text: summary));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('📋 テキストをコピーしました'),
                      backgroundColor: Color(0xFF4CAF50)),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF69F0AE).withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              icon: const Icon(Icons.content_copy, size: 16, color: Color(0xFF69F0AE)),
              label: const Text('テキストをコピー',
                  style: TextStyle(color: Color(0xFF69F0AE), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ── 3秒声かけフレーズ ─────────────────────────────────────

class _CoachingPhraseCard extends StatelessWidget {
  final dynamic state; // MandalaState
  final String goal;
  const _CoachingPhraseCard({required this.state, required this.goal});

  @override
  Widget build(BuildContext context) {
    // 直近の回答からフレーズ生成
    final labels = (state.labels as List<String>)
        .where((l) => l.isNotEmpty).toList();
    final phrases = labels.map((l) =>
        CoachingPhraseService.generate(l, goal: goal)).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Text('💬', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('3秒声かけフレーズ',
                style: TextStyle(color: Color(0xFFFFB74D), fontSize: 15, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 4),
          const Text('そのまま読み上げるだけでOK！お子さまが喜びます',
              style: TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 12),
          if (phrases.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('お子さまが回答すると、声かけフレーズが表示されます',
                  style: TextStyle(color: Colors.white24, fontSize: 12)),
            )
          else
            ...phrases.take(4).map((p) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB74D).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.phrase,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(6)),
                        child: Text(p.category,
                            style: const TextStyle(color: Colors.white30, fontSize: 9)),
                      ),
                    ],
                  )),
                ],
              ),
            )),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }
}

// ── ポートフォリオ生成 ────────────────────────────────────

class _PortfolioCard extends StatelessWidget {
  final TextEditingController nameCtrl;
  final PortfolioReport? portfolio;
  final bool generating;
  final VoidCallback onGenerate;

  const _PortfolioCard({
    required this.nameCtrl, this.portfolio, required this.generating,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFF1A0A3D).withOpacity(0.8),
          const Color(0xFF0D1F33).withOpacity(0.8),
        ]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Text('📄', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('受験ポートフォリオ',
                style: TextStyle(color: Color(0xFF7C4DFF), fontSize: 15, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 4),
          const Text('直近30日の学習履歴から自動生成',
              style: TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 12),
          // 名前入力
          TextField(
            controller: nameCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'お名前',
              labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: generating ? null : onGenerate,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: generating
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('レポート生成 📄',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          if (portfolio != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _gradeColor(portfolio!.evaluationGrade).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8)),
                      child: Text('評価: ${portfolio!.evaluationGrade}',
                          style: TextStyle(color: _gradeColor(portfolio!.evaluationGrade),
                              fontSize: 14, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 8),
                    Text('${portfolio!.totalSessions}セッション',
                        style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  ]),
                  const SizedBox(height: 8),
                  Text(portfolio!.evaluationComment,
                      style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.5)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: portfolio!.filePath));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('📄 保存先: ${portfolio!.filePath}'),
                            backgroundColor: const Color(0xFF4CAF50)),
                      );
                    },
                    child: const Text('📁 ファイルパスをコピー',
                        style: TextStyle(color: Color(0xFF7C4DFF), fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Color _gradeColor(String grade) => switch (grade) {
    'A' => const Color(0xFF69F0AE),
    'B' => const Color(0xFFFFD740),
    'C' => const Color(0xFFFFAB40),
    _ => const Color(0xFFFF5252),
  };
}

// ── ウィジェット設定 ──────────────────────────────────────

class _WidgetSettingsCard extends StatelessWidget {
  final DailySeed dailySeed;
  const _WidgetSettingsCard({required this.dailySeed});

  @override
  Widget build(BuildContext context) {
    final highlights = CoachingPhraseService.dailyHighlights(dailySeed.allItems);

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
          const Row(children: [
            Text('📱', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('ホーム画面ウィジェット',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 4),
          const Text('アプリを開かずにお子さまの語録をチェック',
              style: TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 12),
          // プレビュー
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF8E7), Color(0xFFFFF0D0)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Text('✨', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 4),
                  Text('きょうの キラリ語録',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF5A4A3A))),
                ]),
                const SizedBox(height: 6),
                if (highlights.isEmpty)
                  const Text('まだ ことばが ないよ',
                      style: TextStyle(fontSize: 12, color: Color(0xFFA09080)))
                else
                  ...highlights.map((h) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(h,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                            color: Color(0xFF5A4A3A))),
                  )),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'iOSウィジェット: 設定 → ホーム画面 → ウィジェット追加\n'
            '※ WidgetKit連携は次期アップデートで対応予定',
            style: TextStyle(color: Colors.white24, fontSize: 9, height: 1.4),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }
}

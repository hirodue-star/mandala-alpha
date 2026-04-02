import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/daily_cycle_providers.dart';
import '../providers/character_providers.dart';

// ─────────────────────────────────────────────────────────
// DailyDiaryScreen — 冒険日記（1日のマンダラ付きレポート）
// ─────────────────────────────────────────────────────────

class DailyDiaryScreen extends ConsumerStatefulWidget {
  const DailyDiaryScreen({super.key});

  @override
  ConsumerState<DailyDiaryScreen> createState() => _DailyDiaryScreenState();
}

class _DailyDiaryScreenState extends ConsumerState<DailyDiaryScreen> {
  final GlobalKey _captureKey = GlobalKey();

  Future<void> _capture() async {
    try {
      final boundary = _captureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/mandala_diary.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      await Clipboard.setData(ClipboardData(text: file.path));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📔 冒険日記を保存しました！'), backgroundColor: Color(0xFF4CAF50)),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final seed = ref.watch(dailyCycleProvider);
    final charState = ref.watch(characterProvider);
    final now = DateTime.now();
    final dateStr = '${now.year}.${now.month}.${now.day}';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('冒険日記', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: _capture,
            icon: const Icon(Icons.save_alt, color: Color(0xFFFFB74D), size: 18),
            label: const Text('保存', style: TextStyle(color: Color(0xFFFFB74D), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: RepaintBoundary(
          key: _captureKey,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A0A3D), Color(0xFF0A1A2D), Color(0xFF0D2818)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.3), width: 2),
            ),
            child: Column(
              children: [
                // タイトル
                Row(children: [
                  Text(charState.fullEquipDisplay, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('📔 きょうの ぼうけん にっき',
                          style: TextStyle(color: Color(0xFFFFD740), fontSize: 16, fontWeight: FontWeight.w900)),
                      Text('$dateStr — ${charState.def.name}の1にち',
                          style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  )),
                ]),
                const SizedBox(height: 20),

                // 朝フェーズ
                _PhaseCard(
                  emoji: '🌅',
                  label: 'あさ — ひよこ級',
                  color: const Color(0xFFFFD54F),
                  goal: seed.morningGoal,
                  items: seed.morningItems,
                  equipEmoji: '🐤',
                ),
                // 接続線
                _DiaryConnector(hasData: seed.morningItems.isNotEmpty),
                // 昼フェーズ
                _PhaseCard(
                  emoji: '☀️',
                  label: 'ひる — ペンギン級',
                  color: const Color(0xFF64B5F6),
                  goal: seed.noonGoal,
                  items: seed.noonItems,
                  inheritedItems: seed.morningItems,
                  equipEmoji: '🎩',
                ),
                // 接続線
                _DiaryConnector(hasData: seed.noonItems.isNotEmpty),
                // 夜フェーズ
                _PhaseCard(
                  emoji: '🌙',
                  label: 'よる — ライオン級',
                  color: const Color(0xFFFF8A65),
                  goal: seed.nightGoal,
                  items: seed.nightItems,
                  inheritedItems: [...seed.morningItems, ...seed.noonItems],
                  equipEmoji: '👑',
                ),
                const SizedBox(height: 20),

                // 1日のまとめ
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.3)),
                  ),
                  child: Column(children: [
                    const Text('きょうの まとめ',
                        style: TextStyle(color: Color(0xFFFFB74D), fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      _SumStat(label: 'テーマ', value: '${seed.allGoals.length}つ'),
                      _SumStat(label: 'あつめた', value: '${seed.allItems.length}こ'),
                      _SumStat(label: 'そうび', value: _equipLabel(seed.equipStage)),
                    ]),
                    const SizedBox(height: 8),
                    // キャラ進化ライン
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(charState.def.emoji, style: const TextStyle(fontSize: 20)),
                      if (seed.equipStage >= 1) const Text(' → 🧣', style: TextStyle(fontSize: 14, color: Colors.white30)),
                      if (seed.equipStage >= 2) const Text(' → 🎩', style: TextStyle(fontSize: 14, color: Colors.white30)),
                      if (seed.equipStage >= 3) const Text(' → 👑', style: TextStyle(fontSize: 14, color: Colors.white30)),
                      const Text(' ✨', style: TextStyle(fontSize: 16)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 14),

                // フッター
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(dateStr, style: const TextStyle(color: Colors.white24, fontSize: 10)),
                  const Text('マンダラα — 冒険日記', style: TextStyle(color: Colors.white24, fontSize: 10)),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _equipLabel(int stage) {
    return switch (stage) {
      0 => 'なし',
      1 => 'スカーフ',
      2 => 'ぼうし',
      _ => 'フルそうび！',
    };
  }
}

class _PhaseCard extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final String? goal;
  final List<String> items;
  final List<String> inheritedItems;
  final String equipEmoji;

  const _PhaseCard({
    required this.emoji, required this.label, required this.color,
    this.goal, this.items = const [], this.inheritedItems = const [],
    required this.equipEmoji,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = goal != null && goal!.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasData ? color.withOpacity(0.1) : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hasData ? color.withOpacity(0.4) : Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(equipEmoji, style: const TextStyle(fontSize: 16)),
          ]),
          if (hasData) ...[
            const SizedBox(height: 8),
            Text('テーマ: 「$goal」',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 6, runSpacing: 4,
                children: items.map((item) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(item, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                )).toList(),
              ),
            ],
            if (inheritedItems.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('引き継ぎ: ${inheritedItems.join(", ")}',
                  style: const TextStyle(color: Colors.white24, fontSize: 9, fontStyle: FontStyle.italic)),
            ],
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('まだ ぼうけんしていないよ',
                  style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11)),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _DiaryConnector extends StatelessWidget {
  final bool hasData;
  const _DiaryConnector({required this.hasData});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 20, width: 3,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: hasData ? const Color(0xFFFFB74D).withOpacity(0.4) : Colors.white10,
        ),
      ),
    );
  }
}

class _SumStat extends StatelessWidget {
  final String label;
  final String value;
  const _SumStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white30, fontSize: 9)),
    ]);
  }
}

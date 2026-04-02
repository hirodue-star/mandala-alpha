import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/social_providers.dart';
import '../providers/character_providers.dart';
import 'hospitality_platform_screen.dart';

// ─────────────────────────────────────────────────────────
// SocialScreen — リアルクエスト・友達・おもてなしレポート
// ─────────────────────────────────────────────────────────

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});
  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final GlobalKey _reportKey = GlobalKey();

  @override
  void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _captureReport() async {
    try {
      final boundary = _reportKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/hospitality_report.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      await Clipboard.setData(ClipboardData(text: file.path));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📸 おもてなしレポートを保存しました！'),
              backgroundColor: Color(0xFF4CAF50)));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E7), elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF5A4A3A)),
          onPressed: () => Navigator.pop(context)),
        title: const Text('🤝 ソーシャル',
            style: TextStyle(color: Color(0xFF5A4A3A), fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Text('🌍', style: TextStyle(fontSize: 20)),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HospitalityPlatformScreen())),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: const Color(0xFFFF8A65),
          unselectedLabelColor: const Color(0xFFA09080),
          indicatorColor: const Color(0xFFFF8A65),
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Text('👟', style: TextStyle(fontSize: 18)), text: 'おてつだい'),
            Tab(icon: Text('🤝', style: TextStyle(fontSize: 18)), text: 'ともだち'),
            Tab(icon: Text('📸', style: TextStyle(fontSize: 18)), text: 'レポート'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _QuestTab(),
          _FriendsTab(),
          _ReportTab(reportKey: _reportKey, onCapture: _captureReport),
        ],
      ),
    );
  }
}

// ── おてつだいタブ ────────────────────────────────────────

class _QuestTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questState = ref.watch(questProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // おもてなしスコア
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFE0C0), Color(0xFFFFF3D6)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              const Text('🏅', style: TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('おもてなしスコア',
                      style: TextStyle(fontSize: 11, color: Color(0xFF8A6A3A))),
                  Text('${questState.hospitalityScore}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900,
                          color: Color(0xFFE8A030))),
                ],
              )),
              Text('${questState.completed.where((q) => q.approved).length}かい クリア',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF8A6A3A))),
            ]),
          ),
          const SizedBox(height: 16),

          const Text('おてつだい クエスト',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF5A4A3A))),
          const SizedBox(height: 4),
          const Text('おてつだいを して マンダラのピースを ゲット！',
              style: TextStyle(fontSize: 11, color: Color(0xFFA09080))),
          const SizedBox(height: 12),

          // クエスト一覧
          ...questState.available.map((q) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 1,
              child: ListTile(
                leading: Text(q.emoji, style: const TextStyle(fontSize: 28)),
                title: Text(q.name, style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF5A4A3A))),
                subtitle: Text('+${q.rewardPoints}ポイント',
                    style: const TextStyle(fontSize: 10, color: Color(0xFFA09080))),
                trailing: FilledButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ref.read(questProvider.notifier).requestComplete(q.id);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${q.emoji} ${q.name} かんりょう！ おやに しょうにんを もらおう'),
                      backgroundColor: const Color(0xFFFFB74D)));
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB74D),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('できた！', style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          )),

          // 親の承認待ち
          if (questState.completed.any((q) => !q.approved)) ...[
            const SizedBox(height: 16),
            const Text('🔒 おやの しょうにん まち',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF8A6A3A))),
            const SizedBox(height: 8),
            ...questState.completed.where((q) => !q.approved).map((q) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: const Color(0xFFFFF0E0),
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  dense: true,
                  leading: Text(q.emoji, style: const TextStyle(fontSize: 22)),
                  title: Text(q.name, style: const TextStyle(fontSize: 12, color: Color(0xFF5A4A3A))),
                  trailing: FilledButton(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      ref.read(questProvider.notifier).approve(q.id);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('しょうにん ✅', style: TextStyle(fontSize: 10,
                        fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }
}

// ── ともだちタブ ──────────────────────────────────────────

class _FriendsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final socialState = ref.watch(socialProvider);
    final ranking = socialState.ranking;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🏆 ランキング',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF5A4A3A))),
          const SizedBox(height: 12),
          ...ranking.asMap().entries.map((e) {
            final i = e.key;
            final f = e.value;
            final medal = i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '　';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: f.isFollowing ? const Color(0xFFFFF0E0) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: f.isFollowing
                    ? const Color(0xFFFFCC80) : const Color(0xFFE0D5C0)),
              ),
              child: Row(children: [
                Text(medal, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(f.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.name, style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF5A4A3A))),
                    Text('${f.score}ポイント',
                        style: const TextStyle(fontSize: 10, color: Color(0xFFA09080))),
                  ],
                )),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(socialProvider.notifier).toggleFollow(f.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: f.isFollowing
                          ? const Color(0xFFFF8A65).withOpacity(0.15)
                          : const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(f.isFollowing ? 'フォロー中' : 'フォロー',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                            color: f.isFollowing ? const Color(0xFFFF8A65) : const Color(0xFF8A7A6A))),
                  ),
                ),
              ]),
            );
          }),

          const SizedBox(height: 20),
          // 共同ミッション
          const Text('🎯 きょうどう ミッション',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF5A4A3A))),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFE3F2FD), Color(0xFFE8F5E9)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: [
              const Text('🌍 みんなで 100こ おてつだいしよう！',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2A4A6A))),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: 0.42, minHeight: 10,
                  backgroundColor: Colors.white,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF64B5F6))),
              ),
              const SizedBox(height: 4),
              const Text('42/100 — みんな がんばってるよ！',
                  style: TextStyle(fontSize: 10, color: Color(0xFF6A8AAA))),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── レポートタブ ──────────────────────────────────────────

class _ReportTab extends ConsumerWidget {
  final GlobalKey reportKey;
  final VoidCallback onCapture;
  const _ReportTab({required this.reportKey, required this.onCapture});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questState = ref.watch(questProvider);
    final charState = ref.watch(characterProvider);
    final socialState = ref.watch(socialProvider);
    final now = DateTime.now();
    final dateStr = '${now.year}.${now.month}.${now.day}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        RepaintBoundary(
          key: reportKey,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A0A3D), Color(0xFF0D2818)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.4), width: 2),
            ),
            child: Column(children: [
              // ヘッダー
              Row(children: [
                Text(charState.fullEquipDisplay, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 10),
                const Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🏅 おもてなし レポート',
                        style: TextStyle(color: Color(0xFFFFD740), fontSize: 16, fontWeight: FontWeight.w900)),
                    Text('おてつだい＆ともだち きろく',
                        style: TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
                )),
              ]),
              const SizedBox(height: 16),

              // スコア
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  const Text('おもてなしスコア',
                      style: TextStyle(color: Color(0xFFFFB74D), fontSize: 11)),
                  Text('${questState.hospitalityScore}',
                      style: const TextStyle(color: Color(0xFFFFD740), fontSize: 40,
                          fontWeight: FontWeight.w900)),
                  Text('${questState.completed.where((q) => q.approved).length}こ クリア',
                      style: const TextStyle(color: Colors.white38, fontSize: 10)),
                ]),
              ),
              const SizedBox(height: 12),

              // 完了クエスト
              if (questState.completed.where((q) => q.approved).isNotEmpty)
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: questState.completed.where((q) => q.approved)
                      .take(8).map((q) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8)),
                    child: Text('${q.emoji} ${q.name}',
                        style: const TextStyle(color: Colors.white60, fontSize: 10)),
                  )).toList(),
                ),
              const SizedBox(height: 12),

              // フォロー中の友達
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: socialState.following.take(4).map((f) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(children: [
                    Text(f.emoji, style: const TextStyle(fontSize: 20)),
                    Text(f.name, style: const TextStyle(color: Colors.white38, fontSize: 8)),
                  ]),
                )).toList(),
              ),
              const SizedBox(height: 12),

              // フッター
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(dateStr, style: const TextStyle(color: Colors.white24, fontSize: 10)),
                const Text('マンダラα', style: TextStyle(color: Colors.white24, fontSize: 10)),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // シェアボタン
        Row(children: [
          Expanded(child: FilledButton.icon(
            onPressed: onCapture,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE1306C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            icon: const Text('📸', style: TextStyle(fontSize: 16)),
            label: const Text('Instagram', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          )),
          const SizedBox(width: 10),
          Expanded(child: FilledButton.icon(
            onPressed: onCapture,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF06C755),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            icon: const Text('💬', style: TextStyle(fontSize: 16)),
            label: const Text('LINE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          )),
        ]),
      ]),
    );
  }
}

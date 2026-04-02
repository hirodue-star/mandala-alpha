import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mandala_state.dart';
import '../providers/mandala_providers.dart';
import '../providers/character_providers.dart';
import '../providers/hospitality_providers.dart';
import '../providers/social_providers.dart';
import '../services/hospitality_platform_service.dart';

// ─────────────────────────────────────────────────────────
// HospitalityPlatformScreen — 段階的ホスピタリティ＋SNS連携
// ─────────────────────────────────────────────────────────

class HospitalityPlatformScreen extends ConsumerWidget {
  const HospitalityPlatformScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mandalaProvider);
    final hState = ref.watch(hospitalityProvider);
    final charState = ref.watch(characterProvider);
    final questState = ref.watch(questProvider);

    final tasks = TaskCatalogService.forLevel(state.ageMode);
    final allowedScopes = ShareGateService.allowedScopes(state.ageMode);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E7), elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF5A4A3A)),
          onPressed: () => Navigator.pop(context)),
        title: const Text('🌍 ホスピタリティ',
            style: TextStyle(color: Color(0xFF5A4A3A), fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // H値スコアカード
            _HScoreCard(hScore: hState.hScore),
            const SizedBox(height: 16),

            // 1. 能力別タスクカタログ
            _TaskCatalogSection(
              tasks: tasks,
              ageMode: state.ageMode,
              onComplete: (task) {
                HapticFeedback.mediumImpact();
                ref.read(questProvider.notifier).requestComplete(task.id);
                ref.read(hospitalityProvider.notifier).onQuestComplete(task.points);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${task.emoji} ${task.name} +${task.points}H値！'),
                  backgroundColor: const Color(0xFF4CAF50)));
              },
            ),
            const SizedBox(height: 16),

            // 3. シェア制限ゲート
            _ShareGateSection(
              currentScope: hState.shareScope,
              allowedScopes: allowedScopes,
              ageMode: state.ageMode,
              onChanged: (scope) => ref.read(hospitalityProvider.notifier).setShareScope(scope),
            ),
            const SizedBox(height: 16),

            // 5. 1タップシェア
            _QuickShareSection(
              charName: charState.def.name,
              childName: 'おこさま',
              hospitalityScore: hState.hScore.totalH,
              questCount: questState.completed.where((q) => q.approved).length,
              highlights: questState.pieceLabels.take(3).toList(),
              onShare: () => ref.read(hospitalityProvider.notifier).onShare(),
            ),
            const SizedBox(height: 16),

            // 2. バトン機能プレビュー
            _BatonPreview(
              batonCount: hState.batonIds.length,
              onCreateBaton: () {
                final baton = BatonImage.create('local_user');
                ref.read(hospitalityProvider.notifier).onBatonJoin(baton.batonId);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('🎨 バトンID: ${baton.batonId.substring(0, 16)}... を作成！'),
                  backgroundColor: const Color(0xFF7C4DFF)));
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── H値スコアカード ───────────────────────────────────────

class _HScoreCard extends StatelessWidget {
  final HospitalityScore hScore;
  const _HScoreCard({required this.hScore});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFE0C0), Color(0xFFFFF3D6)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFFFFB74D).withOpacity(0.3),
            blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(children: [
        const Text('H値（ホスピタリティ）',
            style: TextStyle(fontSize: 12, color: Color(0xFF8A6A3A))),
        Text('${hScore.totalH}',
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Color(0xFFE8A030))),
        Text(hScore.rank,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF8A6A3A))),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _HDetail('クエスト', '${hScore.questPoints}'),
          _HDetail('シェア', '${hScore.sharePoints * 2}'),
          _HDetail('リアクション', '${hScore.reactionPoints}'),
          _HDetail('バトン', '${hScore.batonPoints * 3}'),
        ]),
      ]),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _HDetail extends StatelessWidget {
  final String label;
  final String value;
  const _HDetail(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF5A4A3A))),
      Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFFA09080))),
    ]);
  }
}

// ── 能力別タスクカタログ ──────────────────────────────────

class _TaskCatalogSection extends StatelessWidget {
  final List<TaskCatalog> tasks;
  final AgeMode ageMode;
  final void Function(TaskCatalog) onComplete;
  const _TaskCatalogSection({required this.tasks, required this.ageMode, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    // スコープごとにグループ化
    final grouped = <TaskScope, List<TaskCatalog>>{};
    for (final t in tasks) {
      grouped.putIfAbsent(t.scope, () => []).add(t);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(ageMode.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Text('${ageMode.label}級の タスク',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF5A4A3A))),
        ]),
        const SizedBox(height: 10),
        ...grouped.entries.map((e) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE0C0), borderRadius: BorderRadius.circular(8)),
              child: Text('${e.key.emoji} ${e.key.label}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF8A6A3A))),
            ),
            const SizedBox(height: 6),
            ...e.value.map((t) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: Colors.white, borderRadius: BorderRadius.circular(14), elevation: 1,
                child: ListTile(
                  dense: true,
                  leading: Text(t.emoji, style: const TextStyle(fontSize: 24)),
                  title: Text(t.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                      color: Color(0xFF5A4A3A))),
                  subtitle: Text('+${t.points}H値', style: const TextStyle(fontSize: 9, color: Color(0xFFA09080))),
                  trailing: GestureDetector(
                    onTap: () => onComplete(t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB74D), borderRadius: BorderRadius.circular(10)),
                      child: const Text('できた！', style: TextStyle(fontSize: 10,
                          fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            )),
            const SizedBox(height: 8),
          ],
        )),
      ],
    );
  }
}

// ── シェア制限ゲート ──────────────────────────────────────

class _ShareGateSection extends StatelessWidget {
  final ShareScope currentScope;
  final List<ShareScope> allowedScopes;
  final AgeMode ageMode;
  final void Function(ShareScope) onChanged;
  const _ShareGateSection({
    required this.currentScope, required this.allowedScopes,
    required this.ageMode, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0D5C0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Text('🔒', style: TextStyle(fontSize: 18)),
            SizedBox(width: 6),
            Text('シェア範囲', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                color: Color(0xFF5A4A3A))),
          ]),
          const SizedBox(height: 4),
          Text('${ageMode.label}級では以下の範囲でシェアできます',
              style: const TextStyle(fontSize: 10, color: Color(0xFFA09080))),
          const SizedBox(height: 10),
          Row(children: ShareScope.values.map((s) {
            final allowed = allowedScopes.contains(s);
            final selected = s == currentScope;
            return Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: allowed ? () => onChanged(s) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFFFB74D).withOpacity(0.15)
                        : allowed ? Colors.white : const Color(0xFFF5F0E8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? const Color(0xFFFFB74D)
                        : allowed ? const Color(0xFFE0D5C0) : const Color(0xFFE8E0D5))),
                  child: Column(children: [
                    Text(allowed ? s.emoji : '🔒', style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 2),
                    Text(s.label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                        color: allowed ? const Color(0xFF5A4A3A) : const Color(0xFFD0C8B8))),
                  ]),
                ),
              ),
            ));
          }).toList()),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }
}

// ── 1タップシェア ─────────────────────────────────────────

class _QuickShareSection extends StatelessWidget {
  final String charName;
  final String childName;
  final int hospitalityScore;
  final int questCount;
  final List<String> highlights;
  final VoidCallback onShare;
  const _QuickShareSection({
    required this.charName, required this.childName,
    required this.hospitalityScore, required this.questCount,
    required this.highlights, required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final text = ShareTextService.generateShareText(
      childName: childName, charName: charName,
      hospitalityScore: hospitalityScore, questCount: questCount,
      grade: hospitalityScore >= 50 ? 'A' : hospitalityScore >= 20 ? 'B' : 'C',
      highlights: highlights,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE8F5E9), Color(0xFFFFF8E7)]),
        borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Text('📤', style: TextStyle(fontSize: 18)),
            SizedBox(width: 6),
            Text('1タップ シェア', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                color: Color(0xFF5A4A3A))),
          ]),
          const SizedBox(height: 4),
          const Text('お受験ポートフォリオ風の定型文を自動生成',
              style: TextStyle(fontSize: 10, color: Color(0xFFA09080))),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF5A4A3A), height: 1.5)),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: text));
                onShare();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('📋 コピーしました！+2 H値'),
                      backgroundColor: Color(0xFF4CAF50)));
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('コピー＆シェア 📤',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }
}

// ── バトン機能プレビュー ──────────────────────────────────

class _BatonPreview extends StatelessWidget {
  final int batonCount;
  final VoidCallback onCreateBaton;
  const _BatonPreview({required this.batonCount, required this.onCreateBaton});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCE93D8).withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Text('🎨', style: TextStyle(fontSize: 18)),
            SizedBox(width: 6),
            Text('バトン機能', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                color: Color(0xFF5A4A3A))),
          ]),
          const SizedBox(height: 4),
          const Text('写真にIDを付けて、お友達がレイヤーを重ねる共創機能',
              style: TextStyle(fontSize: 10, color: Color(0xFFA09080))),
          const SizedBox(height: 10),
          Row(children: [
            Text('参加バトン: $batonCount',
                style: const TextStyle(fontSize: 12, color: Color(0xFF5A4A3A))),
            const Spacer(),
            FilledButton(
              onPressed: onCreateBaton,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('バトン作成 +3H値',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ]),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/community_providers.dart';

// ─────────────────────────────────────────────────────────
// CommunityScreen — 親向けフィードバック・投票・お知らせ
// ─────────────────────────────────────────────────────────

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticeState = ref.watch(noticeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF060E1F),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          const Text('コミュニティ',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          if (noticeState.unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252), borderRadius: BorderRadius.circular(10)),
              child: Text('${noticeState.unreadCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. お知らせ
            _NoticesSection(),
            const SizedBox(height: 16),
            // 2. 改善提案フォーム
            _FeedbackSection(),
            const SizedBox(height: 16),
            // 3. 投票システム
            _VoteSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── お知らせセクション ─────────────────────────────────────

class _NoticesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notices = ref.watch(noticeProvider).notices;

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
          const Row(children: [
            Text('🔔', style: TextStyle(fontSize: 18)),
            SizedBox(width: 8),
            Text('お知らせ', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          if (notices.isEmpty)
            const Text('お知らせはありません', style: TextStyle(color: Colors.white30, fontSize: 12))
          else
            ...notices.take(5).map((n) => GestureDetector(
              onTap: () => ref.read(noticeProvider.notifier).markRead(n.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: n.isRead ? Colors.white.withOpacity(0.02) : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: n.isPersonal
                      ? const Color(0xFFFFB74D).withOpacity(0.3)
                      : Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    if (n.isPersonal) const Text('⭐', style: TextStyle(fontSize: 14))
                    else if (!n.isRead) const Text('🔵', style: TextStyle(fontSize: 8)),
                    const SizedBox(width: 8),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.title, style: TextStyle(
                          color: n.isRead ? Colors.white54 : Colors.white,
                          fontSize: 12, fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                        Text(n.body, style: const TextStyle(color: Colors.white38, fontSize: 10),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    )),
                  ],
                ),
              ),
            )),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ── 改善提案フォーム ──────────────────────────────────────

class _FeedbackSection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FeedbackSection> createState() => _FeedbackSectionState();
}

class _FeedbackSectionState extends ConsumerState<_FeedbackSection> {
  FeedbackCategory _category = FeedbackCategory.ui;
  final _ctrl = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_ctrl.text.trim().isEmpty) return;
    await ref.read(feedbackProvider.notifier).submit(_category, _ctrl.text.trim());
    // 限定アイテム報酬通知
    ref.read(noticeProvider.notifier).addPersonalNotice(
      '🎁 ありがとう！限定アイテムゲット！',
      'フィードバック投稿の お礼に 限定アイテムを プレゼントしました。',
    );
    setState(() => _submitted = true);
    _ctrl.clear();
    Future.delayed(2.seconds, () { if (mounted) setState(() => _submitted = false); });
  }

  @override
  Widget build(BuildContext context) {
    final fbState = ref.watch(feedbackProvider);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFF1A0A3D).withOpacity(0.8),
          const Color(0xFF0A1A3D).withOpacity(0.8),
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('💬', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            const Text('改善提案', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF69F0AE).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8)),
              child: Text('🎁 ×${fbState.limitedItemCount}',
                  style: const TextStyle(color: Color(0xFF69F0AE), fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 4),
          const Text('投稿するたびに限定アイテムがもらえます！',
              style: TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 10),

          // カテゴリー選択
          Row(children: FeedbackCategory.values.map((c) {
            final sel = c == _category;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _category = c),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF7C4DFF).withOpacity(0.3) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: sel ? const Color(0xFF7C4DFF) : Colors.white12),
                  ),
                  child: Text('${c.emoji} ${c.label}',
                      style: TextStyle(color: sel ? Colors.white : Colors.white54,
                          fontSize: 10, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                ),
              ),
            );
          }).toList()),
          const SizedBox(height: 10),

          // テキスト入力
          TextField(
            controller: _ctrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'ご意見・ご要望をお聞かせください',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 2)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 10),

          // 送信ボタン
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitted ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _submitted ? const Color(0xFF69F0AE) : const Color(0xFF7C4DFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(_submitted ? '✅ ありがとうございます！' : '送信する 🎁',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }
}

// ── 投票セクション ────────────────────────────────────────

class _VoteSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voteState = ref.watch(voteProvider);
    final sorted = [...voteState.candidates]..sort((a, b) => b.voteCount.compareTo(a.voteCount));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🗳️', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            const Text('次期開発に投票', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(
              voteState.canVoteToday ? '投票できます' : '明日また投票！',
              style: TextStyle(
                color: voteState.canVoteToday ? const Color(0xFF69F0AE) : Colors.white38,
                fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ]),
          const SizedBox(height: 4),
          const Text('1日1票。あなたの声が開発を動かします',
              style: TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 12),
          ...sorted.map((c) {
            final isVoted = voteState.lastVotedId == c.id && !voteState.canVoteToday;
            final maxVotes = sorted.first.voteCount.clamp(1, 999);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: voteState.canVoteToday ? () async {
                  HapticFeedback.mediumImpact();
                  final ok = await ref.read(voteProvider.notifier).vote(c.id);
                  if (ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${c.emoji} 「${c.title}」に投票しました！'),
                      backgroundColor: const Color(0xFF4CAF50),
                    ));
                  }
                } : null,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isVoted
                        ? const Color(0xFFFFB74D).withOpacity(0.1)
                        : Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isVoted ? const Color(0xFFFFB74D).withOpacity(0.4) : Colors.white10),
                  ),
                  child: Row(children: [
                    Text(c.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.title, style: const TextStyle(
                            color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        Text(c.description, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                        const SizedBox(height: 4),
                        // 投票バー
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: c.voteCount / maxVotes,
                            minHeight: 4,
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation(
                              isVoted ? const Color(0xFFFFB74D) : const Color(0xFF7C4DFF)),
                          ),
                        ),
                      ],
                    )),
                    const SizedBox(width: 8),
                    Column(children: [
                      Text('${c.voteCount}', style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const Text('票', style: TextStyle(color: Colors.white30, fontSize: 9)),
                    ]),
                  ]),
                ),
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }
}

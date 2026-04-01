import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gacha_collection.dart';
import '../providers/gacha_providers.dart';

// ─────────────────────────────────────────────────────────
// GachaScreen — びっくらポン・ガチャ & コレクション
// ─────────────────────────────────────────────────────────

class GachaScreen extends ConsumerStatefulWidget {
  const GachaScreen({super.key});
  @override
  ConsumerState<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends ConsumerState<GachaScreen> {
  bool _spinning = false;
  CostumeItem? _result;
  bool _showResult = false;

  Future<void> _spin() async {
    if (_spinning) return;
    final item = ref.read(collectionProvider.notifier).spinGacha();
    if (item == null) return;

    HapticFeedback.heavyImpact();
    setState(() { _spinning = true; _showResult = false; _result = null; });

    // 演出待ち
    await Future.delayed(1800.ms);
    if (!mounted) return;

    HapticFeedback.heavyImpact();
    setState(() { _spinning = false; _result = item; _showResult = true; });

    // 自動で閉じ
    await Future.delayed(3000.ms);
    if (mounted) setState(() => _showResult = false);
  }

  @override
  Widget build(BuildContext context) {
    final collection = ref.watch(collectionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF8A7A6A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('びっくらポン！',
            style: TextStyle(color: Color(0xFF5A4A3A), fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE0F0), borderRadius: BorderRadius.circular(16)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('🎫', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text('${collection.gachaTickets}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFE91E63))),
            ]),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // ガチャマシン
              Expanded(flex: 5, child: _GachaMachine(
                spinning: _spinning,
                tickets: collection.gachaTickets,
                onSpin: _spin,
              )),
              // コレクション
              Expanded(flex: 4, child: _CollectionGrid(
                owned: collection.ownedCostumes,
                equipped: collection.equippedCostume,
                onEquip: (id) => ref.read(collectionProvider.notifier).equip(id),
              )),
            ],
          ),
          // ガチャ結果オーバーレイ
          if (_showResult && _result != null)
            _GachaResultOverlay(item: _result!),
        ],
      ),
    );
  }
}

// ── ガチャマシン ──────────────────────────────────────────

class _GachaMachine extends StatelessWidget {
  final bool spinning;
  final int tickets;
  final VoidCallback onSpin;
  const _GachaMachine({required this.spinning, required this.tickets, required this.onSpin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // マシン本体
          Container(
            width: 180, height: 200,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFCC80), Color(0xFFFF8A65)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: const Color(0xFFFF8A65).withOpacity(0.3),
                  blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 球体の窓
                Positioned(
                  top: 20,
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.3),
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                    ),
                    child: Center(
                      child: spinning
                          ? const Text('❓', style: TextStyle(fontSize: 50))
                              .animate(onPlay: (c) => c.repeat())
                              .rotate(duration: 300.ms)
                              .scaleXY(begin: 0.8, end: 1.2, duration: 300.ms)
                          : const Text('🎁', style: TextStyle(fontSize: 50))
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scaleXY(end: 1.1, duration: 1200.ms),
                    ),
                  ),
                ),
                // 出口
                Positioned(
                  bottom: 10,
                  child: Container(
                    width: 50, height: 25,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5D4037),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 回すボタン
          GestureDetector(
            onTap: tickets > 0 && !spinning ? onSpin : null,
            child: AnimatedContainer(
              duration: 300.ms,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                gradient: tickets > 0
                    ? const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFFF5252)])
                    : null,
                color: tickets > 0 ? null : const Color(0xFFE0D8CE),
                borderRadius: BorderRadius.circular(24),
                boxShadow: tickets > 0 ? [
                  BoxShadow(color: const Color(0xFFE91E63).withOpacity(0.4),
                      blurRadius: 12, offset: const Offset(0, 4)),
                ] : [],
              ),
              child: Text(
                spinning ? 'ガラガラ...' : tickets > 0 ? 'まわす！🎰' : 'チケットがないよ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                    color: tickets > 0 ? Colors.white : const Color(0xFFB0A090)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── ガチャ結果 ────────────────────────────────────────────

class _GachaResultOverlay extends StatelessWidget {
  final CostumeItem item;
  const _GachaResultOverlay({required this.item});

  Color get _rarityColor => switch (item.rarity) {
    CostumeRarity.common    => const Color(0xFF81C784),
    CostumeRarity.rare      => const Color(0xFF42A5F5),
    CostumeRarity.superRare => const Color(0xFFFFD740),
  };

  String get _rarityLabel => switch (item.rarity) {
    CostumeRarity.common    => '★',
    CostumeRarity.rare      => '★★ レア！',
    CostumeRarity.superRare => '★★★ スーパーレア！！',
  };

  @override
  Widget build(BuildContext context) {
    final rng = math.Random(42);
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // キラキラ
          for (int i = 0; i < 16; i++)
            Text(i % 2 == 0 ? '✨' : '⭐',
                style: TextStyle(fontSize: 14 + rng.nextDouble() * 10))
                .animate()
                .move(begin: Offset.zero,
                    end: Offset(math.cos(i * math.pi * 2 / 16) * 120,
                        math.sin(i * math.pi * 2 / 16) * 120),
                    duration: 700.ms, curve: Curves.easeOut)
                .fadeOut(delay: 500.ms, duration: 300.ms),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 80))
                  .animate()
                  .scaleXY(begin: 0, end: 1, duration: 600.ms, curve: Curves.elasticOut),
              const SizedBox(height: 12),
              Text(item.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white))
                  .animate().fadeIn(delay: 400.ms, duration: 300.ms),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: _rarityColor, borderRadius: BorderRadius.circular(16)),
                child: Text(_rarityLabel,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              ).animate().fadeIn(delay: 600.ms).scaleXY(begin: 0.5, end: 1, delay: 600.ms, duration: 400.ms),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

// ── コレクション ──────────────────────────────────────────

class _CollectionGrid extends StatelessWidget {
  final Set<String> owned;
  final String? equipped;
  final void Function(String) onEquip;
  const _CollectionGrid({required this.owned, required this.equipped, required this.onEquip});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text('👗 コレクション（${owned.length}/${allCostumes.length}）',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF5A4A3A))),
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: allCostumes.length,
              itemBuilder: (_, i) {
                final c = allCostumes[i];
                final isOwned = owned.contains(c.id);
                final isEquipped = equipped == c.id;
                return GestureDetector(
                  onTap: isOwned ? () => onEquip(c.id) : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isOwned ? Colors.white : const Color(0xFFF0EBE0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isEquipped ? const Color(0xFFE91E63)
                            : isOwned ? const Color(0xFFFFCC80) : const Color(0xFFE0D8CE),
                        width: isEquipped ? 2.5 : 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(isOwned ? c.emoji : '❓',
                            style: TextStyle(fontSize: 24, color: isOwned ? null : const Color(0xFFD0C8B8))),
                        if (isOwned)
                          Text(c.name, style: const TextStyle(fontSize: 7, color: Color(0xFF7A6A5A))),
                        if (isEquipped)
                          const Text('♥', style: TextStyle(fontSize: 8, color: Color(0xFFE91E63))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

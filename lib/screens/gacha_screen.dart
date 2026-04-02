import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gacha_collection.dart';
import '../providers/gacha_providers.dart';
import '../widgets/gacha_fx.dart';

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
          // ゴールデンパーティクル演出
          if (_showResult && _result != null)
            GoldenParticleSystem(active: true, rarity: _result!.rarity),
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
          // マシン本体（マテリアルシェーダー付き）
          SizedBox(
            width: 180, height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 金属ベース
                CustomPaint(
                  size: const Size(180, 200),
                  painter: MaterialShaderPainter(
                    material: GachaMaterial.metal,
                    animValue: spinning ? 0.5 : 0.3,
                  ),
                ),
                // 樹脂オーバーレイ
                Container(
                  width: 180, height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: const Color(0xFFFFB74D).withOpacity(0.3),
                        blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                ),
                // アクリル球体の窓
                Positioned(
                  top: 20,
                  child: SizedBox(
                    width: 120, height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(120, 120),
                          painter: MaterialShaderPainter(
                            material: GachaMaterial.acrylic,
                            animValue: spinning ? 0.8 : 0.4,
                          ),
                        ),
                        Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                          ),
                        ),
                        Center(
                          child: spinning
                              ? const Text('❓', style: TextStyle(fontSize: 50))
                                  .animate(onPlay: (c) => c.repeat())
                                  .rotate(duration: 300.ms)
                                  .scaleXY(begin: 0.8, end: 1.2, duration: 300.ms)
                              : const Text('🎁', style: TextStyle(fontSize: 50))
                                  .animate(onPlay: (c) => c.repeat(reverse: true))
                                  .scaleXY(end: 1.1, duration: 1200.ms),
                        ),
                      ],
                    ),
                  ),
                ),
                // 樹脂の出口
                Positioned(
                  bottom: 10,
                  child: SizedBox(
                    width: 50, height: 25,
                    child: CustomPaint(
                      size: const Size(50, 25),
                      painter: MaterialShaderPainter(material: GachaMaterial.resin),
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
                  child: Stack(
                    children: [
                      Item3DCard(
                        emoji: c.emoji,
                        name: c.name,
                        rarity: c.rarity,
                        owned: isOwned,
                      ),
                      if (isEquipped)
                        Positioned(top: 2, right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE91E63), shape: BoxShape.circle),
                            child: const Text('♥', style: TextStyle(fontSize: 8, color: Colors.white)),
                          ),
                        ),
                    ],
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

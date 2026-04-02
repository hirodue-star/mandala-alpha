import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/gacha_collection.dart';

// ─────────────────────────────────────────────────────────
// GachaFX — ハイエンドガチャ演出ウィジェット集
//
// 1. MaterialShaderPainter: アクリル/金属/樹脂の質感
// 2. GoldenParticleSystem: 物理演算パーティクル + Bloom
// 3. Item3DCard: 3Dモデル風の多層カード
// 4. MedalFlyAnimation: メダル飛翔アニメーション
// ─────────────────────────────────────────────────────────

// ── 1. マテリアルシェーダー（CustomPainter） ──────────────

enum GachaMaterial { acrylic, metal, resin }

class MaterialShaderPainter extends CustomPainter {
  final GachaMaterial material;
  final double animValue; // 0.0〜1.0（光の角度）

  MaterialShaderPainter({required this.material, this.animValue = 0.5});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    switch (material) {
      case GachaMaterial.acrylic:
        // アクリル: 半透明グラデーション + 反射ハイライト
        canvas.drawOval(rect, Paint()
          ..shader = RadialGradient(
            center: Alignment(animValue - 0.5, -0.3),
            colors: [
              Colors.white.withOpacity(0.6),
              const Color(0xFFFFCCCC).withOpacity(0.3),
              const Color(0xFFFFCCCC).withOpacity(0.1),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(rect));
        // 反射スポット
        final spotX = size.width * (0.3 + animValue * 0.4);
        canvas.drawCircle(Offset(spotX, size.height * 0.3), radius * 0.15,
          Paint()..color = Colors.white.withOpacity(0.7)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

      case GachaMaterial.metal:
        // 金属: メタリックグラデーション + 鏡面反射
        canvas.drawOval(rect, Paint()
          ..shader = LinearGradient(
            begin: Alignment(animValue * 2 - 1, -1),
            end: const Alignment(0, 1),
            colors: const [
              Color(0xFFD4AF37), Color(0xFFF5E6A0),
              Color(0xFFD4AF37), Color(0xFFB8860B),
            ],
            stops: const [0.0, 0.3, 0.6, 1.0],
          ).createShader(rect));
        // 鏡面反射ライン
        final reflectY = size.height * animValue;
        canvas.drawLine(Offset(size.width * 0.2, reflectY), Offset(size.width * 0.8, reflectY),
          Paint()..color = Colors.white.withOpacity(0.5)..strokeWidth = 2..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

      case GachaMaterial.resin:
        // 樹脂: 温かみのあるグロー + 内部光
        canvas.drawOval(rect, Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFF8A65).withOpacity(0.8),
              const Color(0xFFFFCC80).withOpacity(0.5),
              const Color(0xFFFF6E40).withOpacity(0.3),
            ],
          ).createShader(rect));
        // 内部光
        canvas.drawCircle(center, radius * 0.6, Paint()
          ..color = Colors.white.withOpacity(0.2 + animValue * 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
    }
  }

  @override
  bool shouldRepaint(MaterialShaderPainter old) => old.animValue != animValue;
}

// ── 2. ゴールデンパーティクルシステム ──────────────────────

class GoldenParticleSystem extends StatefulWidget {
  final bool active;
  final CostumeRarity rarity;
  const GoldenParticleSystem({super.key, required this.active, required this.rarity});

  @override
  State<GoldenParticleSystem> createState() => _GoldenParticleSystemState();
}

class _GoldenParticleSystemState extends State<GoldenParticleSystem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _rng = math.Random();
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final count = switch (widget.rarity) {
      CostumeRarity.common => 12,
      CostumeRarity.rare => 24,
      CostumeRarity.superRare => 48,
    };
    _particles = List.generate(count, (_) => _Particle.random(_rng));
    _ctrl = AnimationController(vsync: this, duration: 2.seconds)
      ..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: Size.infinite,
        painter: _ParticlePainter(
          particles: _particles,
          progress: _ctrl.value,
          rarity: widget.rarity,
        ),
      ),
    );
  }
}

class _Particle {
  final double x, y;    // 初期位置 (0-1)
  final double vx, vy;  // 速度
  final double size;
  final double delay;

  const _Particle(this.x, this.y, this.vx, this.vy, this.size, this.delay);

  factory _Particle.random(math.Random rng) => _Particle(
    rng.nextDouble(),
    rng.nextDouble(),
    (rng.nextDouble() - 0.5) * 0.3,
    -0.2 - rng.nextDouble() * 0.5, // 上方向
    2 + rng.nextDouble() * 4,
    rng.nextDouble(),
  );
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final CostumeRarity rarity;

  _ParticlePainter({required this.particles, required this.progress, required this.rarity});

  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = switch (rarity) {
      CostumeRarity.common => const Color(0xFF81C784),
      CostumeRarity.rare => const Color(0xFF42A5F5),
      CostumeRarity.superRare => const Color(0xFFFFD740),
    };

    for (final p in particles) {
      final t = (progress + p.delay) % 1.0;
      final x = (p.x + p.vx * t) * size.width;
      final y = (p.y + p.vy * t) * size.height;
      final alpha = (1.0 - t).clamp(0.0, 1.0);
      final s = p.size * (1.0 + t * 0.5);

      // Bloom効果（ぼかし円 + コア円）
      canvas.drawCircle(Offset(x, y), s * 3, Paint()
        ..color = baseColor.withOpacity(alpha * 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
      canvas.drawCircle(Offset(x, y), s, Paint()
        ..color = baseColor.withOpacity(alpha * 0.8));
      // 光点
      canvas.drawCircle(Offset(x, y), s * 0.4, Paint()
        ..color = Colors.white.withOpacity(alpha * 0.9));
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

// ── 3. 3Dモデル風アイテムカード ───────────────────────────

class Item3DCard extends StatelessWidget {
  final String emoji;
  final String name;
  final CostumeRarity rarity;
  final bool owned;

  const Item3DCard({
    super.key, required this.emoji, required this.name,
    required this.rarity, required this.owned,
  });

  @override
  Widget build(BuildContext context) {
    final bg = switch (rarity) {
      CostumeRarity.common => const [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
      CostumeRarity.rare => const [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
      CostumeRarity.superRare => const [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
    };
    final border = switch (rarity) {
      CostumeRarity.common => const Color(0xFF81C784),
      CostumeRarity.rare => const Color(0xFF42A5F5),
      CostumeRarity.superRare => const Color(0xFFFFD740),
    };

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: owned ? bg : [const Color(0xFFF5F0E8), const Color(0xFFE8E0D5)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: owned ? border : const Color(0xFFE0D5C0), width: owned ? 2 : 1),
        boxShadow: owned ? [
          BoxShadow(color: border.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
          // 内側ハイライト
          BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 4,
              spreadRadius: -2, offset: const Offset(0, -2)),
        ] : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 3D風の影付き絵文字
          Container(
            width: 40, height: 40,
            decoration: owned ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: border.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
            ) : null,
            child: Center(
              child: Text(owned ? emoji : '❓',
                  style: TextStyle(fontSize: 28, color: owned ? null : const Color(0xFFD0C8B8))),
            ),
          ),
          if (owned) ...[
            const SizedBox(height: 2),
            Text(name, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Color(0xFF5A4A3A))),
            // レアリティ星
            Text(
              switch (rarity) {
                CostumeRarity.common => '★',
                CostumeRarity.rare => '★★',
                CostumeRarity.superRare => '★★★',
              },
              style: TextStyle(fontSize: 6, color: border),
            ),
          ],
        ],
      ),
    );
  }
}

// ── 4. メダル飛翔アニメーション ───────────────────────────

class MedalFlyAnimation extends StatelessWidget {
  final bool active;
  const MedalFlyAnimation({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    if (!active) return const SizedBox.shrink();
    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: List.generate(3, (i) {
            final delay = Duration(milliseconds: i * 300);
            return Positioned(
              left: MediaQuery.of(context).size.width * 0.5 - 16,
              bottom: 100,
              child: const Text('🏅', style: TextStyle(fontSize: 32))
                  .animate()
                  .moveY(begin: 0, end: -300, duration: 1200.ms, delay: delay,
                      curve: Curves.easeOutCubic)
                  .moveX(begin: 0, end: (i - 1) * 40.0, duration: 1200.ms,
                      delay: delay, curve: Curves.easeInOut)
                  .scaleXY(begin: 1.0, end: 0.3, duration: 1200.ms, delay: delay)
                  .fadeOut(delay: delay + 800.ms, duration: 400.ms),
            );
          }),
        ),
      ),
    );
  }
}

// ── 5. 図鑑コンバータ ─────────────────────────────────────

class ItemCatalogEntry {
  final String id;
  final String emoji;
  final String name;
  final CostumeRarity rarity;
  final String category; // equipment/furniture/badge
  final bool owned;

  const ItemCatalogEntry({
    required this.id, required this.emoji, required this.name,
    required this.rarity, required this.category, required this.owned,
  });
}

class ItemCatalogConverter {
  ItemCatalogConverter._();

  /// 旧コスチュームデータを図鑑エントリに変換
  static List<ItemCatalogEntry> fromCostumes(Set<String> ownedIds) {
    return allCostumes.map((c) => ItemCatalogEntry(
      id: c.id,
      emoji: c.emoji,
      name: c.name,
      rarity: c.rarity,
      category: 'equipment',
      owned: ownedIds.contains(c.id),
    )).toList();
  }

  /// 家具アイテムを図鑑エントリに変換
  static List<ItemCatalogEntry> furnitureEntries(Set<int> unlockedItems) {
    const furniture = [
      ('🧸', 'くまさん'), ('🎀', 'リボン'), ('🌸', 'おはな'),
      ('⭐', 'おほし'), ('🎈', 'ふうせん'), ('🎹', 'ピアノ'),
      ('🛋️', 'ソファ'), ('🌈', 'にじ'),
    ];
    return furniture.asMap().entries.map((e) => ItemCatalogEntry(
      id: 'furn_${e.key}',
      emoji: e.value.$1,
      name: e.value.$2,
      rarity: e.key < 5 ? CostumeRarity.common : CostumeRarity.rare,
      category: 'furniture',
      owned: unlockedItems.contains(e.key),
    )).toList();
  }

  /// 称号バッジを図鑑エントリに変換
  static List<ItemCatalogEntry> badgeEntries(int totalCleared) {
    const badges = [
      (1, '🌱', 'はじめのいっぽ'),
      (5, '🌿', 'がんばりや'),
      (10, '🌳', 'チャレンジャー'),
      (25, '⭐', 'スター'),
      (50, '🏆', 'マスター'),
      (100, '👑', 'レジェンド'),
    ];
    return badges.map((b) => ItemCatalogEntry(
      id: 'badge_${b.$1}',
      emoji: b.$2,
      name: b.$3,
      rarity: b.$1 >= 50 ? CostumeRarity.superRare
          : b.$1 >= 10 ? CostumeRarity.rare : CostumeRarity.common,
      category: 'badge',
      owned: totalCleared >= b.$1,
    )).toList();
  }
}

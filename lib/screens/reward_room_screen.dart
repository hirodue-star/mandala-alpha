import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/character_providers.dart';
import '../models/character.dart';
import '../models/mandala_state.dart';
import '../widgets/puppy_character.dart';
import '../widgets/gaogao_character.dart';
import 'character_select_screen.dart';

// ─────────────────────────────────────────────────────────
// RewardRoomScreen — プピィの部屋デコ＋カレンダー
// ─────────────────────────────────────────────────────────

// ── State ─────────────────────────────────────────────────

class RewardState {
  final int acorns;
  final Set<int> unlockedItems;
  final List<DateTime> stampDates;

  const RewardState({this.acorns = 0, this.unlockedItems = const {}, this.stampDates = const []});

  RewardState copyWith({int? acorns, Set<int>? unlockedItems, List<DateTime>? stampDates}) =>
      RewardState(
        acorns: acorns ?? this.acorns,
        unlockedItems: unlockedItems ?? this.unlockedItems,
        stampDates: stampDates ?? this.stampDates,
      );
}

class RewardNotifier extends StateNotifier<RewardState> {
  RewardNotifier() : super(const RewardState());

  void earnAcorn() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final alreadyStamped = state.stampDates.any(
        (d) => d.year == todayDate.year && d.month == todayDate.month && d.day == todayDate.day);
    state = state.copyWith(
      acorns: state.acorns + 1,
      stampDates: alreadyStamped ? state.stampDates : [...state.stampDates, todayDate],
    );
  }

  bool buyItem(int itemId, int cost) {
    if (state.acorns < cost || state.unlockedItems.contains(itemId)) return false;
    state = state.copyWith(
      acorns: state.acorns - cost,
      unlockedItems: {...state.unlockedItems, itemId},
    );
    return true;
  }

  // デバッグ用
  void addAcorns(int n) => state = state.copyWith(acorns: state.acorns + n);
}

final rewardProvider = StateNotifierProvider<RewardNotifier, RewardState>(
    (ref) => RewardNotifier());

// ── 家具データ ────────────────────────────────────────────

class _FurnitureItem {
  final int id;
  final String emoji;
  final String name;
  final int cost;
  const _FurnitureItem(this.id, this.emoji, this.name, this.cost);
}

const _furniture = [
  _FurnitureItem(0, '🧸', 'くまさん', 1),
  _FurnitureItem(1, '🎀', 'リボン', 1),
  _FurnitureItem(2, '🌸', 'おはな', 2),
  _FurnitureItem(3, '⭐', 'おほしさま', 2),
  _FurnitureItem(4, '🎈', 'ふうせん', 3),
  _FurnitureItem(5, '🎹', 'ピアノ', 3),
  _FurnitureItem(6, '🛋️', 'ソファ', 4),
  _FurnitureItem(7, '🌈', 'にじ', 5),
  _FurnitureItem(8, '🏰', 'おしろ', 7),
];

// ── Screen ────────────────────────────────────────────────

class RewardRoomScreen extends ConsumerStatefulWidget {
  const RewardRoomScreen({super.key});
  @override
  ConsumerState<RewardRoomScreen> createState() => _RewardRoomScreenState();
}

class _RewardRoomScreenState extends ConsumerState<RewardRoomScreen> {
  bool _showThankYou = false;
  String _boughtItemEmoji = '';
  int _acornBounceTrigger = 0;

  void _onBuyItem(int itemId, int cost) {
    final success = ref.read(rewardProvider.notifier).buyItem(itemId, cost);
    if (success) {
      HapticFeedback.heavyImpact();
      final item = _furniture.firstWhere((f) => f.id == itemId);
      setState(() {
        _boughtItemEmoji = item.emoji;
        _showThankYou = true;
      });
      Future.delayed(2500.ms, () {
        if (mounted) setState(() => _showThankYou = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reward = ref.watch(rewardProvider);
    final charDef = ref.watch(characterProvider).def;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF8A7A6A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${charDef.name}のおへや',
            style: const TextStyle(color: Color(0xFF5A4A3A), fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          // おうちボタン（スタート画面に戻る）
          GestureDetector(
            onTap: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const CharacterSelectScreen()),
              (_) => false,
            ),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0D0), shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE0D0B0))),
              child: const Text('🏠', style: TextStyle(fontSize: 14)),
            ),
          ),
          // どんぐりカウンター
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8B0), borderRadius: BorderRadius.circular(16)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('🌰', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text('${reward.acorns}', style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF6B4E2A))),
            ]),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(flex: 5, child: _RoomView(unlocked: reward.unlockedItems, charDef: charDef)),
              _StampCalendar(stamps: reward.stampDates),
              const SizedBox(height: 8),
              Expanded(flex: 4, child: _Shop(
                reward: reward,
                onBuy: _onBuyItem,
              )),
            ],
          ),
          // どんぐりバウンス演出
          if (_acornBounceTrigger > 0)
            _AcornBounceOverlay(key: ValueKey(_acornBounceTrigger)),
          // ありがとうカットイン
          if (_showThankYou)
            _ThankYouCutscene(itemEmoji: _boughtItemEmoji, charDef: charDef),
        ],
      ),
    );
  }
}

// ── どんぐりバウンス（物理演算風） ──────────────────────────

class _AcornBounceOverlay extends StatelessWidget {
  const _AcornBounceOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final rng = math.Random();
    final w = MediaQuery.of(context).size.width;

    return IgnorePointer(
      child: Stack(
        children: List.generate(4, (i) {
          final startX = 40.0 + rng.nextDouble() * (w - 80);
          final delay = Duration(milliseconds: i * 120);
          return Positioned(
            left: startX,
            top: -30,
            child: const Text('🌰', style: TextStyle(fontSize: 28))
                .animate()
                // 落下（バウンス曲線）
                .moveY(begin: 0, end: MediaQuery.of(context).size.height * 0.75,
                    duration: 900.ms, delay: delay,
                    curve: Curves.bounceOut)
                // 横揺れ
                .moveX(begin: 0, end: (i.isEven ? 20.0 : -20.0),
                    duration: 900.ms, delay: delay,
                    curve: Curves.easeInOut)
                // 回転
                .rotate(end: (i.isEven ? 0.5 : -0.5), duration: 900.ms, delay: delay)
                // 吸い込まれ（縮小＋フェードアウト）
                .then(delay: 100.ms)
                .scaleXY(end: 0.3, duration: 400.ms, curve: Curves.easeIn)
                .moveY(end: 100, duration: 400.ms, curve: Curves.easeIn)
                .fadeOut(duration: 300.ms),
          );
        }),
      ),
    );
  }
}

// ── ありがとう！カットイン ──────────────────────────────────

class _ThankYouCutscene extends StatelessWidget {
  final String itemEmoji;
  final CharacterDef charDef;
  const _ThankYouCutscene({required this.itemEmoji, required this.charDef});

  @override
  Widget build(BuildContext context) {
    final rng = math.Random(42);
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ハートエフェクト（放射状に飛ぶ）
          for (int i = 0; i < 12; i++)
            Positioned(
              child: Text(
                i % 3 == 0 ? '❤️' : i % 3 == 1 ? '💖' : '💕',
                style: TextStyle(fontSize: 20 + rng.nextDouble() * 16),
              )
                  .animate()
                  .move(
                    begin: Offset.zero,
                    end: Offset(
                      math.cos(i * math.pi * 2 / 12) * 140,
                      math.sin(i * math.pi * 2 / 12) * 140,
                    ),
                    duration: 800.ms, delay: Duration(milliseconds: 200 + i * 50),
                    curve: Curves.easeOut,
                  )
                  .fadeOut(delay: 600.ms, duration: 400.ms)
                  .scaleXY(begin: 0.3, end: 1.2, duration: 600.ms),
            ),

          // キャラ大ズームアップ
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 120, height: 130,
                child: charDef.id == CharacterId.puppy
                    ? const PuppyCharacter(stage: 0, phase: ResonancePhase.locked)
                    : const GaogaoCharacter(stage: 0, phase: ResonancePhase.locked),
              ).animate()
                  .scaleXY(begin: 0.1, end: 1.0, duration: 600.ms, curve: Curves.elasticOut)
                  .then()
                  .scaleXY(end: 1.05, duration: 400.ms)
                  .then()
                  .scaleXY(end: 1.0, duration: 300.ms),
              const SizedBox(height: 8),
              // アイテム表示
              Text(itemEmoji, style: const TextStyle(fontSize: 48))
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 300.ms)
                  .scaleXY(begin: 0, end: 1, delay: 400.ms, duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 12),
              // ありがとう！テキスト
              const Text(
                'ありがとう！',
                style: TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w900,
                  color: Color(0xFFFFB74D),
                  shadows: [
                    Shadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 300.ms)
                  .slideY(begin: 0.3, end: 0, delay: 500.ms, duration: 400.ms, curve: Curves.easeOutBack)
                  .then(delay: 200.ms)
                  .shimmer(duration: 800.ms, color: Colors.white),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 200.ms);
  }
}

// ── 部屋ビュー ────────────────────────────────────────────

class _RoomView extends StatelessWidget {
  final Set<int> unlocked;
  final CharacterDef charDef;
  const _RoomView({required this.unlocked, required this.charDef});

  @override
  Widget build(BuildContext context) {
    // キャラ別の部屋カラー
    final isPuppy = charDef.id == CharacterId.puppy;
    final wallColor = isPuppy ? const Color(0xFFFFF0F5) : const Color(0xFFF1F8E9);
    final floorColor = isPuppy ? const Color(0xFFFFD6E8) : const Color(0xFFC8E6C9);
    final borderColor = isPuppy ? const Color(0xFFFFB3DE) : const Color(0xFF81C784);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [wallColor, wallColor.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor.withOpacity(0.5), width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // パステル水彩ドット壁紙
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: CustomPaint(painter: _PastelWallpaperPainter(isPuppy: isPuppy)),
            ),
          ),
          // 床
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: floorColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(22), bottomRight: Radius.circular(22))),
            ),
          ),
          // キャラクター（マンダラ中央と同じCustomPaint描画）
          Positioned(
            bottom: 24,
            child: charDef.id == CharacterId.puppy
                ? const PuppyCharacter(stage: 0, phase: ResonancePhase.locked)
                : const GaogaoCharacter(stage: 0, phase: ResonancePhase.locked),
          ),
          // 家具
          for (final item in _furniture)
            if (unlocked.contains(item.id))
              Positioned(
                left: 20.0 + (item.id % 3) * 90,
                top: 20.0 + (item.id ~/ 3) * 55,
                child: Text(item.emoji, style: const TextStyle(fontSize: 30))
                    .animate().scaleXY(begin: 0, end: 1, duration: 400.ms, curve: Curves.elasticOut),
              ),
        ],
      ),
    );
  }
}

class _PastelWallpaperPainter extends CustomPainter {
  final bool isPuppy;
  _PastelWallpaperPainter({required this.isPuppy});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    // パステル水彩ドット
    final colors = isPuppy
        ? [const Color(0xFFFFD6E8), const Color(0xFFFFB3DE), const Color(0xFFFFF0F5)]
        : [const Color(0xFFC8E6C9), const Color(0xFF81C784), const Color(0xFFE8F5E9)];

    for (double x = 12; x < size.width; x += 28) {
      for (double y = 12; y < size.height - 50; y += 28) {
        final c = colors[rng.nextInt(colors.length)];
        canvas.drawCircle(Offset(x + rng.nextDouble() * 6, y + rng.nextDouble() * 6),
            2 + rng.nextDouble() * 2,
            Paint()..color = c.withOpacity(0.3 + rng.nextDouble() * 0.2)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5));
      }
    }

    // 水彩風の大きなにじみ
    for (int i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * (size.height - 60)),
        20 + rng.nextDouble() * 30,
        Paint()..color = colors[i % colors.length].withOpacity(0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── スタンプ帳 ─────────────────────────────────────────────

class _StampCalendar extends StatelessWidget {
  final List<DateTime> stamps;
  const _StampCalendar({required this.stamps});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final stampSet = stamps
        .where((d) => d.year == now.year && d.month == now.month)
        .map((d) => d.day).toSet();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text('${now.month}がつ スタンプちょう',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF6A5A4A))),
          const SizedBox(height: 6),
          SizedBox(
            height: 28,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: daysInMonth,
              itemBuilder: (_, i) {
                final day = i + 1;
                final hasStamp = stampSet.contains(day);
                final isToday = day == now.day;
                return Container(
                  width: 26, height: 26,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasStamp ? const Color(0xFFFFD740)
                        : isToday ? const Color(0xFFFFF0C0) : Colors.transparent,
                    border: isToday ? Border.all(color: const Color(0xFFFFB300), width: 1.5) : null,
                  ),
                  child: Center(
                    child: Text(hasStamp ? '🌟' : '$day',
                        style: TextStyle(fontSize: hasStamp ? 14 : 9,
                            color: const Color(0xFF8A7A6A), fontWeight: FontWeight.w600)),
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

// ── ショップ ───────────────────────────────────────────────

class _Shop extends StatelessWidget {
  final RewardState reward;
  final void Function(int itemId, int cost) onBuy;
  const _Shop({required this.reward, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 6),
            child: Text('🛒 おかいもの',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF5A4A3A))),
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.85),
              itemCount: _furniture.length,
              itemBuilder: (_, i) {
                final item = _furniture[i];
                final owned = reward.unlockedItems.contains(item.id);
                final canBuy = reward.acorns >= item.cost;
                return GestureDetector(
                  onTap: owned ? null : () {
                    if (canBuy) onBuy(item.id, item.cost);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: owned ? const Color(0xFFE8F5E9) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: owned ? const Color(0xFF81C784)
                            : canBuy ? const Color(0xFFFFCC80) : const Color(0xFFE0D8CE),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item.emoji, style: TextStyle(fontSize: 28,
                            color: owned || canBuy ? null : const Color(0xFFCCC0B0))),
                        const SizedBox(height: 4),
                        Text(item.name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                            color: owned ? const Color(0xFF4CAF50) : const Color(0xFF7A6A5A))),
                        if (!owned)
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            const Text('🌰', style: TextStyle(fontSize: 10)),
                            Text(' ${item.cost}', style: TextStyle(fontSize: 10,
                                color: canBuy ? const Color(0xFF6B4E2A) : const Color(0xFFCCC0B0),
                                fontWeight: FontWeight.bold)),
                          ]),
                        if (owned) const Text('✓', style: TextStyle(fontSize: 12, color: Color(0xFF4CAF50))),
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

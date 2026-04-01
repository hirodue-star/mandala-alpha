import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/mandala_state.dart';

// ─────────────────────────────────────────────────────────
// ResonanceCell v2 — 楽器別ネオンカラー + Dark Navy
//
// 各マスに楽器固有のネオンパステルカラーを割り当て。
// 完了時は同色のグロー発光。
// ─────────────────────────────────────────────────────────

class ResonanceCell extends StatelessWidget {
  final int cellIndex;
  final String label;
  final bool completed;
  final ResonancePhase phase;
  final int waveDelayMs;
  final VoidCallback onTap;

  const ResonanceCell({
    super.key,
    required this.cellIndex,
    required this.label,
    required this.completed,
    required this.phase,
    required this.waveDelayMs,
    required this.onTap,
  });

  // ── 楽器別カラー定義 ────────────────────────────────────
  // インデックス: 0=上(ピアノ) 1=右上(チェロ) 2=右(フルート)
  //              3=右下(バイオリン) 4=下(ドラム) 5=左下(トランペット)
  //              6=左(ギター) 7=左上(マリンバ)

  static const List<Color> baseColors = [
    Color(0xFF0D1F33), // ピアノ    : ダークネイビー
    Color(0xFF1A0D33), // チェロ    : ダークパープル
    Color(0xFF0D2918), // フルート  : ダークグリーン
    Color(0xFF2A1E00), // バイオリン: ダークアンバー
    Color(0xFF2A0A0A), // ドラム    : ダークレッド
    Color(0xFF2A1200), // トランペット:ダークオレンジ
    Color(0xFF152800), // ギター    : ダークライム
    Color(0xFF002828), // マリンバ  : ダークティール
  ];

  static const List<Color> neonAccents = [
    Color(0xFF40C4FF), // ピアノ    : ネオン水色
    Color(0xFFCE93D8), // チェロ    : ネオン紫
    Color(0xFF69F0AE), // フルート  : ネオンミント
    Color(0xFFFFD740), // バイオリン: ネオン黄
    Color(0xFFFF5252), // ドラム    : ネオンレッド
    Color(0xFFFF6D00), // トランペット:ネオンオレンジ
    Color(0xFF76FF03), // ギター    : ネオンライム
    Color(0xFF18FFFF), // マリンバ  : ネオンシアン
  ];

  static const List<String> instrumentEmojis = [
    '🎹', '🎻', '🎵', '🎸', '🥁', '🎺', '🎸', '🎼',
  ];

  static const List<String> instrumentNames = [
    'ピアノ', 'チェロ', 'フルート', 'バイオリン',
    'ドラム', 'トランペット', 'ギター', 'マリンバ',
  ];

  bool get _isLocked => phase == ResonancePhase.locked;
  Color get _accent => neonAccents[cellIndex % neonAccents.length];
  Color get _base => baseColors[cellIndex % baseColors.length];

  @override
  Widget build(BuildContext context) {
    Widget cell = GestureDetector(
      onTap: _isLocked ? null : onTap,
      child: AnimatedContainer(
        duration: 350.ms,
        decoration: BoxDecoration(
          color: _isLocked
              ? const Color(0xFF111111)
              : completed
                  ? _base.withRed((_base.red + 20).clamp(0, 255))
                  : _base,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isLocked
                ? Colors.white12
                : completed
                    ? _accent
                    : _accent.withOpacity(0.4),
            width: completed ? 2 : 1.5,
          ),
          boxShadow: _isLocked
              ? []
              : completed
                  ? [
                      BoxShadow(
                        color: _accent.withOpacity(0.55),
                        blurRadius: 18,
                        spreadRadius: 3,
                      ),
                      BoxShadow(
                        color: _accent.withOpacity(0.25),
                        blurRadius: 40,
                        spreadRadius: 6,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: _accent.withOpacity(0.12),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 楽器絵文字
            AnimatedOpacity(
              opacity: _isLocked ? 0.18 : 1.0,
              duration: 400.ms,
              child: Text(
                instrumentEmojis[cellIndex % instrumentEmojis.length],
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(height: 2),
            // 楽器名（完了時）またはラベル
            AnimatedOpacity(
              opacity: _isLocked ? 0.18 : 1.0,
              duration: 400.ms,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Text(
                  completed
                      ? instrumentNames[cellIndex % instrumentNames.length]
                      : label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: completed ? _accent : Colors.white70,
                    height: 1.2,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // 完了時：♪ネオン発光
            if (completed) ...[
              const SizedBox(height: 2),
              Text(
                '♪',
                style: TextStyle(
                  fontSize: 12,
                  color: _accent,
                  fontWeight: FontWeight.bold,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .shimmer(duration: 900.ms, color: Colors.white)
                  .scaleXY(end: 1.25, duration: 450.ms),
            ],
          ],
        ),
      ),
    );

    // 波紋展開アニメーション
    if (!_isLocked) {
      cell = cell
          .animate()
          .slideY(
            begin: 0.2,
            end: 0,
            delay: Duration(milliseconds: waveDelayMs),
            duration: 500.ms,
            curve: Curves.easeOutBack,
          )
          .fadeIn(
            delay: Duration(milliseconds: waveDelayMs),
            duration: 400.ms,
          );
    }

    return cell;
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/mandala_state.dart';
import '../services/audio_mixer_service.dart';

// ─────────────────────────────────────────────────────────
// ResonanceCell — 共鳴マスWidget
// 完了時に金色発光 + 楽器名ラベルを表示
// ─────────────────────────────────────────────────────────

class ResonanceCell extends StatelessWidget {
  final int cellIndex;      // 0〜7
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

  // 8マスの色テーマ
  static const List<Color> _cellColors = [
    Color(0xFFE3F2FD), // 上    : 水色
    Color(0xFFF3E5F5), // 右上  : 薄紫
    Color(0xFFE8F5E9), // 右    : 薄緑
    Color(0xFFFFF8E1), // 右下  : 薄黄
    Color(0xFFFFEBEE), // 下    : 薄赤
    Color(0xFFFBE9E7), // 左下  : 薄オレンジ
    Color(0xFFE0F7FA), // 左    : 薄シアン
    Color(0xFFF1F8E9), // 左上  : 薄ライム
  ];

  static const List<Color> _doneColors = [
    Color(0xFFFFD700), // 完了は全セル金色
  ];

  bool get _isLocked => phase == ResonancePhase.locked;

  Color get _bgColor {
    if (_isLocked) return const Color(0xFFEEEEEE);
    if (completed) return const Color(0xFFFFD700);
    return _cellColors[cellIndex % _cellColors.length];
  }

  @override
  Widget build(BuildContext context) {
    Widget cell = GestureDetector(
      onTap: _isLocked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: completed
                ? const Color(0xFFFFD700)
                : _isLocked
                    ? Colors.grey.shade300
                    : _cellColors[cellIndex % _cellColors.length]
                        .withOpacity(1),
            width: completed ? 2 : 1.5,
          ),
          boxShadow: completed
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.6),
                    blurRadius: 16,
                    spreadRadius: 3,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isLocked ? 0.03 : 0.07),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedOpacity(
              opacity: _isLocked ? 0.25 : 1.0,
              duration: const Duration(milliseconds: 400),
              child: Text(
                _instrumentEmoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedOpacity(
              opacity: _isLocked ? 0.25 : 1.0,
              duration: const Duration(milliseconds: 400),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: completed
                        ? const Color(0xFF5D4037)
                        : const Color(0xFF4A4A6A),
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (completed) ...[
              const SizedBox(height: 2),
              const Text(
                '♪',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF5D4037),
                  fontWeight: FontWeight.bold,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .shimmer(duration: 1000.ms, color: Colors.white)
                  .scaleXY(end: 1.2, duration: 500.ms),
            ],
          ],
        ),
      ),
    );

    // 波紋展開アニメーション（ロック解除時）
    if (!_isLocked) {
      cell = cell
          .animate()
          .slideY(
            begin: 0.25,
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

  // 楽器絵文字（AudioMixerService.trackNames と対応）
  static const List<String> _instrumentEmojis = [
    '🎹', // ピアノ
    '🎻', // チェロ
    '🎵', // フルート
    '🎸', // バイオリン（代替）
    '🥁', // ドラム
    '🎺', // トランペット
    '🎸', // ギター
    '🎼', // マリンバ（代替）
  ];

  String get _instrumentEmoji =>
      _instrumentEmojis[cellIndex % _instrumentEmojis.length];
}

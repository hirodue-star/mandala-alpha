import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/mandala_state.dart';

// ─────────────────────────────────────────────────────────
// EggWidget — たまごの進化アニメーション
//
// stage 0   : 白たまご（静止）
// stage 1-2 : 底部から淡い光
// stage 3-4 : ヒビ2本 + わずかな揺れ
// stage 5-6 : ヒビ4本 + 傾き + 黄金グロー
// stage 7   : ヒビ6本 + 激しい振動 + 強グロー
// stage 8   : 孵化バースト → ひよこ🐣
// ─────────────────────────────────────────────────────────

class EggWidget extends StatelessWidget {
  final int stage;           // 0〜8
  final ResonancePhase phase;
  final VoidCallback? onTap;

  const EggWidget({
    super.key,
    required this.stage,
    required this.phase,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (phase == ResonancePhase.hatched) {
      return _HatchedChick();
    }
    if (phase == ResonancePhase.hatching) {
      return _HatchingBurst(stage: stage);
    }
    return _EggBody(stage: stage, onTap: onTap);
  }
}

// ── たまご本体 ─────────────────────────────────────────

class _EggBody extends StatelessWidget {
  final int stage;
  final VoidCallback? onTap;

  const _EggBody({required this.stage, this.onTap});

  // 揺れの強さ (degree)
  double get _wobbleDeg {
    if (stage <= 2) return 0;
    if (stage <= 4) return 3;
    if (stage <= 6) return 7;
    return 12;
  }

  // グローの強さ
  double get _glowOpacity {
    if (stage == 0) return 0;
    if (stage <= 2) return 0.15;
    if (stage <= 4) return 0.35;
    if (stage <= 6) return 0.55;
    return 0.8;
  }

  Color get _glowColor {
    if (stage <= 4) return const Color(0xFFFFD700);
    return const Color(0xFFFF9800);
  }

  @override
  Widget build(BuildContext context) {
    Widget egg = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 110,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: _glowColor.withOpacity(_glowOpacity),
              blurRadius: 24,
              spreadRadius: 8,
            ),
          ],
        ),
        child: CustomPaint(
          painter: _EggPainter(stage: stage),
          child: Center(
            child: stage >= 7
                ? const Text('💥', style: TextStyle(fontSize: 20))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(end: 1.3, duration: 300.ms)
                : null,
          ),
        ),
      ),
    );

    // 揺れアニメーション
    if (_wobbleDeg > 0) {
      egg = egg
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .rotate(
            begin: -_wobbleDeg * math.pi / 180,
            end: _wobbleDeg * math.pi / 180,
            duration: Duration(milliseconds: stage >= 7 ? 120 : 300),
            curve: Curves.easeInOut,
          );
    } else {
      // ステージ0でも呼吸するように微妙にスケール
      egg = egg
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(end: 1.04, duration: 1600.ms, curve: Curves.easeInOut);
    }

    return egg;
  }
}

// ── CustomPainter：たまごの外形とヒビ ─────────────────

class _EggPainter extends CustomPainter {
  final int stage;
  _EggPainter({required this.stage});

  // ヒビの定義（最大6本）
  static const _cracks = [
    // [startFracX, startFracY, endFracX, endFracY]
    [0.45, 0.35, 0.35, 0.25], // ひび1
    [0.55, 0.30, 0.65, 0.20], // ひび2
    [0.40, 0.50, 0.25, 0.40], // ひび3
    [0.60, 0.45, 0.75, 0.35], // ひび4
    [0.50, 0.60, 0.42, 0.70], // ひび5
    [0.50, 0.55, 0.60, 0.65], // ひび6
  ];

  int get _crackCount {
    if (stage <= 2) return 0;
    if (stage <= 4) return 2;
    if (stage <= 6) return 4;
    return 6;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // たまごの外形パス（上が細く下が太い楕円）
    final path = Path();
    path.moveTo(cx, 4);
    path.cubicTo(
      size.width * 1.05, size.height * 0.2,   // 右上制御点
      size.width * 1.0,  size.height * 0.85,  // 右下制御点
      cx, size.height - 4,                    // 下端
    );
    path.cubicTo(
      size.width * 0.0,  size.height * 0.85,  // 左下制御点
      size.width * -0.05, size.height * 0.2,  // 左上制御点
      cx, 4,                                  // 上端（閉じる）
    );
    path.close();

    // 塗り（グラデーション）
    final gradient = RadialGradient(
      center: const Alignment(-0.2, -0.3),
      radius: 0.8,
      colors: [
        Colors.white,
        stage <= 2
            ? const Color(0xFFF5F0FF)
            : stage <= 5
                ? const Color(0xFFFFF8E1)
                : const Color(0xFFFFECB3),
      ],
    );
    final paint = Paint()
      ..shader = gradient.createShader(
          Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // 輪郭
    final borderPaint = Paint()
      ..color = stage >= 5
          ? const Color(0xFFFFD700).withOpacity(0.6)
          : Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = stage >= 7 ? 2.5 : 1.5;
    canvas.drawPath(path, borderPaint);

    // ヒビ
    if (_crackCount > 0) {
      final crackPaint = Paint()
        ..color = const Color(0xFF8D6E63)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < _crackCount; i++) {
        final c = _cracks[i];
        final sx = size.width * c[0];
        final sy = size.height * c[1];
        final ex = size.width * c[2];
        final ey = size.height * c[3];

        // ジグザグヒビ
        final mx = (sx + ex) / 2 + (i.isEven ? 5.0 : -5.0);
        final my = (sy + ey) / 2;
        final crackPath = Path()
          ..moveTo(sx, sy)
          ..lineTo(mx, my)
          ..lineTo(ex, ey);
        canvas.drawPath(crackPath, crackPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_EggPainter old) => old.stage != stage;
}

// ── 孵化バースト（stage 8 / hatching フェーズ） ───────

class _HatchingBurst extends StatelessWidget {
  final int stage;
  const _HatchingBurst({required this.stage});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 外側の光の輪
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFFFD700).withOpacity(0.9),
                  const Color(0xFFFF9800).withOpacity(0.0),
                ],
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(begin: 0.8, end: 1.6, duration: 800.ms)
              .fadeOut(begin: 1.0, duration: 800.ms),

          // たまごの殻の破片
          for (int i = 0; i < 5; i++)
            Positioned(
              left: 30 + math.cos(i * math.pi * 2 / 5) * 35,
              top: 30 + math.sin(i * math.pi * 2 / 5) * 35,
              child: const Text('🥚', style: TextStyle(fontSize: 14))
                  .animate(onPlay: (c) => c.forward())
                  .moveY(
                    begin: 0,
                    end: -(20 + i * 5).toDouble(),
                    duration: 600.ms,
                    curve: Curves.easeOut,
                  )
                  .fadeOut(delay: 300.ms, duration: 400.ms),
            ),

          // 中央：ひよこ出現
          const Text('🐣', style: TextStyle(fontSize: 48))
              .animate()
              .scaleXY(begin: 0.1, end: 1.0, duration: 700.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}

// ── 孵化完了（hatched フェーズ） ──────────────────────

class _HatchedChick extends StatelessWidget {
  const _HatchedChick();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🐥', style: TextStyle(fontSize: 56))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: 0, end: -6, duration: 600.ms, curve: Curves.easeInOut)
            .scaleXY(end: 1.08, duration: 600.ms),
        const SizedBox(height: 4),
        const Text(
          'たんじょう！',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF9800),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .shimmer(duration: 1200.ms, color: const Color(0xFFFFD700)),
      ],
    );
  }
}

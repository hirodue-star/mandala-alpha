import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/mandala_state.dart';

// ─────────────────────────────────────────────────────────
// EggWidget v2 — ネオンパステル + オーラ輪 + Squashアニメ
//
// stage 0   : 白たまご、呼吸エフェクト
// stage 1-2 : 底部からパステルグロー
// stage 3-4 : ヒビ2本 + オーラリング1枚
// stage 5-6 : ヒビ4本 + オーラリング2枚 + 傾き
// stage 7   : ヒビ6本 + オーラリング3枚 + 激しい振動
// stage 8   : 孵化バースト → ひよこ🐥 + レインボーオーラ
// ─────────────────────────────────────────────────────────

class EggWidget extends StatelessWidget {
  final int stage;
  final ResonancePhase phase;
  final int squashTrigger; // セルタップのたびにインクリメント
  final VoidCallback? onTap;

  const EggWidget({
    super.key,
    required this.stage,
    required this.phase,
    this.squashTrigger = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (phase == ResonancePhase.hatched) return const _HatchedChick();
    if (phase == ResonancePhase.hatching) return _HatchingBurst(stage: stage);
    return _EggWithAura(
      stage: stage,
      squashTrigger: squashTrigger,
      onTap: onTap,
    );
  }
}

// ── オーラ + たまご ────────────────────────────────────────

class _EggWithAura extends StatelessWidget {
  final int stage;
  final int squashTrigger;
  final VoidCallback? onTap;

  const _EggWithAura({
    required this.stage,
    required this.squashTrigger,
    this.onTap,
  });

  // オーラリング数
  int get _auraCount {
    if (stage <= 2) return 0;
    if (stage <= 4) return 1;
    if (stage <= 6) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // オーラリング（後ろに描画）
          for (int i = 0; i < _auraCount; i++)
            _AuraRing(
              index: i,
              stage: stage,
              totalRings: _auraCount,
            ),

          // たまご本体
          _EggBody(
            stage: stage,
            squashTrigger: squashTrigger,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

// ── オーラリング ───────────────────────────────────────────

class _AuraRing extends StatelessWidget {
  final int index;
  final int stage;
  final int totalRings;

  const _AuraRing({
    required this.index,
    required this.stage,
    required this.totalRings,
  });

  // ステージ別パステルカラーパレット
  static const List<List<Color>> _palettes = [
    [Color(0xFF7FDBFF), Color(0xFFFFB3DE)],           // stage 3-4: シアン×ピンク
    [Color(0xFFFFB3DE), Color(0xFFFFF176), Color(0xFF7FDBFF)], // stage 5-6: ピンク×黄×シアン
    [Color(0xFF7FDBFF), Color(0xFFFFF176), Color(0xFFFFB3DE), Color(0xFFB9F6CA)], // 7+: レインボー
  ];

  Color get _ringColor {
    final palette = stage <= 4
        ? _palettes[0]
        : stage <= 6
            ? _palettes[1]
            : _palettes[2];
    return palette[index % palette.length];
  }

  double get _baseSize => 80.0 + (index + 1) * 22.0;
  double get _opacity => (0.55 - index * 0.12).clamp(0.1, 0.55);

  @override
  Widget build(BuildContext context) {
    final delay = Duration(milliseconds: index * 200);
    return Container(
      width: _baseSize,
      height: _baseSize * 1.15,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _ringColor.withOpacity(_opacity),
          width: 2.5 - index * 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _ringColor.withOpacity(_opacity * 0.6),
            blurRadius: 12 + index * 4.0,
            spreadRadius: 2,
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(
          begin: 0.9,
          end: 1.08,
          duration: Duration(milliseconds: 1400 + index * 300),
          delay: delay,
          curve: Curves.easeInOut,
        )
        .fadeIn(delay: delay, duration: 600.ms);
  }
}

// ── たまご本体（Squash アニメ付き StatefulWidget） ─────────

class _EggBody extends StatefulWidget {
  final int stage;
  final int squashTrigger;
  final VoidCallback? onTap;

  const _EggBody({
    required this.stage,
    required this.squashTrigger,
    this.onTap,
  });

  @override
  State<_EggBody> createState() => _EggBodyState();
}

class _EggBodyState extends State<_EggBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _squashCtrl;
  late final Animation<double> _scaleX;
  late final Animation<double> _scaleY;

  @override
  void initState() {
    super.initState();
    _squashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    // Squash: 横に広がり → 縦に伸びて → 元に戻る（ビヨーン）
    _scaleX = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.75), weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 0.75, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 50),
    ]).animate(_squashCtrl);

    _scaleY = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.7), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 1.3), weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 1.3, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 50),
    ]).animate(_squashCtrl);
  }

  @override
  void didUpdateWidget(_EggBody old) {
    super.didUpdateWidget(old);
    if (old.squashTrigger != widget.squashTrigger &&
        widget.squashTrigger > 0) {
      _squashCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _squashCtrl.dispose();
    super.dispose();
  }

  double get _wobbleDeg {
    if (widget.stage <= 2) return 0;
    if (widget.stage <= 4) return 3;
    if (widget.stage <= 6) return 7;
    return 13;
  }

  @override
  Widget build(BuildContext context) {
    Widget egg = GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _squashCtrl,
        builder: (_, child) => Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(
            _scaleX.value,
            _scaleY.value,
            1.0,
          ),
          child: child,
        ),
        child: SizedBox(
          width: 72,
          height: 90,
          child: CustomPaint(
            painter: _EggPainter(stage: widget.stage),
          ),
        ),
      ),
    );

    // 揺れアニメーション（Squash中は一時停止しない—自然に重なる）
    if (_wobbleDeg > 0) {
      egg = egg
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .rotate(
            begin: -_wobbleDeg * math.pi / 180,
            end: _wobbleDeg * math.pi / 180,
            duration:
                Duration(milliseconds: widget.stage >= 7 ? 110 : 280),
            curve: Curves.easeInOut,
          );
    } else {
      egg = egg
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(end: 1.04, duration: 1800.ms, curve: Curves.easeInOut);
    }

    return egg;
  }
}

// ── CustomPainter：ネオンパステルたまご + ヒビ ────────────

class _EggPainter extends CustomPainter {
  final int stage;
  _EggPainter({required this.stage});

  static const _cracks = [
    [0.45, 0.35, 0.33, 0.22],
    [0.55, 0.30, 0.67, 0.18],
    [0.38, 0.52, 0.22, 0.42],
    [0.62, 0.47, 0.78, 0.37],
    [0.48, 0.62, 0.38, 0.74],
    [0.52, 0.58, 0.63, 0.68],
  ];

  int get _crackCount {
    if (stage <= 2) return 0;
    if (stage <= 4) return 2;
    if (stage <= 6) return 4;
    return 6;
  }

  // ネオンパステルグロー色
  List<Color> get _glowColors {
    if (stage == 0) return [Colors.white, const Color(0xFFF0EEFF)];
    if (stage <= 2) return [Colors.white, const Color(0xFFCCF2FF)];
    if (stage <= 4) return [Colors.white, const Color(0xFFFFD6F0)];
    if (stage <= 6) return [Colors.white, const Color(0xFFFFF5A0)];
    return [Colors.white, const Color(0xFFB0FFEE)];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // たまご外形パス
    final path = Path()
      ..moveTo(cx, 3)
      ..cubicTo(
        size.width * 1.06, size.height * 0.22,
        size.width * 1.0,  size.height * 0.84,
        cx, size.height - 3,
      )
      ..cubicTo(
        0, size.height * 0.84,
        size.width * -0.06, size.height * 0.22,
        cx, 3,
      )
      ..close();

    // ネオンパステルグラデーション塗り
    final gradient = RadialGradient(
      center: const Alignment(-0.25, -0.35),
      radius: 0.85,
      colors: _glowColors,
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = gradient.createShader(
            Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill,
    );

    // 光沢ハイライト
    final highlightPath = Path()
      ..moveTo(cx * 0.6, size.height * 0.12)
      ..cubicTo(
        cx * 0.3, size.height * 0.08,
        cx * 0.2, size.height * 0.28,
        cx * 0.5, size.height * 0.32,
      );
    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // 外枠 ネオングロー
    final borderColor = stage >= 7
        ? const Color(0xFF18FFFF)
        : stage >= 5
            ? const Color(0xFFFFB3DE)
            : stage >= 3
                ? const Color(0xFF7FDBFF)
                : Colors.white.withOpacity(0.5);
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor.withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter =
            MaskFilter.blur(BlurStyle.normal, stage >= 5 ? 3.0 : 1.5),
    );

    // ヒビ
    if (_crackCount > 0) {
      final crackPaint = Paint()
        ..color = const Color(0xFFA0522D).withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < _crackCount; i++) {
        final c = _cracks[i];
        final sx = size.width * c[0];
        final sy = size.height * c[1];
        final ex = size.width * c[2];
        final ey = size.height * c[3];
        final mx = (sx + ex) / 2 + (i.isEven ? 6.0 : -6.0);
        final my = (sy + ey) / 2;
        canvas.drawPath(
          Path()
            ..moveTo(sx, sy)
            ..lineTo(mx, my)
            ..lineTo(ex, ey),
          crackPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_EggPainter old) => old.stage != stage;
}

// ── 孵化バースト ───────────────────────────────────────────

class _HatchingBurst extends StatelessWidget {
  final int stage;
  const _HatchingBurst({required this.stage});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // レインボーオーラ爆発
          for (int i = 0; i < 3; i++)
            Container(
              width: 60.0 + i * 25,
              height: 70.0 + i * 25,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    const Color(0xFF7FDBFF),
                    const Color(0xFFFFB3DE),
                    const Color(0xFFFFF176),
                    const Color(0xFFB9F6CA),
                    const Color(0xFF7FDBFF),
                  ],
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .scaleXY(
                  begin: 0.6,
                  end: 1.8,
                  duration: Duration(milliseconds: 700 + i * 150),
                )
                .fadeOut(duration: Duration(milliseconds: 700 + i * 150)),

          // 殻の破片
          for (int i = 0; i < 5; i++)
            Positioned(
              left: 40 + math.cos(i * math.pi * 2 / 5) * 38,
              top: 40 + math.sin(i * math.pi * 2 / 5) * 38,
              child: const Text('🥚', style: TextStyle(fontSize: 13))
                  .animate()
                  .moveY(begin: 0, end: -25.0 - i * 4, duration: 600.ms)
                  .rotate(end: (i.isEven ? 0.5 : -0.5))
                  .fadeOut(delay: 250.ms, duration: 350.ms),
            ),

          // ひよこ出現
          const Text('🐣', style: TextStyle(fontSize: 52))
              .animate()
              .scaleXY(
                begin: 0.05,
                end: 1.0,
                duration: 650.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 350.ms),
        ],
      ),
    );
  }
}

// ── 孵化完了 ─────────────────────────────────────────────

class _HatchedChick extends StatelessWidget {
  const _HatchedChick();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🐥', style: TextStyle(fontSize: 54))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: 0, end: -7, duration: 650.ms, curve: Curves.easeInOut)
            .scaleXY(end: 1.1, duration: 650.ms),
        const SizedBox(height: 4),
        const Text(
          'たんじょう！',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFD700),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .shimmer(duration: 1000.ms, color: Colors.white),
      ],
    );
  }
}

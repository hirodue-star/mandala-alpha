import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/mandala_state.dart';
import '../l10n/strings.dart';

// ─────────────────────────────────────────────────────────
// PuppyCharacter — 「プピィ」パステルピンク・ちびうさぎ
//
// サンリオ風: 丸フォルム、キラキラ目、耳にリボン
// タップで「ぷるん」と跳ねる
// ─────────────────────────────────────────────────────────

class PuppyCharacter extends StatelessWidget {
  final int stage;
  final ResonancePhase phase;
  final int squashTrigger;

  const PuppyCharacter({
    super.key, required this.stage, required this.phase, this.squashTrigger = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (phase == ResonancePhase.hatched) return const _Born(emoji: '🐰');
    if (phase == ResonancePhase.hatching) return const _Hatching(emoji: '🐰', color: Color(0xFFFFB3DE));
    return _ChibiBody(stage: stage, squashTrigger: squashTrigger);
  }
}

class _ChibiBody extends StatefulWidget {
  final int stage;
  final int squashTrigger;
  const _ChibiBody({required this.stage, required this.squashTrigger});
  @override
  State<_ChibiBody> createState() => _ChibiBodyState();
}

class _ChibiBodyState extends State<_ChibiBody> with TickerProviderStateMixin {
  late final AnimationController _sqCtrl;
  late final Animation<double> _sx, _sy;
  bool _isBlinking = false;

  @override
  void initState() {
    super.initState();
    _sqCtrl = AnimationController(vsync: this, duration: 450.ms);
    // ぷるんバウンス
    _sx = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.75), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.75, end: 1.1), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0)
          .chain(CurveTween(curve: Curves.elasticOut)), weight: 45),
    ]).animate(_sqCtrl);
    _sy = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.7), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 1.3), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.92), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.0)
          .chain(CurveTween(curve: Curves.elasticOut)), weight: 45),
    ]).animate(_sqCtrl);
    _startBlinkLoop();
  }

  void _startBlinkLoop() async {
    while (mounted) {
      await Future.delayed(Duration(milliseconds: 3000 + math.Random().nextInt(2500)));
      if (!mounted) return;
      setState(() => _isBlinking = true);
      await Future.delayed(200.ms);
      if (!mounted) return;
      setState(() => _isBlinking = false);
    }
  }

  @override
  void didUpdateWidget(_ChibiBody old) {
    super.didUpdateWidget(old);
    if (old.squashTrigger != widget.squashTrigger && widget.squashTrigger > 0) {
      _sqCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() { _sqCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    Widget body = AnimatedBuilder(
      animation: _sqCtrl,
      builder: (_, child) => Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.diagonal3Values(_sx.value, _sy.value, 1),
        child: child,
      ),
      child: SizedBox(
        width: 85, height: 98,
        child: CustomPaint(painter: _PuppyPainter(isBlinking: _isBlinking)),
      ),
    );
    // 呼吸アニメ
    body = body.animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(end: 1.04, duration: 2400.ms, curve: Curves.easeInOut);
    return body;
  }
}

// ── プピィペインター（パステルピンク・ちびうさぎ） ──────

class _PuppyPainter extends CustomPainter {
  final bool isBlinking;
  _PuppyPainter({required this.isBlinking});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // ── 耳 ──
    _drawEar(canvas, cx - 16, 8, -0.1, size);  // 左耳
    _drawEar(canvas, cx + 16, 8, 0.15, size);  // 右耳

    // ── リボン（右耳の根元） ──
    final ribbonP = Paint()..color = const Color(0xFFFF4081);
    // 左羽
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 8, 28), width: 14, height: 10), ribbonP);
    // 右羽
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 24, 28), width: 14, height: 10), ribbonP);
    // 中心結び目
    canvas.drawCircle(Offset(cx + 16, 28), 4,
        Paint()..color = const Color(0xFFE91E63));

    // ── 体（まんまる） ──
    final bodyY = size.height * 0.58;
    final bodyR = size.width * 0.40;
    final bodyRect = Rect.fromCircle(center: Offset(cx, bodyY), radius: bodyR);

    // 接地シャドウ
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, size.height - 2), width: bodyR * 1.2, height: 8),
      Paint()..color = const Color(0xFFDDA0C0).withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));

    // 外側グロー
    canvas.drawCircle(Offset(cx, bodyY), bodyR + 4,
      Paint()..color = const Color(0xFFFFD6E8).withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // ボディ塗り（パステルピンク → 白グラデ）
    canvas.drawCircle(Offset(cx, bodyY), bodyR, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.35), radius: 0.9,
        colors: [const Color(0xFFFFEEF3), const Color(0xFFFFD6E8)],
      ).createShader(bodyRect));

    // つやつやハイライト
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 8, bodyY - bodyR * 0.5), width: 20, height: 11),
      Paint()..color = Colors.white.withOpacity(0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 8, bodyY - bodyR * 0.35), width: 8, height: 5),
      Paint()..color = Colors.white.withOpacity(0.6));

    // おなか（白）
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, bodyY + 4), width: bodyR * 0.9, height: bodyR * 0.7),
      Paint()..color = Colors.white.withOpacity(0.5));

    // ── 顔 ──
    final faceY = bodyY - 4;

    if (isBlinking) {
      final bP = Paint()..color = const Color(0xFF6A4A5A)
        ..style = PaintingStyle.stroke..strokeWidth = 2.2..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCenter(center: Offset(cx - 10, faceY), width: 11, height: 6),
          0, math.pi, false, bP);
      canvas.drawArc(Rect.fromCenter(center: Offset(cx + 10, faceY), width: 11, height: 6),
          0, math.pi, false, bP);
    } else {
      // キラキラ大きな目
      final eyeP = Paint()..color = const Color(0xFF2A1A2A);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx - 10, faceY), width: 11, height: 13), eyeP);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + 10, faceY), width: 11, height: 13), eyeP);
      // ハイライト（大小2つずつ — キラキラ感）
      final hlP = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(cx - 8, faceY - 3), 3.5, hlP);
      canvas.drawCircle(Offset(cx + 12, faceY - 3), 3.5, hlP);
      canvas.drawCircle(Offset(cx - 12, faceY + 2), 1.3, hlP);
      canvas.drawCircle(Offset(cx + 8, faceY + 2), 1.3, hlP);
    }

    // 鼻（ちいさなピンク丸）
    canvas.drawCircle(Offset(cx, faceY + 9), 2.5,
        Paint()..color = const Color(0xFFFF8FAE));

    // 口（ω型）
    final mP = Paint()..color = const Color(0xFF8A6A7A)..style = PaintingStyle.stroke
      ..strokeWidth = 1.3..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCenter(center: Offset(cx - 3, faceY + 13), width: 7, height: 5),
        0, math.pi, false, mP);
    canvas.drawArc(Rect.fromCenter(center: Offset(cx + 3, faceY + 13), width: 7, height: 5),
        0, math.pi, false, mP);

    // チーク
    canvas.drawCircle(Offset(cx - 18, faceY + 7), 5.5,
        Paint()..color = const Color(0xFFFF8FAE).withOpacity(0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawCircle(Offset(cx + 18, faceY + 7), 5.5,
        Paint()..color = const Color(0xFFFF8FAE).withOpacity(0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
  }

  void _drawEar(Canvas canvas, double x, double y, double tilt, Size size) {
    canvas.save();
    canvas.translate(x, y + 18);
    canvas.rotate(tilt);
    canvas.translate(-x, -(y + 18));

    // 外側（ピンク）
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y + 2), width: 16, height: 38),
        const Radius.circular(8)),
      Paint()..color = const Color(0xFFFFD6E8));
    // 内側（濃いピンク）
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y + 4), width: 8, height: 24),
        const Radius.circular(4)),
      Paint()..color = const Color(0xFFFFB3DE).withOpacity(0.6));

    canvas.restore();
  }

  @override
  bool shouldRepaint(_PuppyPainter old) => old.isBlinking != isBlinking;
}

// ── 共通: 孵化・誕生 ─────────────────────────────────────

class _Hatching extends StatelessWidget {
  final String emoji;
  final Color color;
  const _Hatching({required this.emoji, required this.color});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130, height: 130,
      child: Stack(alignment: Alignment.center, children: [
        for (int i = 0; i < 3; i++)
          Container(
            width: 55.0 + i * 28, height: 65.0 + i * 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: [
                color, const Color(0xFFFFF176), color.withOpacity(0.5), color,
              ])),
          ).animate(onPlay: (c) => c.repeat())
            .scaleXY(begin: 0.5, end: 1.9, duration: Duration(milliseconds: 650 + i * 160))
            .fadeOut(duration: Duration(milliseconds: 650 + i * 160)),
        Text(emoji, style: const TextStyle(fontSize: 56))
            .animate()
            .scaleXY(begin: 0.05, end: 1.0, duration: 700.ms, curve: Curves.elasticOut)
            .fadeIn(duration: 350.ms),
      ]),
    );
  }
}

class _Born extends StatelessWidget {
  final String emoji;
  const _Born({required this.emoji});
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 58))
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -8, duration: 680.ms).scaleXY(end: 1.1, duration: 680.ms),
      const SizedBox(height: 4),
      Text(AppStrings.current.puppyBornLabel,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFE91E63)))
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(duration: 900.ms, color: Colors.white),
    ]);
  }
}

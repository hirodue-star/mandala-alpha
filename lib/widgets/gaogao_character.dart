import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/mandala_state.dart';

// ─────────────────────────────────────────────────────────
// GaogaoCharacter — 「ガオガオ」スカイブルー・ちび恐竜
//
// デフォルメ: 丸フォルム、探検家の黄色い帽子
// タップで「がおー」吹き出し
// ─────────────────────────────────────────────────────────

class GaogaoCharacter extends StatelessWidget {
  final int stage;
  final ResonancePhase phase;
  final int squashTrigger;

  const GaogaoCharacter({
    super.key, required this.stage, required this.phase, this.squashTrigger = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (phase == ResonancePhase.hatched) return const _GaoBorn();
    if (phase == ResonancePhase.hatching) return const _GaoHatching();
    return _GaoBody(stage: stage, squashTrigger: squashTrigger);
  }
}

class _GaoBody extends StatefulWidget {
  final int stage;
  final int squashTrigger;
  const _GaoBody({required this.stage, required this.squashTrigger});
  @override
  State<_GaoBody> createState() => _GaoBodyState();
}

class _GaoBodyState extends State<_GaoBody> with TickerProviderStateMixin {
  late final AnimationController _sqCtrl;
  late final Animation<double> _sx, _sy;
  bool _isBlinking = false;
  bool _showGao = false;

  @override
  void initState() {
    super.initState();
    _sqCtrl = AnimationController(vsync: this, duration: 450.ms);
    _sx = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.78), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.78, end: 1.08), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0)
          .chain(CurveTween(curve: Curves.elasticOut)), weight: 45),
    ]).animate(_sqCtrl);
    _sy = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.72), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.72, end: 1.28), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.28, end: 0.94), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.94, end: 1.0)
          .chain(CurveTween(curve: Curves.elasticOut)), weight: 45),
    ]).animate(_sqCtrl);
    _startBlinkLoop();
  }

  void _startBlinkLoop() async {
    while (mounted) {
      await Future.delayed(Duration(milliseconds: 2500 + math.Random().nextInt(2000)));
      if (!mounted) return;
      setState(() => _isBlinking = true);
      await Future.delayed(180.ms);
      if (!mounted) return;
      setState(() => _isBlinking = false);
    }
  }

  @override
  void didUpdateWidget(_GaoBody old) {
    super.didUpdateWidget(old);
    if (old.squashTrigger != widget.squashTrigger && widget.squashTrigger > 0) {
      _sqCtrl.forward(from: 0);
      // 「がおー」吹き出し
      setState(() => _showGao = true);
      Future.delayed(1200.ms, () {
        if (mounted) setState(() => _showGao = false);
      });
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
        child: CustomPaint(painter: _GaoPainter(isBlinking: _isBlinking)),
      ),
    );

    body = body.animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(end: 1.04, duration: 2000.ms, curve: Curves.easeInOut);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        body,
        // 「がおー」吹き出し
        if (_showGao)
          Positioned(
            top: -8, right: -10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
              ),
              child: const Text('がおー♪', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50))),
            ).animate().scaleXY(begin: 0, end: 1, duration: 300.ms, curve: Curves.elasticOut)
                .then(delay: 600.ms).fadeOut(duration: 300.ms),
          ),
      ],
    );
  }
}

// ── ガオガオペインター（スカイブルー・ちび恐竜） ────────

class _GaoPainter extends CustomPainter {
  final bool isBlinking;
  _GaoPainter({required this.isBlinking});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // ── 黄色い探検帽子 ──
    final hatP = Paint()..color = const Color(0xFFFFD54F);
    // つば
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, 22), width: 42, height: 10),
        const Radius.circular(5)),
      hatP);
    // 本体
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, 14), width: 30, height: 18),
        const Radius.circular(8)),
      hatP);
    // リボン
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, 20), width: 32, height: 5),
        const Radius.circular(2)),
      Paint()..color = const Color(0xFFFF8A65));

    // ── 背中のトゲ（丸い三角） ──
    final spikeP = Paint()..color = const Color(0xFF81D4FA);
    for (int i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx - 6 + i * 8, 26.0 + i * 3), width: 9, height: 12),
          const Radius.circular(4.5)),
        spikeP);
    }

    // ── しっぽ ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.72, size.height * 0.55, 16, 10),
        const Radius.circular(6)),
      Paint()..color = const Color(0xFF81D4FA));

    // ── 体（まんまるスカイブルー） ──
    final bodyY = size.height * 0.58;
    final bodyR = size.width * 0.40;
    final bodyRect = Rect.fromCircle(center: Offset(cx, bodyY), radius: bodyR);

    // 接地シャドウ
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, size.height - 2), width: bodyR * 1.2, height: 8),
      Paint()..color = const Color(0xFF5A8A9A).withOpacity(0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));

    // 外側グロー
    canvas.drawCircle(Offset(cx, bodyY), bodyR + 4,
      Paint()..color = const Color(0xFFB3E5FC).withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // ボディ（スカイブルーグラデ）
    canvas.drawCircle(Offset(cx, bodyY), bodyR, Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.35), radius: 0.9,
        colors: [const Color(0xFFE1F5FE), const Color(0xFF81D4FA)],
      ).createShader(bodyRect));

    // ハイライト
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 8, bodyY - bodyR * 0.5), width: 20, height: 11),
      Paint()..color = Colors.white.withOpacity(0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 8, bodyY - bodyR * 0.35), width: 8, height: 5),
      Paint()..color = Colors.white.withOpacity(0.6));

    // おなか（クリーム色）
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, bodyY + 4), width: bodyR * 0.85, height: bodyR * 0.65),
      Paint()..color = const Color(0xFFFFF8E1).withOpacity(0.6));

    // ── 顔 ──
    final faceY = bodyY - 4;

    if (isBlinking) {
      final bP = Paint()..color = const Color(0xFF2E7D32)
        ..style = PaintingStyle.stroke..strokeWidth = 2.5..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx - 14, faceY), Offset(cx - 6, faceY), bP);
      canvas.drawLine(Offset(cx + 6, faceY), Offset(cx + 14, faceY), bP);
    } else {
      // 大きなキラキラ目
      final eyeP = Paint()..color = const Color(0xFF1B5E20);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx - 10, faceY), width: 11, height: 13), eyeP);
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + 10, faceY), width: 11, height: 13), eyeP);
      final hlP = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(cx - 8, faceY - 3), 3.5, hlP);
      canvas.drawCircle(Offset(cx + 12, faceY - 3), 3.5, hlP);
      canvas.drawCircle(Offset(cx - 12, faceY + 2), 1.3, hlP);
      canvas.drawCircle(Offset(cx + 8, faceY + 2), 1.3, hlP);
    }

    // 口（にかっ＋歯）
    final mP = Paint()..color = const Color(0xFF2E7D32)..style = PaintingStyle.stroke
      ..strokeWidth = 1.8..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCenter(center: Offset(cx, faceY + 13), width: 18, height: 8),
        0.1, math.pi - 0.2, false, mP);
    // かわいい歯
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 3, faceY + 14), width: 3, height: 3),
      const Radius.circular(1)), Paint()..color = Colors.white);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + 3, faceY + 14), width: 3, height: 3),
      const Radius.circular(1)), Paint()..color = Colors.white);

    // チーク（オレンジ系）
    canvas.drawCircle(Offset(cx - 18, faceY + 7), 5.5,
        Paint()..color = const Color(0xFFFFCC80).withOpacity(0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawCircle(Offset(cx + 18, faceY + 7), 5.5,
        Paint()..color = const Color(0xFFFFCC80).withOpacity(0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
  }

  @override
  bool shouldRepaint(_GaoPainter old) => old.isBlinking != isBlinking;
}

// ── 孵化・誕生 ───────────────────────────────────────────

class _GaoHatching extends StatelessWidget {
  const _GaoHatching();
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 130, height: 130,
      child: Stack(alignment: Alignment.center, children: [
        for (int i = 0; i < 3; i++)
          Container(width: 55.0 + i * 28, height: 65.0 + i * 28,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: SweepGradient(colors: [
                const Color(0xFF81D4FA), const Color(0xFFFFCC80),
                const Color(0xFF81C784), const Color(0xFF81D4FA)])),
          ).animate(onPlay: (c) => c.repeat())
            .scaleXY(begin: 0.5, end: 1.9, duration: Duration(milliseconds: 650 + i * 160))
            .fadeOut(duration: Duration(milliseconds: 650 + i * 160)),
        const Text('🦕', style: TextStyle(fontSize: 56))
            .animate().scaleXY(begin: 0.05, end: 1.0, duration: 700.ms, curve: Curves.elasticOut)
            .fadeIn(duration: 350.ms),
      ]));
  }
}

class _GaoBorn extends StatelessWidget {
  const _GaoBorn();
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('🦕', style: TextStyle(fontSize: 58))
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: 0, end: -8, duration: 680.ms).scaleXY(end: 1.1, duration: 680.ms),
      const SizedBox(height: 4),
      const Text('ガオガオ たんじょう！',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)))
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(duration: 900.ms, color: Colors.white),
    ]);
  }
}

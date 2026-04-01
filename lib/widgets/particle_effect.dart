import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ─────────────────────────────────────────────────────────
// ParticleEffect — キラキラ飛ぶパーティクル演出
//
// 使い方:
//   Stack の上位に ParticleOverlay を配置し、
//   trigger が変化するたびに爆発エフェクトを再生する。
// ─────────────────────────────────────────────────────────

class ParticleOverlay extends StatefulWidget {
  final int trigger;          // インクリメントで起動
  final Offset origin;        // 爆発の中心（画面座標）
  final Widget child;

  const ParticleOverlay({
    super.key,
    required this.trigger,
    required this.origin,
    required this.child,
  });

  @override
  State<ParticleOverlay> createState() => _ParticleOverlayState();
}

class _ParticleOverlayState extends State<ParticleOverlay> {
  final List<_Particle> _particles = [];
  int _lastTrigger = 0;

  @override
  void didUpdateWidget(ParticleOverlay old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && widget.trigger > 0) {
      _spawnParticles();
    }
  }

  void _spawnParticles() {
    final rng = math.Random();
    final burst = List.generate(16, (i) => _Particle(
      id: '${widget.trigger}_$i',
      origin: widget.origin,
      angle: i * (math.pi * 2 / 16) + rng.nextDouble() * 0.3,
      speed: 80 + rng.nextDouble() * 80,
      color: _kColors[rng.nextInt(_kColors.length)],
      size: 6 + rng.nextDouble() * 10,
      shape: _ParticleShape.values[rng.nextInt(_ParticleShape.values.length)],
    ));

    setState(() {
      _particles.addAll(burst);
      _lastTrigger = widget.trigger;
    });

    // 1秒後に掃除
    Future.delayed(1100.ms, () {
      if (mounted) setState(() => _particles.removeWhere((p) => p.id.startsWith('${widget.trigger}_')));
    });
  }

  static const _kColors = [
    Color(0xFF7FDBFF), Color(0xFFFFB3DE), Color(0xFFFFF176),
    Color(0xFFB9F6CA), Color(0xFFFFD700), Color(0xFFFF5252),
    Color(0xFF69F0AE), Color(0xFF18FFFF),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_particles.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: _particles.map((p) => _ParticleWidget(p: p)).toList(),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── データ ────────────────────────────────────────────────

enum _ParticleShape { star, circle, diamond }

class _Particle {
  final String id;
  final Offset origin;
  final double angle;
  final double speed;
  final Color color;
  final double size;
  final _ParticleShape shape;
  const _Particle({
    required this.id, required this.origin, required this.angle,
    required this.speed, required this.color, required this.size,
    required this.shape,
  });

  Offset get destination => origin + Offset(
    math.cos(angle) * speed,
    math.sin(angle) * speed,
  );
}

// ─── パーティクルWidget ────────────────────────────────────

class _ParticleWidget extends StatelessWidget {
  final _Particle p;
  const _ParticleWidget({required this.p});

  @override
  Widget build(BuildContext context) {
    final Widget shape = switch (p.shape) {
      _ParticleShape.star    => Text('✦', style: TextStyle(fontSize: p.size, color: p.color)),
      _ParticleShape.circle  => Container(
          width: p.size, height: p.size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: p.color),
        ),
      _ParticleShape.diamond => Transform.rotate(
          angle: math.pi / 4,
          child: Container(width: p.size * 0.8, height: p.size * 0.8, color: p.color),
        ),
    };

    return Positioned(
      left: p.origin.dx,
      top: p.origin.dy,
      child: shape
          .animate()
          .move(
            begin: Offset.zero,
            end: p.destination - p.origin,
            duration: 900.ms,
            curve: Curves.easeOut,
          )
          .scaleXY(begin: 1.0, end: 0.0, duration: 900.ms, curve: Curves.easeIn)
          .fadeOut(delay: 400.ms, duration: 500.ms),
    );
  }
}

// ─── シンプルなセルバースト（位置不要版） ─────────────────

/// セル上に直接重ねる小さなバーストエフェクト
class CellBurstEffect extends StatelessWidget {
  final int trigger;
  const CellBurstEffect({super.key, required this.trigger});

  @override
  Widget build(BuildContext context) {
    if (trigger == 0) return const SizedBox.shrink();
    final rng = math.Random(trigger);

    return IgnorePointer(
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(10, (i) {
          final angle = i * math.pi * 2 / 10 + rng.nextDouble() * 0.4;
          final dist = 25.0 + rng.nextDouble() * 25;
          final colors = [
            const Color(0xFF7FDBFF), const Color(0xFFFFB3DE),
            const Color(0xFFFFF176), const Color(0xFFFFD700),
          ];
          return Text(
            i % 3 == 0 ? '✦' : i % 3 == 1 ? '★' : '•',
            style: TextStyle(
              fontSize: 8 + rng.nextDouble() * 8,
              color: colors[i % colors.length],
            ),
          )
              .animate()
              .move(
                begin: Offset.zero,
                end: Offset(math.cos(angle) * dist, math.sin(angle) * dist),
                duration: 700.ms,
                curve: Curves.easeOut,
              )
              .fadeOut(delay: 300.ms, duration: 400.ms);
        }),
      ),
    );
  }
}

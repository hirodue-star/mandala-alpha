import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/chart_cell.dart';
import '../services/whisper_service.dart';

class InputScreen extends StatefulWidget {
  final ChartCell cell;
  final String whisperApiKey;
  final void Function(String text) onDone;

  const InputScreen({
    super.key,
    required this.cell,
    required this.whisperApiKey,
    required this.onDone,
  });

  @override
  State<InputScreen> createState() => _InputScreenState();
}

enum _Phase { idle, recording, transcribing, done }

class _InputScreenState extends State<InputScreen>
    with TickerProviderStateMixin {
  final _recorder = AudioRecorder();
  _Phase _phase = _Phase.idle;
  String _transcribedText = '';
  String? _recordPath;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      _showPermissionError();
      return;
    }

    final dir = await getTemporaryDirectory();
    _recordPath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _recordPath!,
    );

    setState(() => _phase = _Phase.recording);
    _pulseController.repeat(reverse: true);
  }

  Future<void> _stopRecording() async {
    await _recorder.stop();
    _pulseController.stop();
    setState(() => _phase = _Phase.transcribing);
    await _transcribe();
  }

  Future<void> _transcribe() async {
    try {
      final service = WhisperService(apiKey: widget.whisperApiKey);
      final text = await service.transcribe(_recordPath!);
      setState(() {
        _transcribedText = text;
        _phase = _Phase.done;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _phase = _Phase.idle);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('変換エラー: $e')),
        );
      }
    }
  }

  void _onMicTap() {
    if (_phase == _Phase.idle) {
      _startRecording();
    } else if (_phase == _Phase.recording) {
      _stopRecording();
    }
  }

  void _confirm() {
    widget.onDone(_transcribedText);
    Navigator.pop(context);
  }

  void _retry() {
    setState(() {
      _phase = _Phase.idle;
      _transcribedText = '';
    });
  }

  void _showPermissionError() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('マイクの許可が必要です'),
        content: const Text('設定からマイクへのアクセスを許可してください。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('設定を開く'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF4A4A6A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // カテゴリヘッダー
              Text(widget.cell.icon,
                  style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              Text(
                widget.cell.category,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A4A6A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _phaseLabel,
                style: TextStyle(fontSize: 15, color: Colors.grey[500]),
              ),
              const SizedBox(height: 48),

              // メインコンテンツ
              if (_phase != _Phase.done) ...[
                _MicButton(
                  phase: _phase,
                  pulseController: _pulseController,
                  onTap: _onMicTap,
                ),
              ] else ...[
                _DoneView(
                  text: _transcribedText,
                  onConfirm: _confirm,
                  onRetry: _retry,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String get _phaseLabel {
    switch (_phase) {
      case _Phase.idle:
        return 'マイクをタップして話してね';
      case _Phase.recording:
        return '録音中… もう一度タップして止める';
      case _Phase.transcribing:
        return 'もじにしてるよ…';
      case _Phase.done:
        return 'こんなこと言ったね！';
    }
  }
}

// ---- マイクボタン ----

class _MicButton extends StatelessWidget {
  final _Phase phase;
  final AnimationController pulseController;
  final VoidCallback onTap;

  const _MicButton({
    required this.phase,
    required this.pulseController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRecording = phase == _Phase.recording;
    final isTranscribing = phase == _Phase.transcribing;

    return GestureDetector(
      onTap: isTranscribing ? null : onTap,
      child: AnimatedBuilder(
        animation: pulseController,
        builder: (context, child) {
          final scale = isRecording
              ? 1.0 + pulseController.value * 0.1
              : 1.0;
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 外側のリング（録音中）
            if (isRecording)
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF5252).withOpacity(0.15),
                ),
              ).animate(onPlay: (c) => c.repeat()).scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.3, 1.3),
                    duration: 800.ms,
                    curve: Curves.easeOut,
                  ).fadeOut(duration: 800.ms),
            // メインボタン
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isRecording
                    ? const Color(0xFFFF5252)
                    : isTranscribing
                        ? Colors.grey[300]
                        : const Color(0xFF7C4DFF),
                boxShadow: [
                  BoxShadow(
                    color: (isRecording
                            ? const Color(0xFFFF5252)
                            : const Color(0xFF7C4DFF))
                        .withOpacity(0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  )
                ],
              ),
              child: isTranscribing
                  ? const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 3)
                  : Icon(
                      isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- 完了ビュー ----

class _DoneView extends StatelessWidget {
  final String text;
  final VoidCallback onConfirm;
  final VoidCallback onRetry;

  const _DoneView({
    required this.text,
    required this.onConfirm,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 星アニメーション
        const _StarBurst(),
        const SizedBox(height: 24),
        // テキストバブル
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Text(
            text.isEmpty ? '（聞き取れなかったよ）' : text,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF4A4A6A),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.2, end: 0),
        const SizedBox(height: 32),
        // できた！ボタン
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C4DFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),
            onPressed: onConfirm,
            child: const Text('できた！ 🎉'),
          ),
        )
            .animate()
            .fadeIn(delay: 300.ms, duration: 400.ms)
            .slideY(begin: 0.3, end: 0),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onRetry,
          child: const Text('もう一度録音する',
              style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}

// ---- 星が飛ぶアニメーション ----

class _StarBurst extends StatelessWidget {
  const _StarBurst();

  @override
  Widget build(BuildContext context) {
    final rng = Random(42);
    return SizedBox(
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text('できた！',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7C4DFF),
              )).animate().scale(
                begin: const Offset(0.5, 0.5),
                duration: 400.ms,
                curve: Curves.elasticOut,
              ),
          ...List.generate(12, (i) {
            final angle = i * 30.0 * pi / 180;
            final dx = cos(angle) * (40 + rng.nextDouble() * 30);
            final dy = sin(angle) * (40 + rng.nextDouble() * 30);
            return Positioned(
              left: 50 + dx,
              top: 50 - dy,
              child: Text(
                ['⭐', '✨', '🌟'][i % 3],
                style: const TextStyle(fontSize: 16),
              )
                  .animate()
                  .fadeIn(delay: (i * 50).ms, duration: 300.ms)
                  .move(
                    begin: Offset.zero,
                    end: Offset(dx * 0.3, -dy * 0.3),
                    duration: 600.ms,
                    curve: Curves.easeOut,
                  ),
            );
          }),
        ],
      ),
    );
  }
}

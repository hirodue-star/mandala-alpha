import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_analysis_service.dart';
import '../services/template_question_service.dart';
import '../providers/storage_counter_provider.dart';
import '../providers/character_providers.dart';

// ─────────────────────────────────────────────────────────
// ImageMandalaScreen — 画像付きマンダラ（カメラ撮影→解析→設問）
// ─────────────────────────────────────────────────────────

class ImageMandalaScreen extends ConsumerStatefulWidget {
  const ImageMandalaScreen({super.key});

  @override
  ConsumerState<ImageMandalaScreen> createState() => _ImageMandalaScreenState();
}

class _ImageMandalaScreenState extends ConsumerState<ImageMandalaScreen> {
  File? _image;
  ImageTag? _tag;
  List<TemplateQuestion>? _questions;
  bool _analyzing = false;
  final Map<int, String> _answers = {};

  Future<void> _pickImage(ImageSource source) async {
    final quota = ref.read(storageCounterProvider);
    if (quota.isOverQuota) {
      _showQuotaDialog();
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _analyzing = true);

    // 圧縮
    final original = File(picked.path);
    final (compressed, origKb, compKb) = await ImageAnalysisService.compressAndSave(original);

    // 解析
    final tag = await ImageAnalysisService.analyze(compressed);
    final questions = TemplateQuestionService.fromTag(tag);

    // ストレージカウント
    await ref.read(storageCounterProvider.notifier).recordSave(compKb);

    setState(() {
      _image = compressed;
      _tag = tag;
      _questions = questions;
      _analyzing = false;
    });
  }

  void _showQuotaDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFFFFF8EE),
        title: const Row(children: [
          Text('🔒', style: TextStyle(fontSize: 24)),
          SizedBox(width: 8),
          Text('ほぞん いっぱい', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        content: const Text(
          'むりょうで ほぞんできる かずが いっぱいです。\nプレミアムに アップグレードすると もっと ほぞんできるよ！',
          style: TextStyle(fontSize: 13, color: Color(0xFF5A4A3A)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('とじる'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 課金フロー
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFB74D)),
            child: const Text('プレミアム', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final charDef = ref.watch(characterProvider).def;
    final quota = ref.watch(storageCounterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8E7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF5A4A3A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          const Text('📷 がぞう マンダラ',
              style: TextStyle(color: Color(0xFF5A4A3A), fontSize: 16, fontWeight: FontWeight.bold)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: quota.isOverQuota ? const Color(0xFFFFCDD2) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${quota.remaining}/${quota.maxFreeCount}',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                  color: quota.isOverQuota ? Colors.red : Colors.green),
            ),
          ),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 撮影エリア
            if (_image == null) ...[
              const SizedBox(height: 20),
              Text(charDef.emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text('しゃしんを とって マンダラを つくろう！',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF5A4A3A)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CaptureButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'カメラ',
                    color: const Color(0xFFFFB74D),
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                  const SizedBox(width: 20),
                  _CaptureButton(
                    icon: Icons.photo_library_rounded,
                    label: 'アルバム',
                    color: const Color(0xFF64B5F6),
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),
            ] else ...[
              // 画像 + タグ表示
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(_image!, height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),
              if (_analyzing)
                const Center(child: CircularProgressIndicator(color: Color(0xFFFFB74D)))
              else if (_tag != null) ...[
                // タグバッジ
                Wrap(
                  spacing: 8, runSpacing: 6,
                  children: [
                    _TagBadge(emoji: _tag!.colorEmoji, label: _tag!.dominantColor),
                    _TagBadge(emoji: '🔷', label: _tag!.estimatedShape),
                    _TagBadge(emoji: _tag!.brightness == 'あかるい' ? '☀️' : _tag!.brightness == 'くらい' ? '🌙' : '🌤️',
                        label: _tag!.brightness),
                    _TagBadge(emoji: '📦', label: '${_tag!.compressedSizeKb}KB'),
                  ],
                ),
                const SizedBox(height: 16),

                // テンプレート設問
                if (_questions != null)
                  ..._questions!.asMap().entries.map((e) {
                    final i = e.key;
                    final q = e.value;
                    final answered = _answers.containsKey(i);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: answered ? const Color(0xFFE8F5E9) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: answered ? const Color(0xFF81C784) : const Color(0xFFE0D5C0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(q.emoji, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(q.question,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                                    color: Color(0xFF5A4A3A)))),
                            if (answered)
                              const Text('✅', style: TextStyle(fontSize: 16)),
                          ]),
                          if (q.choices.isNotEmpty && !answered) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6, runSpacing: 6,
                              children: q.choices.map((c) => GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _answers[i] = c);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0E0),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFFFCC80)),
                                  ),
                                  child: Text(c, style: const TextStyle(fontSize: 12, color: Color(0xFF5A4A3A))),
                                ),
                              )).toList(),
                            ),
                          ],
                          if (answered)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('→ ${_answers[i]}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF4CAF50),
                                      fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ).animate()
                        .fadeIn(delay: Duration(milliseconds: i * 100), duration: 300.ms);
                  }),

                // リセット
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _image = null; _tag = null; _questions = null; _answers.clear();
                  }),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('べつの しゃしん', style: TextStyle(fontSize: 12)),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _CaptureButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _TagBadge extends StatelessWidget {
  final String emoji;
  final String label;
  const _TagBadge({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFCC80)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF5A4A3A))),
      ]),
    );
  }
}

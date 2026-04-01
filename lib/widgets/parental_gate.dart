import 'package:flutter/material.dart';
import 'dart:math';

/// ペアレンタルゲート：ランダムな掛け算を出題
class ParentalGate {
  static Future<bool> show(BuildContext context) async {
    final rng = Random();
    final a = rng.nextInt(9) + 2; // 2〜10
    final b = rng.nextInt(9) + 2;
    final answer = a * b;

    final controller = TextEditingController();
    bool? result;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        String? errorText;
        return StatefulBuilder(
          builder: (ctx, setS) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              title: const Row(
                children: [
                  Text('🔒', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 8),
                  Text('保護者確認', style: TextStyle(fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('保護者の方のみ入れます。\n答えを入力してください。',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 16),
                  Text(
                    '$a × $b = ?',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C4DFF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24),
                    decoration: InputDecoration(
                      errorText: errorText,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      hintText: '答えを入力',
                    ),
                    autofocus: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    result = false;
                    Navigator.pop(ctx);
                  },
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C4DFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final input = int.tryParse(controller.text.trim());
                    if (input == answer) {
                      result = true;
                      Navigator.pop(ctx);
                    } else {
                      setS(() => errorText = 'ちがいます。もう一度。');
                      controller.clear();
                    }
                  },
                  child: const Text('確認'),
                ),
              ],
            );
          },
        );
      },
    );

    return result == true;
  }
}

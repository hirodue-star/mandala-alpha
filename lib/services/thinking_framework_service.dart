// ─────────────────────────────────────────────────────────
// ThinkingFrameworkService — ライオン級「思考力育成モード」
//
// Life Strategy Engine (Amodei 11-module framework) を
// 幼児向け8セル・マンダラに変換した構造化思考プログラム。
//
// 3レイヤー → 8セル:
//   Layer 1 ANALYSIS (外部環境): セル 0-2
//   Layer 2 REASONING (思考の質): セル 3-5
//   Layer 3 DECISION (意思決定):  セル 6-7
// ─────────────────────────────────────────────────────────

/// 各セルの思考フレーム（ライオン級専用）
class ThinkingFrame {
  final int cellIndex;
  final String layer;
  final String emoji;
  final String prompt;       // 子供に表示するガイド質問
  final String parentLabel;  // 保護者向け解説
  final String module;       // 元の Life Strategy Engine モジュール名

  const ThinkingFrame({
    required this.cellIndex,
    required this.layer,
    required this.emoji,
    required this.prompt,
    required this.parentLabel,
    required this.module,
  });
}

class ThinkingFrameworkService {
  ThinkingFrameworkService._();

  /// ゴールに応じた8セルの思考フレームを生成
  static List<ThinkingFrame> getFrames(String goal) {
    return [
      // ── Layer 1: ANALYSIS（かんさつ） ─────────────────
      ThinkingFrame(
        cellIndex: 0,
        layer: 'かんさつ',
        emoji: '🔍',
        prompt: '「$goal」って なに？ せつめいしてみよう！',
        parentLabel: '定義・分解力（M1: 構造化分析）',
        module: 'M1',
      ),
      ThinkingFrame(
        cellIndex: 1,
        layer: 'かんさつ',
        emoji: '⏰',
        prompt: '「$goal」は いつ する？ どんなとき？',
        parentLabel: '時間軸思考（M2: タイムライン）',
        module: 'M2',
      ),
      ThinkingFrame(
        cellIndex: 2,
        layer: 'かんさつ',
        emoji: '👥',
        prompt: '「$goal」は だれと する？ だれが よろこぶ？',
        parentLabel: '関係性把握（M4: ネットワーク分析）',
        module: 'M4',
      ),

      // ── Layer 2: REASONING（かんがえる） ────────────────
      ThinkingFrame(
        cellIndex: 3,
        layer: 'かんがえる',
        emoji: '💭',
        prompt: '「$goal」が すきな りゆうは？ なぜ？',
        parentLabel: '因果推論（M6: 深層思考）',
        module: 'M6',
      ),
      ThinkingFrame(
        cellIndex: 4,
        layer: 'かんがえる',
        emoji: '🛠️',
        prompt: '「$goal」を するには どうやる？',
        parentLabel: '手段分解（M6: サブ問題分解）',
        module: 'M6',
      ),
      ThinkingFrame(
        cellIndex: 5,
        layer: 'かんがえる',
        emoji: '⚡',
        prompt: '「$goal」で むずかしいところは？',
        parentLabel: '課題発見（M5: 脆弱性監査）',
        module: 'M5',
      ),

      // ── Layer 3: DECISION（きめる） ────────────────────
      ThinkingFrame(
        cellIndex: 6,
        layer: 'きめる',
        emoji: '🌟',
        prompt: '「$goal」が できたら どうなる？',
        parentLabel: '未来予測（M11: 後悔最小化）',
        module: 'M11',
      ),
      ThinkingFrame(
        cellIndex: 7,
        layer: 'きめる',
        emoji: '🚀',
        prompt: '「$goal」を もっと よくするには？',
        parentLabel: '改善思考（M3: 蓄積資産分析）',
        module: 'M3',
      ),
    ];
  }

  /// セルのレイヤーカラー
  static const layerColors = {
    'かんさつ': 0xFFFFE0B2,   // オレンジパステル
    'かんがえる': 0xFFB3E5FC,  // ブルーパステル
    'きめる': 0xFFC8E6C9,     // グリーンパステル
  };

  /// セルのレイヤーアクセントカラー
  static const layerAccents = {
    'かんさつ': 0xFFFF9800,
    'かんがえる': 0xFF03A9F4,
    'きめる': 0xFF4CAF50,
  };

  /// 保護者向け: セッションの思考力評価
  static ThinkingAssessment assess(List<String> answers) {
    int filled = answers.where((a) => a.isNotEmpty).length;
    int diverse = answers.toSet().length;
    int longAnswers = answers.where((a) => a.length >= 4).length;

    return ThinkingAssessment(
      completionRate: filled / 8.0,
      diversityRate: filled > 0 ? diverse / filled.toDouble() : 0,
      depthRate: filled > 0 ? longAnswers / filled.toDouble() : 0,
      analysisCount: answers.take(3).where((a) => a.isNotEmpty).length,
      reasoningCount: answers.skip(3).take(3).where((a) => a.isNotEmpty).length,
      decisionCount: answers.skip(6).take(2).where((a) => a.isNotEmpty).length,
    );
  }
}

/// 思考力評価結果（保護者ダッシュボード用）
class ThinkingAssessment {
  final double completionRate;    // 完了率
  final double diversityRate;     // 回答の多様性
  final double depthRate;         // 深い回答の率（4文字以上）
  final int analysisCount;        // Layer1 完了数 (max 3)
  final int reasoningCount;       // Layer2 完了数 (max 3)
  final int decisionCount;        // Layer3 完了数 (max 2)

  const ThinkingAssessment({
    required this.completionRate,
    required this.diversityRate,
    required this.depthRate,
    required this.analysisCount,
    required this.reasoningCount,
    required this.decisionCount,
  });

  /// 私立小受験レベルの思考力スコア（0-100）
  int get examReadyScore {
    // 完了率 40% + 多様性 30% + 深さ 30%
    return ((completionRate * 40 + diversityRate * 30 + depthRate * 30)).round().clamp(0, 100);
  }

  String get examReadyLabel {
    final s = examReadyScore;
    if (s >= 80) return '受験準備◎ — 構造化思考が身についています';
    if (s >= 60) return '順調 — 多角的に考える力が育っています';
    if (s >= 40) return '成長中 — 自分の言葉で表現できています';
    return 'スタート — 考える習慣を楽しく続けましょう';
  }
}

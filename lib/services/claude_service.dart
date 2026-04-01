import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chart_cell.dart';
import '../models/report.dart';

class ClaudeService {
  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-6';

  final String apiKey;

  const ClaudeService({required this.apiKey});

  /// 週次曼荼羅チャートデータからレポートを生成する
  Future<Report> generateWeeklyReport({
    required String childName,
    required int ageYears,
    required List<ChartCell> cells,
    required DateTime weekOf,
  }) async {
    final chartData = _buildChartSummary(cells);
    final prompt = '''
以下は${childName}（${ageYears}歳）の今週の曼荼羅チャート記録です。
$chartData

以下の形式でレポートを生成してください：
1. 今週のがんばりポイント（具体的に・褒める表現で）
2. 伸びている非認知能力（上位2つ）
3. 来週取り組むとよいこと（1つだけ）
4. 受験に向けた成長コメント（保護者へ）

※文体は「〜ですね」「〜しましょう」の丁寧語。
※子供を主語にした温かい表現で。
''';

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 1024,
        'system': 'あなたは私立小学校受験の専門家であり、幼児教育カウンセラーです。',
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Claude API error: ${response.statusCode} ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final summary = (json['content'] as List).first['text'] as String;
    final scores = _estimateScores(cells);

    return Report(
      id: 'r_${weekOf.millisecondsSinceEpoch}',
      weekOf: weekOf,
      summary: summary,
      scores: scores,
      achievedCount: cells.where((c) => c.status == CellStatus.done).length,
      generatedAt: DateTime.now(),
    );
  }

  String _buildChartSummary(List<ChartCell> cells) {
    final lines = cells.map((c) {
      final statusLabel = switch (c.status) {
        CellStatus.done => '達成',
        CellStatus.trying => '挑戦中',
        CellStatus.empty => '未実施',
      };
      final memo = c.voiceMemo != null ? '（${c.voiceMemo}）' : '';
      return '- ${c.category}：$statusLabel$memo';
    });
    return lines.join('\n');
  }

  /// チャート記録から非認知能力スコアを推定する
  NonCognitiveScores _estimateScores(List<ChartCell> cells) {
    double score(List<int> indices) {
      final achieved = indices
          .where((i) => cells[i].status == CellStatus.done)
          .length;
      return achieved / indices.length;
    }

    // カテゴリとスコアのマッピング（defaultCells のインデックスに対応）
    // 0=あいさつ, 1=おきがえ, 2=たいそう, 3=おてつだい,
    // 4=えほん, 5=かずあそび, 6=おえかき, 7=きもちメモ
    return NonCognitiveScores(
      selfControl: score([1]),         // おきがえ → 自律性
      communication: score([0, 7]),    // あいさつ + きもちメモ
      persistence: score([2, 3]),      // たいそう + おてつだい
      creativity: score([6, 7]),       // おえかき + きもちメモ
    );
  }
}

class NonCognitiveScores {
  final double selfControl;
  final double communication;
  final double persistence;
  final double creativity;

  const NonCognitiveScores({
    required this.selfControl,
    required this.communication,
    required this.persistence,
    required this.creativity,
  });
}

class Report {
  final String id;
  final DateTime weekOf;
  final String summary;
  final NonCognitiveScores scores;
  final int achievedCount; // 8マス中何マス達成
  final DateTime generatedAt;

  const Report({
    required this.id,
    required this.weekOf,
    required this.summary,
    required this.scores,
    required this.achievedCount,
    required this.generatedAt,
  });
}

// ダミーデータ（Firebase接続前の開発用）
final List<Report> dummyReports = [
  Report(
    id: 'r1',
    weekOf: DateTime(2026, 3, 23),
    summary:
        'たろうくんは今週、あいさつとえほんをとても頑張りましたね。特に毎朝自分からあいさつできるようになったことは、コミュニケーション力の大きな成長です。来週はたいそうにも挑戦してみましょう。受験に向けて、自律性と表現力が着実に育っています。',
    scores: const NonCognitiveScores(
      selfControl: 0.6,
      communication: 0.85,
      persistence: 0.5,
      creativity: 0.7,
    ),
    achievedCount: 5,
    generatedAt: DateTime(2026, 3, 29),
  ),
  Report(
    id: 'r2',
    weekOf: DateTime(2026, 3, 16),
    summary:
        'おてつだいとかずあそびに積極的に取り組んだ一週間でした。数を数えながらお手伝いする姿がとても微笑ましいですね。論理思考と協調性が伸びています。',
    scores: const NonCognitiveScores(
      selfControl: 0.55,
      communication: 0.65,
      persistence: 0.75,
      creativity: 0.6,
    ),
    achievedCount: 4,
    generatedAt: DateTime(2026, 3, 22),
  ),
  Report(
    id: 'r3',
    weekOf: DateTime(2026, 3, 9),
    summary:
        'おえかきで自分の気持ちを表現することがとても上手になりました。創造性と自己表現力が育っています。引き続き毎日少しずつ続けましょう。',
    scores: const NonCognitiveScores(
      selfControl: 0.5,
      communication: 0.6,
      persistence: 0.65,
      creativity: 0.9,
    ),
    achievedCount: 3,
    generatedAt: DateTime(2026, 3, 15),
  ),
];

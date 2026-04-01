// ─────────────────────────────────────────────────────────
// ActivityLog — 子供の操作ログ（分析指標の原データ）
// ─────────────────────────────────────────────────────────

class CellCompletionEvent {
  final int cellIndex;
  final DateTime completedAt;
  final String enteredLabel;      // 入力したラベル
  final bool labelCustomized;     // デフォルト("アクション①"等)から変更したか
  final Duration elapsedSinceStart; // セッション開始からの経過時間

  const CellCompletionEvent({
    required this.cellIndex,
    required this.completedAt,
    required this.enteredLabel,
    required this.labelCustomized,
    required this.elapsedSinceStart,
  });
}

/// セッション全体の記録
class SessionLog {
  final DateTime sessionStart;
  final String goal;
  final List<CellCompletionEvent> events;

  const SessionLog({
    required this.sessionStart,
    required this.goal,
    required this.events,
  });

  bool get isComplete => events.length == 8;
  Duration get totalDuration =>
      isComplete ? events.last.elapsedSinceStart : Duration.zero;
}

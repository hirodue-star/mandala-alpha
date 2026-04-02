import 'package:flutter/foundation.dart';
import 'activity_log.dart';

// ─────────────────────────────────────────────────────────
// AgeMode — 年齢別グリッドモード
// ─────────────────────────────────────────────────────────

enum AgeMode {
  age3, // ひよこ級：4マス（中心1＋周囲3）語彙「発見」
  age4, // ペンギン級：6マス（中心1＋周囲5）関連性「連結」
  age5, // ライオン級：9マス（中心1＋周囲8）論理的「分類」＋思考力育成モード
}

extension AgeModeExt on AgeMode {
  int get activeCells => switch (this) { AgeMode.age3 => 3, AgeMode.age4 => 5, AgeMode.age5 => 8 };
  String get label => switch (this) { AgeMode.age3 => 'ひよこ', AgeMode.age4 => 'ペンギン', AgeMode.age5 => 'ライオン' };
  String get emoji => switch (this) { AgeMode.age3 => '🐤', AgeMode.age4 => '🐧', AgeMode.age5 => '🦁' };
  String get centerLabel => switch (this) {
    AgeMode.age3 => 'きょうの だいすき',
    AgeMode.age4 => 'きょうの すき',
    AgeMode.age5 => 'きょうの テーマ',
  };
  String get coachingPrompt => switch (this) {
    AgeMode.age3 => 'の どんなところが すき？',
    AgeMode.age4 => 'について おしえて！',
    AgeMode.age5 => 'を じぶんで かんがえて うめてみよう！',
  };
  /// ライオン級は思考力育成モード（自由記述）
  bool get isFreeInputMode => this == AgeMode.age5;

  // gridMap: null=center(puppy), -1=empty slot, 0〜7=action cell index
  List<int?> get gridMap => switch (this) {
    AgeMode.age3 => const [-1,  0, -1,  1, null,  2, -1, -1, -1],
    AgeMode.age4 => const [-1,  0,  1,  4, null,  2, -1,  3, -1],
    AgeMode.age5 => const [ 7,  0,  1,  6, null,  2,  5,  4,  3],
  };

  List<String> get defaultLabels => switch (this) {
    AgeMode.age3 => ['', '', '', '', '', '', '', ''],
    AgeMode.age4 => ['', '', '', '', '', '', '', ''],
    AgeMode.age5 => ['', '', '', '', '', '', '', ''],
  };
}

// ─────────────────────────────────────────────────────────
// ResonancePhase
// ─────────────────────────────────────────────────────────

enum ResonancePhase { locked, activated, hatching, hatched }

// ─────────────────────────────────────────────────────────
// MandalaState
// ─────────────────────────────────────────────────────────

@immutable
class MandalaState {
  final String goal;
  final List<String> labels;
  final List<bool> completed;
  final ResonancePhase phase;
  final List<CellCompletionEvent> logs;
  final DateTime? sessionStart;
  final AgeMode ageMode;
  final int currentStage;       // 現在のステージ番号（1始まり）
  final int totalClearedStages; // 累計クリア数

  const MandalaState({
    required this.goal,
    required this.labels,
    required this.completed,
    required this.phase,
    required this.logs,
    required this.ageMode,
    this.sessionStart,
    this.currentStage = 1,
    this.totalClearedStages = 0,
  });

  factory MandalaState.initial({AgeMode mode = AgeMode.age5, int stage = 1, int cleared = 0}) =>
      MandalaState(
        goal: '',
        labels: mode.defaultLabels,
        completed: List.filled(8, false),
        phase: ResonancePhase.locked,
        logs: const [],
        ageMode: mode,
        currentStage: stage,
        totalClearedStages: cleared,
      );

  int get activeCellCount => ageMode.activeCells;
  int get doneCount => completed.take(activeCellCount).where((c) => c).length;
  bool get isAllDone => doneCount == activeCellCount;
  int get eggStage => (doneCount * 8 / activeCellCount).round().clamp(0, 8);

  // ── スコア ─────────────────────────────────────────────

  double get metacognitionScore {
    if (logs.isEmpty) return 0;
    final custom = logs.where((e) => e.labelCustomized).length;
    return custom / logs.length;
  }

  double get focusScore {
    if (logs.length < 2) return 0;
    final intervals = <Duration>[];
    for (int i = 1; i < logs.length; i++) {
      intervals.add(logs[i].elapsedSinceStart - logs[i - 1].elapsedSinceStart);
    }
    final avgMs = intervals.map((d) => d.inMilliseconds).reduce((a, b) => a + b) / intervals.length;
    return (1.0 - ((avgMs - 30000) / (300000 - 30000))).clamp(0.0, 1.0);
  }

  double get logicalThinkingScore {
    if (logs.length < 3) return 0;
    int sequential = 0;
    for (int i = 1; i < logs.length; i++) {
      final diff = (logs[i].cellIndex - logs[i - 1].cellIndex).abs();
      if (diff == 1 || diff == 7) sequential++;
    }
    return sequential / (logs.length - 1).toDouble();
  }

  MandalaState copyWith({
    String? goal,
    List<String>? labels,
    List<bool>? completed,
    ResonancePhase? phase,
    List<CellCompletionEvent>? logs,
    DateTime? sessionStart,
    AgeMode? ageMode,
    int? currentStage,
    int? totalClearedStages,
  }) {
    return MandalaState(
      goal: goal ?? this.goal,
      labels: labels ?? this.labels,
      completed: completed ?? this.completed,
      phase: phase ?? this.phase,
      logs: logs ?? this.logs,
      sessionStart: sessionStart ?? this.sessionStart,
      ageMode: ageMode ?? this.ageMode,
      currentStage: currentStage ?? this.currentStage,
      totalClearedStages: totalClearedStages ?? this.totalClearedStages,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MandalaState &&
      other.goal == goal &&
      listEquals(other.labels, labels) &&
      listEquals(other.completed, completed) &&
      other.phase == phase &&
      listEquals(other.logs, logs) &&
      other.ageMode == ageMode &&
      other.currentStage == currentStage;

  @override
  int get hashCode =>
      Object.hash(goal, Object.hashAll(labels), Object.hashAll(completed),
          phase, logs.length, ageMode, currentStage);
}

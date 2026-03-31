import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────
// MandalaState — 不変状態クラス（Riverpod StateNotifier用）
// ─────────────────────────────────────────────────────────

enum ResonancePhase {
  /// 起動直後：中央たまごのみ、周囲マスはロック
  locked,

  /// ゴール設定済み：周囲マスを操作可能
  activated,

  /// 孵化エフェクト再生中
  hatching,

  /// 孵化完了：ひよこ表示・フルオーケストラ
  hatched,
}

@immutable
class MandalaState {
  final String goal;
  final List<String> labels;
  final List<bool> completed;
  final ResonancePhase phase;

  const MandalaState({
    required this.goal,
    required this.labels,
    required this.completed,
    required this.phase,
  });

  factory MandalaState.initial() => MandalaState(
        goal: '',
        labels: const [
          'アクション①', 'アクション②', 'アクション③', 'アクション④',
          'アクション⑤', 'アクション⑥', 'アクション⑦', 'アクション⑧',
        ],
        completed: List.filled(8, false),
        phase: ResonancePhase.locked,
      );

  /// 完了数 0〜8
  int get doneCount => completed.where((c) => c).length;

  /// 全完了フラグ
  bool get isAllDone => doneCount == 8;

  /// たまごの進化ステージ 0〜8（doneCount と同値）
  int get eggStage => doneCount;

  MandalaState copyWith({
    String? goal,
    List<String>? labels,
    List<bool>? completed,
    ResonancePhase? phase,
  }) {
    return MandalaState(
      goal: goal ?? this.goal,
      labels: labels ?? this.labels,
      completed: completed ?? this.completed,
      phase: phase ?? this.phase,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MandalaState &&
      other.goal == goal &&
      listEquals(other.labels, labels) &&
      listEquals(other.completed, completed) &&
      other.phase == phase;

  @override
  int get hashCode =>
      Object.hash(goal, Object.hashAll(labels), Object.hashAll(completed), phase);
}

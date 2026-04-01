import 'package:flutter/foundation.dart';
import '../models/chart_cell.dart';

// ─────────────────────────────────────────────
// MandalaLogicService
// マンダラチャートの状態と遷移ロジックを一元管理。
// UIはこのサービスを ListenableBuilder で監視し、
// メソッド呼び出しで状態を変化させる。
// ─────────────────────────────────────────────

enum ChartPhase { locked, activated, celebrating }

class MandalaLogicService extends ChangeNotifier {
  // ── 状態 ──────────────────────────────────
  ChartPhase _phase = ChartPhase.locked;
  String _goal = '';

  final List<String> _labels;
  final List<CellStatus> _statuses;

  // ── 定数（UIに渡す） ───────────────────────

  /// 8マスのアイコン（時計回り: 上→右上→右→右下→下→左下→左→左上）
  static const List<String> icons = [
    '📝', '💡', '💪', '🎯', '🔑', '⭐', '🌟', '🏆',
  ];

  /// デフォルトラベル
  static const List<String> defaultLabels = [
    'アクション①', 'アクション②', 'アクション③', 'アクション④',
    'アクション⑤', 'アクション⑥', 'アクション⑦', 'アクション⑧',
  ];

  /// 3x3グリッドの cellIndex マッピング (null = 中央GOALセル)
  /// [左上, 上,  右上]
  /// [左,  中央, 右  ]
  /// [左下, 下,  右下]
  static const List<int?> gridMap = [7, 0, 1, 6, null, 2, 5, 4, 3];

  /// 波紋アニメーション遅延(ms) — 中央から外側へ広がる順
  /// インデックスは cellIndex (0=上, 1=右上, … 7=左上)
  static const List<int> waveDelayMs = [
    0,   // 上
    100, // 右上
    200, // 右
    300, // 右下
    200, // 下
    100, // 左下
    0,   // 左
    100, // 左上
  ];

  // ── コンストラクタ ────────────────────────

  MandalaLogicService()
      : _labels = List<String>.from(defaultLabels),
        _statuses = List<CellStatus>.filled(8, CellStatus.empty);

  // ── ゲッター ──────────────────────────────

  ChartPhase get phase => _phase;
  String get goal => _goal;
  int get doneCount => _statuses.where((s) => s == CellStatus.done).length;
  bool get isAllDone => doneCount == 8;

  String labelAt(int index) => _labels[index];
  CellStatus statusAt(int index) => _statuses[index];

  /// フェーズ別ヒントメッセージ
  String get hintMessage {
    switch (_phase) {
      case ChartPhase.locked:
        return '🎯 中央のゴールをタップしてスタート！';
      case ChartPhase.activated:
        if (doneCount == 0) return '💡 各マスをタップしてアクションを入力しよう';
        if (doneCount < 4) return '💪 いい調子！続けよう ($doneCount/8)';
        if (doneCount < 8) return '🌟 もう少し！あと ${8 - doneCount} マス';
        return '🏆 全マス完了！すごい！';
      case ChartPhase.celebrating:
        return '🎉 マンダラチャート完成！';
    }
  }

  // ── アクション ────────────────────────────

  /// ゴールを設定して locked → activated へ遷移
  void activate(String goal) {
    assert(_phase == ChartPhase.locked || _phase == ChartPhase.activated);
    _goal = goal.trim();
    if (_phase == ChartPhase.locked) {
      _phase = ChartPhase.activated;
    }
    notifyListeners();
  }

  /// ゴール文字列だけ更新（フェーズ変更なし）
  void updateGoal(String goal) {
    _goal = goal.trim();
    notifyListeners();
  }

  /// セルを完了状態にしてラベルを更新
  /// [index] 0〜7、[label] 空文字の場合は既存ラベルを維持
  void completeCell(int index, String label) {
    assert(index >= 0 && index < 8);
    if (label.isNotEmpty) _labels[index] = label;
    _statuses[index] = CellStatus.done;
    notifyListeners();
    if (isAllDone) _phase = ChartPhase.celebrating;
    notifyListeners(); // celebrating への遷移も通知
  }

  /// セルを未完了に戻す
  void resetCell(int index) {
    assert(index >= 0 && index < 8);
    _statuses[index] = CellStatus.empty;
    if (_phase == ChartPhase.celebrating) _phase = ChartPhase.activated;
    notifyListeners();
  }

  /// 祝福オーバーレイを閉じる
  void closeCelebration() {
    _phase = ChartPhase.activated;
    notifyListeners();
  }

  /// チャートをリセット（開発・デバッグ用）
  void reset() {
    _phase = ChartPhase.locked;
    _goal = '';
    for (int i = 0; i < 8; i++) {
      _labels[i] = defaultLabels[i];
      _statuses[i] = CellStatus.empty;
    }
    notifyListeners();
  }
}

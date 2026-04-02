import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mandala_state.dart';
import '../services/context_service.dart';
import 'context_providers.dart';

// ─────────────────────────────────────────────────────────
// DailyCycleProvider — 1日完結型・思考サイクル
//
// 朝(6-11) → ひよこ級  昼(11-17) → ペンギン級  夜(17-) → ライオン級
// 朝の「種」を昼・夜に引き継ぎ、1日で3段階進化する。
// ─────────────────────────────────────────────────────────

/// 1日の冒険の種（朝に選んだテーマ＆アイテム）
class DailySeed {
  final DateTime date;
  final String? morningGoal;        // 朝のテーマ
  final List<String> morningItems;  // 朝に集めたアイテム
  final String? noonGoal;           // 昼のテーマ
  final List<String> noonItems;     // 昼に集めたアイテム
  final String? nightGoal;          // 夜のテーマ
  final List<String> nightItems;    // 夜に集めたアイテム
  final bool timeLockEnabled;       // 時間ロック有効

  const DailySeed({
    required this.date,
    this.morningGoal,
    this.morningItems = const [],
    this.noonGoal,
    this.noonItems = const [],
    this.nightGoal,
    this.nightItems = const [],
    this.timeLockEnabled = false,
  });

  bool get isSameDay {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// 今の時間帯に対応する級
  static AgeMode currentPhaseMode() {
    final h = DateTime.now().hour;
    if (h < 11) return AgeMode.age3;      // 朝 → ひよこ
    if (h < 17) return AgeMode.age4;      // 昼 → ペンギン
    return AgeMode.age5;                   // 夜 → ライオン
  }

  /// 時間帯ラベル
  static String currentPhaseLabel() {
    final h = DateTime.now().hour;
    if (h < 11) return 'あさ';
    if (h < 17) return 'ひる';
    return 'よる';
  }

  /// 時間帯絵文字
  static String currentPhaseEmoji() {
    final h = DateTime.now().hour;
    if (h < 11) return '🌅';
    if (h < 17) return '☀️';
    return '🌙';
  }

  /// 級がロックされているか（時間ロック有効時）
  bool isLocked(AgeMode mode) {
    if (!timeLockEnabled) return false;
    final current = currentPhaseMode();
    return mode.index > current.index;
  }

  /// 前フェーズから引き継ぐアイテム
  List<String> get inheritedItems {
    final h = DateTime.now().hour;
    if (h < 11) return [];                              // 朝は引き継ぎなし
    if (h < 17) return morningItems;                    // 昼は朝の種を引き継ぎ
    return [...morningItems, ...noonItems];              // 夜は朝+昼を引き継ぎ
  }

  /// 前フェーズのゴール
  String? get inheritedGoal {
    final h = DateTime.now().hour;
    if (h < 11) return null;
    if (h < 17) return morningGoal;
    return noonGoal ?? morningGoal;
  }

  /// 1日の全アイテム
  List<String> get allItems => [...morningItems, ...noonItems, ...nightItems];

  /// 1日の全ゴール
  List<String> get allGoals =>
      [morningGoal, noonGoal, nightGoal].whereType<String>().toList();

  /// 装備の進化段階 (0=なし, 1=朝, 2=昼, 3=夜フル装備)
  int get equipStage {
    int s = 0;
    if (morningItems.isNotEmpty) s++;
    if (noonItems.isNotEmpty) s++;
    if (nightItems.isNotEmpty) s++;
    return s;
  }

  DailySeed copyWith({
    DateTime? date,
    String? morningGoal,
    List<String>? morningItems,
    String? noonGoal,
    List<String>? noonItems,
    String? nightGoal,
    List<String>? nightItems,
    bool? timeLockEnabled,
  }) => DailySeed(
    date: date ?? this.date,
    morningGoal: morningGoal ?? this.morningGoal,
    morningItems: morningItems ?? this.morningItems,
    noonGoal: noonGoal ?? this.noonGoal,
    noonItems: noonItems ?? this.noonItems,
    nightGoal: nightGoal ?? this.nightGoal,
    nightItems: nightItems ?? this.nightItems,
    timeLockEnabled: timeLockEnabled ?? this.timeLockEnabled,
  );
}

class DailyCycleNotifier extends StateNotifier<DailySeed> {
  DailyCycleNotifier() : super(DailySeed(date: DateTime.now()));

  /// 日付が変わったらリセット
  void ensureToday() {
    if (!state.isSameDay) {
      state = DailySeed(date: DateTime.now(), timeLockEnabled: state.timeLockEnabled);
    }
  }

  /// 時間ロックの切替
  void toggleTimeLock(bool enabled) {
    state = state.copyWith(timeLockEnabled: enabled);
  }

  /// 朝の種を保存
  void saveMorningSeed(String goal, List<String> items) {
    ensureToday();
    state = state.copyWith(morningGoal: goal, morningItems: items);
  }

  /// 昼の種を保存
  void saveNoonSeed(String goal, List<String> items) {
    ensureToday();
    state = state.copyWith(noonGoal: goal, noonItems: items);
  }

  /// 夜の種を保存
  void saveNightSeed(String goal, List<String> items) {
    ensureToday();
    state = state.copyWith(nightGoal: goal, nightItems: items);
  }

  /// セッション完了時に自動保存
  void onSessionComplete(AgeMode mode, String goal, List<String> completedLabels) {
    ensureToday();
    final items = completedLabels.where((l) => l.isNotEmpty).toList();
    switch (mode) {
      case AgeMode.age3: saveMorningSeed(goal, items);
      case AgeMode.age4: saveNoonSeed(goal, items);
      case AgeMode.age5: saveNightSeed(goal, items);
    }
  }
}

final dailyCycleProvider = StateNotifierProvider<DailyCycleNotifier, DailySeed>(
    (ref) => DailyCycleNotifier());

/// 現在の推奨フェーズ
final currentPhaseProvider = Provider<AgeMode>((ref) {
  ref.watch(dailyCycleProvider); // 日替わり検知
  return DailySeed.currentPhaseMode();
});

/// 時間帯ラベル
final phaseInfoProvider = Provider<({String label, String emoji, AgeMode mode})>((ref) {
  ref.watch(dailyCycleProvider);
  return (
    label: DailySeed.currentPhaseLabel(),
    emoji: DailySeed.currentPhaseEmoji(),
    mode: DailySeed.currentPhaseMode(),
  );
});

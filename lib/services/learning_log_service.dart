import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/mandala_state.dart';
import '../models/activity_log.dart';

/// 学習ログの永続化サービス
/// JSON形式でローカルファイルに保存
class LearningLogService {
  static const _fileName = 'learning_log.json';

  static Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// セッション完了時にログを追加保存
  static Future<void> saveSession(MandalaState state) async {
    final logs = await loadAll();
    logs.add(LearningSession(
      date: DateTime.now(),
      ageMode: state.ageMode.name,
      ageModeLabel: state.ageMode.label,
      goal: state.goal,
      completedCells: state.doneCount,
      totalCells: state.activeCellCount,
      events: state.logs,
      metacognitionScore: state.metacognitionScore,
      focusScore: state.focusScore,
      logicalThinkingScore: state.logicalThinkingScore,
      stage: state.currentStage,
      isFreeInput: state.ageMode.isFreeInputMode,
    ));
    final file = await _file;
    await file.writeAsString(jsonEncode(logs.map((l) => l.toJson()).toList()));
  }

  /// 全ログ読み込み
  static Future<List<LearningSession>> loadAll() async {
    try {
      final file = await _file;
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];
      final list = jsonDecode(content) as List;
      return list.map((e) => LearningSession.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// 直近N日分のログ
  static Future<List<LearningSession>> loadRecent({int days = 30}) async {
    final all = await loadAll();
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return all.where((s) => s.date.isAfter(cutoff)).toList();
  }

  /// 週間サマリー
  static Future<WeeklyGrowthSummary> weeklyGrowth() async {
    final recent = await loadRecent(days: 14);
    final now = DateTime.now();
    final thisWeek = recent.where((s) =>
        s.date.isAfter(now.subtract(const Duration(days: 7)))).toList();
    final lastWeek = recent.where((s) =>
        s.date.isBefore(now.subtract(const Duration(days: 7))) &&
        s.date.isAfter(now.subtract(const Duration(days: 14)))).toList();

    return WeeklyGrowthSummary(
      thisWeekSessions: thisWeek.length,
      lastWeekSessions: lastWeek.length,
      thisWeekAvgMeta: _avg(thisWeek.map((s) => s.metacognitionScore)),
      lastWeekAvgMeta: _avg(lastWeek.map((s) => s.metacognitionScore)),
      thisWeekAvgFocus: _avg(thisWeek.map((s) => s.focusScore)),
      lastWeekAvgFocus: _avg(lastWeek.map((s) => s.focusScore)),
      thisWeekAvgLogic: _avg(thisWeek.map((s) => s.logicalThinkingScore)),
      lastWeekAvgLogic: _avg(lastWeek.map((s) => s.logicalThinkingScore)),
      totalSessions: (await loadAll()).length,
      freeInputCount: thisWeek.where((s) => s.isFreeInput).length,
    );
  }

  static double _avg(Iterable<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }
}

/// 1セッション分の永続化データ
class LearningSession {
  final DateTime date;
  final String ageMode;
  final String ageModeLabel;
  final String goal;
  final int completedCells;
  final int totalCells;
  final List<CellCompletionEvent> events;
  final double metacognitionScore;
  final double focusScore;
  final double logicalThinkingScore;
  final int stage;
  final bool isFreeInput;

  const LearningSession({
    required this.date,
    required this.ageMode,
    required this.ageModeLabel,
    required this.goal,
    required this.completedCells,
    required this.totalCells,
    required this.events,
    required this.metacognitionScore,
    required this.focusScore,
    required this.logicalThinkingScore,
    required this.stage,
    required this.isFreeInput,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'ageMode': ageMode,
    'ageModeLabel': ageModeLabel,
    'goal': goal,
    'completedCells': completedCells,
    'totalCells': totalCells,
    'events': events.map((e) => {
      'cellIndex': e.cellIndex,
      'completedAt': e.completedAt.toIso8601String(),
      'enteredLabel': e.enteredLabel,
      'labelCustomized': e.labelCustomized,
      'elapsedMs': e.elapsedSinceStart.inMilliseconds,
    }).toList(),
    'metacognitionScore': metacognitionScore,
    'focusScore': focusScore,
    'logicalThinkingScore': logicalThinkingScore,
    'stage': stage,
    'isFreeInput': isFreeInput,
  };

  factory LearningSession.fromJson(Map<String, dynamic> json) => LearningSession(
    date: DateTime.parse(json['date'] as String),
    ageMode: json['ageMode'] as String,
    ageModeLabel: json['ageModeLabel'] as String? ?? '',
    goal: json['goal'] as String,
    completedCells: json['completedCells'] as int,
    totalCells: json['totalCells'] as int,
    events: (json['events'] as List).map((e) => CellCompletionEvent(
      cellIndex: e['cellIndex'] as int,
      completedAt: DateTime.parse(e['completedAt'] as String),
      enteredLabel: e['enteredLabel'] as String,
      labelCustomized: e['labelCustomized'] as bool,
      elapsedSinceStart: Duration(milliseconds: e['elapsedMs'] as int),
    )).toList(),
    metacognitionScore: (json['metacognitionScore'] as num).toDouble(),
    focusScore: (json['focusScore'] as num).toDouble(),
    logicalThinkingScore: (json['logicalThinkingScore'] as num).toDouble(),
    stage: json['stage'] as int? ?? 1,
    isFreeInput: json['isFreeInput'] as bool? ?? false,
  );
}

/// 週間成長サマリー
class WeeklyGrowthSummary {
  final int thisWeekSessions;
  final int lastWeekSessions;
  final double thisWeekAvgMeta;
  final double lastWeekAvgMeta;
  final double thisWeekAvgFocus;
  final double lastWeekAvgFocus;
  final double thisWeekAvgLogic;
  final double lastWeekAvgLogic;
  final int totalSessions;
  final int freeInputCount;

  const WeeklyGrowthSummary({
    required this.thisWeekSessions,
    required this.lastWeekSessions,
    required this.thisWeekAvgMeta,
    required this.lastWeekAvgMeta,
    required this.thisWeekAvgFocus,
    required this.lastWeekAvgFocus,
    required this.thisWeekAvgLogic,
    required this.lastWeekAvgLogic,
    required this.totalSessions,
    required this.freeInputCount,
  });

  int get sessionsDelta => thisWeekSessions - lastWeekSessions;
  double get metaDelta => thisWeekAvgMeta - lastWeekAvgMeta;
  double get focusDelta => thisWeekAvgFocus - lastWeekAvgFocus;
  double get logicDelta => thisWeekAvgLogic - lastWeekAvgLogic;
}

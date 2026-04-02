import '../models/mandala_state.dart';
import '../providers/social_providers.dart';

// ─────────────────────────────────────────────────────────
// HospitalityPlatformService — 段階的ホスピタリティ＋SNS連携
//
// 1. 能力別タスク自動スライド
// 2. 画像バトンID生成
// 3. シェア制限ゲート
// 4. H値（Hospitality）計算
// 5. 定型文自動生成
// ─────────────────────────────────────────────────────────

// ── 1. 能力別タスク・カタログ ─────────────────────────────

class TaskCatalog {
  final String id;
  final String emoji;
  final String name;
  final int points;
  final TaskScope scope; // 自分/家族/社会

  const TaskCatalog(this.id, this.emoji, this.name, this.points, this.scope);
}

enum TaskScope { self, family, community }

extension TaskScopeExt on TaskScope {
  String get label => switch (this) {
    TaskScope.self => 'じぶん',
    TaskScope.family => 'かぞく',
    TaskScope.community => 'しゃかい',
  };
  String get emoji => switch (this) {
    TaskScope.self => '🧒',
    TaskScope.family => '👨‍👩‍👧',
    TaskScope.community => '🌍',
  };
}

class TaskCatalogService {
  TaskCatalogService._();

  /// 級に応じたタスクカタログを返す（自動スライド）
  static List<TaskCatalog> forLevel(AgeMode mode) {
    return switch (mode) {
      // ひよこ級: 自分専用タスク
      AgeMode.age3 => const [
        TaskCatalog('t_wash',   '🧼', 'ておあらい',       1, TaskScope.self),
        TaskCatalog('t_dress',  '👕', 'おきがえ',         1, TaskScope.self),
        TaskCatalog('t_teeth',  '🪥', 'はみがき',         1, TaskScope.self),
        TaskCatalog('t_tidy_s', '🧸', 'おもちゃかたづけ', 1, TaskScope.self),
        TaskCatalog('t_eat',    '🍚', 'ごはんたべきり',   1, TaskScope.self),
      ],
      // ペンギン級: 自分＋家族タスク
      AgeMode.age4 => const [
        TaskCatalog('t_wash',   '🧼', 'ておあらい',       1, TaskScope.self),
        TaskCatalog('t_shoes',  '👟', 'くつそろえ',       1, TaskScope.family),
        TaskCatalog('t_tidy_f', '🧹', 'おかたづけ',       2, TaskScope.family),
        TaskCatalog('t_dishes', '🍽️', 'おさらはこび',     1, TaskScope.family),
        TaskCatalog('t_plants', '🌱', 'おみずやり',       1, TaskScope.family),
        TaskCatalog('t_greet',  '🙇', 'あいさつ',         1, TaskScope.family),
      ],
      // ライオン級: 自分＋家族＋社会貢献
      AgeMode.age5 => const [
        TaskCatalog('t_shoes',  '👟', 'くつそろえ',       1, TaskScope.family),
        TaskCatalog('t_cook',   '🍳', 'おりょうりてつだい', 3, TaskScope.family),
        TaskCatalog('t_laundry','👕', 'おせんたくたたみ', 2, TaskScope.family),
        TaskCatalog('t_letter', '✉️', 'おてがみかく',     2, TaskScope.community),
        TaskCatalog('t_clean',  '🗑️', 'まちのそうじ',     3, TaskScope.community),
        TaskCatalog('t_share',  '🎁', 'おすそわけ',       2, TaskScope.community),
        TaskCatalog('t_teach',  '📖', 'おしえてあげる',   3, TaskScope.community),
      ],
    };
  }
}

// ── 2. 画像バトンID ───────────────────────────────────────

class BatonImage {
  final String batonId;        // 一意ID
  final String originalUserId;
  final DateTime createdAt;
  final List<String> layerPaths; // レイヤー画像パス

  const BatonImage({
    required this.batonId, required this.originalUserId,
    required this.createdAt, this.layerPaths = const [],
  });

  /// 新しいバトンIDを生成
  static BatonImage create(String userId) => BatonImage(
    batonId: 'baton_${DateTime.now().millisecondsSinceEpoch}_$userId',
    originalUserId: userId,
    createdAt: DateTime.now(),
  );

  /// レイヤー追加（上書き撮影）
  BatonImage addLayer(String path) => BatonImage(
    batonId: batonId,
    originalUserId: originalUserId,
    createdAt: createdAt,
    layerPaths: [...layerPaths, path],
  );
}

// ── 3. シェア制限ゲート ───────────────────────────────────

enum ShareScope { familyOnly, friendsOnly, public }

extension ShareScopeExt on ShareScope {
  String get label => switch (this) {
    ShareScope.familyOnly => 'かぞくだけ',
    ShareScope.friendsOnly => 'おともだちまで',
    ShareScope.public => 'だれでも',
  };
  String get emoji => switch (this) {
    ShareScope.familyOnly => '🏠',
    ShareScope.friendsOnly => '🤝',
    ShareScope.public => '🌍',
  };
}

class ShareGateService {
  ShareGateService._();

  /// 級に応じたデフォルトシェア範囲
  static ShareScope defaultScope(AgeMode mode) => switch (mode) {
    AgeMode.age3 => ShareScope.familyOnly,
    AgeMode.age4 => ShareScope.friendsOnly,
    AgeMode.age5 => ShareScope.public,
  };

  /// 許可されたシェア範囲一覧
  static List<ShareScope> allowedScopes(AgeMode mode) => switch (mode) {
    AgeMode.age3 => [ShareScope.familyOnly],
    AgeMode.age4 => [ShareScope.familyOnly, ShareScope.friendsOnly],
    AgeMode.age5 => ShareScope.values,
  };
}

// ── 4. H値（Hospitality）計算 ─────────────────────────────

class HospitalityScore {
  final int questPoints;       // クエスト完了
  final int sharePoints;       // シェアした回数
  final int reactionPoints;    // Like/Stamp した回数
  final int batonPoints;       // バトン参加

  const HospitalityScore({
    this.questPoints = 0, this.sharePoints = 0,
    this.reactionPoints = 0, this.batonPoints = 0,
  });

  int get totalH => questPoints + sharePoints * 2 + reactionPoints + batonPoints * 3;

  String get rank {
    final h = totalH;
    if (h >= 100) return '🌟 マスター';
    if (h >= 50) return '⭐ エキスパート';
    if (h >= 20) return '✨ チャレンジャー';
    return '🌱 ビギナー';
  }

  HospitalityScore copyWith({
    int? questPoints, int? sharePoints, int? reactionPoints, int? batonPoints,
  }) => HospitalityScore(
    questPoints: questPoints ?? this.questPoints,
    sharePoints: sharePoints ?? this.sharePoints,
    reactionPoints: reactionPoints ?? this.reactionPoints,
    batonPoints: batonPoints ?? this.batonPoints,
  );
}

// ── 5. 定型文自動生成 ─────────────────────────────────────

class ShareTextService {
  ShareTextService._();

  /// お受験ポートフォリオ風の定型文を生成
  static String generateShareText({
    required String childName,
    required String charName,
    required int hospitalityScore,
    required int questCount,
    required String grade,
    required List<String> highlights,
  }) {
    final buf = StringBuffer();
    buf.writeln('🏆 $childNameの成長レポート');
    buf.writeln('');
    buf.writeln('$charNameと一緒に、$questCount個のチャレンジを達成！');
    buf.writeln('おもてなしスコア: $hospitalityScore');
    buf.writeln('総合評価: $grade');
    if (highlights.isNotEmpty) {
      buf.writeln('');
      buf.writeln('✨ キラリ語録:');
      for (final h in highlights.take(3)) {
        buf.writeln('  「$h」');
      }
    }
    buf.writeln('');
    buf.writeln('#マンダラα #知育 #思考力 #非認知能力 #お受験');
    return buf.toString();
  }

  /// LINE用の短縮テキスト
  static String generateLineText({
    required String childName,
    required int score,
  }) => '🏆 $childNameが おもてなしスコア${score}に到達！すごい！ #マンダラα';
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

// ─────────────────────────────────────────────────────────
// SocialProviders — リアルクエスト・友達連携・おもてなしスコア
// ─────────────────────────────────────────────────────────

// ── リアル・クエスト（お手伝い） ──────────────────────────

class RealQuest {
  final String id;
  final String emoji;
  final String name;
  final int rewardPoints;
  final bool approved;        // 親の承認済み
  final DateTime? completedAt;

  const RealQuest({
    required this.id, required this.emoji, required this.name,
    this.rewardPoints = 1, this.approved = false, this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'emoji': emoji, 'name': name,
    'rewardPoints': rewardPoints, 'approved': approved,
    'completedAt': completedAt?.toIso8601String(),
  };

  factory RealQuest.fromJson(Map<String, dynamic> j) => RealQuest(
    id: j['id'] as String, emoji: j['emoji'] as String, name: j['name'] as String,
    rewardPoints: j['rewardPoints'] as int? ?? 1,
    approved: j['approved'] as bool? ?? false,
    completedAt: j['completedAt'] != null ? DateTime.parse(j['completedAt'] as String) : null,
  );
}

const defaultQuests = [
  RealQuest(id: 'q_shoes',   emoji: '👟', name: 'くつそろえ',     rewardPoints: 1),
  RealQuest(id: 'q_tidy',    emoji: '🧹', name: 'おかたづけ',     rewardPoints: 2),
  RealQuest(id: 'q_dishes',  emoji: '🍽️', name: 'おさらはこび',   rewardPoints: 1),
  RealQuest(id: 'q_plants',  emoji: '🌱', name: 'おみずやり',     rewardPoints: 1),
  RealQuest(id: 'q_laundry', emoji: '👕', name: 'おせんたくたたみ', rewardPoints: 2),
  RealQuest(id: 'q_greet',   emoji: '🙇', name: 'あいさつ',       rewardPoints: 1),
  RealQuest(id: 'q_cook',    emoji: '🍳', name: 'おりょうりてつだい', rewardPoints: 3),
  RealQuest(id: 'q_pet',     emoji: '🐕', name: 'ペットのおせわ',   rewardPoints: 2),
];

class QuestState {
  final List<RealQuest> available;
  final List<RealQuest> completed;
  final int hospitalityScore;      // おもてなしスコア

  const QuestState({
    this.available = const [],
    this.completed = const [],
    this.hospitalityScore = 0,
  });

  QuestState copyWith({
    List<RealQuest>? available, List<RealQuest>? completed, int? hospitalityScore,
  }) => QuestState(
    available: available ?? this.available,
    completed: completed ?? this.completed,
    hospitalityScore: hospitalityScore ?? this.hospitalityScore,
  );

  /// マンダラのピースとして使える完了済みクエスト
  List<String> get pieceLabels =>
      completed.where((q) => q.approved).map((q) => q.name).toList();
}

class QuestNotifier extends StateNotifier<QuestState> {
  QuestNotifier() : super(QuestState(available: defaultQuests)) { _load(); }

  static const _fileName = 'quest_data.json';

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> _load() async {
    try {
      final file = await _file;
      if (!await file.exists()) return;
      final json = jsonDecode(await file.readAsString());
      state = QuestState(
        available: (json['available'] as List?)
            ?.map((e) => RealQuest.fromJson(e as Map<String, dynamic>)).toList() ?? defaultQuests,
        completed: (json['completed'] as List?)
            ?.map((e) => RealQuest.fromJson(e as Map<String, dynamic>)).toList() ?? [],
        hospitalityScore: json['hospitalityScore'] as int? ?? 0,
      );
    } catch (_) {}
  }

  Future<void> _save() async {
    final file = await _file;
    await file.writeAsString(jsonEncode({
      'available': state.available.map((q) => q.toJson()).toList(),
      'completed': state.completed.map((q) => q.toJson()).toList(),
      'hospitalityScore': state.hospitalityScore,
    }));
  }

  /// 子供がクエスト完了を申告
  Future<void> requestComplete(String questId) async {
    final quest = state.available.firstWhere((q) => q.id == questId, orElse: () => defaultQuests.first);
    final entry = RealQuest(
      id: '${questId}_${DateTime.now().millisecondsSinceEpoch}',
      emoji: quest.emoji, name: quest.name,
      rewardPoints: quest.rewardPoints,
      completedAt: DateTime.now(),
    );
    state = state.copyWith(completed: [...state.completed, entry]);
    await _save();
  }

  /// 親が承認 → おもてなしスコア加算
  Future<void> approve(String entryId) async {
    final updated = state.completed.map((q) {
      if (q.id == entryId) {
        return RealQuest(
          id: q.id, emoji: q.emoji, name: q.name,
          rewardPoints: q.rewardPoints, approved: true, completedAt: q.completedAt,
        );
      }
      return q;
    }).toList();
    final approved = updated.firstWhere((q) => q.id == entryId, orElse: () => defaultQuests.first);
    state = state.copyWith(
      completed: updated,
      hospitalityScore: state.hospitalityScore + approved.rewardPoints,
    );
    await _save();
  }
}

final questProvider = StateNotifierProvider<QuestNotifier, QuestState>(
    (ref) => QuestNotifier());

// ── 友達連携 ──────────────────────────────────────────────

class FriendProfile {
  final String id;
  final String name;
  final String emoji;
  final int score;
  final bool isFollowing;

  const FriendProfile({
    required this.id, required this.name, required this.emoji,
    this.score = 0, this.isFollowing = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'emoji': emoji,
    'score': score, 'isFollowing': isFollowing,
  };

  factory FriendProfile.fromJson(Map<String, dynamic> j) => FriendProfile(
    id: j['id'] as String, name: j['name'] as String, emoji: j['emoji'] as String,
    score: j['score'] as int? ?? 0, isFollowing: j['isFollowing'] as bool? ?? false,
  );
}

class SocialState {
  final List<FriendProfile> friends;
  final List<String> coopMissions; // 共同ミッション履歴

  const SocialState({this.friends = const [], this.coopMissions = const []});

  List<FriendProfile> get following => friends.where((f) => f.isFollowing).toList();
  List<FriendProfile> get ranking => [...friends]..sort((a, b) => b.score.compareTo(a.score));

  SocialState copyWith({List<FriendProfile>? friends, List<String>? coopMissions}) =>
      SocialState(
        friends: friends ?? this.friends,
        coopMissions: coopMissions ?? this.coopMissions,
      );
}

class SocialNotifier extends StateNotifier<SocialState> {
  SocialNotifier() : super(SocialState(friends: _demoFriends)) { _load(); }

  static final _demoFriends = [
    const FriendProfile(id: 'f1', name: 'はなちゃん', emoji: '🌸', score: 42, isFollowing: true),
    const FriendProfile(id: 'f2', name: 'そうたくん', emoji: '⚡', score: 38, isFollowing: true),
    const FriendProfile(id: 'f3', name: 'みおちゃん', emoji: '🎀', score: 55, isFollowing: false),
    const FriendProfile(id: 'f4', name: 'ゆうとくん', emoji: '🚀', score: 29, isFollowing: false),
  ];

  static const _fileName = 'social_data.json';

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> _load() async {
    try {
      final file = await _file;
      if (!await file.exists()) return;
      final json = jsonDecode(await file.readAsString());
      state = SocialState(
        friends: (json['friends'] as List?)
            ?.map((e) => FriendProfile.fromJson(e as Map<String, dynamic>)).toList() ?? _demoFriends,
        coopMissions: (json['coopMissions'] as List?)?.cast<String>() ?? [],
      );
    } catch (_) {}
  }

  Future<void> _save() async {
    final file = await _file;
    await file.writeAsString(jsonEncode({
      'friends': state.friends.map((f) => f.toJson()).toList(),
      'coopMissions': state.coopMissions,
    }));
  }

  Future<void> toggleFollow(String friendId) async {
    final updated = state.friends.map((f) {
      if (f.id == friendId) {
        return FriendProfile(
          id: f.id, name: f.name, emoji: f.emoji,
          score: f.score, isFollowing: !f.isFollowing,
        );
      }
      return f;
    }).toList();
    state = state.copyWith(friends: updated);
    await _save();
  }

  Future<void> addCoopMission(String mission) async {
    state = state.copyWith(coopMissions: [...state.coopMissions, mission]);
    await _save();
  }
}

final socialProvider = StateNotifierProvider<SocialNotifier, SocialState>(
    (ref) => SocialNotifier());

import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

// ─────────────────────────────────────────────────────────
// CommunityProviders — フィードバック・投票・お知らせ
// ─────────────────────────────────────────────────────────

// ── フィードバック ─────────────────────────────────────────

enum FeedbackCategory { ui, education, bug }

extension FeedbackCategoryExt on FeedbackCategory {
  String get label => switch (this) {
    FeedbackCategory.ui => 'UI・デザイン',
    FeedbackCategory.education => '知育内容',
    FeedbackCategory.bug => '不具合',
  };
  String get emoji => switch (this) {
    FeedbackCategory.ui => '🎨',
    FeedbackCategory.education => '📚',
    FeedbackCategory.bug => '🐛',
  };
}

class FeedbackEntry {
  final String id;
  final FeedbackCategory category;
  final String body;
  final DateTime createdAt;
  final bool rewarded; // 限定アイテム付与済みか

  const FeedbackEntry({
    required this.id, required this.category, required this.body,
    required this.createdAt, this.rewarded = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'category': category.name, 'body': body,
    'createdAt': createdAt.toIso8601String(), 'rewarded': rewarded,
  };

  factory FeedbackEntry.fromJson(Map<String, dynamic> j) => FeedbackEntry(
    id: j['id'] as String,
    category: FeedbackCategory.values.firstWhere((c) => c.name == j['category'],
        orElse: () => FeedbackCategory.ui),
    body: j['body'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    rewarded: j['rewarded'] as bool? ?? false,
  );
}

class FeedbackState {
  final List<FeedbackEntry> entries;
  final int limitedItemCount; // フィードバック報酬で得た限定アイテム数

  const FeedbackState({this.entries = const [], this.limitedItemCount = 0});

  FeedbackState copyWith({List<FeedbackEntry>? entries, int? limitedItemCount}) =>
      FeedbackState(
        entries: entries ?? this.entries,
        limitedItemCount: limitedItemCount ?? this.limitedItemCount,
      );
}

class FeedbackNotifier extends StateNotifier<FeedbackState> {
  FeedbackNotifier() : super(const FeedbackState()) { _load(); }

  static const _fileName = 'feedback_data.json';

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> _load() async {
    try {
      final file = await _file;
      if (!await file.exists()) return;
      final json = jsonDecode(await file.readAsString());
      final entries = (json['entries'] as List?)
          ?.map((e) => FeedbackEntry.fromJson(e as Map<String, dynamic>))
          .toList() ?? [];
      state = FeedbackState(
        entries: entries,
        limitedItemCount: json['limitedItemCount'] as int? ?? 0,
      );
    } catch (_) {}
  }

  Future<void> _save() async {
    final file = await _file;
    await file.writeAsString(jsonEncode({
      'entries': state.entries.map((e) => e.toJson()).toList(),
      'limitedItemCount': state.limitedItemCount,
    }));
  }

  /// フィードバック投稿 → 限定アイテムフラグ付与
  Future<void> submit(FeedbackCategory category, String body) async {
    final entry = FeedbackEntry(
      id: 'fb_${DateTime.now().millisecondsSinceEpoch}',
      category: category,
      body: body,
      createdAt: DateTime.now(),
      rewarded: true,
    );
    state = state.copyWith(
      entries: [...state.entries, entry],
      limitedItemCount: state.limitedItemCount + 1,
    );
    await _save();
  }
}

final feedbackProvider = StateNotifierProvider<FeedbackNotifier, FeedbackState>(
    (ref) => FeedbackNotifier());

// ── 投票システム ──────────────────────────────────────────

class VoteCandidate {
  final String id;
  final String title;
  final String emoji;
  final String description;
  int voteCount;

  VoteCandidate({
    required this.id, required this.title, required this.emoji,
    required this.description, this.voteCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'emoji': emoji,
    'description': description, 'voteCount': voteCount,
  };

  factory VoteCandidate.fromJson(Map<String, dynamic> j) => VoteCandidate(
    id: j['id'] as String, title: j['title'] as String,
    emoji: j['emoji'] as String, description: j['description'] as String,
    voteCount: j['voteCount'] as int? ?? 0,
  );
}

class VoteState {
  final List<VoteCandidate> candidates;
  final DateTime? lastVotedAt;
  final String? lastVotedId;

  const VoteState({this.candidates = const [], this.lastVotedAt, this.lastVotedId});

  bool get canVoteToday {
    if (lastVotedAt == null) return true;
    final now = DateTime.now();
    return now.year != lastVotedAt!.year ||
        now.month != lastVotedAt!.month ||
        now.day != lastVotedAt!.day;
  }

  VoteState copyWith({List<VoteCandidate>? candidates, DateTime? lastVotedAt, String? lastVotedId}) =>
      VoteState(
        candidates: candidates ?? this.candidates,
        lastVotedAt: lastVotedAt ?? this.lastVotedAt,
        lastVotedId: lastVotedId ?? this.lastVotedId,
      );
}

class VoteNotifier extends StateNotifier<VoteState> {
  VoteNotifier() : super(VoteState(candidates: _defaultCandidates)) { _load(); }

  static final _defaultCandidates = [
    VoteCandidate(id: 'v1', title: 'おえかきモード', emoji: '🎨',
        description: 'じゆうに おえかきして マンダラに はれる'),
    VoteCandidate(id: 'v2', title: 'おともだち きょうりょく', emoji: '🤝',
        description: 'ふたりで いっしょに マンダラを つくる'),
    VoteCandidate(id: 'v3', title: 'きせつの イベント', emoji: '🎄',
        description: 'ハロウィンや クリスマスの とくべつステージ'),
    VoteCandidate(id: 'v4', title: 'ミニゲーム', emoji: '🎮',
        description: 'クリアごとに あそべる ボーナスゲーム'),
  ];

  static const _fileName = 'vote_data.json';

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> _load() async {
    try {
      final file = await _file;
      if (!await file.exists()) return;
      final json = jsonDecode(await file.readAsString());
      final candidates = (json['candidates'] as List?)
          ?.map((e) => VoteCandidate.fromJson(e as Map<String, dynamic>))
          .toList();
      state = VoteState(
        candidates: candidates ?? _defaultCandidates,
        lastVotedAt: json['lastVotedAt'] != null
            ? DateTime.parse(json['lastVotedAt'] as String) : null,
        lastVotedId: json['lastVotedId'] as String?,
      );
    } catch (_) {}
  }

  Future<void> _save() async {
    final file = await _file;
    await file.writeAsString(jsonEncode({
      'candidates': state.candidates.map((c) => c.toJson()).toList(),
      'lastVotedAt': state.lastVotedAt?.toIso8601String(),
      'lastVotedId': state.lastVotedId,
    }));
  }

  Future<bool> vote(String candidateId) async {
    if (!state.canVoteToday) return false;
    final updated = state.candidates.map((c) {
      if (c.id == candidateId) c.voteCount++;
      return c;
    }).toList();
    state = state.copyWith(
      candidates: updated,
      lastVotedAt: DateTime.now(),
      lastVotedId: candidateId,
    );
    await _save();
    return true;
  }
}

final voteProvider = StateNotifierProvider<VoteNotifier, VoteState>(
    (ref) => VoteNotifier());

// ── お知らせ ──────────────────────────────────────────────

class NoticeEntry {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final bool isPersonal; // 個別通知か

  const NoticeEntry({
    required this.id, required this.title, required this.body,
    required this.createdAt, this.isRead = false, this.isPersonal = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'body': body,
    'createdAt': createdAt.toIso8601String(), 'isRead': isRead,
    'isPersonal': isPersonal,
  };

  factory NoticeEntry.fromJson(Map<String, dynamic> j) => NoticeEntry(
    id: j['id'] as String, title: j['title'] as String,
    body: j['body'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    isRead: j['isRead'] as bool? ?? false,
    isPersonal: j['isPersonal'] as bool? ?? false,
  );
}

class NoticeState {
  final List<NoticeEntry> notices;
  const NoticeState({this.notices = const []});
  int get unreadCount => notices.where((n) => !n.isRead).length;
}

class NoticeNotifier extends StateNotifier<NoticeState> {
  NoticeNotifier() : super(NoticeState(notices: _defaultNotices)) { _load(); }

  static final _defaultNotices = [
    NoticeEntry(
      id: 'n1',
      title: '🎉 マンダラα へようこそ！',
      body: 'おこさまの しこうりょくを そだてる ぼうけんが はじまります。',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static const _fileName = 'notices_data.json';

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> _load() async {
    try {
      final file = await _file;
      if (!await file.exists()) return;
      final json = jsonDecode(await file.readAsString());
      final notices = (json['notices'] as List?)
          ?.map((e) => NoticeEntry.fromJson(e as Map<String, dynamic>))
          .toList() ?? _defaultNotices;
      state = NoticeState(notices: notices);
    } catch (_) {}
  }

  Future<void> _save() async {
    final file = await _file;
    await file.writeAsString(jsonEncode({
      'notices': state.notices.map((n) => n.toJson()).toList(),
    }));
  }

  void markRead(String id) {
    final updated = state.notices.map((n) =>
      n.id == id ? NoticeEntry(
        id: n.id, title: n.title, body: n.body,
        createdAt: n.createdAt, isRead: true, isPersonal: n.isPersonal,
      ) : n
    ).toList();
    state = NoticeState(notices: updated);
    _save();
  }

  /// フィードバック採用時の個別通知追加
  Future<void> addPersonalNotice(String title, String body) async {
    final notice = NoticeEntry(
      id: 'pn_${DateTime.now().millisecondsSinceEpoch}',
      title: title, body: body,
      createdAt: DateTime.now(), isPersonal: true,
    );
    state = NoticeState(notices: [notice, ...state.notices]);
    await _save();
  }
}

final noticeProvider = StateNotifierProvider<NoticeNotifier, NoticeState>(
    (ref) => NoticeNotifier());

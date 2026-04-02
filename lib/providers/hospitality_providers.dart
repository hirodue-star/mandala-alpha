import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../services/hospitality_platform_service.dart';

// ─────────────────────────────────────────────────────────
// HospitalityProviders — H値・シェア設定の永続化
// ─────────────────────────────────────────────────────────

class HospitalityState {
  final HospitalityScore hScore;
  final ShareScope shareScope;
  final List<String> batonIds;

  const HospitalityState({
    this.hScore = const HospitalityScore(),
    this.shareScope = ShareScope.familyOnly,
    this.batonIds = const [],
  });

  HospitalityState copyWith({
    HospitalityScore? hScore, ShareScope? shareScope, List<String>? batonIds,
  }) => HospitalityState(
    hScore: hScore ?? this.hScore,
    shareScope: shareScope ?? this.shareScope,
    batonIds: batonIds ?? this.batonIds,
  );
}

class HospitalityNotifier extends StateNotifier<HospitalityState> {
  HospitalityNotifier() : super(const HospitalityState()) { _load(); }

  static const _fileName = 'hospitality_data.json';

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> _load() async {
    try {
      final file = await _file;
      if (!await file.exists()) return;
      final j = jsonDecode(await file.readAsString());
      state = HospitalityState(
        hScore: HospitalityScore(
          questPoints: j['questPoints'] as int? ?? 0,
          sharePoints: j['sharePoints'] as int? ?? 0,
          reactionPoints: j['reactionPoints'] as int? ?? 0,
          batonPoints: j['batonPoints'] as int? ?? 0,
        ),
        shareScope: ShareScope.values[j['shareScope'] as int? ?? 0],
        batonIds: (j['batonIds'] as List?)?.cast<String>() ?? [],
      );
    } catch (_) {}
  }

  Future<void> _save() async {
    final file = await _file;
    await file.writeAsString(jsonEncode({
      'questPoints': state.hScore.questPoints,
      'sharePoints': state.hScore.sharePoints,
      'reactionPoints': state.hScore.reactionPoints,
      'batonPoints': state.hScore.batonPoints,
      'shareScope': state.shareScope.index,
      'batonIds': state.batonIds,
    }));
  }

  /// クエスト完了でH値加算
  Future<void> onQuestComplete(int points) async {
    state = state.copyWith(
      hScore: state.hScore.copyWith(questPoints: state.hScore.questPoints + points),
    );
    await _save();
  }

  /// シェアでH値加算
  Future<void> onShare() async {
    state = state.copyWith(
      hScore: state.hScore.copyWith(sharePoints: state.hScore.sharePoints + 1),
    );
    await _save();
  }

  /// Like/Stamp反応でH値加算
  Future<void> onReaction() async {
    state = state.copyWith(
      hScore: state.hScore.copyWith(reactionPoints: state.hScore.reactionPoints + 1),
    );
    await _save();
  }

  /// バトン参加でH値加算
  Future<void> onBatonJoin(String batonId) async {
    state = state.copyWith(
      hScore: state.hScore.copyWith(batonPoints: state.hScore.batonPoints + 1),
      batonIds: [...state.batonIds, batonId],
    );
    await _save();
  }

  /// シェア範囲変更
  Future<void> setShareScope(ShareScope scope) async {
    state = state.copyWith(shareScope: scope);
    await _save();
  }
}

final hospitalityProvider = StateNotifierProvider<HospitalityNotifier, HospitalityState>(
    (ref) => HospitalityNotifier());

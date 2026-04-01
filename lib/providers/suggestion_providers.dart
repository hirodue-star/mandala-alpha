import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/suggestion_service.dart';
import 'mandala_providers.dart';

/// テーマ連想候補を提供するプロバイダー
/// ゴールが設定されると自動でローカル辞書から候補を生成
/// (APIキーがあればClaude APIにもフォールバック可)
final suggestionsProvider = Provider<List<String>>((ref) {
  final state = ref.watch(mandalaProvider);
  if (state.goal.isEmpty) return [];
  return SuggestionService.getLocalSuggestions(state.goal);
});

/// API経由で取得する非同期バージョン（将来用）
final asyncSuggestionsProvider = FutureProvider<List<String>>((ref) async {
  final state = ref.read(mandalaProvider);
  if (state.goal.isEmpty) return [];
  final apiKey = const String.fromEnvironment('ANTHROPIC_API_KEY');
  return SuggestionService.fetchFromApi(state.goal, apiKey: apiKey);
});

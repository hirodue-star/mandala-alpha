import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/context_service.dart';

// ─── 親トピック ───────────────────────────────────────────

class ParentTopicNotifier extends StateNotifier<String?> {
  ParentTopicNotifier() : super(null);
  void setTopic(String? topic) => state = (topic != null && topic.trim().isNotEmpty) ? topic.trim() : null;
  void clear() => state = null;
}

final parentTopicProvider = StateNotifierProvider<ParentTopicNotifier, String?>(
    (ref) => ParentTopicNotifier());

// ─── 環境コンテキスト ─────────────────────────────────────

final environmentContextProvider = Provider<EnvironmentContext>((ref) {
  final topic = ref.watch(parentTopicProvider);
  return ContextService.getContext(parentTopic: topic);
});

// ─── 挨拶テキスト ─────────────────────────────────────────

final puppyGreetingProvider = Provider<String>((ref) {
  final ctx = ref.watch(environmentContextProvider);
  return ContextService.generateGreeting(ctx);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mandala_state.dart';
import '../models/activity_log.dart';
import '../services/audio_mixer_service.dart';
import '../services/suggestion_service.dart';

class MandalaNotifier extends StateNotifier<MandalaState> {
  final AudioMixerService _audio;

  MandalaNotifier(this._audio) : super(MandalaState.initial());

  void setAge(AgeMode mode) {
    state = MandalaState.initial(mode: mode);
  }

  void activate(String goal) {
    if (goal.trim().isEmpty) return;
    List<String> labels;
    if (state.ageMode.isFreeInputMode) {
      // ライオン級: 自動候補なし（思考力育成モード）
      labels = state.labels;
    } else {
      final suggestions = SuggestionService.getLocalSuggestions(goal.trim());
      labels = _mergeLabels(state.labels, suggestions, state.activeCellCount);
    }
    state = state.copyWith(
      goal: goal.trim(),
      labels: labels,
      phase: ResonancePhase.activated,
      sessionStart: DateTime.now(),
    );
  }

  void updateGoal(String goal) {
    if (goal.trim().isEmpty) return;
    if (state.ageMode.isFreeInputMode) {
      // ライオン級: ゴール変更してもラベルは自動書き換えしない
      state = state.copyWith(goal: goal.trim());
    } else {
      final suggestions = SuggestionService.getLocalSuggestions(goal.trim());
      final labels = _mergeLabels(state.labels, suggestions, state.activeCellCount);
      state = state.copyWith(goal: goal.trim(), labels: labels);
    }
  }

  /// 完了済みセルのラベルは保持し、未完了セルだけAI候補で上書き
  List<String> _mergeLabels(List<String> current, List<String> suggestions, int active) {
    final merged = List<String>.from(current);
    for (int i = 0; i < active && i < suggestions.length; i++) {
      if (!state.completed[i]) merged[i] = suggestions[i];
    }
    return merged;
  }

  Future<void> completeCell(int index, {String? label}) async {
    if (state.phase != ResonancePhase.activated) return;
    if (state.completed[index]) return;

    final enteredLabel = (label != null && label.isNotEmpty) ? label : state.labels[index];
    final isCustomized = enteredLabel != state.ageMode.defaultLabels[index];
    final elapsed = state.sessionStart != null
        ? DateTime.now().difference(state.sessionStart!)
        : Duration.zero;

    final event = CellCompletionEvent(
      cellIndex: index,
      completedAt: DateTime.now(),
      enteredLabel: enteredLabel,
      labelCustomized: isCustomized,
      elapsedSinceStart: elapsed,
    );

    final newCompleted = List<bool>.from(state.completed)..[index] = true;
    final newLabels = label != null && label.isNotEmpty
        ? (List<String>.from(state.labels)..[index] = label)
        : state.labels;
    final newLogs = [...state.logs, event];

    state = state.copyWith(
      completed: newCompleted,
      labels: newLabels,
      logs: newLogs,
    );

    await _audio.enableTrack(index);
    if (state.isAllDone) await _startHatching();
  }

  Future<void> resetCell(int index) async {
    if (!state.completed[index]) return;
    final newCompleted = List<bool>.from(state.completed)..[index] = false;
    final newPhase = (state.phase == ResonancePhase.hatched || state.phase == ResonancePhase.hatching)
        ? ResonancePhase.activated
        : state.phase;
    state = state.copyWith(completed: newCompleted, phase: newPhase);
    await _audio.disableTrack(index);
  }

  Future<void> _startHatching() async {
    state = state.copyWith(phase: ResonancePhase.hatching);
    await _audio.playOrchestra();
  }

  void onHatchAnimationDone() {
    state = state.copyWith(phase: ResonancePhase.hatched);
  }

  /// ステージクリア → 次のステージへ自動移行
  Future<void> advanceStage() async {
    await _audio.stopAll();
    final nextStage = state.currentStage + 1;
    final cleared = state.totalClearedStages + 1;
    state = MandalaState.initial(
      mode: state.ageMode,
      stage: nextStage,
      cleared: cleared,
    );
  }

  Future<void> reset() async {
    await _audio.stopAll();
    state = MandalaState.initial(mode: state.ageMode,
        stage: state.currentStage, cleared: state.totalClearedStages);
  }

  void debugSetStage(int stage) {
    assert(stage >= 0 && stage <= 8);
    const debugGoal = 'どうぶつえん';
    final active = state.ageMode.activeCells;
    final clampedStage = stage.clamp(0, active);
    final completed = List<bool>.generate(8, (i) => i < clampedStage);
    final phase = clampedStage == active
        ? ResonancePhase.hatched
        : clampedStage > 0 ? ResonancePhase.activated : ResonancePhase.locked;
    // Observer: ゴールからラベルを自動生成
    final suggestions = SuggestionService.getLocalSuggestions(debugGoal);
    final labels = List.generate(8, (i) => i < suggestions.length ? suggestions[i] : '');
    state = state.copyWith(
      goal: debugGoal,
      completed: completed,
      labels: labels,
      phase: phase,
      logs: List.generate(clampedStage, (i) => CellCompletionEvent(
        cellIndex: i,
        completedAt: DateTime.now().subtract(Duration(seconds: (clampedStage - i) * 45)),
        enteredLabel: i < suggestions.length ? suggestions[i] : '',
        labelCustomized: false,
        elapsedSinceStart: Duration(seconds: i * 45),
      )),
    );
  }
}

// ─── Providers ─────────────────────────────────────────────

final audioMixerProvider = Provider<AudioMixerService>((ref) {
  final service = AudioMixerService();
  ref.onDispose(service.dispose);
  return service;
});

final mandalaProvider = StateNotifierProvider<MandalaNotifier, MandalaState>((ref) {
  final audio = ref.watch(audioMixerProvider);
  return MandalaNotifier(audio);
});

final analyticsProvider = Provider((ref) {
  final s = ref.watch(mandalaProvider);
  return (
    metacognition: s.metacognitionScore,
    focus: s.focusScore,
    logicalThinking: s.logicalThinkingScore,
  );
});

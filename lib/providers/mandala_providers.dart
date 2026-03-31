import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mandala_state.dart';
import '../services/audio_mixer_service.dart';

// ─────────────────────────────────────────────────────────
// MandalaNotifier — 状態遷移とオーディオミキサーを統合
// ─────────────────────────────────────────────────────────

class MandalaNotifier extends StateNotifier<MandalaState> {
  final AudioMixerService _audio;

  MandalaNotifier(this._audio) : super(MandalaState.initial());

  // ── ゴール設定 → locked → activated ────────────────────

  void activate(String goal) {
    if (goal.trim().isEmpty) return;
    state = state.copyWith(
      goal: goal.trim(),
      phase: ResonancePhase.activated,
    );
  }

  /// activated 中にゴール文字列だけ更新
  void updateGoal(String goal) {
    if (goal.trim().isEmpty) return;
    state = state.copyWith(goal: goal.trim());
  }

  // ── セル操作 ────────────────────────────────────────────

  /// セルを完了にする（index: 0〜7）
  Future<void> completeCell(int index, {String? label}) async {
    if (state.phase != ResonancePhase.activated) return;
    if (state.completed[index]) return;

    final newCompleted = List<bool>.from(state.completed)..[index] = true;
    final newLabels = label != null && label.isNotEmpty
        ? (List<String>.from(state.labels)..[index] = label)
        : state.labels;

    state = state.copyWith(completed: newCompleted, labels: newLabels);

    // その楽器トラックを ON
    await _audio.enableTrack(index);

    // 全完了 → 孵化へ
    if (state.isAllDone) {
      await _startHatching();
    }
  }

  /// セルを未完了に戻す
  Future<void> resetCell(int index) async {
    if (!state.completed[index]) return;
    final newCompleted = List<bool>.from(state.completed)..[index] = false;

    // 孵化済みなら activated へ戻す
    final newPhase = state.phase == ResonancePhase.hatched ||
            state.phase == ResonancePhase.hatching
        ? ResonancePhase.activated
        : state.phase;

    state = state.copyWith(completed: newCompleted, phase: newPhase);
    await _audio.disableTrack(index);
  }

  // ── 孵化フロー ───────────────────────────────────────────

  Future<void> _startHatching() async {
    state = state.copyWith(phase: ResonancePhase.hatching);
    await _audio.playOrchestra();
  }

  /// hatching アニメーション完了後に呼ぶ
  void onHatchAnimationDone() {
    state = state.copyWith(phase: ResonancePhase.hatched);
  }

  // ── リセット ─────────────────────────────────────────────

  Future<void> reset() async {
    await _audio.stopAll();
    state = MandalaState.initial();
  }
}

// ─── Providers ─────────────────────────────────────────

final audioMixerProvider = Provider<AudioMixerService>((ref) {
  final service = AudioMixerService();
  ref.onDispose(service.dispose);
  return service;
});

final mandalaProvider =
    StateNotifierProvider<MandalaNotifier, MandalaState>((ref) {
  final audio = ref.watch(audioMixerProvider);
  return MandalaNotifier(audio);
});

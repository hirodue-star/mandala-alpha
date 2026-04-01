import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/character.dart';

class CharacterState {
  final CharacterId selected;
  final int puppyPlayCount;
  final int gaogaoPlayCount;

  const CharacterState({
    this.selected = CharacterId.puppy,
    this.puppyPlayCount = 0,
    this.gaogaoPlayCount = 0,
  });

  CharacterDef get def => selected == CharacterId.puppy ? puppyDef : gaogaoDef;

  /// 興味分析: どちらをより好んでいるか (0.0=プピィ寄り, 1.0=ガオガオ寄り)
  double get interestRatio {
    final total = puppyPlayCount + gaogaoPlayCount;
    if (total == 0) return 0.5;
    return gaogaoPlayCount / total;
  }

  String get preferenceLabel {
    if (puppyPlayCount + gaogaoPlayCount < 3) return 'まだデータが少ないです';
    if (interestRatio > 0.65) return 'ガオガオが お気に入り！🦕';
    if (interestRatio < 0.35) return 'プピィが お気に入り！🐰';
    return 'どちらも バランスよく遊んでいます 🌟';
  }

  CharacterState copyWith({CharacterId? selected, int? puppyPlayCount, int? gaogaoPlayCount}) =>
      CharacterState(
        selected: selected ?? this.selected,
        puppyPlayCount: puppyPlayCount ?? this.puppyPlayCount,
        gaogaoPlayCount: gaogaoPlayCount ?? this.gaogaoPlayCount,
      );
}

class CharacterNotifier extends StateNotifier<CharacterState> {
  CharacterNotifier() : super(const CharacterState());

  void select(CharacterId id) {
    final newState = state.copyWith(selected: id);
    // プレイ回数加算
    if (id == CharacterId.puppy) {
      state = newState.copyWith(puppyPlayCount: state.puppyPlayCount + 1);
    } else {
      state = newState.copyWith(gaogaoPlayCount: state.gaogaoPlayCount + 1);
    }
  }
}

final characterProvider = StateNotifierProvider<CharacterNotifier, CharacterState>(
    (ref) => CharacterNotifier());

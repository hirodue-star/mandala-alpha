import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/character.dart';
import '../models/mandala_state.dart';

// ─────────────────────────────────────────────────────────
// 装備アイテム定義（級クリアで獲得）
// ─────────────────────────────────────────────────────────

class EquipItem {
  final String id;
  final String emoji;
  final String name;
  final String sourceLevel; // age3/age4/age5
  const EquipItem(this.id, this.emoji, this.name, this.sourceLevel);
}

const levelEquipItems = {
  'age3': EquipItem('scarf_yellow', '🧣', 'ひよこスカーフ', 'age3'),
  'age4': EquipItem('hat_penguin',  '🎩', 'ペンギンぼうし', 'age4'),
  'age5': EquipItem('crown_lion',   '👑', 'ライオンおうかん', 'age5'),
};

class CharacterState {
  final CharacterId selected;
  final int puppyPlayCount;
  final int gaogaoPlayCount;
  final List<String> equippedItems; // 獲得済み装備ID一覧

  const CharacterState({
    this.selected = CharacterId.puppy,
    this.puppyPlayCount = 0,
    this.gaogaoPlayCount = 0,
    this.equippedItems = const [],
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

  /// フル装備の絵文字一覧（SNSレポート用）
  List<String> get equippedEmojis =>
      equippedItems.map((id) => levelEquipItems.values
          .where((e) => e.id == id).firstOrNull?.emoji ?? '')
          .where((e) => e.isNotEmpty).toList();

  bool hasEquip(String id) => equippedItems.contains(id);

  /// キャラ＋装備のフルビジュアル文字列
  String get fullEquipDisplay {
    final base = def.emoji;
    final items = equippedEmojis.join('');
    return '$base$items';
  }

  /// キャラに応じたガイドトーン
  String get guideTone => selected == CharacterId.puppy ? 'gentle' : 'bold';

  CharacterState copyWith({
    CharacterId? selected, int? puppyPlayCount, int? gaogaoPlayCount,
    List<String>? equippedItems,
  }) => CharacterState(
    selected: selected ?? this.selected,
    puppyPlayCount: puppyPlayCount ?? this.puppyPlayCount,
    gaogaoPlayCount: gaogaoPlayCount ?? this.gaogaoPlayCount,
    equippedItems: equippedItems ?? this.equippedItems,
  );
}

class CharacterNotifier extends StateNotifier<CharacterState> {
  CharacterNotifier() : super(const CharacterState());

  void select(CharacterId id) {
    final newState = state.copyWith(selected: id);
    if (id == CharacterId.puppy) {
      state = newState.copyWith(puppyPlayCount: state.puppyPlayCount + 1);
    } else {
      state = newState.copyWith(gaogaoPlayCount: state.gaogaoPlayCount + 1);
    }
  }

  /// 級クリア時に装備を付与
  void awardLevelEquip(AgeMode mode) {
    final item = levelEquipItems[mode.name];
    if (item == null) return;
    if (state.hasEquip(item.id)) return; // 重複防止
    state = state.copyWith(
      equippedItems: [...state.equippedItems, item.id],
    );
  }
}

final characterProvider = StateNotifierProvider<CharacterNotifier, CharacterState>(
    (ref) => CharacterNotifier());

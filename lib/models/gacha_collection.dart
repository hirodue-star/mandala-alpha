// ─────────────────────────────────────────────────────────
// GachaCollection — きせかえ & コレクション & 冒険ステージ
// ─────────────────────────────────────────────────────────

/// プピィの衣装アイテム
class CostumeItem {
  final String id;
  final String emoji;
  final String name;
  final CostumeRarity rarity;
  final CostumeStyle style; // かわいい系 or かっこいい系
  const CostumeItem(this.id, this.emoji, this.name, this.rarity, this.style);
}

enum CostumeRarity { common, rare, superRare }
enum CostumeStyle { cute, cool, both }

const allCostumes = [
  // Common — かわいい系
  CostumeItem('ribbon', '🎀', 'リボン', CostumeRarity.common, CostumeStyle.cute),
  CostumeItem('flower', '🌸', 'おはな', CostumeRarity.common, CostumeStyle.cute),
  CostumeItem('heart', '💖', 'ハート', CostumeRarity.common, CostumeStyle.cute),
  // Common — かっこいい系
  CostumeItem('fire', '🔥', 'ほのお', CostumeRarity.common, CostumeStyle.cool),
  CostumeItem('shield', '🛡️', 'たて', CostumeRarity.common, CostumeStyle.cool),
  CostumeItem('dinoegg', '🥚', 'きょうりゅうのたまご', CostumeRarity.common, CostumeStyle.cool),
  // Rare — かわいい系
  CostumeItem('crown', '👑', 'おうかん', CostumeRarity.rare, CostumeStyle.cute),
  CostumeItem('wand', '🪄', 'まほうのつえ', CostumeRarity.rare, CostumeStyle.cute),
  // Rare — かっこいい系
  CostumeItem('cape', '🦸', 'マント', CostumeRarity.rare, CostumeStyle.cool),
  CostumeItem('sword', '⚔️', 'つるぎ', CostumeRarity.rare, CostumeStyle.cool),
  // Super Rare — 両方使える
  CostumeItem('rainbow', '🌈', 'にじのドレス', CostumeRarity.superRare, CostumeStyle.both),
  CostumeItem('astronaut', '🚀', 'うちゅうふく', CostumeRarity.superRare, CostumeStyle.both),
];

/// 冒険ステージの背景テーマ
class AdventureStage {
  final int stageNumber;
  final String name;
  final String emoji;
  final List<double> bgColors; // ARGB hex values stored as doubles for const
  final String costumeHint;

  const AdventureStage(this.stageNumber, this.name, this.emoji, this.bgColors, this.costumeHint);
}

const adventureStages = [
  AdventureStage(1, 'おへや',      '🏠', [0xFFFFF8E7, 0xFFFFF0D0], ''),
  AdventureStage(2, 'にじのもり',  '🌈', [0xFFE8F5E9, 0xFFB9F6CA], 'ぼうし'),
  AdventureStage(3, 'ほしぞらのうみ','🌊', [0xFF1A1A4D, 0xFF0D0D33], 'うきわ'),
  AdventureStage(4, 'おかしのくに', '🍭', [0xFFFFF0F5, 0xFFFFE0EC], 'おうかん'),
  AdventureStage(5, 'くものうえ',  '☁️', [0xFFE8EAF6, 0xFFC5CAE9], 'つばさ'),
  AdventureStage(6, 'おかしのうちゅう','🍩', [0xFF1A0A3D, 0xFF0A0520], 'ヘルメット'),
];

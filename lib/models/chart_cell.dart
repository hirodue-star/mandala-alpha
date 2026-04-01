enum CellStatus { empty, trying, done }

class ChartCell {
  final String category;
  final String icon;
  CellStatus status;
  String? voiceMemo;

  ChartCell({
    required this.category,
    required this.icon,
    this.status = CellStatus.empty,
    this.voiceMemo,
  });
}

// 8マス定義（時計回り：上→右上→右→右下→下→左下→左→左上）
final List<ChartCell> defaultCells = [
  ChartCell(category: 'あいさつ',   icon: '👋'),
  ChartCell(category: 'おきがえ',   icon: '👕'),
  ChartCell(category: 'たいそう',   icon: '🤸'),
  ChartCell(category: 'おてつだい', icon: '🧹'),
  ChartCell(category: 'えほん',     icon: '📚'),
  ChartCell(category: 'かずあそび', icon: '🔢'),
  ChartCell(category: 'おえかき',   icon: '🎨'),
  ChartCell(category: 'きもちメモ', icon: '💬'),
];

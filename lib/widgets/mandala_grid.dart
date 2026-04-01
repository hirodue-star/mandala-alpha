import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/chart_cell.dart';

// 3x3グリッドのインデックスマッピング
// [左上, 上,  右上]
// [左,  中央, 右  ]
// [左下, 下,  右下]
//
// defaultCells インデックス（時計回り）：
//   上=0, 右上=1, 右=2, 右下=3, 下=4, 左下=5, 左=6, 左上=7
const List<int?> _gridMap = [
  7, 0, 1,  // row 0
  6, null, 2,  // row 1  (null = 中央)
  5, 4, 3,  // row 2
];

class MandalaGrid extends StatelessWidget {
  final List<ChartCell> cells;
  final String theme;
  final void Function(int index) onCellTap;
  final VoidCallback onThemeTap;

  const MandalaGrid({
    super.key,
    required this.cells,
    required this.theme,
    required this.onCellTap,
    required this.onThemeTap,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: 9,
        itemBuilder: (context, gridIndex) {
          final cellIndex = _gridMap[gridIndex];
          if (cellIndex == null) {
            return _CenterCell(theme: theme, onTap: onThemeTap);
          }
          return _MandalaCell(
            cell: cells[cellIndex],
            onTap: () => onCellTap(cellIndex),
          );
        },
      ),
    );
  }
}

class _MandalaCell extends StatelessWidget {
  final ChartCell cell;
  final VoidCallback onTap;

  const _MandalaCell({required this.cell, required this.onTap});

  Color get _bgColor {
    switch (cell.status) {
      case CellStatus.done:
        return const Color(0xFFFFD700); // 金色
      case CellStatus.trying:
        return const Color(0xFFFFE082);
      case CellStatus.empty:
        return const Color(0xFFF3F0FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: cell.status == CellStatus.done
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(cell.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              cell.category,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A4A6A),
              ),
              textAlign: TextAlign.center,
            ),
            if (cell.status == CellStatus.done)
              const Text('⭐', style: TextStyle(fontSize: 12))
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 1200.ms),
          ],
        ),
      ),
    );
  }
}

class _CenterCell extends StatelessWidget {
  final String theme;
  final VoidCallback onTap;

  const _CenterCell({required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C4DFF), Color(0xFF9C6FFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C4DFF).withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 2,
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✨', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              theme,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(end: 1.04, duration: 1500.ms, curve: Curves.easeInOut),
    );
  }
}

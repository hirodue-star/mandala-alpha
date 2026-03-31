import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// マンダラビュー：9マスグリッド（中央＝Goal）
class MandalaView extends StatefulWidget {
  const MandalaView({super.key});

  @override
  State<MandalaView> createState() => _MandalaViewState();
}

class _MandalaViewState extends State<MandalaView> {
  String _goal = 'ゴールを\n入力しよう';

  final List<_SubCell> _cells = [
    _SubCell(label: 'やること①', icon: '📝'),
    _SubCell(label: 'やること②', icon: '🌟'),
    _SubCell(label: 'やること③', icon: '💪'),
    _SubCell(label: 'やること④', icon: '🎯'),
    _SubCell(label: 'やること⑤', icon: '🔑'),
    _SubCell(label: 'やること⑥', icon: '💡'),
    _SubCell(label: 'やること⑦', icon: '🏆'),
    _SubCell(label: 'やること⑧', icon: '✨'),
  ];

  // グリッドマッピング（時計回り）
  // [7, 0, 1]
  // [6, *, 2]  * = Goal（中央）
  // [5, 4, 3]
  static const List<int?> _gridMap = [7, 0, 1, 6, null, 2, 5, 4, 3];

  void _onGoalTap() {
    final controller = TextEditingController(text: _goal.replaceAll('\n', ' '));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ゴールを設定', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '例：英語が話せるようになる',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() => _goal = text);
              }
              Navigator.pop(ctx);
            },
            child: const Text('決定'),
          ),
        ],
      ),
    );
  }

  void _onCellTap(int index) {
    final controller = TextEditingController(text: _cells[index].label);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${_cells[index].icon} マスを編集'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '行動・サポート項目を入力',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                setState(() => _cells[index] = _cells[index].copyWith(label: text));
              }
              Navigator.pop(ctx);
            },
            child: const Text('決定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'マンダラチャート',
          style: TextStyle(
            color: Color(0xFF4A4A6A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF4A4A6A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            const _HintText(),
            const SizedBox(height: 12),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 9,
                  itemBuilder: (context, gridIndex) {
                    final cellIndex = _gridMap[gridIndex];
                    if (cellIndex == null) {
                      return _GoalCell(goal: _goal, onTap: _onGoalTap);
                    }
                    return _SubCellWidget(
                      cell: _cells[cellIndex],
                      onTap: () => _onCellTap(cellIndex),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ─── データクラス ───────────────────────────────────────────
class _SubCell {
  final String label;
  final String icon;
  const _SubCell({required this.label, required this.icon});
  _SubCell copyWith({String? label, String? icon}) =>
      _SubCell(label: label ?? this.label, icon: icon ?? this.icon);
}

// ─── ウィジェット ───────────────────────────────────────────

class _HintText extends StatelessWidget {
  const _HintText();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE7FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.touch_app_outlined, size: 16, color: Color(0xFF7C4DFF)),
          const SizedBox(width: 6),
          Text(
            'マスをタップして編集できます',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalCell extends StatelessWidget {
  final String goal;
  final VoidCallback onTap;
  const _GoalCell({required this.goal, required this.onTap});

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
              color: const Color(0xFF7C4DFF).withOpacity(0.45),
              blurRadius: 14,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎯', style: TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            const Text(
              'GOAL',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white70,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                goal,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(end: 1.04, duration: 1600.ms, curve: Curves.easeInOut),
    );
  }
}

class _SubCellWidget extends StatelessWidget {
  final _SubCell cell;
  final VoidCallback onTap;
  const _SubCellWidget({required this.cell, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0D7FF), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(cell.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                cell.label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A4A6A),
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

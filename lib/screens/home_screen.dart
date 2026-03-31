import 'package:flutter/material.dart';
import '../models/chart_cell.dart';
import '../widgets/mandala_grid.dart';
import '../widgets/parental_gate.dart';
import 'dashboard_screen.dart';
import 'input_screen.dart';
import 'mandala_chart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<ChartCell> _cells = List.from(defaultCells);
  String _theme = 'こんしゅうの\nテーマ';

  int get _doneCount => _cells.where((c) => c.status == CellStatus.done).length;

  void _onCellTap(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InputScreen(
          cell: _cells[index],
          whisperApiKey: const String.fromEnvironment('OPENAI_API_KEY'),
          onDone: (text) {
            setState(() {
              _cells[index].status = CellStatus.done;
              _cells[index].voiceMemo = text;
            });
          },
        ),
      ),
    );
  }

  void _onThemeTap() {
    showDialog(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(text: _theme);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('今週のテーマ'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'テーマを入力'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _theme = controller.text.trim().isEmpty
                    ? _theme
                    : controller.text.trim());
                Navigator.pop(ctx);
              },
              child: const Text('決定'),
            ),
          ],
        );
      },
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
          'マンダラα',
          style: TextStyle(
            color: Color(0xFF4A4A6A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view_rounded, color: Color(0xFF7C4DFF)),
            tooltip: 'マンダラチャートMVP',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MandalaChartScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.dashboard_outlined, color: Color(0xFF4A4A6A)),
            tooltip: '保護者ダッシュボード',
            onPressed: () async {
              final ok = await ParentalGate.show(context);
              if (ok && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DashboardScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            _ProgressBar(done: _doneCount, total: 8),
            const SizedBox(height: 16),
            Expanded(
              child: MandalaGrid(
                cells: _cells,
                theme: _theme,
                onCellTap: _onCellTap,
                onThemeTap: _onThemeTap,
              ),
            ),
            const SizedBox(height: 16),
            _EncouragementText(done: _doneCount),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int done;
  final int total;

  const _ProgressBar({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'こんしゅうのきろく',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$done / $total',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF7C4DFF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: done / total,
            minHeight: 10,
            backgroundColor: const Color(0xFFE0D7FF),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF7C4DFF)),
          ),
        ),
      ],
    );
  }
}

class _EncouragementText extends StatelessWidget {
  final int done;

  const _EncouragementText({required this.done});

  String get _message {
    if (done == 8) return 'かんぺき！すごいね！🎉';
    if (done >= 5) return 'もうすこし！がんばれ！✨';
    if (done >= 1) return 'いいね！つづけよう！⭐';
    return 'タップしてはじめよう！👆';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A4A6A),
            ),
          ),
        ],
      ),
    );
  }
}

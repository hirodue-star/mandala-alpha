import 'package:flutter/material.dart';
import '../models/report.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = dummyReports;
    final latest = reports.first;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF4A4A6A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '保護者ダッシュボード',
          style: TextStyle(
            color: Color(0xFF4A4A6A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          _WeeklyAchievementCard(report: latest),
          const SizedBox(height: 16),
          _ScoreRadarCard(scores: latest.scores),
          const SizedBox(height: 16),
          _ReportCard(report: latest, isLatest: true),
          const SizedBox(height: 24),
          const Text(
            '過去のレポート',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A4A6A),
            ),
          ),
          const SizedBox(height: 12),
          ...reports.skip(1).map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ReportCard(report: r, isLatest: false),
              )),
        ],
      ),
    );
  }
}

class _WeeklyAchievementCard extends StatelessWidget {
  final Report report;

  const _WeeklyAchievementCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final pct = (report.achievedCount / 8 * 100).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C4DFF), Color(0xFF9C6FFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C4DFF).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('今週の達成率',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Text(
                  '$pct%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${report.achievedCount} / 8 マス',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          _CircleProgress(value: report.achievedCount / 8),
        ],
      ),
    );
  }
}

class _CircleProgress extends StatelessWidget {
  final double value;

  const _CircleProgress({required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 8,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
          Center(
            child: Text(
              '⭐' * (value * 5).round(),
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRadarCard extends StatelessWidget {
  final NonCognitiveScores scores;

  const _ScoreRadarCard({required this.scores});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('自律性', scores.selfControl, '👕'),
      ('コミュニケーション', scores.communication, '👋'),
      ('忍耐力', scores.persistence, '🤸'),
      ('創造性', scores.creativity, '🎨'),
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '非認知能力スコア',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A4A6A),
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ScoreBar(
                  icon: item.$3,
                  label: item.$1,
                  value: item.$2,
                ),
              )),
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final String icon;
  final String label;
  final double value;

  const _ScoreBar(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF4A4A6A)),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 10,
              backgroundColor: const Color(0xFFE0D7FF),
              valueColor: AlwaysStoppedAnimation(
                value >= 0.8
                    ? const Color(0xFFFFD700)
                    : const Color(0xFF7C4DFF),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(value * 100).round()}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7C4DFF),
          ),
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Report report;
  final bool isLatest;

  const _ReportCard({required this.report, required this.isLatest});

  String _formatWeek(DateTime weekOf) {
    return '${weekOf.month}月${weekOf.day}日〜の週';
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isLatest)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C4DFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('最新',
                      style: TextStyle(color: Colors.white, fontSize: 11)),
                ),
              if (isLatest) const SizedBox(width: 8),
              Text(
                _formatWeek(report.weekOf),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '⭐ ${report.achievedCount}/8',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7C4DFF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.summary,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4A4A6A),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }
}

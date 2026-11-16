import 'package:flutter/material.dart';
import 'package:sleepy/src/features/report/presentation/widgets/week/report_shared.dart';
import 'package:sleepy/src/core/models/sleep_report.dart';

class ScoreCardSection extends StatelessWidget {
  const ScoreCardSection({
    super.key,
    required this.title,
    required this.report,
  });

  final String title;
  final SleepReport report;

  @override
  Widget build(BuildContext context) {
    final avgScore = report.avgSleepScore;
    final avgTSTMinutes = report.avgSleepDuration.inMinutes;
    final avgAwakenings = report.avgAwakenings;

    final tt = Theme.of(context).textTheme;
    final h = (avgTSTMinutes / 60).floor();
    final m = (avgTSTMinutes % 60).round();

    final List<String> tips = report.summaryMessages;

    return reportCard(
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '${avgScore.round()}점',
              style: tt.displaySmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (avgScore.clamp(0, 100)) / 100.0,
                minHeight: 10,
                backgroundColor: const Color(0xFFECEFF3),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF7A5AF8)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _miniStat(context, label: '평균 수면 시간', value: '${h}h ${m}m'),
                _miniStat(
                  context,
                  label: '수면 중 깬 횟수',
                  value: '${avgAwakenings.toStringAsFixed(1)}회',
                ),
                _miniStat(
                  context,
                  label: '수면 효율',
                  value: '${report.avgSleepEfficiency.toStringAsFixed(1)}%',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _miniStat(
                  context,
                  label: 'SRI(수면 규칙성 지표)',
                  value: '${report.sleepRegularityIndex.toStringAsFixed(1)}점',
                ),
                _miniStat(
                  context,
                  label: 'SJL(사회적 시차)',
                  value: '${report.socialJetlag.inMinutes.toStringAsFixed(1)}분',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '맞춤 조언',
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 6),
            ...tips.map(
              (t) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: Color(0xFF7A5AF8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t,
                        style: tt.bodyMedium?.copyWith(
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final tt = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          value,
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: tt.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:sleepy/src/core/models/child_profile.dart';
import 'package:sleepy/src/core/models/sleep_report.dart';
import 'package:sleepy/src/features/report/presentation/widgets/daily/daily_report_shared.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.child, required this.report});

  final ChildProfile child;
  final DailyReportData report;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final duration = report.sleepDuration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return reportCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // AI 요약 메시지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Text.rich(
              TextSpan(
                style: tt.bodyLarge?.copyWith(height: 1.6),
                children: [
                  TextSpan(
                    text: '${child.firstName}이는 ',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(
                    text: '$hours시간 $minutes분',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(
                    text: ' 동안 잠을 잤어요.\n기상 후 컨디션은 \'',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(
                    text: report.sleepData!.morningCondition.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(
                    text: '\'이었네요!',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // 핵심 지표
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              // Row 대신에 각 항목이 공간을 균등하게 차지하도록 수정
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildMetricItem(
                    context,
                    '수면 점수',
                    '${report.sleepData!.sleepScore}점',
                    Icons.star_rounded,
                    scoreColor(report.sleepData!.sleepScore.toDouble()),
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    context,
                    '수면 효율',
                    '${report.sleepEfficiency.toStringAsFixed(1)}%',
                    Icons.shield_moon_rounded, // ★★★ 아이콘 변경 ★★★
                    scoreColor(report.sleepEfficiency), // 점수도 효율 기준으로 변경
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    context,
                    '잠드는 시간', // 가독성을 위해 줄바꿈 제거
                    '${report.sleepData!.analysis.timeToFallAsleep.inMinutes}분',
                    Icons.bedtime_rounded,
                    Colors.blueGrey.shade600,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    context,
                    '방해 요인', // 라벨을 더 간결하게 수정
                    '총 ${report.sleepData!.analysis.problematicEvents.length + report.sleepData!.analysis.awakeningsCount}회',
                    Icons.warning_amber_rounded,
                    Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center, // ★★★ 텍스트 중앙 정렬 추가 ★★★
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

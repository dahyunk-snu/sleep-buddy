import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sleepy/src/features/report/presentation/widgets/week/report_shared.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sleepy/src/features/report/application/report_controller.dart';
import 'package:sleepy/src/core/models/sleep_report.dart';

class ChartSection extends ConsumerWidget {
  const ChartSection({super.key, required this.dailyData});
  final List<DailyReportData> dailyData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedChartType = ref.watch(
      reportControllerProvider.select((s) => s.selectedChartType),
    );
    final controller = ref.read(reportControllerProvider.notifier);

    return Column(
      children: [
        Center(
          child: IntrinsicWidth(
            child: ReportSegmentedThree(
              labels: const ['총 수면 시간', '수면 효율', '수면 점수'],
              index: ReportChartType.values.indexOf(selectedChartType),
              onTap: (i) =>
                  controller.changeChartType(ReportChartType.values[i]),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          width: double.infinity,
          child: _SleepLineChart(
            dailyData: dailyData,
            chartType: selectedChartType,
          ),
        ),
      ],
    );
  }
}

/// ===============================
/// 차트
/// ===============================
class _SleepLineChart extends StatelessWidget {
  const _SleepLineChart({required this.dailyData, required this.chartType});
  final List<DailyReportData> dailyData;
  final ReportChartType chartType;

  ({double minY, double maxY, double interval}) _getYAxisValues() {
    switch (chartType) {
      case ReportChartType.totalSleepTime:
        return (minY: 0, maxY: 12, interval: 3);
      case ReportChartType.sleepEfficiency:
        return (minY: 0, maxY: 100, interval: 25);
      case ReportChartType.sleepScore:
        return (minY: 0, maxY: 100, interval: 25);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (int i = 0; i < dailyData.length; i++) {
      if (dailyData[i].hasData) {
        final double yValue;
        switch (chartType) {
          case ReportChartType.totalSleepTime:
            yValue = (dailyData[i].sleepDuration.inMinutes).toDouble() / 60.0;
            break;
          case ReportChartType.sleepEfficiency:
            yValue = (dailyData[i].sleepEfficiency).toDouble();
            break;
          case ReportChartType.sleepScore:
            yValue = (dailyData[i].sleepData!.sleepScore).toDouble();
            break;
        }
        spots.add(FlSpot(i.toDouble(), yValue));
      }
    }

    if (spots.isEmpty) {
      return const Center(child: Text('차트를 표시할 데이터가 없습니다.'));
    }

    final yAxis = _getYAxisValues();

    return LineChart(
      LineChartData(
        minY: yAxis.minY,
        maxY: yAxis.maxY,
        minX: -0.5,
        maxX: dailyData.length.toDouble() - 0.5,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yAxis.interval,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: const Color(0xFFECEFF3), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) =>
                  _bottomTitleWidgets(value, meta, context),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 41,
              interval: yAxis.interval,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xFFE8EBF0)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF7A5AF8),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 3,
                    color: const Color(0xFF7A5AF8),
                    strokeWidth: 1,
                    strokeColor: Colors.white,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF7A5AF8).withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomTitleWidgets(
    double value,
    TitleMeta meta,
    BuildContext context,
  ) {
    final isMonthly = dailyData.length > 7;
    final int index = value.toInt();
    if (value != index.toDouble()) return const SizedBox.shrink();
    if (isMonthly && index % 5 != 0) return const SizedBox.shrink();
    if (index < 0 || index >= dailyData.length) return const SizedBox.shrink();

    final date = dailyData[index].date;
    final String text = isMonthly
        ? DateFormat('d').format(date)
        : DateFormat('E', 'ko_KR').format(date);

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8.0,
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TargetScheduleCard extends StatelessWidget {
  const TargetScheduleCard({
    super.key,
    required this.periodLabel, // 예: '2025년 8월 2주차' 또는 '2025년 8월'
    required this.days, // 길이 N의 날짜 리스트
    required this.actualOnsets, // 길이 N, null이면 데이터 없음
    required this.actualWakes, // 길이 N, null이면 데이터 없음
    required this.targetOnset, // TimeOfDay
    required this.targetWake, // TimeOfDay
  });

  final String periodLabel;
  final List<DateTime> days;
  final List<DateTime?> actualOnsets;
  final List<DateTime?> actualWakes;
  final TimeOfDay targetOnset;
  final TimeOfDay targetWake;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    final onsetStats = _deviationStats(days, actualOnsets, targetOnset);
    final wakeStats = _deviationStats(days, actualWakes, targetWake);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EBF0)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '목표 수면 스케줄',
            style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            periodLabel,
            style: tt.bodySmall?.copyWith(color: const Color(0xFF667085)),
          ),
          const SizedBox(height: 14),

          _rowHeader(context, '입면', onsetStats),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: _Sparkline(
              days: days,
              actual: actualOnsets,
              target: targetOnset,
              color: const Color(0xFF7A5AF8),
              centerAroundMidnight: true,
            ),
          ),

          const SizedBox(height: 16),

          _rowHeader(context, '기상', wakeStats),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: _Sparkline(
              days: days,
              actual: actualWakes,
              target: targetWake,
              color: const Color(0xFF12B886),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowHeader(BuildContext context, String title, _Stats stats) {
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(
          title,
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 8),
        _chip('평균 이탈 ${stats.avg.abs().round()}분', const Color(0xFF475467)),
        const SizedBox(width: 6),
        _chip('정시(±15분) ${stats.onTimeRate}%', const Color(0xFF475467)),
      ],
    );
  }

  Widget _chip(String t, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFE8EBF0)),
      ),
      child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({
    required this.days,
    required this.actual,
    required this.target,
    required this.color,
    this.centerAroundMidnight = false,
  });

  final List<DateTime> days;
  final List<DateTime?> actual;
  final TimeOfDay target;
  final Color color;
  final bool centerAroundMidnight;

  double _transformHour(double hour) {
    if (!centerAroundMidnight) return hour;
    // 12시 이전 시간은 24시간을 더해 다음날로 취급
    return hour < 12 ? hour + 24 : hour;
  }

  double _todToHour(TimeOfDay t) => _transformHour(t.hour + t.minute / 60.0);
  double _dtToHour(DateTime dt) => _transformHour(dt.hour + dt.minute / 60.0);

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (int i = 0; i < days.length; i++) {
      final v = actual[i];
      if (v != null) {
        spots.add(FlSpot(i.toDouble(), _dtToHour(v)));
      }
    }

    final hasData = spots.isNotEmpty;
    final targetH = _todToHour(target);
    final minY = centerAroundMidnight ? 12.0 : 0.0;
    final maxY = centerAroundMidnight ? 36.0 : 24.0;

    return LineChart(
      LineChartData(
        minX: -0.5,
        maxX: days.length - 0.5,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 4,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: const Color(0xFFECEFF3), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 6,
              getTitlesWidget: (v, m) {
                var label = v.toInt();
                if (centerAroundMidnight) {
                  if (label >= 24) label -= 24; // 24시는 0시, 25시는 1시로 표시
                }
                return Text(
                  '${label}h',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: 1,
              getTitlesWidget: (v, m) {
                final i = v.toInt();
                if (v != i.toDouble() || i < 0 || i >= days.length) {
                  return const SizedBox.shrink();
                }
                if (days.length > 14 && i % 2 == 1) {
                  return const SizedBox.shrink();
                }
                return Text(
                  '${days[i].day}',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xFFE8EBF0)),
        ),
        lineBarsData: [
          // 목표 수평선
          LineChartBarData(
            spots: [FlSpot(-0.5, targetH), FlSpot(days.length - 0.5, targetH)],
            color: const Color(0xFF98A2B3),
            barWidth: 2,
            isCurved: false,
            dotData: const FlDotData(show: false),
          ),
          // 실제 데이터
          if (hasData)
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                  radius: 3,
                  color: color,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.18),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stats {
  final double avg; // 평균 이탈(분), +: 늦음, -: 이름
  final int onTimeRate; // ±15분 내 비율(%)
  const _Stats(this.avg, this.onTimeRate);
}

_Stats _deviationStats(
  List<DateTime> days,
  List<DateTime?> actual,
  TimeOfDay target,
) {
  int n = 0;
  double sum = 0;
  int onTime = 0;

  for (int i = 0; i < days.length; i++) {
    final a = actual[i];
    if (a == null) continue;

    final ref = DateTime(
      days[i].year,
      days[i].month,
      days[i].day,
      target.hour,
      target.minute,
    );

    var diff = a.difference(ref).inMinutes;
    diff = diff % 1440;

    if (diff > 720) {
      diff -= 1440;
    } else if (diff < -720) {
      diff += 1440;
    }
    sum += diff;
    n++;

    if (diff.abs() <= 15) onTime++;
  }
  if (n == 0) return const _Stats(0, 0);
  return _Stats(sum / n, ((onTime / n) * 100).round());
}

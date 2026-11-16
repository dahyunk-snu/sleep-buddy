import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:sleepy/src/core/models/sleep_data.dart';
import 'package:sleepy/src/core/models/problematic_event.dart';
import 'package:sleepy/src/core/models/sleep_report.dart';
import 'package:sleepy/src/features/report/presentation/widgets/daily/daily_report_shared.dart';

typedef EventTapArea = ({Rect area, ProblematicEvent event});
typedef SelectedEventInfo = ({Offset position, ProblematicEvent event});

class SleepTimelineCard extends StatefulWidget {
  const SleepTimelineCard({super.key, required this.reportData});
  final DailyReportData reportData;

  @override
  State<SleepTimelineCard> createState() => _SleepTimelineCardState();
}

class _SleepTimelineCardState extends State<SleepTimelineCard> {
  SelectedEventInfo? _selectedEvent;
  List<EventTapArea> _eventTapAreas = [];

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final sleepData = widget.reportData.sleepData!;

    // 1. 이상 행동 횟수 계산
    final eventCounts = sleepData.analysis.problematicEvents
        .groupListsBy((e) => e.type)
        .map((key, value) => MapEntry(key, value.length));

    return reportCard(
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '수면 타임라인',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              '${intl.DateFormat('HH:mm').format(sleepData.startTime)} ~ ${intl.DateFormat('HH:mm').format(sleepData.endTime)}',
              style: tt.bodySmall?.copyWith(color: const Color(0xFF667085)),
            ),
            const SizedBox(height: 16),
            // 타임라인 차트
            GestureDetector(
              onTapDown: (details) {
                final tapPosition = details.localPosition;
                SelectedEventInfo? newSelectedEvent;

                // 탭 영역이 넓은 순서대로(가장 위에 그려진 이벤트) 확인해야 정확
                for (final eventArea in _eventTapAreas.reversed) {
                  if (eventArea.area.contains(tapPosition)) {
                    newSelectedEvent = (
                      position: tapPosition,
                      event: eventArea.event,
                    );
                    break;
                  }
                }
                setState(() => _selectedEvent = newSelectedEvent);
              },
              child: SizedBox(
                height: 80,
                child: CustomPaint(
                  painter: _SleepTimelinePainter(
                    sleepData: sleepData,
                    selectedEvent: _selectedEvent,
                    onAreasPainted: (areas) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _eventTapAreas = areas);
                      });
                    },
                  ),
                  size: const Size(double.infinity, 80),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildTimelineLegend(context),
            if (eventCounts.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade200, height: 1),
              const SizedBox(height: 12),
              _buildProblematicEventsSummary(context, eventCounts),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _legendItem(context, const Color(0xFFC7D2FE), '잠드는 시간'),
        _legendItem(context, const Color(0xFFA5B4FC), '잠에서 깬 시간'),
        _legendItem(context, _eventColor(null), '이상 행동'),
      ],
    );
  }

  Widget _legendItem(BuildContext context, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _buildProblematicEventsSummary(
    BuildContext context,
    Map<ProblematicEventType, int> eventCounts,
  ) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: eventCounts.entries.map((entry) {
        return _buildEventSummaryItem(
          context,
          entry.key.displayName,
          '${entry.value}회',
          _eventIcon(entry.key),
          _eventColor(entry.key),
        );
      }).toList(),
    );
  }

  Widget _buildEventSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

/// =========================================
/// 타임라인 Custom Painter
/// =========================================
class _SleepTimelinePainter extends CustomPainter {
  final SleepData sleepData;
  final SelectedEventInfo? selectedEvent;
  final Function(List<EventTapArea>) onAreasPainted;

  _SleepTimelinePainter({
    required this.sleepData,
    required this.selectedEvent,
    required this.onAreasPainted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = sleepData.endTime.difference(sleepData.startTime);
    if (total.inSeconds <= 0) return;

    final List<EventTapArea> currentTapAreas = [];
    const barHeight = 28.0;
    final barY = size.height / 2 - barHeight / 2;
    final barRadius = Radius.circular(barHeight / 2);

    final bgPaint = Paint()..color = Colors.grey.shade200;
    final sleepPaint = Paint()..color = const Color(0xFF7A5AF8);
    final awakePaint = Paint()..color = const Color(0xFFA5B4FC);
    final latencyPaint = Paint()..color = const Color(0xFFC7D2FE);

    final barRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, barY, size.width, barHeight),
      barRadius,
    );

    // 1. 배경 바
    canvas.drawRRect(barRRect, bgPaint);

    // 2. 실제 수면 구간
    canvas.drawRRect(barRRect, sleepPaint);

    // --- 그리기 영역을 둥근 막대 안으로 제한하여 모서리 유지 ---
    canvas.save();
    canvas.clipRRect(barRRect);

    // 3. 이상 행동 (우선순위 낮음 - 가장 먼저 그림)
    final events = sleepData.analysis.problematicEvents
        .where((e) => e.time != null)
        .toList();
    for (final e in events) {
      final paint = Paint()..color = _eventColor(null);
      final ratio =
          e.time!.difference(sleepData.startTime).inSeconds / total.inSeconds;
      final x = ratio * size.width;
      const eventWidth = 2.0; // 얇은 두께
      canvas.drawRect(
        Rect.fromLTWH(x - eventWidth / 2, barY, eventWidth, barHeight),
        paint,
      );

      currentTapAreas.add((
        area: Rect.fromLTWH(x - 8, 0, 16, size.height), // 탭 영역
        event: e,
      ));
    }

    // 4. 중간에 깬 시간 (이상 행동 위에 덧칠)
    for (final awake in sleepData.analysis.awakeningTimes) {
      final startRatio =
          awake.start.difference(sleepData.startTime).inSeconds /
          total.inSeconds;
      final endRatio =
          awake.end.difference(sleepData.startTime).inSeconds / total.inSeconds;
      final startX = startRatio * size.width;
      final endX = endRatio * size.width;
      final eventWidth = max(2.0, endX - startX);
      canvas.drawRect(
        Rect.fromLTWH(startX, barY, eventWidth, barHeight),
        awakePaint,
      );
    }

    // 5. 잠드는 시간 (우선순위 높음 - 가장 마지막에 그림)
    final latencyRatio =
        sleepData.analysis.timeToFallAsleep.inSeconds / total.inSeconds;
    final latencyWidth = latencyRatio * size.width;
    if (latencyWidth > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, barY, latencyWidth, barHeight),
        latencyPaint,
      );
    }

    // --- 그리기 영역 제한 해제 ---
    canvas.restore();

    // 6. 선택된 이벤트 정보 표시 (툴팁)
    if (selectedEvent != null) {
      final tp = TextPainter(
        text: TextSpan(
          text:
              '${selectedEvent!.event.type.displayName} ${intl.DateFormat('HH:mm').format(selectedEvent!.event.time!)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final tooltipPaint = Paint()..color = Colors.black.withValues(alpha: 0.7);
      final tooltipPadding = const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      );
      final tooltipRect = Rect.fromLTWH(
        0,
        0,
        tp.width + tooltipPadding.horizontal,
        tp.height + tooltipPadding.vertical,
      );

      var dx = selectedEvent!.position.dx - tooltipRect.width / 2;
      if (dx < 0) dx = 0;
      if (dx + tooltipRect.width > size.width) {
        dx = size.width - tooltipRect.width;
      }
      final dy = barY - tooltipRect.height - 6;

      final rrect = RRect.fromRectAndRadius(
        tooltipRect.shift(Offset(dx, dy)),
        const Radius.circular(4),
      );

      canvas.drawRRect(rrect, tooltipPaint);
      tp.paint(
        canvas,
        Offset(dx + tooltipPadding.left, dy + tooltipPadding.top),
      );
    }

    onAreasPainted(currentTapAreas);
  }

  @override
  bool shouldRepaint(covariant _SleepTimelinePainter old) {
    return old.selectedEvent != selectedEvent || old.sleepData != sleepData;
  }
}

Color _eventColor(ProblematicEventType? t) => switch (t) {
  ProblematicEventType.snoring => Colors.orange.shade700,
  ProblematicEventType.restlessness => Colors.teal.shade400,
  ProblematicEventType.noise => Colors.blueGrey.shade400,
  ProblematicEventType.breathingIssue => Colors.red.shade600,
  ProblematicEventType.urinaryIssue => Colors.lightBlue.shade500,
  null => Colors.orange, // For legend
};

IconData _eventIcon(ProblematicEventType t) => switch (t) {
  ProblematicEventType.snoring => Icons.volume_up_rounded,
  ProblematicEventType.restlessness => Icons.king_bed_rounded,
  ProblematicEventType.noise => Icons.hearing_rounded,
  ProblematicEventType.breathingIssue => Icons.air_rounded,
  ProblematicEventType.urinaryIssue => Icons.wc_rounded,
};

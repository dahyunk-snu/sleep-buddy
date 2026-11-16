import 'package:flutter/material.dart';

/// 정돈된 Tip 카드 + 시각화 바
class TipCard extends StatelessWidget {
  const TipCard({
    super.key, 
    required this.recLabel,
    required this.recMin,
    required this.recMax,
    required this.avgBed,
    required this.avgWake,
    required this.avgHours,
    required this.goalBed,
    required this.goalWake,
    required this.goalHours,
    required this.fmtTod,
    required this.fmtDur,
  });

  final String recLabel;
  final double recMin;
  final double recMax;

  final TimeOfDay? avgBed;
  final TimeOfDay? avgWake;
  final double? avgHours;

  final TimeOfDay? goalBed;
  final TimeOfDay? goalWake;
  final double? goalHours;

  final String Function(TimeOfDay) fmtTod;
  final String Function(Duration) fmtDur;

  @override
  Widget build(BuildContext context) {
    final hasAvg = avgBed != null && avgWake != null && avgHours != null;
    final hasGoal = goalBed != null && goalWake != null && goalHours != null;

    // 게이지 범위: 5h ~ 14h 사이로 통일(권장 범위와 값 모두 포함)
    const minGauge = 5.0;
    const maxGauge = 14.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: const [
              Text('요약 & Tip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),

          // 값 배치: 배지 형태로 간결하게
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Badge(label: '권장', value: '$recLabel  ${recMin.toStringAsFixed(0)}–${recMax.toStringAsFixed(0)}시간'),
              if (hasAvg) _Badge(label: '평소',
                value: '${fmtTod(avgBed!)} → ${fmtTod(avgWake!)}  (${avgHours!.toStringAsFixed(1)}시간)'),
              if (hasGoal) _Badge(label: '목표',
                value: '${fmtTod(goalBed!)} → ${fmtTod(goalWake!)}  (${goalHours!.toStringAsFixed(1)}시간)'),
            ],
          ),

          const SizedBox(height: 12),

          // 시각화 바: 권장 범위(밴드) + 평소/목표 마커
          _RangeBar(
            min: minGauge,
            max: maxGauge,
            recMin: recMin,
            recMax: recMax,
            avg: hasAvg ? avgHours : null,
            goal: hasGoal ? goalHours : null,
          ),

          const SizedBox(height: 8),

          // 보조 설명
          if (hasGoal)
            Text(
              _compareToRange(goalHours!, recMin, recMax),
              style: const TextStyle(color: Colors.white, fontSize: 13),
            )
          else
            const Text(
              '목표 취침/기상 시간을 선택하면 권장 범위와의 차이를 확인할 수 있어요.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
        ],
      ),
    );
  }

  String _compareToRange(double hours, double minR, double maxR) {
    if (hours < minR) return '권장 대비 ${(minR - hours).toStringAsFixed(1)}시간 부족해요.';
    if (hours > maxR) return '권장 대비 ${(hours - maxR).toStringAsFixed(1)}시간 많아요.';
    return '권장 범위 안에 있어요. 잘하고 있어요!';
  }
}

/// 라벨 배지
class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF374151), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

/// 권장 범위(밴드) + 평소/목표 마커
class _RangeBar extends StatelessWidget {
  const _RangeBar({
    required this.min,
    required this.max,
    required this.recMin,
    required this.recMax,
    this.avg,
    this.goal,
  });

  final double min;    // 게이지 최소 (예: 5h)
  final double max;    // 게이지 최대 (예: 14h)
  final double recMin; // 권장 범위 최소
  final double recMax; // 권장 범위 최대
  final double? avg;   // 평소 수면시간
  final double? goal;  // 목표 수면시간

  double _pos(double v) {
    final clamped = v.clamp(min, max);
    return (clamped - min) / (max - min);
  }
  
  String _hLabel(double h) => h % 1 == 0 ? '${h.toStringAsFixed(0)}h' : '${h.toStringAsFixed(1)}h';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth;
        final bandL = w * _pos(recMin);
        final bandR = w * _pos(recMax);

        final avgX  = (avg  != null) ? w * _pos(avg!)  : null;
        final goalX = (goal != null) ? w * _pos(goal!) : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 28),
              // 트랙 + 권장 밴드
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(height: 10, decoration: BoxDecoration(
                    color: const Color(0xFF374151), borderRadius: BorderRadius.circular(999),
                  )),
                  Positioned(
                    left: bandL, right: w - bandR, top: 0, bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981), // 권장 범위(초록)
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                    if (avgX != null)
                      Positioned(
                        left: avgX - _MarkerLine.markerWidth/2,
                        top: -12, // 선+삼각형이 트랙 위로 살짝 나오도록
                        child: _MarkerLine(
                          label:  _hLabel(avg!),
                          color: const Color(0xFF60A5FA), // 파란색(평소)
                        ),
                      ),
                    if (goalX != null)
                      Positioned(
                        left: goalX - _MarkerLine.markerWidth/2,
                        top: -12,
                        child: _MarkerLine(
                          label:  _hLabel(goal!),
                          color: const Color(0xFFF59E0B), // 주황색(목표)
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${min.toStringAsFixed(0)}h', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                Text('${max.toStringAsFixed(0)}h', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            )
          ],
        );
      },
    );
  }
}

/// 세로선 + 역삼각형 팁 + 아래 텍스트 라벨
class _MarkerLine extends StatelessWidget {
  const _MarkerLine({required this.label, required this.color});

  final String label;
  final Color color;

  static const double markerWidth = 44;
  static const double lineHeight  = 22;
  static const double lineWidth   = 2;
  static const double triW        = 12;
  static const double triH        = 7;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 역삼각형 팁(위, 아래를 향해 뾰족)
        CustomPaint(
          size: const Size(triW, triH),
          painter: _TriangleDownPainter(color),
        ),
        // 세로선
        Container(
          width: lineWidth,
          height: lineHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 4),
        // 아래 라벨(시간)
        Container(
          width: markerWidth,
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// 역삼각형(아래를 향한 tip) 그리기
class _TriangleDownPainter extends CustomPainter {
  _TriangleDownPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    // 테두리를 흰색으로 살짝 강조하고 싶다면 아래 줄도 추가:
    // final border = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5;

    canvas.drawPath(path, paint);
    // canvas.drawPath(path, border); // 테두리 사용 시 주석 해제
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'dart:math' as math show pi;
import 'package:flutter/material.dart';
import 'package:sleepy/src/core/models/sleep_routine.dart';

/// 카드 래퍼 (일관된 라운드/보더)
Widget reportCard(Widget child) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE8EBF0)),
    ),
    child: child,
  );
}

/// 2분할 세그먼트 (주간/월간 등)
class ReportSegmentedTwo extends StatelessWidget {
  const ReportSegmentedTwo({
    super.key,
    required this.a,
    required this.b,
    required this.isA,
    required this.onTap,
  });
  final String a, b;
  final bool isA;
  final ValueChanged<bool> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _segItem(context, a, isA, () => onTap(true)),
          _segItem(context, b, !isA, () => onTap(false)),
        ],
      ),
    );
  }

  Widget _segItem(
    BuildContext context,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: selected ? const Color(0xFF101828) : const Color(0xFF667085),
          ),
        ),
      ),
    );
  }
}

/// 3분할 세그먼트 (총 수면/각성/점수)
class ReportSegmentedThree extends StatelessWidget {
  const ReportSegmentedThree({
    super.key,
    required this.labels,
    required this.index,
    required this.onTap,
  });
  final List<String> labels;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == index;
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? const Color(0xFF101828)
                      : const Color(0xFF667085),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// 도넛 게이지 (레이블 포함)
class DonutGauge extends StatelessWidget {
  const DonutGauge({
    super.key,
    required this.percent, // 0~1
    required this.label, // 중앙 텍스트 (예: '82')
    this.trackColor = const Color(0xFFE8EBF0),
    this.fillColor = const Color(0xFF12B886),
    this.size = 88,
    this.stroke = 10,
  });

  final double percent;
  final String label;
  final Color trackColor;
  final Color fillColor;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutGaugePainter(
          percent: percent,
          trackColor: trackColor,
          fillColor: fillColor,
          label: label,
          stroke: stroke,
        ),
      ),
    );
  }
}

class _DonutGaugePainter extends CustomPainter {
  final double percent;
  final Color trackColor;
  final Color fillColor;
  final String label;
  final double stroke;

  _DonutGaugePainter({
    required this.percent,
    required this.trackColor,
    required this.fillColor,
    required this.label,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;

    final prog = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = fillColor;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, track);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * percent, false, prog);

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF101828),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _DonutGaugePainter old) {
    return old.percent != percent ||
        old.fillColor != fillColor ||
        old.label != label ||
        old.stroke != stroke;
  }
}

/// 환경 라벨 & 점수 & 색상 (Daily/Weekly/Monthly 공통)
String lightLabel(LightCondition l) => switch (l) {
  LightCondition.dark => '어두움',
  LightCondition.nightLight => '수면등',
  LightCondition.dim => '희미함',
  LightCondition.normal => '보통',
  LightCondition.bright => '밝음',
};

String soundLabel(SoundCondition s) => switch (s) {
  SoundCondition.quiet => '조용함',
  SoundCondition.whiteNoise => '백색소음',
  SoundCondition.noisy => '주변소음',
};

double scoreLight(LightCondition l) => switch (l) {
  LightCondition.dark => 1.0,
  LightCondition.nightLight => 0.85,
  LightCondition.dim => 0.7,
  LightCondition.normal => 0.3,
  LightCondition.bright => 0.0,
};

double scoreSound(SoundCondition s) => switch (s) {
  SoundCondition.quiet => 1.0,
  SoundCondition.whiteNoise => 0.7,
  SoundCondition.noisy => 0.0,
};

Color scoreColor(double pOrScore) {
  final p = pOrScore > 1.0 ? (pOrScore / 100.0) : pOrScore;
  if (p >= 0.8) return const Color(0xFF12B886);
  if (p >= 0.6) return const Color(0xFF2E90FA);
  if (p >= 0.4) return const Color(0xFFF79009);
  return const Color(0xFFF04438);
}

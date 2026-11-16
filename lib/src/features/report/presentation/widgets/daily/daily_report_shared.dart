import 'package:flutter/material.dart';

/// 일일 리포트 카드들의 기본 스타일을 정의하는 공유 위젯
Widget reportCard(Widget child) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

/// 점수(0~100) 또는 비율(0~1)에 따라 색상을 반환하는 공유 함수
Color scoreColor(double pOrScore) {
  final p = pOrScore > 1.0 ? (pOrScore / 100.0) : pOrScore;
  if (p >= 0.8) return const Color(0xFF12B886);
  if (p >= 0.6) return const Color(0xFF2E90FA);
  if (p >= 0.4) return const Color(0xFFF79009);
  return const Color(0xFFF04438);
}

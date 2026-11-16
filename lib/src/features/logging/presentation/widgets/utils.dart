import 'package:flutter/material.dart';
import 'package:sleepy/src/core/models/sleep_data.dart';

// MorningCondition → 아이콘/컬러 매핑
IconData condIcon(MorningCondition c) => switch (c) {
  MorningCondition.veryGood => Icons.sentiment_very_satisfied_rounded,
  MorningCondition.good => Icons.sentiment_satisfied_alt_rounded,
  MorningCondition.neutral => Icons.sentiment_neutral_rounded,
  MorningCondition.bad => Icons.sentiment_dissatisfied_rounded,
  MorningCondition.veryBad => Icons.sentiment_very_dissatisfied_rounded,
};

Color condColor(MorningCondition c) => switch (c) {
  MorningCondition.veryGood => const Color(0xFF12B886),
  MorningCondition.good => const Color(0xFF2FB36C),
  MorningCondition.neutral => const Color(0xFF868E96),
  MorningCondition.bad => const Color(0xFFFA8C16),
  MorningCondition.veryBad => const Color(0xFFF03E3E),
};

// 배경 그라데이션 (routine_start_screen과 동일 팔레트)
List<Color> bgForSession(SleepSessionType t) {
  if (t == SleepSessionType.night) {
    return const [Color(0xFF0D1B2A), Color(0xFF192A46), Color(0xFF304C78)];
  }
  return const [Color(0xFF87CEFA), Color(0xFFE6F3FF), Color(0xFFFFF2CC)];
}

// 공용 카드
Widget card(Widget child) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE8EBF0)),
    ),
    padding: const EdgeInsets.all(16),
    child: child,
  );
}

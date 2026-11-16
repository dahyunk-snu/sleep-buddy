import 'package:flutter/material.dart';
import 'package:sleepy/src/features/report/presentation/widgets/week/target_schedule_card.dart';

class TargetScheduleSection extends StatelessWidget {
  const TargetScheduleSection({
    super.key,
    required this.periodTitle,
    required this.days,
    required this.actualOnsets,
    required this.actualWakes,
    required this.targetOnset,
    required this.targetWake,
  });

  final String periodTitle;
  final List<DateTime> days;
  final List<DateTime?> actualOnsets;
  final List<DateTime?> actualWakes;
  final TimeOfDay targetOnset;
  final TimeOfDay targetWake;

  @override
  Widget build(BuildContext context) {
    return TargetScheduleCard(
      periodLabel: periodTitle,
      days: days,
      actualOnsets: actualOnsets,
      actualWakes: actualWakes,
      targetOnset: targetOnset,
      targetWake: targetWake,
    );
  }
}

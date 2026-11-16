import 'package:flutter/material.dart';
import 'package:sleepy/src/features/report/presentation/widgets/week/report_shared.dart';

class CoachingSection extends StatelessWidget {
  const CoachingSection({super.key, required this.tips});
  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '수면 코칭',
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ...tips.map(
          (tip) => reportCard(
            ListTile(
              leading: const Icon(
                Icons.lightbulb_outline,
                color: Color(0xFFF79009),
              ),
              title: Text(tip),
              dense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sleepy/src/core/models/sleep_data.dart';
import 'package:sleepy/src/core/services/auth_service.dart';
import 'package:sleepy/src/core/services/database_service.dart';
import 'package:sleepy/src/features/dashboard/application/dashboard_notifier.dart';

import 'package:sleepy/src/features/report/presentation/widgets/week/report_shared.dart';
import 'package:sleepy/src/features/report/application/routine_summary.dart';

typedef _SleepQuery = ({
  String uid,
  String childId,
  DateTime start,
  DateTime end,
});

final _sleepDataForPeriodProvider = FutureProvider.autoDispose
    .family<List<SleepData>, _SleepQuery>((ref, q) async {
      // DB 인스턴스는 watch가 아니라 read로 (불필요 리빌드 방지)
      final db = ref.read(databaseServiceProvider);
      return db.getSleepDataForPeriod(q.uid, q.childId, q.start, q.end);
    });

/// ===============================
/// RoutineAdherenceCard
/// ===============================

class RoutineAdherenceCard extends ConsumerWidget {
  const RoutineAdherenceCard({
    super.key,
    required this.startDate,
    required this.endDate,
    this.showCorrelation = false,
  });

  final DateTime startDate;
  final DateTime endDate;
  final bool showCorrelation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final user = ref.watch(authServiceProvider).currentUser;
    final childId = ref.watch(
      dashboardNotifierProvider.select((s) => s.selectedChildId),
    );

    if (user == null || childId == null) {
      return reportCard(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '루틴 데이터를 불러오지 못했어요.',
            style: tt.bodyMedium?.copyWith(color: const Color(0xFF667085)),
          ),
        ),
      );
    }

    final asyncSleeps = ref.watch(
      _sleepDataForPeriodProvider((
        uid: user.uid,
        childId: childId,
        start: startDate,
        end: endDate,
      )),
    );

    return asyncSleeps.when(
      loading: () => reportCard(
        const Padding(
          padding: EdgeInsets.all(16),
          child: LinearProgressIndicator(minHeight: 8),
        ),
      ),
      error: (e, _) => reportCard(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '표본 데이터가 부족해요.',
            style: tt.bodyMedium?.copyWith(color: const Color(0xFF667085)),
          ),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return reportCard(
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '표본 데이터가 부족해요.',
                style: tt.bodyMedium?.copyWith(color: const Color(0xFF667085)),
              ),
            ),
          );
        }

        final sample = pickMainSleepsByDay(list);
        final summary = summarizeRoutine(sample);
        final insights = showCorrelation
            ? analyzeCorrelations(sample)
            : <String>[];

        return reportCard(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '루틴 이행',
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    DonutGauge(
                      percent: summary.percent,
                      fillColor: scoreColor(summary.percent),
                      label: '${summary.score}',
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _envRow(
                            context,
                            '조명',
                            summary.lightModeLabel,
                            summary.lightAvg,
                            icon: Icons.nights_stay_rounded,
                          ),
                          const SizedBox(height: 6),
                          _envRow(
                            context,
                            '소리',
                            summary.soundModeLabel,
                            summary.soundAvg,
                            icon: Icons.volume_down_rounded,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${sample.length}일 표본 평균',
                              style: tt.bodySmall?.copyWith(
                                color: const Color(0xFF667085),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: summary.chips.map((c) {
                    final col = c.done
                        ? const Color(0xFF12B886)
                        : const Color(0xFF98A2B3);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: col.withValues(alpha: 0.55)),
                        color: c.done
                            ? col.withValues(alpha: 0.08)
                            : Colors.white,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            c.done ? Icons.check_rounded : Icons.remove_rounded,
                            size: 16,
                            color: col,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${c.label} ${c.hit}/${c.total}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: col,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                if (showCorrelation && insights.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Divider(color: Colors.grey.shade200, height: 1),
                  const SizedBox(height: 14),
                  Text(
                    '습관-수면 연관성 분석 💡',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...insights.map(
                    (text) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 3),
                            child: Icon(
                              Icons.check_circle_outline_rounded,
                              size: 16,
                              color: Color(0xFF12B886),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              text,
                              style: tt.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _envRow(
    BuildContext context,
    String title,
    String valueLabel,
    double frac, {
    required IconData icon,
  }) {
    final col = scoreColor(frac);
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF475467)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 8,
              color: col,
              backgroundColor: const Color(0xFFE8EBF0),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(valueLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

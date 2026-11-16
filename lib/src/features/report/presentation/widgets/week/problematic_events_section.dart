import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sleepy/src/core/models/problematic_event.dart';
import 'package:sleepy/src/core/models/sleep_data.dart';
import 'package:sleepy/src/core/services/auth_service.dart';
import 'package:sleepy/src/core/services/database_service.dart';
import 'package:sleepy/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:sleepy/src/features/report/presentation/widgets/week/report_shared.dart';

typedef _ProblematicEventsQuery = ({
  String uid,
  String childId,
  DateTime start,
  DateTime end,
});

final _problematicEventsProvider = FutureProvider.autoDispose
    .family<List<SleepData>, _ProblematicEventsQuery>((ref, q) async {
      final db = ref.read(databaseServiceProvider);
      return db.getSleepDataForPeriod(q.uid, q.childId, q.start, q.end);
    });

class ProblematicEventsSection extends ConsumerWidget {
  const ProblematicEventsSection({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

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
            '이상 행동 데이터를 불러오지 못했어요.',
            style: tt.bodyMedium?.copyWith(color: const Color(0xFF667085)),
          ),
        ),
      );
    }

    final asyncSleeps = ref.watch(
      _problematicEventsProvider((
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

        final counts = <ProblematicEventType, int>{
          for (final t in ProblematicEventType.values) t: 0,
        };

        for (final sd in list) {
          for (final e in sd.analysis.problematicEvents) {
            counts[e.type] = (counts[e.type] ?? 0) + 1;
          }
        }

        final entries = counts.entries.where((e) => e.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return reportCard(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이상 행동 요약',
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entries.map((e) {
                    final col = _eventColor(e.key);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: col.withAlpha(90)),
                        color: col.withAlpha(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: col,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_label(e.key)} ${e.value}회',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                if (entries.isNotEmpty)
                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 2,
                              getTitlesWidget: (v, m) => Text(
                                v.toInt().toString(),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (v, m) {
                                final idx = v.toInt();
                                if (idx < 0 || idx >= entries.length) {
                                  return const SizedBox.shrink();
                                }
                                final t = entries[idx].key;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    _shortLabel(t),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: List.generate(entries.length.clamp(0, 6), (
                          i,
                        ) {
                          final e = entries[i];
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: e.value.toDouble(),
                                width: 18,
                                borderRadius: BorderRadius.circular(6),
                                color: _eventColor(e.key),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      '기록된 이상 행동이 없습니다.',
                      style: tt.bodyMedium?.copyWith(
                        color: const Color(0xFF667085),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _eventColor(ProblematicEventType t) {
    switch (t) {
      case ProblematicEventType.snoring:
        return const Color(0xFF7A5AF8);
      case ProblematicEventType.restlessness:
        return const Color(0xFFF59E0B);
      case ProblematicEventType.noise:
        return const Color(0xFF3B82F6);
      case ProblematicEventType.breathingIssue:
        return const Color(0xFF8B5CF6);
      case ProblematicEventType.urinaryIssue:
        return const Color(0xFF6366F1);
    }
  }

  String _label(ProblematicEventType t) => t.displayName;

  String _shortLabel(ProblematicEventType t) {
    switch (t) {
      case ProblematicEventType.snoring:
        return '코골이';
      case ProblematicEventType.restlessness:
        return '뒤척임';
      case ProblematicEventType.noise:
        return '소음';
      case ProblematicEventType.breathingIssue:
        return '호흡';
      case ProblematicEventType.urinaryIssue:
        return '비뇨';
    }
  }
}

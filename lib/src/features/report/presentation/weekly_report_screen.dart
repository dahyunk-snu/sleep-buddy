import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sleepy/src/core/models/child_profile.dart';
import 'package:sleepy/src/core/models/sleep_report.dart';
import 'package:sleepy/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:sleepy/src/features/report/application/report_controller.dart';
import 'package:sleepy/src/features/report/presentation/widgets/week/report_shared.dart';
import 'package:sleepy/src/features/report/presentation/widgets/week/routine_adherence_card.dart';
import 'package:sleepy/src/features/report/presentation/widgets/week/problematic_events_section.dart';
import 'package:sleepy/src/features/report/presentation/widgets/week/score_card.dart';
import 'package:sleepy/src/features/report/presentation/utils/utils.dart';
import 'package:sleepy/src/features/report/presentation/widgets/week/target_schedule.dart';
import 'package:sleepy/src/features/report/presentation/widgets/week/coaching_section.dart';
import 'package:sleepy/src/features/report/presentation/widgets/week/chart.dart';

/// ===============================
/// WeeklyReportScreen
/// ===============================
class WeeklyReportScreen extends ConsumerWidget {
  const WeeklyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportState = ref.watch(reportControllerProvider);
    final controller = ref.read(reportControllerProvider.notifier);

    final childId = ref.watch(
      dashboardNotifierProvider.select((d) => d.selectedChildId),
    );

    final asyncReport = childId == null
        ? AsyncValue.error('아이를 선택해주세요.', StackTrace.current)
        : ref.watch(
            reportProvider(
              childId,
              reportState.reportType,
              reportState.selectedDate,
            ),
          );

    return Scaffold(
      appBar: AppBar(title: const Text('수면 리포트')),
      body: Column(
        children: [
          // 상단 컨트롤
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ReportSegmentedTwo(
                  a: '주간',
                  b: '월간',
                  isA: reportState.reportType == ReportType.weekly,
                  onTap: (isA) => controller.changeReportType(
                    isA ? ReportType.weekly : ReportType.monthly,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      periodLabel(
                        reportState.reportType,
                        reportState.selectedDate,
                      ),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final newDate = await showDatePicker(
                          context: context,
                          initialDate: reportState.selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          locale: const Locale('ko'),
                        );
                        if (newDate != null) {
                          controller.changeSelectedDate(newDate);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 리포트 본문
          Expanded(
            child: asyncReport.when(
              data: (report) => _ReportDataView(report: report),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('리포트 로딩 오류:\n$e', textAlign: TextAlign.center),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportDataView extends ConsumerStatefulWidget {
  const _ReportDataView({required this.report});
  final SleepReport report;

  @override
  ConsumerState<_ReportDataView> createState() => _ReportDataViewState();
}

class _ReportDataViewState extends ConsumerState<_ReportDataView> {
  late final ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ⬇︎ select로 필요한 필드만 watch (차트 변경이 여기까지 전파되지 않게)
    final reportType = ref.watch(
      reportControllerProvider.select((s) => s.reportType),
    );
    final selectedDate = ref.watch(
      reportControllerProvider.select((s) => s.selectedDate),
    );

    // child/profile 안전 조회
    final child = ref.watch(
      dashboardNotifierProvider.select((d) {
        final id = d.selectedChildId;
        final list = d.childProfiles.asData?.value ?? const <ChildProfile>[];
        if (id == null) return null;
        for (final p in list) {
          if (p.id == id) return p;
        }
        return null;
      }),
    );

    final recordedDays = widget.report.dailyData
        .where((d) => d.hasData)
        .toList();
    if (recordedDays.isEmpty) {
      return const Center(child: Text('이번 기간의 수면 데이터가 없습니다.'));
    }

    // 공통 데이터 준비
    final days = widget.report.dailyData.map((e) => e.date).toList();
    final actualOnsets = widget.report.dailyData
        .map((e) => e.actualOnset)
        .toList();
    final actualWakes = widget.report.dailyData
        .map((e) => e.actualWake)
        .toList();

    final DateTime startDate = (widget.report.dailyData.first.date);
    final DateTime endDate = (widget.report.dailyData.last.date).add(
      const Duration(hours: 23, minutes: 59, seconds: 59),
    );

    final periodTitle = periodLabel(reportType, selectedDate);

    return SingleChildScrollView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1) 종합 점수 카드
          ScoreCardSection(title: periodTitle, report: widget.report),
          const SizedBox(height: 16),

          // 2) 타겟 스케줄 카드
          if (child != null)
            TargetScheduleSection(
              periodTitle: periodTitle,
              days: days,
              actualOnsets: actualOnsets,
              actualWakes: actualWakes,
              targetOnset: parseHHmm(child.goalBedTime),
              targetWake: parseHHmm(child.goalWakeUpTime),
            ),
          if (child != null) const SizedBox(height: 24),

          // 3) 루틴 이행 카드
          RoutineAdherenceCard(
            startDate: startDate,
            endDate: endDate,
            showCorrelation: true,
          ),
          const SizedBox(height: 24),

          // 4) 차트 & 세그먼트 (이 블록만 chartType 변화에 반응)
          ChartSection(dailyData: widget.report.dailyData),
          const SizedBox(height: 24),

          // 4.5) 이상 행동 섹션 추가
          ProblematicEventsSection(startDate: startDate, endDate: endDate),
          const SizedBox(height: 24),

          // 5) 코칭 (기존 tips 유지)
          CoachingSection(tips: widget.report.coachingTips),
        ],
      ),
    );
  }
}

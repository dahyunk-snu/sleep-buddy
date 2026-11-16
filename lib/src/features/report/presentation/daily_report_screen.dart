import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:sleepy/src/core/models/child_profile.dart';
import 'package:sleepy/src/core/models/sleep_report.dart';
import 'package:sleepy/src/features/report/presentation/widgets/daily/summary_card.dart';
import 'package:sleepy/src/features/report/presentation/widgets/daily/sleep_timeline_card.dart';
//import 'package:sleepy/src/features/report/presentation/widgets/daily/routine_adherence_card.dart';

class DailyReportScreen extends ConsumerWidget {
  const DailyReportScreen({
    super.key,
    required this.child,
    required this.report,
  });
  final ChildProfile child;
  final DailyReportData report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!report.hasData) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('해당 날짜의 수면 데이터가 없습니다.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${intl.DateFormat('M월 d일').format(report.date)}의 수면'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // 1. 요약 + 핵심 지표 카드
          SummaryCard(child: child, report: report),
          const SizedBox(height: 20),

          // 2. 수면 타임라인 카드
          SleepTimelineCard(reportData: report),
          const SizedBox(height: 20),

          // 3. 루틴 이행 카드
          //RoutineAdherenceCard(reportData: reportData),
        ],
      ),
    );
  }
}

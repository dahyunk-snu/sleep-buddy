import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sleepy/src/core/models/sleep_data.dart';
import 'package:sleepy/src/core/models/sleep_report.dart';
import 'package:sleepy/src/core/services/auth_service.dart';
import 'package:sleepy/src/core/services/database_service.dart';

import 'package:collection/collection.dart';

part 'report_controller.g.dart';

@riverpod
Future<SleepReport> report(
  Ref ref,
  String childId,
  ReportType reportType,
  DateTime selectedDate,
) async {
  // 1. User와 Child Profile 로드
  final user = ref.watch(authServiceProvider).currentUser;
  if (user == null) {
    throw Exception('로그인이 필요합니다.');
  }
  final databaseService = ref.read(databaseServiceProvider);
  final childProfile = await databaseService.getChildProfile(user.uid, childId);
  if (childProfile == null) {
    throw Exception('아동 프로필을 불러올 수 없습니다. 다시 시도해주세요.');
  }

  // 2. 리포트 기간의 수면 데이터 로드
  final (startDate, endDate) = _calculateDateRange(reportType, selectedDate);
  final daysInPeriod = endDate.difference(startDate).inDays + 1;

  final List<SleepData> sleepDataList = await databaseService
      .getSleepDataForPeriod(user.uid, childId, startDate, endDate);

  // 3. 일일 리포트 리스트 생성
  final groupedByDay = groupBy(sleepDataList, (sleepData) => sleepData.date);
  final dailyData = List.generate(daysInPeriod, (i) {
    final date = startDate.add(Duration(days: i));
    final recordsOnDay = groupedByDay[date];

    if (recordsOnDay == null || recordsOnDay.isEmpty) {
      // 해당 날짜에 데이터가 없으면 'empty' 모델 생성
      return DailyReportData.empty(date);
    } else {
      // 데이터가 있으면 가장 긴 수면을 찾아 'fromSleepData' 모델 생성
      final mainSleep = recordsOnDay.reduce(
        (a, b) =>
            a.endTime.difference(a.startTime) >
                b.endTime.difference(b.startTime)
            ? a
            : b,
      );
      return DailyReportData.fromSleepData(mainSleep);
    }
  });
  final reportId = reportType == ReportType.weekly
      ? '${startDate.year}-W${DateFormat('w').format(startDate)}'
      : '${startDate.year}-${startDate.month}';

  // 4. 최종 리포트 생성
  return SleepReport(
    reportId: reportId,
    period: reportId,
    dailyData: dailyData,
    goalBedTimeString: childProfile.goalBedTime,
    goalWakeUpTimeString: childProfile.goalWakeUpTime,
  );
}

(DateTime, DateTime) _calculateDateRange(ReportType type, DateTime date) {
  final endDate = DateTime(date.year, date.month, date.day);

  if (type == ReportType.weekly) {
    // 주간 리포트: 선택된 날짜로부터 6일 전까지 (총 7일)
    final startDate = endDate.subtract(const Duration(days: 6));
    return (startDate, endDate);
  } else {
    // 월간 리포트: 선택된 날짜로부터 29일 전까지 (총 30일)
    final startDate = endDate.subtract(const Duration(days: 29));
    return (startDate, endDate);
  }
}

enum ReportChartType { totalSleepTime, sleepEfficiency, sleepScore }

enum ReportType { weekly, monthly }

class ReportScreenState extends Equatable {
  const ReportScreenState({
    this.reportType = ReportType.weekly,
    this.selectedChartType = ReportChartType.totalSleepTime,
    required this.selectedDate,
  });

  final ReportType reportType;
  final ReportChartType selectedChartType;
  final DateTime selectedDate;

  ReportScreenState copyWith({
    ReportType? reportType,
    ReportChartType? selectedChartType,
    DateTime? selectedDate,
  }) {
    return ReportScreenState(
      reportType: reportType ?? this.reportType,
      selectedChartType: selectedChartType ?? this.selectedChartType,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }

  @override
  List<Object?> get props => [reportType, selectedChartType, selectedDate];
}

@riverpod
class ReportController extends _$ReportController {
  @override
  ReportScreenState build() {
    return ReportScreenState(
      selectedDate: DateTime.now(),
      selectedChartType: ReportChartType.totalSleepTime,
    );
  }

  void changeReportType(ReportType newType) {
    state = state.copyWith(reportType: newType);
  }

  void changeSelectedDate(DateTime newDate) {
    state = state.copyWith(selectedDate: newDate);
  }

  void changeChartType(ReportChartType newType) {
    state = state.copyWith(selectedChartType: newType);
  }
}

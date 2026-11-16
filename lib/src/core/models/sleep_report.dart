import 'dart:math';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:sleepy/src/core/models/sleep_data.dart';
import 'package:sleepy/src/core/models/sleep_routine.dart';

class DailyReportData extends Equatable {
  final DateTime date;
  final SleepData? sleepData;
  final bool hasData;
  final Duration sleepDuration; // SD (Sleep Duration)
  final double sleepEfficiency; // SE (Sleep Efficiency) in %
  final DateTime? actualOnset; // 실제 잠든 시간
  final DateTime? actualWake; // 실제 깨어난 시간
  final int? adherenceScore; // 루틴 이행 점수

  // 데이터가 없는 날을 위한 private 생성자
  const DailyReportData._({
    required this.date,
    this.sleepData,
    this.hasData = false,
    this.sleepDuration = Duration.zero,
    this.sleepEfficiency = 0.0,
    this.actualOnset,
    this.actualWake,
    this.adherenceScore,
  });

  /// 데이터가 없는 날짜에 대한 인스턴스 생성
  factory DailyReportData.empty(DateTime date) {
    return DailyReportData._(date: date);
  }

  /// SleepData로부터 리포트용 데이터 생성
  factory DailyReportData.fromSleepData(SleepData mainSleep) {
    final timeInBed = mainSleep.endTime.difference(mainSleep.startTime);
    final timeToFallAsleep = mainSleep.analysis.timeToFallAsleep;

    // 1. SD: 유효 수면 시간 계산
    // 1) awakeningTimes 리스트의 모든 duration을 합산
    final totalAwakeDuration = mainSleep.analysis.awakeningTimes.fold<Duration>(
      Duration.zero,
      (previousValue, awakeTime) => previousValue + awakeTime.duration,
    );
    // 2) SD 계산
    final sleepDuration = timeInBed > timeToFallAsleep + totalAwakeDuration
        ? timeInBed - timeToFallAsleep - totalAwakeDuration
        : Duration.zero;

    // 2. SE: 수면 효율 계산
    final sleepEfficiency = timeInBed.inMinutes > 0
        ? (sleepDuration.inMinutes / timeInBed.inMinutes) * 100
        : 0.0;

    // 3. 실제 잠든 시간 계산
    DateTime actualOnset = mainSleep.startTime.add(timeToFallAsleep);
    if (actualOnset.isAfter(mainSleep.endTime)) actualOnset = mainSleep.endTime;

    // 4. 루틴 이행 점수 계산
    final r = mainSleep.routine;
    final env = r.sleepEnv;
    final routineItems = {
      'drinkWater': r.drinkWater,
      'stretch': r.stretch,
      'screenOff': r.screenOff,
      'overeating': !r.overeating,
      'brushedTeeth': env.brushedTeeth,
      'showered': env.showered,
    };
    final satisfiedCount = routineItems.values.where((v) => v).length;
    final binaryTotal = routineItems.length;

    final lightScore = _scoreLight(env.light);
    final soundScore = _scoreSound(env.sound);
    final totalPoints = binaryTotal + 2;
    final sum = satisfiedCount + lightScore + soundScore;
    final adherenceScore = ((sum / totalPoints) * 100).round();

    return DailyReportData._(
      date: mainSleep.date,
      sleepData: mainSleep,
      hasData: true,
      sleepDuration: sleepDuration,
      sleepEfficiency: sleepEfficiency,
      actualOnset: actualOnset,
      actualWake: mainSleep.endTime,
      adherenceScore: adherenceScore,
    );
  }

  // 점수 계산 유틸리티
  static double _scoreLight(LightCondition l) =>
      const {
        LightCondition.dark: 1.0,
        LightCondition.nightLight: 0.85,
        LightCondition.dim: 0.7,
        LightCondition.normal: 0.3,
        LightCondition.bright: 0.0,
      }[l] ??
      0.0;

  static double _scoreSound(SoundCondition s) =>
      const {
        SoundCondition.quiet: 1.0,
        SoundCondition.whiteNoise: 0.7,
        SoundCondition.noisy: 0.0,
      }[s] ??
      0.0;

  @override
  List<Object?> get props => [
    date,
    hasData,
    sleepDuration,
    sleepEfficiency,
    actualOnset,
    adherenceScore,
  ];
}

/// [SleepReport] AI가 분석한 주간/월간 수면 리포트 모델
class SleepReport extends Equatable {
  final String reportId;
  final String period;
  final List<DailyReportData> dailyData;
  final String goalBedTimeString;
  final String goalWakeUpTimeString;

  const SleepReport({
    required this.reportId,
    required this.period,
    required this.dailyData,
    required this.goalBedTimeString,
    required this.goalWakeUpTimeString,
  });

  /// [SleepReport.empty] 빈 리포트 생성
  factory SleepReport.empty() {
    return const SleepReport(
      reportId: 'no-data', // 데이터 없음을 나타내는 ID
      period: '',
      dailyData: [],
      goalBedTimeString: '',
      goalWakeUpTimeString: '',
    );
  }

  List<DailyReportData> get recordedDays =>
      dailyData.where((d) => d.hasData).toList();

  double get avgSleepEfficiency {
    if (recordedDays.isEmpty) return 0.0;
    return recordedDays.map((d) => d.sleepEfficiency).average;
  }

  Duration get avgSleepDuration {
    if (recordedDays.isEmpty) return Duration.zero;
    final totalMinutes = recordedDays.map((d) => d.sleepDuration.inMinutes).sum;
    return Duration(minutes: (totalMinutes / recordedDays.length).round());
  }

  double get avgSleepScore {
    if (recordedDays.isEmpty) return 0.0;
    return recordedDays.map((d) => d.sleepData?.sleepScore ?? 50).average;
  }

  double get avgAwakenings {
    if (recordedDays.isEmpty) return 0.0;
    return recordedDays
        .map((d) => d.sleepData?.analysis.awakeningsCount ?? 0)
        .average;
  }

  Duration get socialJetlag {
    final weekdays = recordedDays.where((d) => d.date.weekday <= 5).toList();
    final weekends = recordedDays.where((d) => d.date.weekday > 5).toList();
    if (weekdays.isEmpty || weekends.isEmpty) return Duration.zero;

    final midSleepWeekday = _calculateAvgMidSleep(weekdays);
    final midSleepWeekend = _calculateAvgMidSleep(weekends);
    final difference = (midSleepWeekend - midSleepWeekday).isNegative
        ? -(midSleepWeekend - midSleepWeekday)
        : (midSleepWeekend - midSleepWeekday);

    return difference.inHours > 12
        ? Duration(hours: 24) - difference
        : difference;
  }

  double get sleepRegularityIndex {
    if (recordedDays.length < 2) return 0.0;

    final onsets = recordedDays.map((d) => d.actualOnset).nonNulls.toList();
    if (onsets.length < 2) return 0.0;

    final onsetMinutes = onsets.map((dt) {
      final minutes = dt.hour * 60 + dt.minute;
      return dt.hour < 12 ? minutes + 1440 : minutes;
    });

    final onsetStdDev = _calculateStdDev(onsetMinutes);

    final regularity = 100 - onsetStdDev / 2;
    return max(0, min(100, regularity));
  }

  List<String> get summaryMessages {
    if (recordedDays.isEmpty) return ['해당 기간에 수면 기록이 없습니다.'];

    final List<String> messages = [];

    const int sriThreshold = 75; // 수면 규칙성 지수 기준 (75점 미만)
    const int sjlThresholdInMinutes = 90; // 사회적 시차 기준 (90분 초과)
    const double efficiencyThreshold = 85.0; // 수면 효율 기준 (85% 미만)
    const double awakeningsThreshold = 2.0; // 중간 각성 횟수 기준 (평균 2회 이상)

    // 1. 수면 규칙성(SRI)
    if (sleepRegularityIndex < sriThreshold) {
      messages.add('수면 패턴이 다소 불규칙해요 (SRI: ${sleepRegularityIndex.round()}점).');
    }

    // 2. 사회적 시차(SJL)
    if (socialJetlag.inMinutes > sjlThresholdInMinutes) {
      messages.add(
        '주중과 주말의 수면 시간 차이가 커요 (사회적 시차: ${socialJetlag.inMinutes}분).',
      );
    }

    // 3. 수면 효율
    if (avgSleepEfficiency < efficiencyThreshold) {
      messages.add(
        '수면 효율이 다소 낮아요 (평균 ${avgSleepEfficiency.toStringAsFixed(1)}%).',
      );
    }

    // 4. 수면 중 깬 횟수
    if (avgAwakenings >= awakeningsThreshold) {
      messages.add(
        '밤에 깨는 횟수가 평균 ${avgAwakenings.toStringAsFixed(1)}회로 잦은 편이에요.',
      );
    }

    // 5. 목표 수면 시간과의 비교
    messages.addAll(_getGoalSummaryMessages);

    // 6. 모든 지표가 양호할 경우 기본 메시지 추가
    if (messages.isEmpty) {
      if (avgSleepScore > 85) {
        messages.add('훌륭해요! 전반적으로 매우 건강한 수면 습관을 가지고 있어요. 지금처럼 꾸준히 유지해주세요.');
      } else {
        messages.add('건강한 수면 패턴을 잘 유지하고 있어요. 계속해서 좋은 습관을 이어가 보세요.');
      }
    }

    return messages;
  }

  List<String> get coachingTips {
    if (recordedDays.isEmpty) return ['해당 기간에 수면 기록이 없습니다.'];

    final List<String> tips = [];
    const int sriThreshold = 75;
    const int sjlThresholdInMinutes = 90;
    const double efficiencyThreshold = 85.0;
    const double awakeningsThreshold = 2.0;

    // 1. 수면 패턴 분석
    if (sleepRegularityIndex < sriThreshold) {
      tips.add('매일 비슷한 시간에 잠자리에 드는 것만으로도 수면의 질이 크게 향상될 수 있어요.');
    }
    if (socialJetlag.inMinutes > sjlThresholdInMinutes) {
      tips.add('주말에 늦잠을 자더라도 평소보다 1~2시간 이상 벗어나지 않도록 노력해보세요.');
    }
    if (avgSleepEfficiency < efficiencyThreshold) {
      tips.add('잠들기 전 스마트폰 사용을 줄이고, 침실 환경을 더 어둡고 조용하게 만들어보세요.');
    }
    if (avgAwakenings >= awakeningsThreshold) {
      tips.add('밤에 자주 깬다면, 잠들기 전 과도한 수분 섭취나 카페인 섭취를 피하는 것이 좋아요.');
    }

    // 2. 목표 달성도 분석
    tips.addAll(_getGoalCoachingTips);

    // 3. 두 분석 결과를 조합하여 최종 리스트 생성
    if (tips.isEmpty) {
      tips.add('현재 루틴을 유지하면서 주말에도 기상 시간을 크게 바꾸지 않는 것이 좋아요.');
    }
    return tips;
  }

  List<String> get _getGoalSummaryMessages {
    final (avgBedtimeDiff, avgDurationDiff) = _calculateGoalAdherence();
    if (avgBedtimeDiff == null || avgDurationDiff == null) return [];

    final List<String> feedback = [];

    if (avgBedtimeDiff > 15) {
      feedback.add('목표 시간보다 평균 ${avgBedtimeDiff.round()}분 늦게 잠드는 경향이 있네요.');
    } else if (avgBedtimeDiff < -15) {
      feedback.add(
        '목표보다 평균 ${avgBedtimeDiff.abs().round()}분 일찍 잠드는 좋은 습관을 가지고 있어요!',
      );
    }

    if (avgDurationDiff.inMinutes < -15) {
      feedback.add('목표 수면량보다 평균 ${avgDurationDiff.inMinutes.abs()}분이 부족해요.');
    } else if (avgDurationDiff.inMinutes > 15) {
      feedback.add('목표보다 평균 ${avgDurationDiff.inMinutes}분 더 충분히 자고 있어요.');
    }

    return feedback;
  }

  // 목표 달성도 분석 (취침 시간, 수면량)
  List<String> get _getGoalCoachingTips {
    final (avgBedtimeDiff, avgDurationDiff) = _calculateGoalAdherence();
    if (avgBedtimeDiff == null || avgDurationDiff == null) return [];

    final List<String> tips = [];
    if (avgDurationDiff.inMinutes > 30) {
      tips.add(
        '목표 시간보다 평균 ${avgDurationDiff.inMinutes}분 늦게 잠드는 편이에요. 저녁 루틴을 조금 더 일찍 시작해보세요.',
      );
    }

    if (avgDurationDiff.inMinutes < -30) {
      tips.add(
        '평균 잠이 ${avgDurationDiff.inMinutes.abs()}분이 부족해요. 부족한 잠은 낮잠이 아니라, 밤잠에서 채워주는 게 가장 좋아요.',
      );
    } else if (avgDurationDiff.inMinutes > 30) {
      tips.add('잠을 충분히 잘 자고 있어요. 다만 아침에 기상 시간이 점점 늦어지지 않도록 주말에도 규칙을 유지해주세요.');
    }

    return tips;
  }

  (double?, Duration?) _calculateGoalAdherence() {
    final goalBedTime = _parseTime(goalBedTimeString);
    final goalWakeUpTime = _parseTime(goalWakeUpTimeString);
    if (goalBedTime == null || goalWakeUpTime == null) return (null, null);

    // 평균 취침 시간 차이 계산
    final validDaysCount = recordedDays
        .where((d) => d.actualOnset != null)
        .length;
    if (validDaysCount == 0) return (null, null);

    final totalDifferenceInMinutes = recordedDays
        .map((d) {
          if (d.actualOnset == null) return 0.0;
          final actualTime = TimeOfDay.fromDateTime(d.actualOnset!);
          final actualMinutes = actualTime.hour * 60 + actualTime.minute;
          final goalMinutes = goalBedTime.hour * 60 + goalBedTime.minute;
          var diff = actualMinutes - goalMinutes;
          if (diff < -720) diff += 1440;
          if (diff > 720) diff -= 1440;
          return diff;
        })
        .where((diff) => diff != 0)
        .sum;

    final averageDifference = totalDifferenceInMinutes / validDaysCount;

    // 목표 수면량과의 차이 계산
    final goalBedMinutes = goalBedTime.hour * 60 + goalBedTime.minute;
    final goalWakeMinutes = goalWakeUpTime.hour * 60 + goalWakeUpTime.minute;

    final goalDurationInMinutes = goalWakeMinutes >= goalBedMinutes
        ? goalWakeMinutes - goalBedMinutes
        : (1440 - goalBedMinutes) + goalWakeMinutes; // 1440 = 24 * 60

    final goalSleepDuration = Duration(minutes: goalDurationInMinutes);
    final durationDifference = avgSleepDuration - goalSleepDuration;

    return (averageDifference, durationDifference);
  }

  TimeOfDay? _parseTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return null;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  Duration _calculateAvgMidSleep(List<DailyReportData> days) {
    final validDays = days
        .where((d) => d.hasData && d.sleepData != null && d.actualOnset != null)
        .toList();

    if (validDays.isEmpty) return Duration.zero;

    final totalMinutes = validDays.map((d) {
      final midPoint = d.actualOnset!.add(
        d.actualWake!.difference(d.actualOnset!) ~/ 2,
      );
      return midPoint.hour * 60 + midPoint.minute;
    }).sum;

    return Duration(minutes: (totalMinutes / validDays.length).round());
  }

  double _calculateStdDev(Iterable<num> values) {
    if (values.length < 2) return 0.0;
    final mean = values.average;
    final variance = values.map((v) => pow(v - mean, 2)).sum / values.length;
    return sqrt(variance);
  }

  @override
  List<Object?> get props => [
    reportId,
    period,
    dailyData,
    goalBedTimeString,
    goalWakeUpTimeString,
  ];
}

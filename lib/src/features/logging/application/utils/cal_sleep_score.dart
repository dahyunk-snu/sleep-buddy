import 'package:sleepy/src/core/models/child_profile.dart';
import 'package:sleepy/src/core/models/sleep_analysis.dart';
import 'package:sleepy/src/core/models/sleep_data.dart';
import 'package:sleepy/src/core/models/sleep_routine.dart';
import 'package:sleepy/src/features/logging/application/post_sleep_logging_controller.dart';

/// [calculateSleepScore] 수면 점수 산출
Future<int> calculateSleepScore({
  required PostSleepLog log,
  required SleepRoutine routine,
  required SleepAnalysis analysis,
  required ChildProfile profile,
  required DateTime sessionDate,
}) async {
  double totalScore = 0;

  // --- 영역 1: 목표 달성도 (35점) ---
  double goalScore = 0;
  final targetTimes = _getTargetDateTimes(
    sessionDate: sessionDate,
    goalBedTime: profile.goalBedTime,
    goalWakeUpTime: profile.goalWakeUpTime,
  );

  if (targetTimes != null) {
    final targetBedTime = targetTimes['bedTime']!;
    final targetWakeUpTime = targetTimes['wakeUpTime']!;

    // 목표 총 수면 시간
    final targetDuration = targetWakeUpTime.difference(targetBedTime);
    // 실제 총 침대 위 시간
    final actualTotalDuration = log.endTime.difference(log.startTime);
    if (actualTotalDuration.inMinutes < 5) return 0;

    // 1-1. 총량 점수 (20점): 목표 수면 시간과의 차이로 계산
    final durationDiff = (actualTotalDuration - targetDuration).inMinutes.abs();
    // 3시간(180분) 이상 차이나면 0점
    goalScore += (20 * (1 - (durationDiff / 180))).clamp(0, 20);

    // 1-2. 규칙성 점수 (15점): 목표 시각과의 차이로 계산
    final bedDiff = log.startTime.difference(targetBedTime).inMinutes.abs();
    final wakeDiff = log.endTime.difference(targetWakeUpTime).inMinutes.abs();
    final regularityDiff = bedDiff + wakeDiff;
    // 총 2시간(120분) 이상 차이나면 0점
    goalScore += (15 * (1 - (regularityDiff / 120))).clamp(0, 15);
  }
  totalScore += goalScore;

  // --- 영역 2: 수면 효율성 (30점) ---
  final totalTimeInBed = log.endTime.difference(log.startTime);
  if (totalTimeInBed.inMinutes > 0) {
    final totalAwakeDuration = analysis.awakeningTimes.fold(
      analysis.timeToFallAsleep,
      (prev, e) => prev + e.duration,
    );
    final actualSleepDuration = totalTimeInBed - totalAwakeDuration;
    final efficiency =
        (actualSleepDuration.inMinutes / totalTimeInBed.inMinutes) * 100;

    if (efficiency >= 90) {
      totalScore += 30;
    } else if (efficiency >= 85) {
      totalScore += 25;
    } else if (efficiency >= 80) {
      totalScore += 20;
    } else {
      totalScore += 10;
    }
  }

  // --- 영역 3: 수면 연속성 (20점) ---
  double continuityScore = 20.0;
  final totalAwakeTime = analysis.awakeningTimes.fold(
    Duration.zero,
    (prev, e) => prev + e.duration,
  );
  if (totalAwakeTime.inMinutes >= 30) {
    continuityScore -= 10;
  } else if (totalAwakeTime.inMinutes >= 15) {
    continuityScore -= 5;
  }

  final eventDeduction = (analysis.problematicEvents.length * 2).toDouble();
  continuityScore -= eventDeduction.clamp(0, 10);
  totalScore += continuityScore.clamp(0, 20);

  // --- 영역 4: 주관적 만족도 (15점) ---
  switch (log.condition) {
    case MorningCondition.veryGood:
      totalScore += 15;
      break;
    case MorningCondition.good:
      totalScore += 12;
      break;
    case MorningCondition.neutral:
      totalScore += 8;
      break;
    case MorningCondition.bad:
      totalScore += 4;
      break;
    case MorningCondition.veryBad:
      totalScore += 0;
      break;
  }

  return totalScore.clamp(0, 100).toInt();
}

/// 목표 취침/기상 시간을 DateTime 객체로 변환
Map<String, DateTime>? _getTargetDateTimes({
  required DateTime sessionDate,
  required String goalBedTime,
  required String goalWakeUpTime,
}) {
  try {
    final bedTimeParts = goalBedTime.split(':').map(int.parse).toList();
    final wakeUpTimeParts = goalWakeUpTime.split(':').map(int.parse).toList();

    DateTime targetBedTime = DateTime(
      sessionDate.year,
      sessionDate.month,
      sessionDate.day,
      bedTimeParts[0],
      bedTimeParts[1],
    );

    DateTime targetWakeUpTime = DateTime(
      sessionDate.year,
      sessionDate.month,
      sessionDate.day,
      wakeUpTimeParts[0],
      wakeUpTimeParts[1],
    );

    // 목표 취침 시간이 새벽(0시~12시)이면 다음날로 간주
    if (bedTimeParts[0] < 12) {
      targetBedTime = targetBedTime.add(const Duration(days: 1));
    }

    // 최종 목표 취침 시간보다 기상 시간이 앞서있으면, 기상 시간도 다음날로 처리
    if (targetWakeUpTime.isBefore(targetBedTime) ||
        targetWakeUpTime.isAtSameMomentAs(targetBedTime)) {
      targetWakeUpTime = targetWakeUpTime.add(const Duration(days: 1));
    }

    return {'bedTime': targetBedTime, 'wakeUpTime': targetWakeUpTime};
  } catch (e) {
    return null;
  }
}

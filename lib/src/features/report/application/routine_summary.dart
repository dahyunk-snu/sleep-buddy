import 'package:sleepy/src/core/models/sleep_data.dart';
import 'package:sleepy/src/core/models/sleep_routine.dart';
import 'package:sleepy/src/features/report/presentation/widgets/week/report_shared.dart';
import 'package:collection/collection.dart';

class RoutineChip {
  final String label;
  final int hit;
  final int total;
  bool get done => total == 0 ? false : (hit / total) >= 0.7;
  const RoutineChip(this.label, this.hit, this.total);
}

class RoutineSummary {
  final int score; // 0~100
  final double percent; // 0~1
  final double lightAvg; // 0~1
  final double soundAvg; // 0~1
  final String lightModeLabel;
  final String soundModeLabel;
  final List<RoutineChip> chips;

  const RoutineSummary({
    required this.score,
    required this.percent,
    required this.lightAvg,
    required this.soundAvg,
    required this.lightModeLabel,
    required this.soundModeLabel,
    required this.chips,
  });
}

/// 기간 내 일자별 대표 수면만 고르기 (night 우선 → 가장 긴 세션)
List<SleepData> pickMainSleepsByDay(List<SleepData> all) {
  final byDay = <DateTime, List<SleepData>>{};
  for (final d in all) {
    final key = DateTime(d.date.year, d.date.month, d.date.day);
    byDay.putIfAbsent(key, () => []).add(d);
  }
  final picked = <SleepData>[];
  for (final entry in byDay.entries) {
    final list = entry.value;
    list.sort((a, b) {
      final nightBias =
          (a.sessionType == SleepSessionType.night ? -1 : 0) -
          (b.sessionType == SleepSessionType.night ? -1 : 0);
      if (nightBias != 0) return nightBias;
      final da = a.endTime.difference(a.startTime);
      final db = b.endTime.difference(b.startTime);
      return db.compareTo(da);
    });
    picked.add(list.first);
  }
  picked.sort((a, b) => a.startTime.compareTo(b.startTime));
  return picked;
}

/// 대표 수면들로 루틴 이행 요약/점수 계산
RoutineSummary summarizeRoutine(List<SleepData> days) {
  int bDrink = 0,
      bStretch = 0,
      bScreenOff = 0,
      bOvereat = 0,
      bBrush = 0,
      bShower = 0;

  final lightCounts = <LightCondition, int>{
    for (final l in LightCondition.values) l: 0,
  };
  final soundCounts = <SoundCondition, int>{
    for (final s in SoundCondition.values) s: 0,
  };

  double lightSum = 0, soundSum = 0;

  for (final d in days) {
    final r = d.routine;
    final env = r.sleepEnv;

    if (r.drinkWater) bDrink++;
    if (r.stretch) bStretch++;
    if (r.screenOff) bScreenOff++;
    if (!r.overeating) bOvereat++;
    if (env.brushedTeeth) bBrush++;
    if (env.showered) bShower++;

    lightCounts[env.light] = (lightCounts[env.light] ?? 0) + 1;
    soundCounts[env.sound] = (soundCounts[env.sound] ?? 0) + 1;

    lightSum += scoreLight(env.light);
    soundSum += scoreSound(env.sound);
  }

  final total = days.isEmpty ? 1.0 : days.length.toDouble();
  final lightAvg = lightSum / total;
  final soundAvg = soundSum / total;

  final binAvgs = [
    bDrink / total,
    bStretch / total,
    bScreenOff / total,
    bOvereat / total,
    bBrush / total,
    bShower / total,
  ];
  final sum = (binAvgs.fold<double>(0, (a, b) => a + b)) + lightAvg + soundAvg;
  final percent = (sum / (9 + 2)).clamp(0.0, 1.0);
  final score = (percent * 100).round();

  final chips = <RoutineChip>[
    RoutineChip('양치', bBrush, days.length),
    RoutineChip('샤워', bShower, days.length),
    RoutineChip('수분 조절', bDrink, days.length),
    RoutineChip('스트레칭', bStretch, days.length),
    RoutineChip('스크린 오프', bScreenOff, days.length),
    RoutineChip('과식X', bOvereat, days.length),
  ];

  final lightMode = lightLabel(
    lightCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key,
  );
  final soundMode = soundLabel(
    soundCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key,
  );

  return RoutineSummary(
    score: score,
    percent: percent,
    lightAvg: lightAvg,
    soundAvg: soundAvg,
    lightModeLabel: lightMode,
    soundModeLabel: soundMode,
    chips: chips,
  );
}

class _CorrelationResult {
  final String insight;
  final double score;
  const _CorrelationResult(this.insight, this.score);
}

List<String> analyzeCorrelations(List<SleepData> days) {
  if (days.length < 5) return []; // 최소 5일 데이터가 있을 때만 분석

  final results = <_CorrelationResult>[];
  final routineMap = {
    '수분 섭취를 조절할 때': (SleepData d) => d.routine.drinkWater,
    '양치하고 잠에 들었을 때': (SleepData d) => d.routine.sleepEnv.brushedTeeth,
    '샤워를 하고 잠에 들었을 때': (SleepData d) => d.routine.sleepEnv.showered,
    '어두운 환경에서 잠에 들었을 때': (SleepData d) =>
        d.routine.sleepEnv.light == LightCondition.dark,
    '조용한 환경에서 잠에 들었을 때': (SleepData d) =>
        d.routine.sleepEnv.sound == SoundCondition.quiet,
    '스트레칭을 하고 잠에 들었을 때': (SleepData d) => d.routine.stretch,
    '잠들기 전 스마트폰/TV 보지 않았을 때': (SleepData d) => d.routine.screenOff,
    '과식하지 않았을 때': (SleepData d) => !d.routine.overeating,
  };

  routineMap.forEach((label, condition) {
    final groupA = days.where(condition).toList();
    final groupB = days.where((d) => !condition(d)).toList();

    // 각 그룹에 최소 2일 이상의 데이터가 있어야 비교가 의미 있음
    if (groupA.length < 2 || groupB.length < 2) return;

    // 1. 수면 점수 비교
    final scoreA = groupA.map((d) => d.sleepScore).average; // sleepScore로 효율 대체
    final scoreB = groupB.map((d) => d.sleepScore).average;
    final scoreDiff = scoreA - scoreB;

    if (scoreDiff > 3) {
      // 긍정적 행동 그룹의 효율이 3% 이상 높을 때
      results.add(
        _CorrelationResult(
          '$label 수면 점수가 평균 ${scoreDiff.round()}점 더 높았어요.',
          scoreDiff,
        ),
      );
    }

    // 2. 잠에서 깬 횟수 비교
    final awakeningsA = groupA.map((d) => d.analysis.awakeningsCount).average;
    final awakeningsB = groupB.map((d) => d.analysis.awakeningsCount).average;
    final awakDiff = awakeningsB - awakeningsA;

    if (awakDiff > 0.5) {
      // 긍정적 행동 그룹이 0.5회 이상 덜 깼을 때
      results.add(
        _CorrelationResult(
          '$label 중간에 깨는 횟수가 평균 ${awakDiff.toStringAsFixed(1)}회 더 적었어요.',
          awakDiff * 10, // 깨는 횟수 변화에 더 높은 가중치 부여
        ),
      );
    }
  });

  // 가장 영향력 있는 분석 결과 상위 2개만 선택
  results.sort((a, b) => b.score.compareTo(a.score));
  return results.map((r) => r.insight).take(2).toList();
}

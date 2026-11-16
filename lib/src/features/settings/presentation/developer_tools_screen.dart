import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sleepy/src/core/models/problematic_event.dart';
import 'package:sleepy/src/core/models/sleep_analysis.dart';
import 'package:sleepy/src/core/models/sleep_data.dart';
import 'package:sleepy/src/core/models/sleep_routine.dart';
import 'package:sleepy/src/core/services/auth_service.dart';
import 'package:sleepy/src/core/services/database_service.dart';
import 'package:sleepy/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:sleepy/src/features/logging/application/post_sleep_logging_controller.dart';
import 'package:sleepy/src/features/logging/application/utils/cal_sleep_score.dart';

class DeveloperToolsScreen extends ConsumerStatefulWidget {
  const DeveloperToolsScreen({super.key});

  @override
  ConsumerState<DeveloperToolsScreen> createState() =>
      _DeveloperToolsScreenState();
}

class _DeveloperToolsScreenState extends ConsumerState<DeveloperToolsScreen> {
  bool _isGenerating = false;

  // 임시 수면 데이터 생성 로직
  Future<void> _generateDummyData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('데이터 생성 확인'),
        content: const Text(
          '최근 60일간의 임시 수면 데이터를 생성합니다. 기존 데이터는 삭제됩니다. 계속하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('생성'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isGenerating = true);

    try {
      final user = ref.read(authServiceProvider).currentUser;
      final childId = ref.read(dashboardNotifierProvider).selectedChildId;
      final db = ref.read(databaseServiceProvider);

      if (user == null || childId == null) {
        throw Exception('사용자 또는 선택된 자녀 정보가 없습니다.');
      }
      final childProfile = await db.getChildProfile(user.uid, childId);
      if (childProfile == null) {
        throw Exception('아동 프로필을 불러올 수 없습니다. 다시 시도해주세요.');
      }

      final random = Random();
      final today = DateTime.now();

      for (int i = 0; i < 60; i++) {
        final day = today.subtract(Duration(days: i));
        final date = DateTime(day.year, day.month, day.day);

        // 22:00 ~ 00:00 사이 랜덤 취침 시간
        final startTime = DateTime(
          date.year,
          date.month,
          date.day,
          22 + random.nextInt(2),
          random.nextInt(60),
        );
        // 7시간 ~ 9시간 후 랜덤 기상 시간
        final endTime = startTime.add(
          Duration(hours: 7 + random.nextInt(2), minutes: random.nextInt(60)),
        );

        // 자는 시간 사이에 임의로 깨어 있었던 구간 추가 (AwakeTime 기반)
        final diffMins = endTime.difference(startTime).inMinutes;
        final count = (diffMins <= 60) ? 0 : random.nextInt(3);

        final rawAwakeTimes = List<AwakeTime>.generate(count, (_) {
          final offset = 30 + random.nextInt(diffMins - 60); // 양 끝 30분 마진
          final awakeStart = startTime.add(Duration(minutes: offset));
          final awakeEnd = awakeStart.add(
            Duration(minutes: 5 + random.nextInt(10)),
          );
          return AwakeTime(start: awakeStart, end: awakeEnd);
        });

        final awakeTimes = <AwakeTime>[];
        if (rawAwakeTimes.isNotEmpty) {
          // 시작 시간 기준으로 정렬
          rawAwakeTimes.sort((a, b) => a.start.compareTo(b.start));

          awakeTimes.add(rawAwakeTimes.first);
          for (int i = 1; i < rawAwakeTimes.length; i++) {
            final last = awakeTimes.last;
            final current = rawAwakeTimes[i];

            // 이전 구간이 현재 구간을 포함하거나 겹치면
            if (last.end.isAfter(current.start) ||
                last.end.isAtSameMomentAs(current.start)) {
              // 더 늦게 끝나는 시간으로 이전 구간을 확장(통합)
              final newEnd = last.end.isAfter(current.end)
                  ? last.end
                  : current.end;
              awakeTimes[awakeTimes.length - 1] = AwakeTime(
                start: last.start,
                end: newEnd,
              );
            } else {
              // 겹치지 않으면 새 구간으로 추가
              awakeTimes.add(current);
            }
          }
        }

        // problematic events에 event 종류와 해당하는 시간 추가
        final problematicEvents = List<ProblematicEvent>.generate(
          random.nextInt(5),
          (i) {
            final eventTime = startTime.add(
              Duration(
                minutes:
                    30 +
                    random.nextInt(
                      endTime.difference(startTime).inMinutes - 60,
                    ),
              ),
            );
            final eventType = ProblematicEventType
                .values[random.nextInt(ProblematicEventType.values.length)];
            return ProblematicEvent(type: eventType, time: eventTime);
          },
        );

        final dummyRoutine = SleepRoutine(
          drinkWater: random.nextBool(),
          stretch: random.nextBool(),
          screenOff: random.nextBool(),
          overeating: random.nextBool(),
          sleepEnv: SleepEnvironment(
            brushedTeeth: random.nextBool(),
            showered: random.nextBool(),
            light: LightCondition
                .values[random.nextInt(LightCondition.values.length)],
            sound: SoundCondition
                .values[random.nextInt(SoundCondition.values.length)],
          ),
        );
        final dummyAnalysis = SleepAnalysis(
          timeToFallAsleep: Duration(minutes: 5 + random.nextInt(55)), // 5-60분
          awakeningTimes: awakeTimes,
          awakeningsCount: awakeTimes.length + random.nextInt(2),
          problematicEvents: problematicEvents,
        );
        final morningCondition = MorningCondition
            .values[random.nextInt(MorningCondition.values.length)];

        final dummyLog = PostSleepLog(
          condition: morningCondition,
          timeToFallAsleepInMinutes: dummyAnalysis.timeToFallAsleep.inMinutes,
          awakeTimes: awakeTimes,
          events: problematicEvents,
          startTime: startTime,
          endTime: endTime,
          sessionType: SleepSessionType.night,
        );

        final dummyScore = await calculateSleepScore(
          log: dummyLog,
          routine: dummyRoutine,
          analysis: dummyAnalysis,
          profile: childProfile,
          sessionDate: date,
        );

        final dummySleepData = SleepData(
          childId: childId,
          date: date,
          startTime: startTime,
          endTime: endTime,
          sessionType: SleepSessionType.night,
          sleepScore: dummyScore,
          routine: dummyRoutine,
          analysis: dummyAnalysis,
          morningCondition: morningCondition,
        );

        await db.addSleepData(user.uid, dummySleepData);
      }

      ref.invalidate(dashboardNotifierProvider); // 대시보드 데이터 갱신
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('30일간의 임시 데이터 생성이 완료되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('개발자 도구')),
      body: ListView(
        children: [
          ListTile(
            leading: _isGenerating
                ? const CircularProgressIndicator()
                : const Icon(Icons.add_chart),
            title: const Text('임시 수면 데이터 생성'),
            subtitle: const Text('최근 30일간의 임시 데이터를 생성합니다.'),
            onTap: _isGenerating ? null : _generateDummyData,
          ),
        ],
      ),
    );
  }
}

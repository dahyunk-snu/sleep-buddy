import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sleepy/src/core/models/child_profile.dart';
import 'package:sleepy/src/core/models/sleep_data.dart';
import 'package:sleepy/src/core/models/problematic_event.dart';
import 'package:sleepy/src/core/models/sleep_routine.dart';
import 'package:sleepy/src/core/models/sleep_analysis.dart';
import 'package:sleepy/src/core/router/app_router.dart';
import 'package:sleepy/src/core/services/auth_service.dart';
import 'package:sleepy/src/core/services/database_service.dart';
import 'package:sleepy/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:sleepy/src/core/services/audio_monitoring_service.dart';
import 'package:sleepy/src/core/services/sleep_monitoring_service.dart';
import 'package:sleepy/src/core/services/device_connection_service.dart';
import 'package:logging/logging.dart';

part 'routine_controller.g.dart';

final _log = Logger('RoutineController');

class RoutineState extends Equatable {
  const RoutineState({
    // 체크리스트
    this.drinkWater = false,
    this.stretch = false,
    this.screenOff = false,
    this.overeating = false,

    // 수면 환경
    this.brushedTeeth = false,
    this.showered = false,
    this.light = LightCondition.dark,
    this.sound = SoundCondition.quiet,

    // 진행 상태
    this.isSaving = false,
    this.isTracking = false,
    this.elapsed = Duration.zero,
    this.currentSleepDataId,
    this.sessionType = SleepSessionType.night,
  });

  // 체크리스트
  final bool drinkWater;
  final bool stretch;
  final bool screenOff;
  final bool overeating;

  // 수면 환경
  final bool brushedTeeth;
  final bool showered;
  final LightCondition light;
  final SoundCondition sound;

  // 진행 상태
  final bool isSaving;
  final bool isTracking;
  final Duration elapsed;
  final String? currentSleepDataId;
  final SleepSessionType sessionType;

  RoutineState copyWith({
    bool? drinkWater,
    bool? stretch,
    bool? screenOff,
    bool? overeating,
    bool? brushedTeeth,
    bool? showered,
    LightCondition? light,
    SoundCondition? sound,
    bool? isSaving,
    bool? isTracking,
    Duration? elapsed,
    String? currentSleepDataId,
    SleepSessionType? sessionType,
  }) {
    return RoutineState(
      drinkWater: drinkWater ?? this.drinkWater,
      stretch: stretch ?? this.stretch,
      screenOff: screenOff ?? this.screenOff,
      overeating: overeating ?? this.overeating,
      brushedTeeth: brushedTeeth ?? this.brushedTeeth,
      showered: showered ?? this.showered,
      light: light ?? this.light,
      sound: sound ?? this.sound,
      isSaving: isSaving ?? this.isSaving,
      isTracking: isTracking ?? this.isTracking,
      elapsed: elapsed ?? this.elapsed,
      currentSleepDataId: currentSleepDataId ?? this.currentSleepDataId,
      sessionType: sessionType ?? this.sessionType,
    );
  }

  @override
  List<Object?> get props => [
    drinkWater,
    stretch,
    screenOff,
    overeating,
    brushedTeeth,
    showered,
    light,
    sound,
    isSaving,
    isTracking,
    elapsed,
    currentSleepDataId,
    sessionType,
  ];
}

@Riverpod(keepAlive: true)
class RoutineController extends _$RoutineController {
  Timer? _timer;

  @override
  RoutineState build() {
    // 컨트롤러가 제거될 때 타이머를 정리합니다.
    ref.onDispose(() {
      _timer?.cancel();
    });
    // 컨트롤러가 처음 생성될 때의 초기 상태를 반환합니다.
    ref.watch(audioMonitoringServiceProvider);
    return const RoutineState();
  }

  /// SleepRoutine으로 업데이트
  void setRoutineFromModel(
    SleepRoutine routine, {
    SleepSessionType? sessionType,
  }) {
    final env = routine.sleepEnv;
    state = state.copyWith(
      drinkWater: routine.drinkWater,
      stretch: routine.stretch,
      screenOff: routine.screenOff,
      overeating: routine.overeating,
      brushedTeeth: env.brushedTeeth,
      showered: env.showered,
      light: env.light,
      sound: env.sound,
      sessionType: sessionType ?? state.sessionType,
    );
  }

  /// UI 통해서 업데이트
  void setRoutineBulk({
    required bool drinkWater,
    required bool stretch,
    required bool screenOff,
    required bool overeating,
    required bool brushedTeeth,
    required bool showered,
    required LightCondition light,
    required SoundCondition sound,
    required SleepSessionType sessionType,
  }) {
    state = state.copyWith(
      drinkWater: drinkWater,
      stretch: stretch,
      screenOff: screenOff,
      overeating: overeating,
      brushedTeeth: brushedTeeth,
      showered: showered,
      light: light,
      sound: sound,
      sessionType: sessionType,
    );
  }

  /// 선택된 루틴 데이터를 저장하고 새로운 수면 세션을 시작합니다.
  Future<void> saveRoutineAndStartSleep() async {
    if (state.isSaving || state.isTracking) return;
    state = state.copyWith(isSaving: true);

    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) {
        throw Exception('User not logged in. Cannot start sleep session.');
      }

      final databaseService = ref.read(databaseServiceProvider);
      // 대시보드에서 현재 선택된 아동의 ID를 가져옵니다.
      final childId = ref.read(dashboardNotifierProvider).selectedChildId;
      if (childId == null) {
        // 선택된 아동이 없으면 예외를 발생시킵니다.
        throw Exception('선택된 아동이 없습니다. 먼저 대시보드에서 아동을 선택해주세요.');
      }
      final childProfile = await databaseService.getChildProfile(
        user.uid,
        childId,
      );
      if (childProfile == null) {
        throw Exception('아동 프로필을 불러올 수 없습니다. 다시 시도해주세요.');
      }

      // 현재 state → SleepRoutine
      final env = SleepEnvironment(
        brushedTeeth: state.brushedTeeth,
        showered: state.showered,
        light: state.light,
        sound: state.sound,
      );

      final routine = SleepRoutine(
        drinkWater: state.drinkWater,
        sleepEnv: env,
        stretch: state.stretch,
        screenOff: state.screenOff,
        overeating: state.overeating,
      );

      // 새로운 수면 세션을 나타내는 SleepData 객체를 생성합니다.
      final newSleepSession = SleepData.startNewSession(
        routine: routine,
        childId: childId,
        sessionType: state.sessionType,
      );

      // 새로운 수면 세션 데이터를 Firestore에 저장하고 ID를 반환받습니다.
      final newSleepDataId = await databaseService.addSleepData(
        user.uid,
        newSleepSession,
      );

      // 오디오 자동 감지 시작
      final audio = ref.read(audioMonitoringServiceProvider);
      final motion = ref.read(sleepMonitoringServiceProvider);
      try {
        await audio.start(
          userId: user.uid,
          childId: childId,
          sessionId: newSleepDataId, // YYYYMMDD-sessionType
          sessionType: state.sessionType,
          startTime: newSleepSession.startTime,
        );

        final ble = ref.read(bluetoothDeviceProvider.notifier);
        await ble.startSessionOnDevice(); // 기기에 세션 START 지시

        await motion.start(
          userId: user.uid,
          childId: childId,
          sessionId: newSleepDataId,
          sessionType: state.sessionType,
          startTime: newSleepSession.startTime,
        );

        state = state.copyWith(
          isTracking: true,
          currentSleepDataId: newSleepDataId,
        );
        _startTimer(newSleepSession.startTime, state.sessionType, childProfile);
      } catch (e, s) {
        _log.warning('[saveRoutineAndStartSleep] 오디오/동작 인식이 시작되지 않았습니다.', e, s);
      }
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  bool _lightbyDLMOTriggered = false;
  bool _lightbySLTriggered = false;
  void _startTimer(
    DateTime startTime,
    SleepSessionType sleepSession,
    ChildProfile childProfile,
  ) {
    _timer?.cancel();

    final goalWakeUpTime = _parseTime(childProfile.goalWakeUpTime);
    if (goalWakeUpTime == null) {
      throw Exception('[_startTimer] 목표 기상 시간을 파싱할 수 없습니다.');
    }
    final oneHourBeforeWakeUp = goalWakeUpTime.subtract(
      const Duration(hours: 1),
    );

    _lightbyDLMOTriggered = false;
    _lightbySLTriggered = false;
    final ble = ref.read(bluetoothDeviceProvider.notifier);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final now = DateTime.now();
      final elapsed = now.difference(startTime);
      state = state.copyWith(elapsed: elapsed);
      if (sleepSession == SleepSessionType.night) {
        final lightbySL = now.isAfter(oneHourBeforeWakeUp);

        if (!_lightbySLTriggered && lightbySL) {
          _lightbySLTriggered = true;
          await ble.setLightBySleepLatency(true);
        } else if (!_lightbyDLMOTriggered &&
            elapsed.inMinutes == childProfile.latencyTimeinMinutes) {
          _lightbyDLMOTriggered = true;
          await ble.setLightByDLMO(true);
        }
      }
    });
  }

  DateTime? _parseTime(String time) {
    final now = DateTime.now();
    final parts = time.split(':');
    if (parts.length != 2) {
      return null;
    }
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    var parsedDateTime = DateTime(now.year, now.month, now.day, hour, minute);

    if (!parsedDateTime.isAfter(now)) {
      parsedDateTime = parsedDateTime.add(const Duration(days: 1));
    }

    return parsedDateTime;
  }

  /// 현재 진행 중인 수면 세션을 종료합니다.
  Future<void> endSleepSession() async {
    final sleepDataId = state.currentSleepDataId;
    if (sleepDataId == null) {
      _log.info('[endSleepSession] 진행 중인 세션이 없습니다.');
      return;
    }
    _timer?.cancel();

    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      throw Exception('User not logged in. Cannot end sleep session.');
    }
    final databaseService = ref.read(databaseServiceProvider);

    final childId = ref.read(dashboardNotifierProvider).selectedChildId;
    if (childId == null) {
      // 선택된 아동이 없으면 예외를 발생시킵니다.
      throw Exception('선택된 아동이 없습니다. 먼저 대시보드에서 아동을 선택해주세요.');
    }

    // childId를 얻기 위해 먼저 문서를 가져옵니다.
    final originalData = await databaseService.getSleepDataById(
      user.uid,
      childId,
      sleepDataId,
    );
    if (originalData == null) {
      _log.warning('[endSleepSession] sleepData($sleepDataId) 문서를 찾지 못했습니다.');
      // 문서가 없으면 이벤트 머지 없이 종료 처리만 수행하고 리턴
      ref.invalidate(dashboardNotifierProvider);
      state = const RoutineState();
      ref.read(appRouterProvider).push('/logging/post-sleep/$sleepDataId');
      return;
    }

    final ble = ref.read(bluetoothDeviceProvider.notifier);
    await ble.stopSessionOnDevice();
    await ble.setLightBySleepLatency(false);

    // 오디오 자동 감지 종료 & 이벤트 수집
    final audio = ref.read(audioMonitoringServiceProvider);
    final motion = ref.read(sleepMonitoringServiceProvider);
    List<ProblematicEvent> audioEvents = const [];
    List<ProblematicEvent> motionEvents = const [];
    String? recPath;

    try {
      final collected = await audio.stopAndCollect();
      audioEvents = collected.events;
      recPath = collected.recordingPath;
    } catch (e, s) {
      _log.warning('[endSleepSession] 오디오가 종료되지 않았습니다.', e, s);
    } finally {
      if (recPath != null && recPath.isNotEmpty) {
        await audio.deleteRecording(recPath);
      }
    }

    try {
      motionEvents = await motion.stopAndCollect();
    } catch (e, s) {
      _log.warning('[endSleepSession] 모션 감지가 종료되지 않았습니다.', e, s);
    } finally {
      if (recPath != null && recPath.isNotEmpty) {
        await audio.deleteRecording(recPath);
      }
    }

    // 기존 분석과 자동 감지 이벤트 병합
    final now = DateTime.now();
    final prevAnalysis = originalData.analysis;
    final mergedEvents = _mergeEvents(audioEvents, motionEvents);
    final awakeningTimes = _getAwakeEvents(mergedEvents);
    final timeToFallAsleep = _getTimeToFallAsleep(
      mergedEvents,
      sessionStart: originalData.startTime,
    );

    final newAnalysis = prevAnalysis.copyWith(
      timeToFallAsleep: timeToFallAsleep,
      awakeningTimes: awakeningTimes,
      problematicEvents: mergedEvents,
    );

    // sleep data 업데이트
    await databaseService.updateSleepData(user.uid, childId, sleepDataId, {
      'endTime': now,
      'analysis': newAnalysis.toJson(),
    });

    // 대시보드 데이터를 새로고침합니다.
    ref.invalidate(dashboardNotifierProvider);

    // 상태 초기화
    state = const RoutineState();

    // 기상 후 기록 화면으로 이동하여 사용자 경험을 자연스럽게 연결합니다.
    ref.read(appRouterProvider).push('/logging/post-sleep/$sleepDataId');
  }

  /// [_getAwakeEvents] 뒤척임(restlessness)과 소음(noise)이 1분 이내에 함께 발생하면
  /// 깨어난 것으로 간주하여 AwakeTime(start=min, end=max+5분)을 생성합니다.
  /// 반환 리스트는 후속 단계에서 SleepAnalysis.copyWith()에 의해 정규화/병합됩니다.
  List<AwakeTime> _getAwakeEvents(List<ProblematicEvent> mergedEvents) {
    const pairWindow = Duration(minutes: 5);
    const awakeTail = Duration(minutes: 5);

    // 시간 없는 이벤트 제외 + 타입별 타임스탬프 추출
    final rest = <DateTime>[];
    final noise = <DateTime>[];
    for (final e in mergedEvents) {
      final t = e.time;
      if (t == null) continue;
      if (e.type == ProblematicEventType.restlessness) {
        rest.add(t);
      } else if (e.type == ProblematicEventType.noise) {
        noise.add(t);
      }
    }

    // 오름차순 정렬
    rest.sort();
    noise.sort();

    // 투 포인터로 1:1 그리디 페어링 (클러스터에서 과도한 조합 폭발 방지)
    final awakeCandidates = <AwakeTime>[];
    int i = 0, j = 0;
    while (i < rest.length && j < noise.length) {
      final rt = rest[i];
      final nt = noise[j];
      final diff = rt.isBefore(nt) ? nt.difference(rt) : rt.difference(nt);

      if (diff <= pairWindow) {
        final start = rt.isBefore(nt) ? rt : nt;
        final endBase = rt.isAfter(nt) ? rt : nt;
        final end = endBase.add(awakeTail);
        awakeCandidates.add(AwakeTime(start: start, end: end));

        // 둘 다 다음 후보로 이동(1:1 매칭)
        i++;
        j++;
      } else if (rt.isBefore(nt)) {
        i++;
      } else {
        j++;
      }
    }

    return awakeCandidates;
  }

  // 유틸: 5분 이내 중복 병합 (타입 동일 & 시간 차 ≤ 5분)
  // 규칙: 수동 입력( isAuto=false ) > 자동 감지, 더 이른 시각 우선, 메모는 합침
  List<ProblematicEvent> _mergeEvents(
    List<ProblematicEvent> audioEvents,
    List<ProblematicEvent> motionEvents,
  ) {
    const window = Duration(minutes: 5);
    final result = <ProblematicEvent>[];

    // 먼저 기존 이벤트를 복사(원본 유지)
    result.addAll(audioEvents);

    bool isWithin(DateTime a, DateTime b) =>
        (a.isBefore(b) ? b.difference(a) : a.difference(b)) <= window;

    // 각 신규 이벤트를 result에 병합
    for (final e in motionEvents) {
      // 같은 타입 & 5분 이내인 후보 찾기
      int? hit;
      for (int i = 0; i < result.length; i++) {
        final r = result[i];
        if (r.type != e.type) continue;
        if (r.time == null || e.time == null) continue; // 시간 없는 경우는 병합 대상 제외
        if (isWithin(r.time!, e.time!)) {
          hit = i;
          break;
        }
      }

      if (hit == null) {
        result.add(e);
        continue;
      }

      // 병합: 수동 우선, 더 이른 시각 우선, 메모는 연결
      final r = result[hit];
      final manualWins = ((!r.isAuto && e.isAuto)
          ? r
          : (r.isAuto && !e.isAuto ? e : null));

      ProblematicEvent base;
      if (manualWins != null) {
        base = manualWins;
      } else {
        // 수동/자동 동일하다면, 더 이른 시각 우선
        if (r.time != null && e.time != null) {
          base = r.time!.isBefore(e.time!) ? r : e;
        } else {
          base = r.time != null ? r : e;
        }
      }

      final other = identical(base, r) ? e : r;
      final mergedNote = [
        if ((base.note ?? '').isNotEmpty) base.note,
        if ((other.note ?? '').isNotEmpty) other.note,
      ].whereType<String>().toList().join(' | ');

      result[hit] = base.copyWith(
        // 시각/타입은 base 유지
        note: mergedNote.isEmpty ? base.note : mergedNote,
        // 수동 우선 규칙: 둘 중 하나라도 수동이면 false
        isAuto: base.isAuto && other.isAuto,
      );
    }

    // 정렬(시간 오름차순 → 타입명)
    result.sort();
    return result;
  }

  /// 문제행동(ProblematicEvent)이 '없었던 구간'이 5분 연속으로 최초 성립하는 시각을
  /// '잠든 시각'으로 보고, [sessionStart]로부터의 경과시간(Duration)을 반환.
  /// - 이벤트는 세션 시작 이전 값은 무시
  /// - 이벤트 사이 혹은 시작 이후 5분 '무사고' 구간이 생기면 그 구간의 시작+5분을 onset으로 간주
  /// - 세션 종료 시점(now)까지 그런 구간이 없다면, '아직 잠들지 않음'으로 보고 now - sessionStart 반환
  Duration _getTimeToFallAsleep(
    List<ProblematicEvent> events, {
    required DateTime sessionStart,
    Duration quiet = const Duration(minutes: 5),
    DateTime? sessionEnd,
  }) {
    final end = sessionEnd ?? DateTime.now();

    // 타임스탬프 정제: null 제거, 세션 시작 이전은 제외, 오름차순 정렬
    final times =
        events
            .map((e) => e.time)
            .whereType<DateTime>()
            .where((t) => !t.isBefore(sessionStart))
            .toList()
          ..sort();

    DateTime cursor = sessionStart;

    for (final t in times) {
      // cursor..t 사이에 quiet 이상 비었으면, cursor+quiet가 '잠든 시각'
      if (!t.isBefore(cursor.add(quiet))) {
        final onset = cursor.add(quiet);
        final d = onset.difference(sessionStart);
        return d.isNegative ? Duration.zero : d;
      }
      // 이벤트가 발생했으므로, 시작을 해당 이벤트 시각으로 재설정
      cursor = t;
    }

    // 마지막 이벤트 이후(now 혹은 sessionEnd까지) quiet 이상 비었는지 체크
    if (!end.isBefore(cursor.add(quiet))) {
      final onset = cursor.add(quiet);
      final d = onset.difference(sessionStart);
      return d.isNegative ? Duration.zero : d;
    }

    // 아직 5분 연속 무사고 구간이 없었다면, '아직 잠들지 않음'으로 간주
    final fallback = end.difference(sessionStart);
    return fallback.isNegative ? Duration.zero : fallback;
  }
}

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sleepy/src/core/models/sleep_analysis.dart';
import 'package:sleepy/src/core/models/sleep_data.dart';
import 'package:sleepy/src/core/models/problematic_event.dart';
import 'package:sleepy/src/core/services/auth_service.dart';
import 'package:sleepy/src/core/services/database_service.dart';
import 'package:sleepy/src/core/router/app_router.dart';
import 'package:sleepy/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:sleepy/src/core/services/circadian_rhythm_service.dart';
import 'package:sleepy/src/features/logging/presentation/widgets/analysis_progress_dialog.dart';
import 'package:sleepy/src/features/logging/application/utils/cal_sleep_score.dart';
import 'package:logging/logging.dart';
part 'post_sleep_logging_controller.g.dart';

final _log = Logger('PostSleepLoggingController');

/// [PostSleepLog] PostSleepLoggingScreen의 UI 상태
/// [condition] 아침 컨디션
/// [timeToFallAsleepInMinutes] 잠들기까지 걸린 시간(분)
/// [awakeTimes] ‘깨어 있었던 구간’ 편집용 목록
/// [startTime] 수면 시작 시각
/// [endTime] 기상 시각
/// [sessionType] 세션 유형(밤잠/낮잠)
/// [events] 이상행동(메모/시간 포함)
/// [isSaving] 저장 처리 중 여부
class PostSleepLog {
  final MorningCondition condition;
  final int timeToFallAsleepInMinutes;
  final List<AwakeTime> awakeTimes;
  final DateTime startTime;
  final DateTime endTime;
  final SleepSessionType sessionType;
  final List<ProblematicEvent> events;
  final bool isSaving;

  PostSleepLog({
    this.condition = MorningCondition.neutral,
    this.timeToFallAsleepInMinutes = 0,
    this.awakeTimes = const [],
    DateTime? startTime,
    DateTime? endTime,
    this.sessionType = SleepSessionType.night,
    this.events = const [],
    this.isSaving = false,
  }) : startTime = startTime ?? DateTime.now(),
       endTime = endTime ?? DateTime.now();

  /// [copyWith] 불변 복사
  /// [condition] 아침 컨디션
  /// [timeToFallAsleepInMinutes] 잠들기까지 시간(분)
  /// [awakeTimes] 수정할 깨어있음 구간 목록
  /// [events] 수정할 이상행동 목록
  /// [startTime] 수정할 수면 시작 시각
  /// [endTime] 수정할 기상 시각
  /// [sessionType] 수정할 세션 유형
  /// [isSaving] 저장 처리 중 여부
  PostSleepLog copyWith({
    MorningCondition? condition,
    int? timeToFallAsleepInMinutes,
    List<AwakeTime>? awakeTimes,
    List<ProblematicEvent>? events,
    DateTime? startTime,
    DateTime? endTime,
    SleepSessionType? sessionType,
    bool? isSaving,
  }) {
    return PostSleepLog(
      condition: condition ?? this.condition,
      timeToFallAsleepInMinutes:
          timeToFallAsleepInMinutes ?? this.timeToFallAsleepInMinutes,
      awakeTimes: awakeTimes ?? this.awakeTimes,
      events: events ?? this.events,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      sessionType: sessionType ?? this.sessionType,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

@riverpod
class PostSleepLoggingController extends _$PostSleepLoggingController {
  /// [build] 초기 UI 상태 구성
  /// [sleepDataId] 로드할 수면 데이터 문서 ID
  @override
  Future<PostSleepLog> build(String sleepDataId) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) throw Exception('로그인이 필요합니다.');

    final db = ref.read(databaseServiceProvider);
    final childId = ref.read(dashboardNotifierProvider).selectedChildId;
    if (childId == null) {
      throw Exception('선택된 아동이 없습니다. 먼저 대시보드에서 아동을 선택해주세요.');
    }
    final sd = await db.getSleepDataById(user.uid, childId, sleepDataId);
    if (sd == null) {
      throw Exception('ID에 해당하는 수면 데이터를 찾을 수 없습니다: $sleepDataId');
    }

    final analysis = sd.analysis;

    // 구간/이벤트는 그대로 전달(정규화는 모델에서 보장)
    final awakeTimes = List<AwakeTime>.from(analysis.awakeningTimes);
    final events = List<ProblematicEvent>.from(analysis.problematicEvents);

    return PostSleepLog(
      condition: sd.morningCondition,
      timeToFallAsleepInMinutes: analysis.timeToFallAsleep.inMinutes,
      awakeTimes: awakeTimes,
      events: events,
      startTime: sd.startTime,
      endTime: sd.endTime,
      sessionType: sd.sessionType,
    );
  }

  /// [setLogBulk] 화면에서 수집한 모든 값을 한 번에 커밋
  /// [condition] 아침 컨디션
  /// [timeToFallAsleepInMinutes] 잠들기까지 시간(분)
  /// [awakeTimes] 깨어 있었던 구간 목록
  /// [events] 이상행동 목록
  /// [startTime] 수면 시작 시각
  /// [endTime] 기상 시각
  void setLogBulk({
    required MorningCondition condition,
    required int timeToFallAsleepInMinutes,
    required List<AwakeTime?> awakeTimes,
    required List<ProblematicEvent> events,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    if (!state.hasValue) return;
    final safeStart = startTime;
    final safeEnd = endTime.isBefore(safeStart) ? safeStart : endTime;
    state = AsyncData(
      state.value!.copyWith(
        condition: condition,
        timeToFallAsleepInMinutes: timeToFallAsleepInMinutes < 0
            ? 0
            : timeToFallAsleepInMinutes,
        awakeTimes: List<AwakeTime>.from(awakeTimes),
        events: List<ProblematicEvent>.from(events),
        startTime: safeStart,
        endTime: safeEnd,
      ),
    );
  }

  /// [saveLog] 현재 UI 상태를 Firestore에 저장
  /// - 구간 정규화/병합/정렬은 모델(SleepAnalysis.toJson)에서 처리
  /// - ‘깸’ 횟수는 구간 개수로 집계
  Future<void> saveLog(BuildContext context) async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null || !state.hasValue || state.value!.isSaving) return;

    state = AsyncData(state.value!.copyWith(isSaving: true));
    try {
      final db = ref.read(databaseServiceProvider);
      final childId = ref.read(dashboardNotifierProvider).selectedChildId;
      if (childId == null) {
        throw Exception('선택된 아동이 없습니다. 먼저 대시보드에서 아동을 선택해주세요.');
      }
      final childProfile = await db.getChildProfile(user.uid, childId);
      if (childProfile == null) {
        throw Exception('아동 프로필을 불러올 수 없습니다. 다시 시도해주세요.');
      }

      final original = await db.getSleepDataById(
        user.uid,
        childId,
        sleepDataId,
      );
      if (original == null) {
        throw Exception('Original sleep data not found for ID: $sleepDataId');
      }

      final log = state.value!;

      // 1) 이상행동: 공백 메모 정리(트리밍) → 타입/5분 윈도우 기반 중복 제거
      final cleanedEvents = log.events
          .map(
            (e) => ProblematicEvent(
              type: e.type,
              time: e.time,
              note: (e.note != null && e.note!.trim().isNotEmpty)
                  ? e.note!.trim()
                  : null,
              isAuto: e.isAuto,
            ),
          )
          .toList();

      final events = _dedupEventsWithinWindow(cleanedEvents);

      // 2) 분석 모델(구간은 모델이 저장 시 정규화)
      final analysis = SleepAnalysis(
        timeToFallAsleep: Duration(
          minutes: log.timeToFallAsleepInMinutes < 0
              ? 0
              : log.timeToFallAsleepInMinutes,
        ),
        awakeningTimes: log.awakeTimes,
        awakeningsCount: log.awakeTimes.length,
        problematicEvents: events,
      );

      // 3) 수면 점수 계산
      final sleepScore = await calculateSleepScore(
        log: log,
        routine: original.routine,
        analysis: analysis,
        profile: childProfile,
        sessionDate: original.date,
      );

      final update = {
        'sleepScore': sleepScore,
        'morningCondition': log.condition.name,
        'analysis': analysis.toJson(),
        'startTime': log.startTime,
        'endTime': log.endTime,
      };

      // 4. 수면 데이터 업데이트
      await db.updateSleepData(user.uid, original.childId, sleepDataId, update);

      // 5. DLMO 추정
      try {
        final analysisStream = ref
            .read(circadianRhythmServiceProvider)
            .estimateLatency(user.uid, childId);

        if (!context.mounted) return;
        final newLatency = await showDialog<int?>(
          context: context,
          barrierDismissible: false, // 사용자가 다이얼로그 바깥을 탭해도 닫히지 않음
          builder: (_) => AnalysisProgressDialog(stream: analysisStream),
        );
        _log.fine("Latency 계산 완료: $newLatency");

        if (newLatency != null) {
          final updatedProfile = childProfile.copyWith(
            latencyTimeinMinutes: newLatency,
          );
          await db.updateChildProfile(user.uid, updatedProfile);
        }
      } catch (e) {
        _log.warning("[saveLog] DLMO 추정 오류", e);
      }

      // 대시보드 갱신 및 상세 리포트 이동
      await ref.read(dashboardNotifierProvider.notifier).refreshData();

      final updated = await db.getSleepDataById(user.uid, childId, sleepDataId);
      if (context.mounted && updated != null) {
        ref.read(appRouterProvider).go('/home/report', extra: updated);
      }
    } finally {
      if (state.hasValue) {
        state = AsyncData(state.value!.copyWith(isSaving: false));
      }
    }
  }
}

/// [_dedupEventsWithinWindow] 문제행동 이벤트 중복 제거(타입별, 5분 이내 클러스터 머지)
/// [src] 원본 이벤트 목록
/// [window] 중복 판단 간격(기본 5분)
List<ProblematicEvent> _dedupEventsWithinWindow(
  List<ProblematicEvent> src, {
  Duration window = const Duration(minutes: 5),
}) {
  if (src.isEmpty) return const [];

  // 시간 기준 정렬(없으면 뒤로 유지), 타입은 2차 키
  final timed = src.where((e) => e.time != null).toList()
    ..sort((a, b) {
      final t = a.time!.compareTo(b.time!);
      return t != 0 ? t : a.type.name.compareTo(b.type.name);
    });
  final untimed = src.where((e) => e.time == null).toList();

  final out = <ProblematicEvent>[];
  final lastIndexByType = <ProblematicEventType, int>{};

  for (final e in timed) {
    final lastIdx = lastIndexByType[e.type];
    if (lastIdx == null) {
      lastIndexByType[e.type] = out.length;
      out.add(e);
      continue;
    }

    final last = out[lastIdx];
    final diff = e.time!.difference(last.time!);

    if (diff <= window) {
      // 같은 타입 + 5분 이내 → 클러스터 병합
      final mergedNote = (last.note != null && last.note!.isNotEmpty)
          ? last.note
          : e.note;
      final mergedIsAuto = last.isAuto || e.isAuto;

      out[lastIdx] = ProblematicEvent(
        type: last.type,
        time: last.time,
        note: mergedNote,
        isAuto: mergedIsAuto,
      );
    } else {
      lastIndexByType[e.type] = out.length;
      out.add(e);
    }
  }

  // 시간 없는 이벤트는 원본 순서대로 보존
  out.addAll(untimed);
  return out;
}

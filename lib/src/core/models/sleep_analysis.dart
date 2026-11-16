import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:sleepy/src/core/models/problematic_event.dart';
import 'package:sleepy/src/core/utils.dart';

/// [AwakeTime] '깨어 있었던 구간' 값 객체
/// [start] 깨어나기 시작한 시각
/// [end] 다시 잠든 시각(또는 깨어있음 종료 시각)
class AwakeTime extends Equatable {
  final DateTime start;
  final DateTime end;

  const AwakeTime({required this.start, required this.end});

  /// [duration] 깨어 있었던 총 시간(end - start; 음수면 0으로 보정)
  Duration get duration {
    final d = end.difference(start);
    return d.isNegative ? Duration.zero : d;
  }

  /// [toJson] Firestore 저장 포맷으로 직렬화: {start: Timestamp, end: Timestamp}
  Map<String, dynamic> toJson() => {
    'start': Timestamp.fromDate(start),
    'end': Timestamp.fromDate(end),
  };

  /// [tryFromJson] Firestore/JSON 맵에서 안전 파싱(null/형식 오류 시 null)
  static AwakeTime? tryFromJson(Map<String, dynamic> json) {
    final s = (json['start'] as Timestamp?)?.toDate();
    final e = (json['end'] as Timestamp?)?.toDate();
    if (s == null || e == null) return null;
    return AwakeTime(start: s, end: e);
  }

  @override
  List<Object?> get props => [start, end];
}

/// [SleepAnalysis] 수면 분석 데이터를 종합적으로 관리하는 모델
/// [timeToFallAsleep] 잠들기까지 걸린 시간(Duration)
/// [awakeningTimes] 밤중에 깬 시각 목록(오름차순 정렬 보장)
/// [awakeningsCount] 총 ‘깸’ 횟수(사용자 기록 기반, 0 이상으로 정규화됨)
/// [problematicEvents] 수면 중 이상 행동 이벤트 목록
class SleepAnalysis extends Equatable {
  final Duration timeToFallAsleep;
  final List<AwakeTime> awakeningTimes;
  final int awakeningsCount;
  final List<ProblematicEvent> problematicEvents;

  const SleepAnalysis({
    this.timeToFallAsleep = Duration.zero,
    this.awakeningTimes = const [],
    this.awakeningsCount = 0,
    this.problematicEvents = const [],
  });

  @override
  List<Object?> get props => [
    timeToFallAsleep,
    awakeningTimes,
    awakeningsCount,
    problematicEvents,
  ];

  /// [toJson] Firestore 저장용 맵으로 직렬화
  Map<String, dynamic> toJson() {
    return {
      'timeToFallAsleepInMinutes': timeToFallAsleep.inMinutes,
      'awakeningTimes': _normalizeAwakeTimes(
        awakeningTimes,
      ).map((i) => i.toJson()).toList(),
      'awakeningsCount': awakeningsCount,
      'problematicEvents': problematicEvents.map((e) => e.toJson()).toList(),
    };
  }

  /// [SleepAnalysis.fromJson] Firestore/JSON 맵으로부터 역직렬화
  /// [json] 소스 맵
  factory SleepAnalysis.fromJson(Map<String, dynamic> json) {
    final mins = asNonNegativeInt(json['timeToFallAsleepInMinutes']);
    final count = asNonNegativeInt(json['awakeningsCount']);
    final times = (json['awakeningTimes'] as List<dynamic>? ?? [])
        .map((e) => e is Map<String, dynamic> ? AwakeTime.tryFromJson(e) : null)
        .whereType<AwakeTime>()
        .toList();

    return SleepAnalysis(
      timeToFallAsleep: Duration(minutes: mins),
      awakeningTimes: times,
      awakeningsCount: count,
      problematicEvents: (json['problematicEvents'] as List<dynamic>? ?? [])
          .map((e) => ProblematicEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// [copyWith] 불변 복사(시각 목록은 항상 정렬 보장)
  /// [timeToFallAsleep] 변경할 잠들기까지 시간
  /// [awakeningTimes] 변경할 ‘깸’ 시각 목록(정렬 적용)
  /// [awakeningsCount] 변경할 깸 횟수
  /// [problematicEvents] 변경할 이상 행동 목록
  SleepAnalysis copyWith({
    Duration? timeToFallAsleep,
    List<AwakeTime>? awakeningTimes,
    int? awakeningsCount,
    List<ProblematicEvent>? problematicEvents,
  }) {
    return SleepAnalysis(
      timeToFallAsleep: timeToFallAsleep ?? this.timeToFallAsleep,
      awakeningTimes: awakeningTimes == null
          ? this.awakeningTimes
          : _normalizeAwakeTimes(awakeningTimes),
      awakeningsCount: awakeningsCount ?? this.awakeningsCount,
      problematicEvents: problematicEvents ?? this.problematicEvents,
    );
  }
}

/// [_normalizeAwakeTimes] 깨어 있었던 구간 정규화(보정/정렬/병합/0길이 제거)
/// [src] 원본 리스트
/// [mergeGap] 두 구간 간 간격이 이 값 이내면 병합(기본 5분)
List<AwakeTime> _normalizeAwakeTimes(
  List<AwakeTime> src, {
  Duration mergeGap = const Duration(minutes: 5),
}) {
  if (src.isEmpty) return const [];

  // 1) 시작/종료 보정
  final sanitized = <AwakeTime>[];
  for (final i in src) {
    var s = i.start;
    var e = i.end;
    if (e.isBefore(s)) {
      final t = s;
      s = e;
      e = t;
    }
    if (!e.isAfter(s)) {
      // start == end → 0길이 구간 제거
      continue;
    }
    sanitized.add(AwakeTime(start: s, end: e));
  }
  if (sanitized.isEmpty) return const [];

  // 2) 시작 오름차순(동시 시작이면 종료 오름차순) 정렬
  sanitized.sort((a, b) {
    final c = a.start.compareTo(b.start);
    return c != 0 ? c : a.end.compareTo(b.end);
  });

  // 3) 겹침/포함/인접(mergeGap 이내) 병합
  final out = <AwakeTime>[];
  for (final cur in sanitized) {
    if (out.isEmpty) {
      out.add(cur);
      continue;
    }
    final last = out.last;

    final overlap = !cur.start.isAfter(last.end); // cur.start <= last.end
    final near = !cur.start.isAfter(
      last.end.add(mergeGap),
    ); // cur.start <= last.end + gap

    if (overlap || near) {
      final newEnd = cur.end.isAfter(last.end) ? cur.end : last.end;
      out[out.length - 1] = AwakeTime(start: last.start, end: newEnd);
    } else {
      out.add(cur);
    }
  }
  return out;
}

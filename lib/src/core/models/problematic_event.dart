import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:sleepy/src/core/utils.dart';

/// [ProblematicEventType] 수면 중 발생하는 이상 행동의 종류
enum ProblematicEventType {
  urinaryIssue('비뇨 문제'),
  breathingIssue('호흡/기침 문제'),
  snoring('코골이'),
  restlessness('뒤척임/잠꼬대'),
  noise('기타/외부 소음');

  const ProblematicEventType(this.displayName);
  final String displayName;
}

/// [ProblematicEvent] 단일 이상 행동 이벤트 데이터 모델
class ProblematicEvent extends Equatable
    implements Comparable<ProblematicEvent> {
  final ProblematicEventType type;
  final DateTime? time;
  final String? note;
  final bool isAuto;

  const ProblematicEvent({
    required this.type,
    this.time,
    this.note,
    this.isAuto = false,
  });

  /// [hasTime] 시간 보유 여부
  bool get hasTime => time != null;

  /// [now] 지금 시각으로 이벤트 생성
  /// [type] 이벤트 유형
  /// [note] 메모
  /// [isAuto] 자동 감지 여부
  factory ProblematicEvent.now(
    ProblematicEventType type, {
    String? note,
    bool isAuto = false,
  }) => ProblematicEvent(
    type: type,
    time: DateTime.now(),
    note: note,
    isAuto: isAuto,
  );

  /// [auto] 자동 감지 전용 생성
  /// [type] 이벤트 유형
  /// [time] 발생 시각
  /// [note] 메모
  factory ProblematicEvent.auto(
    ProblematicEventType type,
    DateTime time, {
    String? note,
  }) => ProblematicEvent(type: type, time: time, note: note, isAuto: true);

  /// [copyWith] 불변 복사
  /// [type] 변경할 유형
  /// [time] 변경할 시각
  /// [note] 변경할 메모
  /// [isAuto] 변경할 자동 여부
  /// [removeTime] true면 time을 null로
  /// [removeNote] true면 note를 null로
  ProblematicEvent copyWith({
    ProblematicEventType? type,
    DateTime? time,
    String? note,
    bool? isAuto,
    bool removeTime = false,
    bool removeNote = false,
  }) {
    return ProblematicEvent(
      type: type ?? this.type,
      time: removeTime ? null : (time ?? this.time),
      note: removeNote ? null : (note ?? this.note),
      isAuto: isAuto ?? this.isAuto,
    );
  }

  /// [compareTo] 정렬: time 오름차순 → type.name 사전순 (시간 없으면 뒤)
  @override
  int compareTo(ProblematicEvent other) {
    final a = time, b = other.time;
    if (a != null && b != null) {
      final c = a.compareTo(b);
      if (c != 0) return c;
    } else if (a == null && b != null) {
      return 1;
    } else if (a != null && b == null) {
      return -1;
    }
    return type.name.compareTo(other.type.name);
  }

  @override
  List<Object?> get props => [type, time, note, isAuto];

  /// [toJson] Firestore 직렬화(null/빈 값은 생략)
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'type': type.name,
      'isAuto': isAuto, // false라도 명시 저장(쿼리/통계 편의)
    };
    if (time != null) map['time'] = Timestamp.fromDate(time!);
    if (note != null && note!.isNotEmpty) map['note'] = note;
    return map;
  }

  /// [fromJson] Firestore 역직렬화(안전 파서 + 경고)
  /// [json] 소스 맵
  factory ProblematicEvent.fromJson(Map<String, dynamic> json) {
    return ProblematicEvent(
      type: parseProblematicEventType(json['type']),
      time: parseFirestoreTime(json['time']),
      note: json['note'] as String?,
      isAuto: (json['isAuto'] as bool?) ?? false,
    );
  }
}

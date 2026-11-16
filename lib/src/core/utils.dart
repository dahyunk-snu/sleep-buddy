import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sleepy/src/core/models/problematic_event.dart';
import 'package:sleepy/src/core/models/sleep_data.dart';

/// [TimestampConverter] Firestore Timestamp ↔ Dart DateTime 변환기
class TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const TimestampConverter();

  /// [timestamp] Firestore Timestamp → DateTime
  @override
  DateTime fromJson(Timestamp timestamp) => timestamp.toDate();

  /// [date] DateTime → Firestore Timestamp
  @override
  Timestamp toJson(DateTime date) => Timestamp.fromDate(date);
}

/// [parseProblematicEventType] 문자열 → enum 파싱, 실패 시 폴백 + 경고
/// [v] 원본 값
/// [fallback] 파싱 실패 시 대체 타입
ProblematicEventType parseProblematicEventType(
  Object? v, {
  ProblematicEventType fallback = ProblematicEventType.noise,
}) {
  final s = v is String ? v : null;
  if (s == null) return fallback;
  return ProblematicEventType.values.firstWhere(
    (e) => e.name == s,
    orElse: () => fallback,
  );
}

/// [parseFirestoreTime] Firestore/일반 포맷 → DateTime 파싱(안전)
/// [v] Timestamp | String(ISO8601) | int(msSinceEpoch) | DateTime | null
DateTime? parseFirestoreTime(Object? v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) return DateTime.tryParse(v);
  return null;
}

/// [parseTimeList] 시각 리스트 파싱 + 정렬
/// [v] List? (개별 원소는 [parseFirestoreTime]으로 처리)
List<DateTime> parseTimeList(Object? v) {
  final raw = (v is List) ? v : const [];
  final parsed = <DateTime>[];
  for (final e in raw) {
    final dt = parseFirestoreTime(e);
    if (dt != null) parsed.add(dt);
  }
  return sorted(parsed);
}

/// [parseTime] Timestamp/DateTime/int(ms)/String(ISO8601) → DateTime
/// [v] 원본 값
DateTime parseTime(Object? v, {required String field}) {
  if (v == null) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) {
    final dt = DateTime.tryParse(v);
    if (dt != null) return dt;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

/// [parseDate] Timestamp/DateTime/int(ms)/String(ISO8601) → DateTime?
/// [v] 원본 값
DateTime? parseDate(Object? v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) return DateTime.tryParse(v);
  return null;
}

/// [parseSessionType] 문자열 → [SleepSessionType] (fallback: night)
/// [v] 원본 값
SleepSessionType parseSessionType(Object? v) {
  final s = v is String ? v : null;
  if (s == null) return SleepSessionType.night;
  try {
    return SleepSessionType.values.byName(s);
  } catch (_) {
    return SleepSessionType.night;
  }
}

/// [parseMorningCondition] 문자열 → [MorningCondition] (fallback: neutral)
/// [v] 원본 값
MorningCondition parseMorningCondition(Object? v) {
  final s = v is String ? v : null;
  if (s == null) return MorningCondition.neutral;
  try {
    return MorningCondition.values.byName(s);
  } catch (_) {
    return MorningCondition.neutral;
  }
}

/// [parseDailyData] 일별 데이터 목록 파싱(List → 표준 맵 리스트)
/// [raw] 원본 dailyData(없거나 형식 불일치 가능)
List<Map<String, dynamic>> parseDailyData(Object? raw) {
  final list = (raw is List) ? raw : const <dynamic>[];
  final out = <Map<String, dynamic>>[];

  for (final e in list) {
    final m = (e is Map) ? Map<String, dynamic>.from(e) : null;
    if (m == null) continue;

    final date = parseDate(m['date']);
    final sleepScore = asInt(m['sleepScore'], fallback: 0);
    final totalSleepTime = asInt(m['totalSleepTime'], fallback: 0);
    final awakenings = asInt(m['awakenings'], fallback: 0);

    out.add(<String, dynamic>{
      'date': date, // DateTime? (파싱 실패 시 null)
      'sleepScore': sleepScore,
      'totalSleepTime': totalSleepTime,
      'awakenings': awakenings,
    });
  }

  // 날짜가 있다면 정렬(오름차순); null은 뒤로
  out.sort((a, b) {
    final da = a['date'];
    final db = b['date'];
    if (da is DateTime && db is DateTime) return da.compareTo(db);
    if (da == null && db is DateTime) return 1;
    if (da is DateTime && db == null) return -1;
    return 0;
  });

  return out;
}

/// [asNonNegativeInt] 다양한 숫자 표현을 0 이상 정수로 정규화
/// [v] int | num | String | null
int asNonNegativeInt(Object? v) {
  int parsed;
  if (v is int) {
    parsed = v;
  } else if (v is num) {
    parsed = v.toInt();
  } else if (v is String) {
    parsed = int.tryParse(v) ?? 0;
  } else {
    parsed = 0;
  }
  return parsed < 0 ? 0 : parsed;
}

/// [asInt] 다양한 숫자 표현을 정수로 변환(실패 시 fallback)
/// [v] int | num | String | null
/// [fallback] 변환 실패 시 사용할 기본값
int asInt(Object? v, {required int fallback}) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) {
    final p = int.tryParse(v);
    if (p != null) return p;
  }
  return fallback;
}

/// [sorted] DateTime 목록 오름차순 정렬(새 리스트 반환)
/// [src] 원본 목록
List<DateTime> sorted(List<DateTime> src) {
  if (src.isEmpty) return const [];
  final copy = List<DateTime>.from(src)..sort();
  return List<DateTime>.unmodifiable(copy);
}

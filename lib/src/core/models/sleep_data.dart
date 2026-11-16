import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:sleepy/src/core/models/sleep_analysis.dart';
import 'package:sleepy/src/core/models/sleep_routine.dart';
import 'package:sleepy/src/core/utils.dart';

/// [MorningCondition] 아침 컨디션
enum MorningCondition {
  veryGood('상쾌해요'),
  good('개운해요'),
  neutral('그냥 그래요'),
  bad('조금 졸려요'),
  veryBad('피곤해요');

  const MorningCondition(this.displayName);
  final String displayName;
}

/// [SleepSessionType] 낮잠/밤잠 구분
enum SleepSessionType { night, nap }

/// [SleepData] 하룻밤 전체 수면 데이터 모델
/// [id] Firestore 문서 ID
/// [childId] 아동 프로필 ID
/// [date] 세션 날짜(자정 기준)
/// [startTime] 수면 시작 시각
/// [endTime] 수면 종료 시각
/// [sessionType] 낮잠/밤잠 구분
/// [sleepScore] 수면 점수(기본 50)
/// [routine] 취침 루틴 데이터
/// [analysis] 수면 분석 데이터
/// [morningCondition] 아침 컨디션
class SleepData extends Equatable {
  final String? id;
  final String childId;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final SleepSessionType sessionType;
  final int sleepScore;
  final SleepRoutine routine;
  final SleepAnalysis analysis;
  final MorningCondition morningCondition;

  const SleepData({
    this.id,
    required this.childId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.sessionType = SleepSessionType.night,
    this.sleepScore = 50,
    required this.routine,
    required this.analysis,
    this.morningCondition = MorningCondition.neutral,
  });

  @override
  List<Object?> get props => [
    id,
    childId,
    date,
    startTime,
    endTime,
    sessionType,
    sleepScore,
    routine,
    analysis,
    morningCondition,
  ];

  /// [isNap] 낮잠 여부
  bool get isNap => sessionType == SleepSessionType.nap;

  /// [isNight] 밤잠 여부
  bool get isNight => sessionType == SleepSessionType.night;

  /// [sessionIdForAudio] 오디오 세션 식별자(childId:YYYYMMDD-type)
  String get sessionIdForAudio => '$childId:${docIdForDay()}';

  /// [duration] 수면 지속 시간(음수일 경우 0으로 보정)
  Duration get duration {
    final d = endTime.difference(startTime);
    return d.isNegative ? Duration.zero : d;
  }

  /// [normalizedDate] 자정 기준으로 정규화된 날짜
  DateTime get normalizedDate => DateTime(date.year, date.month, date.day);

  /// [docIdForDay] YYYYMMDD-type 형태의 문서 키
  String docIdForDay() {
    final nd = normalizedDate;
    final y = nd.year.toString().padLeft(4, '0');
    final m = nd.month.toString().padLeft(2, '0');
    final d = nd.day.toString().padLeft(2, '0');
    return '$y$m$d-${sessionType.name}';
  }

  /// [SleepData.startNewSession] 새로운 수면 세션 생성(즉시 시작)
  /// [childId] 아동 ID
  /// [routine] 적용할 루틴
  /// [sessionType] 낮잠/밤잠
  factory SleepData.startNewSession({
    required String childId,
    required SleepRoutine routine,
    SleepSessionType sessionType = SleepSessionType.night,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isNight = sessionType == SleepSessionType.night;

    // 밤잠이고 시작 시각이 정오(12:00) 이전이면 날짜를 전날로 설정
    final date = (isNight && now.hour < 12)
        ? today.subtract(const Duration(days: 1))
        : today;
    return SleepData(
      childId: childId,
      date: date,
      startTime: now,
      endTime: now, // 종료 시 업데이트될 임시 값
      sessionType: sessionType,
      routine: routine,
      analysis: const SleepAnalysis(),
    );
  }

  /// [SleepData.fromFirestore] Firestore 스냅샷 → 모델(안전 파싱 + 폴백)
  /// [snapshot] 문서 스냅샷
  factory SleepData.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError(
        'SleepData.fromFirestore: Missing data for snapshot ${snapshot.id}',
      );
    }

    final childId = data['childId'] as String? ?? '';
    final date = parseTime(data['date'], field: 'date');
    final startTime = parseTime(data['startTime'], field: 'startTime');
    final endTime = parseTime(data['endTime'], field: 'endTime');
    final sessionType = parseSessionType(data['sessionType']);
    final sleepScore = (data['sleepScore'] as int?) ?? 50;
    final routine = SleepRoutine.fromJson(
      (data['routine'] as Map<String, dynamic>?) ?? const {},
    );
    final analysis = SleepAnalysis.fromJson(
      (data['analysis'] as Map<String, dynamic>?) ?? const {},
    );
    final morningCondition = parseMorningCondition(data['morningCondition']);

    return SleepData(
      id: snapshot.id,
      childId: childId,
      date: date,
      startTime: startTime,
      endTime: endTime,
      sessionType: sessionType,
      sleepScore: sleepScore,
      routine: routine,
      analysis: analysis,
      morningCondition: morningCondition,
    );
  }

  /// [toFirestore] 모델 → Firestore 저장용 맵
  Map<String, dynamic> toFirestore() {
    return {
      'childId': childId,
      'date': Timestamp.fromDate(date),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'sessionType': sessionType.name,
      'sleepScore': sleepScore,
      'routine': routine.toJson(),
      'analysis': analysis.toJson(),
      'morningCondition': morningCondition.name,
    };
  }
}

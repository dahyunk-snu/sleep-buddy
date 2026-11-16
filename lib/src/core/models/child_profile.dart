import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sleepy/src/core/utils.dart';
part 'child_profile.freezed.dart';
part 'child_profile.g.dart';

/// [ChildProfile] 아동 프로필 도메인 모델
/// [id] Firestore 문서 ID (toFirestore에서는 제외)
/// [firstName] 이름
/// [lastName] 성
/// [gender] 성별 (도메인에서 허용 값 검증 권장)
/// [birthDate] 생년월일 (Timestamp ↔ DateTime 컨버터 적용)
/// [activityLevel] 활동 수준
/// [avgBedTime] 평소 취침 시각(문자열 형식)
/// [avgWakeUpTime] 평소 기상 시각(문자열 형식)
/// [timeToSleep] 잠들기까지 소요 시간(문자열 형식)
/// [sleepBehaviors] 수면 행동(복수 선택)
/// [sleepConcerns] 수면 고민/문제(복수 선택)
/// [goalBedTime] 목표 취침 시각(문자열 형식)
/// [goalWakeUpTime] 목표 기상 시각(문자열 형식)
@freezed
class ChildProfile with _$ChildProfile {
  const ChildProfile._();
  const factory ChildProfile({
    required String id,
    required String firstName,
    required String lastName,
    required String gender,
    @TimestampConverter() required DateTime birthDate,
    required String activityLevel,
    required String avgBedTime,
    required String avgWakeUpTime,
    required String timeToSleep,
    required List<String> sleepBehaviors,
    required List<String> sleepConcerns,
    required String goalBedTime,
    required String goalWakeUpTime,
    required int latencyTimeinMinutes,
  }) = _ChildProfile;

  /// [fromJson] JSON → 도메인 모델
  factory ChildProfile.fromJson(Map<String, dynamic> json) =>
      _$ChildProfileFromJson(json);

  /// [fromFirestore] DocumentSnapshot → 도메인 모델 (withConverter와 호환)
  /// [snapshot] 문서 스냅샷
  /// [options] 스냅샷 옵션
  factory ChildProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Missing data for ChildProfile ${snapshot.id}');
    }
    final merged = <String, dynamic>{...data, 'id': snapshot.id};
    return ChildProfile.fromJson(merged);
  }

  /// [toFirestore] 도메인 모델 → Firestore 저장용 맵 (id 제외)
  Map<String, dynamic> toFirestore() {
    return toJson()..remove('id');
  }
}

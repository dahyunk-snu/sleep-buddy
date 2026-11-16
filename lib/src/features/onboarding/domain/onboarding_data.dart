import 'package:equatable/equatable.dart';

/// 온보딩 과정에서 수집되는 데이터를 담는 클래스입니다.
class OnboardingData extends Equatable {
  const OnboardingData({
    this.profileId,
    this.childFirstName = '',
    this.childLastName = '',
    this.childGender = '',
    this.childBirthDate,
    this.activityLevel = '',
    this.avgBedTime = '',
    this.avgWakeUpTime = '',
    this.timeToSleep = '',
    this.sleepBehaviors = const <String>{},
    this.sleepConcerns  = const <String>{},
    this.goalBedTime = '',
    this.goalWakeUpTime = '',
  });

  final String? profileId;
  /// 아동 이름
  final String childFirstName;
  /// 아동 성
  final String childLastName;
  /// 아동 성별
  final String childGender;
  /// 아동 생년월일
  final DateTime? childBirthDate;
  /// 활동 수준 (예: '높음', '보통', '낮음')
  final String activityLevel;
  /// 평균 취침 시간
  final String avgBedTime;
  /// 평균 기상 시간
  final String avgWakeUpTime;
  /// 잠들기까지 걸리는 시간
  final String timeToSleep;
  /// 수면 중 보이는 행동 (복수 선택)
  final Set<String> sleepBehaviors;
  /// 수면에 대한 우려 사항 (복수 선택)
  final Set<String> sleepConcerns;
  final String goalBedTime;
  final String goalWakeUpTime;

  /// Firestore에 저장하기 위해 객체를 Map으로 변환합니다.
  Map<String, dynamic> toJson() {
    return {
      'profileId': profileId,
      'childFirstName': childFirstName,
      'childLastName': childLastName,
      'childGender': childGender,
      'childBirthDate': childBirthDate, // Firestore는 DateTime을 Timestamp로 자동 변환합니다.
      'activityLevel': activityLevel,
      'avgBedTime': avgBedTime,
      'avgWakeUpTime': avgWakeUpTime,
      'timeToSleep': timeToSleep,
      'sleepBehaviors': sleepBehaviors.toList(), // Firestore는 Set 대신 List를 사용합니다.
      'sleepConcerns': sleepConcerns.toList(),
      'goalBedTime': goalBedTime,
      'goalWakeUpTime': goalWakeUpTime,
    };
  }

  OnboardingData copyWith({
    String? profileId,
    String? childFirstName,
    String? childLastName,
    String? childGender,
    DateTime? childBirthDate,
    String? activityLevel,
    String? avgBedTime,
    String? avgWakeUpTime,
    String? timeToSleep,
    Set<String>? sleepBehaviors,
    Set<String>? sleepConcerns,
    String? goalBedTime,
    String? goalWakeUpTime,
  }) {
    return OnboardingData(
      profileId: profileId ?? this.profileId,
      childFirstName: childFirstName ?? this.childFirstName,
      childLastName: childLastName ?? this.childLastName,
      childGender: childGender ?? this.childGender,
      childBirthDate: childBirthDate ?? this.childBirthDate,
      activityLevel: activityLevel ?? this.activityLevel,
      avgBedTime: avgBedTime ?? this.avgBedTime,
      avgWakeUpTime: avgWakeUpTime ?? this.avgWakeUpTime,
      timeToSleep: timeToSleep ?? this.timeToSleep,
      sleepBehaviors: sleepBehaviors ?? this.sleepBehaviors,
      sleepConcerns: sleepConcerns ?? this.sleepConcerns,
      goalBedTime: goalBedTime ?? this.goalBedTime,
      goalWakeUpTime: goalWakeUpTime ?? this.goalWakeUpTime,
    );
  }

  @override
  List<Object?> get props => [
        profileId,
        childFirstName, childLastName, childGender, childBirthDate, activityLevel,
        avgBedTime, avgWakeUpTime, timeToSleep,
        sleepBehaviors, sleepConcerns,
        goalBedTime, goalWakeUpTime,
      ];
}
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'child_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChildProfileImpl _$$ChildProfileImplFromJson(Map<String, dynamic> json) =>
    _$ChildProfileImpl(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      gender: json['gender'] as String,
      birthDate: const TimestampConverter().fromJson(
        json['birthDate'] as Timestamp,
      ),
      activityLevel: json['activityLevel'] as String,
      avgBedTime: json['avgBedTime'] as String,
      avgWakeUpTime: json['avgWakeUpTime'] as String,
      timeToSleep: json['timeToSleep'] as String,
      sleepBehaviors: (json['sleepBehaviors'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      sleepConcerns: (json['sleepConcerns'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      goalBedTime: json['goalBedTime'] as String,
      goalWakeUpTime: json['goalWakeUpTime'] as String,
      latencyTimeinMinutes: (json['latencyTimeinMinutes'] as num).toInt(),
    );

Map<String, dynamic> _$$ChildProfileImplToJson(_$ChildProfileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'gender': instance.gender,
      'birthDate': const TimestampConverter().toJson(instance.birthDate),
      'activityLevel': instance.activityLevel,
      'avgBedTime': instance.avgBedTime,
      'avgWakeUpTime': instance.avgWakeUpTime,
      'timeToSleep': instance.timeToSleep,
      'sleepBehaviors': instance.sleepBehaviors,
      'sleepConcerns': instance.sleepConcerns,
      'goalBedTime': instance.goalBedTime,
      'goalWakeUpTime': instance.goalWakeUpTime,
      'latencyTimeinMinutes': instance.latencyTimeinMinutes,
    };

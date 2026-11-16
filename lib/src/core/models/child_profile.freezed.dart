// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'child_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ChildProfile _$ChildProfileFromJson(Map<String, dynamic> json) {
  return _ChildProfile.fromJson(json);
}

/// @nodoc
mixin _$ChildProfile {
  String get id => throw _privateConstructorUsedError;
  String get firstName => throw _privateConstructorUsedError;
  String get lastName => throw _privateConstructorUsedError;
  String get gender => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get birthDate => throw _privateConstructorUsedError;
  String get activityLevel => throw _privateConstructorUsedError;
  String get avgBedTime => throw _privateConstructorUsedError;
  String get avgWakeUpTime => throw _privateConstructorUsedError;
  String get timeToSleep => throw _privateConstructorUsedError;
  List<String> get sleepBehaviors => throw _privateConstructorUsedError;
  List<String> get sleepConcerns => throw _privateConstructorUsedError;
  String get goalBedTime => throw _privateConstructorUsedError;
  String get goalWakeUpTime => throw _privateConstructorUsedError;
  int get latencyTimeinMinutes => throw _privateConstructorUsedError;

  /// Serializes this ChildProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChildProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChildProfileCopyWith<ChildProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChildProfileCopyWith<$Res> {
  factory $ChildProfileCopyWith(
    ChildProfile value,
    $Res Function(ChildProfile) then,
  ) = _$ChildProfileCopyWithImpl<$Res, ChildProfile>;
  @useResult
  $Res call({
    String id,
    String firstName,
    String lastName,
    String gender,
    @TimestampConverter() DateTime birthDate,
    String activityLevel,
    String avgBedTime,
    String avgWakeUpTime,
    String timeToSleep,
    List<String> sleepBehaviors,
    List<String> sleepConcerns,
    String goalBedTime,
    String goalWakeUpTime,
    int latencyTimeinMinutes,
  });
}

/// @nodoc
class _$ChildProfileCopyWithImpl<$Res, $Val extends ChildProfile>
    implements $ChildProfileCopyWith<$Res> {
  _$ChildProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChildProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? firstName = null,
    Object? lastName = null,
    Object? gender = null,
    Object? birthDate = null,
    Object? activityLevel = null,
    Object? avgBedTime = null,
    Object? avgWakeUpTime = null,
    Object? timeToSleep = null,
    Object? sleepBehaviors = null,
    Object? sleepConcerns = null,
    Object? goalBedTime = null,
    Object? goalWakeUpTime = null,
    Object? latencyTimeinMinutes = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            firstName: null == firstName
                ? _value.firstName
                : firstName // ignore: cast_nullable_to_non_nullable
                      as String,
            lastName: null == lastName
                ? _value.lastName
                : lastName // ignore: cast_nullable_to_non_nullable
                      as String,
            gender: null == gender
                ? _value.gender
                : gender // ignore: cast_nullable_to_non_nullable
                      as String,
            birthDate: null == birthDate
                ? _value.birthDate
                : birthDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            activityLevel: null == activityLevel
                ? _value.activityLevel
                : activityLevel // ignore: cast_nullable_to_non_nullable
                      as String,
            avgBedTime: null == avgBedTime
                ? _value.avgBedTime
                : avgBedTime // ignore: cast_nullable_to_non_nullable
                      as String,
            avgWakeUpTime: null == avgWakeUpTime
                ? _value.avgWakeUpTime
                : avgWakeUpTime // ignore: cast_nullable_to_non_nullable
                      as String,
            timeToSleep: null == timeToSleep
                ? _value.timeToSleep
                : timeToSleep // ignore: cast_nullable_to_non_nullable
                      as String,
            sleepBehaviors: null == sleepBehaviors
                ? _value.sleepBehaviors
                : sleepBehaviors // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            sleepConcerns: null == sleepConcerns
                ? _value.sleepConcerns
                : sleepConcerns // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            goalBedTime: null == goalBedTime
                ? _value.goalBedTime
                : goalBedTime // ignore: cast_nullable_to_non_nullable
                      as String,
            goalWakeUpTime: null == goalWakeUpTime
                ? _value.goalWakeUpTime
                : goalWakeUpTime // ignore: cast_nullable_to_non_nullable
                      as String,
            latencyTimeinMinutes: null == latencyTimeinMinutes
                ? _value.latencyTimeinMinutes
                : latencyTimeinMinutes // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChildProfileImplCopyWith<$Res>
    implements $ChildProfileCopyWith<$Res> {
  factory _$$ChildProfileImplCopyWith(
    _$ChildProfileImpl value,
    $Res Function(_$ChildProfileImpl) then,
  ) = __$$ChildProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String firstName,
    String lastName,
    String gender,
    @TimestampConverter() DateTime birthDate,
    String activityLevel,
    String avgBedTime,
    String avgWakeUpTime,
    String timeToSleep,
    List<String> sleepBehaviors,
    List<String> sleepConcerns,
    String goalBedTime,
    String goalWakeUpTime,
    int latencyTimeinMinutes,
  });
}

/// @nodoc
class __$$ChildProfileImplCopyWithImpl<$Res>
    extends _$ChildProfileCopyWithImpl<$Res, _$ChildProfileImpl>
    implements _$$ChildProfileImplCopyWith<$Res> {
  __$$ChildProfileImplCopyWithImpl(
    _$ChildProfileImpl _value,
    $Res Function(_$ChildProfileImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChildProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? firstName = null,
    Object? lastName = null,
    Object? gender = null,
    Object? birthDate = null,
    Object? activityLevel = null,
    Object? avgBedTime = null,
    Object? avgWakeUpTime = null,
    Object? timeToSleep = null,
    Object? sleepBehaviors = null,
    Object? sleepConcerns = null,
    Object? goalBedTime = null,
    Object? goalWakeUpTime = null,
    Object? latencyTimeinMinutes = null,
  }) {
    return _then(
      _$ChildProfileImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        firstName: null == firstName
            ? _value.firstName
            : firstName // ignore: cast_nullable_to_non_nullable
                  as String,
        lastName: null == lastName
            ? _value.lastName
            : lastName // ignore: cast_nullable_to_non_nullable
                  as String,
        gender: null == gender
            ? _value.gender
            : gender // ignore: cast_nullable_to_non_nullable
                  as String,
        birthDate: null == birthDate
            ? _value.birthDate
            : birthDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        activityLevel: null == activityLevel
            ? _value.activityLevel
            : activityLevel // ignore: cast_nullable_to_non_nullable
                  as String,
        avgBedTime: null == avgBedTime
            ? _value.avgBedTime
            : avgBedTime // ignore: cast_nullable_to_non_nullable
                  as String,
        avgWakeUpTime: null == avgWakeUpTime
            ? _value.avgWakeUpTime
            : avgWakeUpTime // ignore: cast_nullable_to_non_nullable
                  as String,
        timeToSleep: null == timeToSleep
            ? _value.timeToSleep
            : timeToSleep // ignore: cast_nullable_to_non_nullable
                  as String,
        sleepBehaviors: null == sleepBehaviors
            ? _value._sleepBehaviors
            : sleepBehaviors // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        sleepConcerns: null == sleepConcerns
            ? _value._sleepConcerns
            : sleepConcerns // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        goalBedTime: null == goalBedTime
            ? _value.goalBedTime
            : goalBedTime // ignore: cast_nullable_to_non_nullable
                  as String,
        goalWakeUpTime: null == goalWakeUpTime
            ? _value.goalWakeUpTime
            : goalWakeUpTime // ignore: cast_nullable_to_non_nullable
                  as String,
        latencyTimeinMinutes: null == latencyTimeinMinutes
            ? _value.latencyTimeinMinutes
            : latencyTimeinMinutes // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ChildProfileImpl extends _ChildProfile {
  const _$ChildProfileImpl({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.gender,
    @TimestampConverter() required this.birthDate,
    required this.activityLevel,
    required this.avgBedTime,
    required this.avgWakeUpTime,
    required this.timeToSleep,
    required final List<String> sleepBehaviors,
    required final List<String> sleepConcerns,
    required this.goalBedTime,
    required this.goalWakeUpTime,
    required this.latencyTimeinMinutes,
  }) : _sleepBehaviors = sleepBehaviors,
       _sleepConcerns = sleepConcerns,
       super._();

  factory _$ChildProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChildProfileImplFromJson(json);

  @override
  final String id;
  @override
  final String firstName;
  @override
  final String lastName;
  @override
  final String gender;
  @override
  @TimestampConverter()
  final DateTime birthDate;
  @override
  final String activityLevel;
  @override
  final String avgBedTime;
  @override
  final String avgWakeUpTime;
  @override
  final String timeToSleep;
  final List<String> _sleepBehaviors;
  @override
  List<String> get sleepBehaviors {
    if (_sleepBehaviors is EqualUnmodifiableListView) return _sleepBehaviors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sleepBehaviors);
  }

  final List<String> _sleepConcerns;
  @override
  List<String> get sleepConcerns {
    if (_sleepConcerns is EqualUnmodifiableListView) return _sleepConcerns;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sleepConcerns);
  }

  @override
  final String goalBedTime;
  @override
  final String goalWakeUpTime;
  @override
  final int latencyTimeinMinutes;

  @override
  String toString() {
    return 'ChildProfile(id: $id, firstName: $firstName, lastName: $lastName, gender: $gender, birthDate: $birthDate, activityLevel: $activityLevel, avgBedTime: $avgBedTime, avgWakeUpTime: $avgWakeUpTime, timeToSleep: $timeToSleep, sleepBehaviors: $sleepBehaviors, sleepConcerns: $sleepConcerns, goalBedTime: $goalBedTime, goalWakeUpTime: $goalWakeUpTime, latencyTimeinMinutes: $latencyTimeinMinutes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChildProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.birthDate, birthDate) ||
                other.birthDate == birthDate) &&
            (identical(other.activityLevel, activityLevel) ||
                other.activityLevel == activityLevel) &&
            (identical(other.avgBedTime, avgBedTime) ||
                other.avgBedTime == avgBedTime) &&
            (identical(other.avgWakeUpTime, avgWakeUpTime) ||
                other.avgWakeUpTime == avgWakeUpTime) &&
            (identical(other.timeToSleep, timeToSleep) ||
                other.timeToSleep == timeToSleep) &&
            const DeepCollectionEquality().equals(
              other._sleepBehaviors,
              _sleepBehaviors,
            ) &&
            const DeepCollectionEquality().equals(
              other._sleepConcerns,
              _sleepConcerns,
            ) &&
            (identical(other.goalBedTime, goalBedTime) ||
                other.goalBedTime == goalBedTime) &&
            (identical(other.goalWakeUpTime, goalWakeUpTime) ||
                other.goalWakeUpTime == goalWakeUpTime) &&
            (identical(other.latencyTimeinMinutes, latencyTimeinMinutes) ||
                other.latencyTimeinMinutes == latencyTimeinMinutes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    firstName,
    lastName,
    gender,
    birthDate,
    activityLevel,
    avgBedTime,
    avgWakeUpTime,
    timeToSleep,
    const DeepCollectionEquality().hash(_sleepBehaviors),
    const DeepCollectionEquality().hash(_sleepConcerns),
    goalBedTime,
    goalWakeUpTime,
    latencyTimeinMinutes,
  );

  /// Create a copy of ChildProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChildProfileImplCopyWith<_$ChildProfileImpl> get copyWith =>
      __$$ChildProfileImplCopyWithImpl<_$ChildProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChildProfileImplToJson(this);
  }
}

abstract class _ChildProfile extends ChildProfile {
  const factory _ChildProfile({
    required final String id,
    required final String firstName,
    required final String lastName,
    required final String gender,
    @TimestampConverter() required final DateTime birthDate,
    required final String activityLevel,
    required final String avgBedTime,
    required final String avgWakeUpTime,
    required final String timeToSleep,
    required final List<String> sleepBehaviors,
    required final List<String> sleepConcerns,
    required final String goalBedTime,
    required final String goalWakeUpTime,
    required final int latencyTimeinMinutes,
  }) = _$ChildProfileImpl;
  const _ChildProfile._() : super._();

  factory _ChildProfile.fromJson(Map<String, dynamic> json) =
      _$ChildProfileImpl.fromJson;

  @override
  String get id;
  @override
  String get firstName;
  @override
  String get lastName;
  @override
  String get gender;
  @override
  @TimestampConverter()
  DateTime get birthDate;
  @override
  String get activityLevel;
  @override
  String get avgBedTime;
  @override
  String get avgWakeUpTime;
  @override
  String get timeToSleep;
  @override
  List<String> get sleepBehaviors;
  @override
  List<String> get sleepConcerns;
  @override
  String get goalBedTime;
  @override
  String get goalWakeUpTime;
  @override
  int get latencyTimeinMinutes;

  /// Create a copy of ChildProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChildProfileImplCopyWith<_$ChildProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dream_friend.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

DreamFriend _$DreamFriendFromJson(Map<String, dynamic> json) {
  return _DreamFriend.fromJson(json);
}

/// @nodoc
mixin _$DreamFriend {
  // 고유 식별자. 각 꿈친구를 구분하는 데 사용됩니다.
  String get id => throw _privateConstructorUsedError; // 사용자가 지정하는 꿈친구의 이름입니다.
  String get name =>
      throw _privateConstructorUsedError; // 꿈친구의 성격, 말투, 역할을 정의하는 페르소나 텍스트입니다.
  // 이 페르소나는 나중에 AI 모델에 전달되어 대화에 반영됩니다.
  String get persona => throw _privateConstructorUsedError;

  /// Serializes this DreamFriend to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DreamFriend
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DreamFriendCopyWith<DreamFriend> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DreamFriendCopyWith<$Res> {
  factory $DreamFriendCopyWith(
    DreamFriend value,
    $Res Function(DreamFriend) then,
  ) = _$DreamFriendCopyWithImpl<$Res, DreamFriend>;
  @useResult
  $Res call({String id, String name, String persona});
}

/// @nodoc
class _$DreamFriendCopyWithImpl<$Res, $Val extends DreamFriend>
    implements $DreamFriendCopyWith<$Res> {
  _$DreamFriendCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DreamFriend
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? persona = null}) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            persona: null == persona
                ? _value.persona
                : persona // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DreamFriendImplCopyWith<$Res>
    implements $DreamFriendCopyWith<$Res> {
  factory _$$DreamFriendImplCopyWith(
    _$DreamFriendImpl value,
    $Res Function(_$DreamFriendImpl) then,
  ) = __$$DreamFriendImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String persona});
}

/// @nodoc
class __$$DreamFriendImplCopyWithImpl<$Res>
    extends _$DreamFriendCopyWithImpl<$Res, _$DreamFriendImpl>
    implements _$$DreamFriendImplCopyWith<$Res> {
  __$$DreamFriendImplCopyWithImpl(
    _$DreamFriendImpl _value,
    $Res Function(_$DreamFriendImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of DreamFriend
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? id = null, Object? name = null, Object? persona = null}) {
    return _then(
      _$DreamFriendImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        persona: null == persona
            ? _value.persona
            : persona // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DreamFriendImpl implements _DreamFriend {
  const _$DreamFriendImpl({
    required this.id,
    required this.name,
    required this.persona,
  });

  factory _$DreamFriendImpl.fromJson(Map<String, dynamic> json) =>
      _$$DreamFriendImplFromJson(json);

  // 고유 식별자. 각 꿈친구를 구분하는 데 사용됩니다.
  @override
  final String id;
  // 사용자가 지정하는 꿈친구의 이름입니다.
  @override
  final String name;
  // 꿈친구의 성격, 말투, 역할을 정의하는 페르소나 텍스트입니다.
  // 이 페르소나는 나중에 AI 모델에 전달되어 대화에 반영됩니다.
  @override
  final String persona;

  @override
  String toString() {
    return 'DreamFriend(id: $id, name: $name, persona: $persona)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DreamFriendImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.persona, persona) || other.persona == persona));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, persona);

  /// Create a copy of DreamFriend
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DreamFriendImplCopyWith<_$DreamFriendImpl> get copyWith =>
      __$$DreamFriendImplCopyWithImpl<_$DreamFriendImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DreamFriendImplToJson(this);
  }
}

abstract class _DreamFriend implements DreamFriend {
  const factory _DreamFriend({
    required final String id,
    required final String name,
    required final String persona,
  }) = _$DreamFriendImpl;

  factory _DreamFriend.fromJson(Map<String, dynamic> json) =
      _$DreamFriendImpl.fromJson;

  // 고유 식별자. 각 꿈친구를 구분하는 데 사용됩니다.
  @override
  String get id; // 사용자가 지정하는 꿈친구의 이름입니다.
  @override
  String get name; // 꿈친구의 성격, 말투, 역할을 정의하는 페르소나 텍스트입니다.
  // 이 페르소나는 나중에 AI 모델에 전달되어 대화에 반영됩니다.
  @override
  String get persona;

  /// Create a copy of DreamFriend
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DreamFriendImplCopyWith<_$DreamFriendImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

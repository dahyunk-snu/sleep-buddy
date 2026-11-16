import 'package:flutter/foundation.dart';

/// [UserProfile] 사용자 프로필 불변 모델
/// [name] 사용자 이름
@immutable
class UserProfile {
  const UserProfile({required this.name});

  final String name;
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'dream_friend.freezed.dart';
part 'dream_friend.g.dart';

@freezed
class DreamFriend with _$DreamFriend {
  const factory DreamFriend({
    // 고유 식별자. 각 꿈친구를 구분하는 데 사용됩니다.
    required String id,
    // 사용자가 지정하는 꿈친구의 이름입니다.
    required String name,
    // 꿈친구의 성격, 말투, 역할을 정의하는 페르소나 텍스트입니다.
    // 이 페르소나는 나중에 AI 모델에 전달되어 대화에 반영됩니다.
    required String persona,
  }) = _DreamFriend;

  // JSON 데이터를 DreamFriend 객체로 변환하는 factory 생성자입니다.
  // Firestore에서 데이터를 읽어올 때 사용됩니다.
  factory DreamFriend.fromJson(Map<String, dynamic> json) =>
      _$DreamFriendFromJson(json);
}
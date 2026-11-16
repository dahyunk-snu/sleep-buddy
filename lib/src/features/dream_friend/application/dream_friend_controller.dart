import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:sleepy/src/core/services/chat_service.dart';
import 'package:sleepy/src/features/dream_friend/domain/dream_friend.dart';
import 'package:sleepy/src/features/dream_friend/presentation/widgets/chat_message.dart';

// 꿈친구의 연결 상태를 나타내는 Enum
enum DreamFriendStatus {
  notConnected,
  connecting,
  connected,
}

// 꿈친구 화면의 전체 상태를 담는 클래스
class DreamFriendState extends Equatable {
  const DreamFriendState({
    this.status = DreamFriendStatus.notConnected,
    this.lastTalkTime = '방금 전',
    this.messages = const [],
    this.isReplying = false,
    this.selectedFriend,
  });

  final DreamFriendStatus status;
  final String lastTalkTime;
  final List<ChatMessage> messages;
  final bool isReplying;
  final DreamFriend? selectedFriend;

  DreamFriendState copyWith({
    DreamFriendStatus? status,
    String? lastTalkTime,
    List<ChatMessage>? messages,
    bool? isReplying,
    DreamFriend? selectedFriend,
    bool clearSelectedFriend = false,
  }) {
    return DreamFriendState(
      status: status ?? this.status,
      lastTalkTime: lastTalkTime ?? this.lastTalkTime,
      messages: messages ?? this.messages,
      isReplying: isReplying ?? this.isReplying,
      selectedFriend: clearSelectedFriend ? null : selectedFriend ?? this.selectedFriend,
    );
  }

  @override
  List<Object?> get props => [status, lastTalkTime, messages, isReplying, selectedFriend];
}

// DreamFriendController를 위한 Provider (수정된 부분)
final dreamFriendControllerProvider =
    StateNotifierProvider<DreamFriendController, DreamFriendState>((ref) {
  return DreamFriendController(ref);
});

final _log = Logger('DreamFriendController');

// 꿈친구 화면의 상태와 비즈니스 로직을 관리하는 컨트롤러
class DreamFriendController extends StateNotifier<DreamFriendState> {
  DreamFriendController(this._ref) : super(const DreamFriendState());

  final Ref _ref;

  // 꿈친구와 연결을 시도하는 메소드
  Future<void> connectToDreamFriend() async {
    // 1. 상태를 '연결 중'으로 변경하여 UI에 로딩 표시
    state = state.copyWith(status: DreamFriendStatus.connecting);

    // 2. 실제로는 여기에 블루투스 연결 또는 서버 통신 로직이 들어갑니다.

    // 3. 연결 성공 후 상태를 '연결 완료'로 변경
    state = state.copyWith(status: DreamFriendStatus.connected);
  }

  /// [sendMessage] 사용자 메시지를 전송하고 Gemini API로부터 응답을 받습니다.
  Future<String> sendMessage(String message) async {
    // 0. 꿈친구가 선택되었는지 확인
    if (state.selectedFriend == null) {
      _log.warning('꿈친구가 선택되지 않은 상태에서 메시지 전송 시도');
      final errorMessage = ChatMessage(text: '먼저 꿈친구를 선택해주세요.', isUser: false);
      state = state.copyWith(messages: [...state.messages, errorMessage]);
      return '';
    }

    // 1. 사용자 메시지를 즉시 채팅 목록에 추가하고, 응답 대기 상태로 변경
    final userMessage = ChatMessage(text: message, isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isReplying: true,
    );

    try {
      // 2. ChatService를 통해 Gemini API 호출
      final chatService = _ref.read(chatServiceProvider);
      final String response = await chatService.sendMessage(message, persona: state.selectedFriend!.persona,);

      // 3. 응답 메시지를 채팅 목록에 추가
      final botMessage = ChatMessage(text: response, isUser: false);
      state = state.copyWith(messages: [...state.messages, botMessage]);
      state = state.copyWith(isReplying: false);
      return response;
    } catch (e, s) {
      _log.severe('메시지 전송 또는 응답 수신 실패', e, s);
      final String response = '메시지 전송에 실패했어요. 다시 시도해주세요.';
      final errorMessage = ChatMessage(text: response, isUser: false);
      state = state.copyWith(messages: [...state.messages, errorMessage]);
      state = state.copyWith(isReplying: false);
      return response;
    }
  }

   /// [selectFriend] 사용자가 꿈친구를 선택하면 상태를 업데이트합니다.
  void selectFriend(DreamFriend friend) {
    _log.info('꿈친구 선택: ${friend.name}');
    state = state.copyWith(selectedFriend: friend);
  }

  /// [clearSelectedFriend] 꿈친구 선택을 해제합니다.
  void clearSelectedFriend() {
    _log.info('꿈친구 선택 해제');
    state = state.copyWith(clearSelectedFriend: true);
  }

  // 연결 해제 메소드
  void disconnect() {
    state = state.copyWith(status: DreamFriendStatus.notConnected);
  }
}
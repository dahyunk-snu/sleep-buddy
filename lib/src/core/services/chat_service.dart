import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:sleepy/src/core/services/auth_service.dart';

/// [_log] ChatService용 로거
final _log = Logger('ChatService');

/// [firebaseFunctionsProvider] Firebase Functions 인스턴스
final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instanceFor(region: 'asia-northeast3');
});

/// [chatServiceProvider] ChatService DI
/// [ref] Riverpod Ref
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ref.watch(firebaseFunctionsProvider), ref);
});

/// [ChatService] Cloud Functions 기반 대화 응답 생성
/// [_functions] Firebase Functions
/// [_ref] Riverpod Ref
class ChatService {
  ChatService(this._functions, this._ref);

  final FirebaseFunctions _functions;
  final Ref _ref;

  /// [_defaultPersona] 기본 페르소나 프롬프트
  static const String _defaultPersona = '너는 친절하고 귀여운 고양이 친구야. 고양이라고 생각하고 말해줘.';

  /// [_errorMessage] 에러가 발생했을 때 반환하는 메세지
  static const String _errorMessage =
      '미안, 지금은 대답하기 조금 어려운 것 같아. 조금 뒤에 다시 이야기해줄래?';

  /// [sendMessage] 대화 요청 전송
  /// [userMessage] 사용자 입력
  /// [persona] 페르소나 프롬프트(미지정 시 기본값)
  Future<String> sendMessage(String userMessage, {String? persona}) async {
    final user = _ref.read(authServiceProvider).currentUser;

    // 인증 확인
    if (user != null) {
      _log.info('Calling function as authenticated user: ${user.uid}');
    } else {
      _log.info('Calling function as unauthenticated user.');
      return '오류: 로그인이 필요한 기능입니다.';
    }

    // 입력 검증
    final msg = userMessage.trim();
    if (msg.isEmpty) {
      return '다시 말해주세요.';
    }

    try {
      final callable = _functions.httpsCallable(
        'generateChatResponse',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 20)),
      );
      final result = await callable.call<Map<String, dynamic>>({
        'persona': persona ?? _defaultPersona,
        'message': userMessage,
      });
      final text = result.data['text'] as String?;
      if (text == null || text.isEmpty) {
        return _errorMessage;
      }
      return text;
    } on FirebaseFunctionsException catch (e, s) {
      _log.severe('Cloud Function 호출 중 오류 발생: ${e.code}', e, s);
      return e.message ?? '꿈친구와 연결하는 데 실패했어요.';
    } catch (e, s) {
      _log.severe('알 수 없는 오류 발생', e, s);
      return _errorMessage;
    }
  }
}

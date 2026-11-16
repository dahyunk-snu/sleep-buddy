import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

/// FirebaseException → 한글 메시지 변환 및 스낵바 표시 유틸

/// [_kGenericUnknownMessage] 공통 기본 오류 메시지
const String _kGenericUnknownMessage = '알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';

/// [_networkErrorCodes] 네트워크 관련 오류 코드 묶음
const Set<String> _networkErrorCodes = {
  'unavailable',
  'network-request-failed',
};

/// [_permissionDeniedCodes] 권한 거부 관련 오류 코드 묶음
const Set<String> _permissionDeniedCodes = {'permission-denied'};

/// [_notFoundCodes] 데이터 없음 관련 오류 코드 묶음
const Set<String> _notFoundCodes = {'not-found'};

/// [_cancelledCodes] 요청 취소 관련 오류 코드 묶음
const Set<String> _cancelledCodes = {'cancelled'};

/// [_userDisabledCodes] 계정 비활성화 관련 오류 코드 묶음
const Set<String> _userDisabledCodes = {'user-disabled'};

/// [parseFirebaseException] Firebase 예외를 사용자 친화적인 한글 메시지로 변환
/// [e] 처리할 예외 객체
String parseFirebaseException(Object e) {
  if (e is! FirebaseException) {
    return _kGenericUnknownMessage;
  }

  final String code = e.code;

  if (_networkErrorCodes.contains(code)) {
    return '네트워크 연결을 확인해주세요. 서비스에 접속할 수 없습니다.';
  }
  if (_permissionDeniedCodes.contains(code)) {
    return '데이터에 접근할 권한이 없습니다. 앱을 재시작하거나 관리자에게 문의해주세요.';
  }
  if (_notFoundCodes.contains(code)) {
    return '요청한 데이터를 찾을 수 없습니다.';
  }
  if (_cancelledCodes.contains(code)) {
    return '요청이 취소되었습니다.';
  }
  if (_userDisabledCodes.contains(code)) {
    return '사용이 중지된 계정입니다.';
  }

  // e.message가 비어 있으면 코드로 대체해 불필요한 빈 문자열/널 표시를 방지
  final String raw = (e.message != null && e.message!.isNotEmpty)
      ? e.message!
      : code;
  return '오류가 발생했습니다: $raw';
}

/// [showErrorSnackBar] 오류 메시지를 스낵바로 표시
/// [context] 위젯 트리 컨텍스트
/// [e] 예외 객체(또는 임의의 오류)
void showErrorSnackBar(BuildContext context, Object e) {
  // 비동기 이후에도 위젯이 유효한지 보장
  if (!context.mounted) return;

  final String errorMessage = parseFirebaseException(e);
  final messenger = ScaffoldMessenger.of(context);

  messenger.showSnackBar(
    SnackBar(
      content: Text(errorMessage),
      backgroundColor: Theme.of(context).colorScheme.error,
    ),
  );
}

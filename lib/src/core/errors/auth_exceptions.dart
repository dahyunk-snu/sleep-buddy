/// [AuthException] 인증 관련 예외의 베이스 클래스
/// [message] 사용자에게 표시할 로컬라이즈된 메시지
abstract class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// [GoogleSignInCancelledException] 사용자가 Google 로그인 흐름을 취소한 경우
class GoogleSignInCancelledException extends AuthException {
  const GoogleSignInCancelledException() : super('로그인을 취소했습니다.');
}

/// [AccountExistsWithDifferentCredentialException]
/// 동일 이메일이 다른 인증 방식으로 이미 가입된 경우
class AccountExistsWithDifferentCredentialException extends AuthException {
  const AccountExistsWithDifferentCredentialException()
    : super('이미 다른 방식으로 가입된 계정입니다. 동일한 방식으로 로그인해주세요.');
}

/// [NetworkRequestFailedException] 인증 과정의 네트워크 실패
class NetworkRequestFailedException extends AuthException {
  const NetworkRequestFailedException()
    : super('네트워크 연결에 실패했습니다. 인터넷 연결을 확인해주세요.');
}

/// [UnknownSignInException] 원인 불명의 로그인 오류
/// [originalMessage] SDK/플랫폼이 제공한 원문 메시지
class UnknownSignInException extends AuthException {
  final String? originalMessage;
  const UnknownSignInException({this.originalMessage})
    : super('알 수 없는 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');

  /// 원문 메시지가 있을 때만 괄호로 덧붙여 “(null)” 노출을 방지
  @override
  String toString() {
    final base = super.toString();
    final extra = originalMessage;
    return (extra != null && extra.isNotEmpty) ? '$base ($extra)' : base;
  }
}

/// [GoogleSignInConfigurationException]
/// SHA-1 누락 등 Google 로그인 설정 오류
class GoogleSignInConfigurationException extends AuthException {
  const GoogleSignInConfigurationException()
    : super('Google 로그인이 올바르게 설정되지 않았습니다. (SHA-1 설정을 확인해주세요)');
}

/// [UserNotSignedInException] 인증이 필요한 작업에 로그인 사용자가 없는 경우
class UserNotSignedInException extends AuthException {
  const UserNotSignedInException() : super('로그인된 사용자가 없어 작업을 수행할 수 없습니다.');
}

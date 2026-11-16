import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';
import 'package:sleepy/src/core/errors/auth_exceptions.dart';
import 'package:sleepy/src/core/services/database_service.dart';

final _log = Logger('AuthService');

/// [firebaseAuthProvider] FirebaseAuth 인스턴스 제공
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// [googleSignInProvider] GoogleSignIn 인스턴스 제공
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(); // 필요 시 scopes/hostedDomain 지정
});

/// [authServiceProvider] AuthService 인스턴스 제공
/// [ref] Riverpod Ref
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref,
    ref.watch(firebaseAuthProvider),
    ref.watch(googleSignInProvider),
  );
});

/// [authStateChangesProvider] 사용자 인증 상태 스트림(User? 변동)
/// [ref] Riverpod Ref
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// [AuthService] Firebase 인증 로직
/// [_ref] DI 참조
/// [_firebaseAuth] FirebaseAuth
/// [_googleSignIn] GoogleSignIn
class AuthService {
  AuthService(this._ref, this._firebaseAuth, this._googleSignIn);

  final Ref _ref;
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  /// [currentUser] 현재 사용자(User?; 없으면 null)
  User? get currentUser => _firebaseAuth.currentUser;

  /// [authStateChanges] 인증 상태 변경 스트림(User? 방출)
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// [signInWithGoogle] Google 계정으로 로그인
  /// 성공 시 User 반환(실패/취소 시 예외 변환)
  Future<User?> signInWithGoogle() async {
    try {
      // 1) Google 계정 선택
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // 2) 사용자가 취소
      if (googleUser == null) {
        throw const GoogleSignInCancelledException();
      }

      // 3) 토큰 획득
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 4) 자격 증명 생성
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5) Firebase 로그인
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e, s) {
      _log.warning('Firebase 로그인 에러: ${e.code}', e, s);
      if (e.code == 'account-exists-with-different-credential') {
        throw const AccountExistsWithDifferentCredentialException();
      }
      if (e.code == 'network-request-failed') {
        throw const NetworkRequestFailedException();
      }
      throw UnknownSignInException(originalMessage: e.message);
    } on PlatformException catch (e, s) {
      _log.severe('Google 로그인 플랫폼 에러: ${e.code}', e, s);
      if (e.code == 'sign_in_canceled') {
        throw const GoogleSignInCancelledException();
      }
      if (e.code == 'sign_in_failed') {
        throw const GoogleSignInConfigurationException();
      }
      throw UnknownSignInException(originalMessage: e.message);
    } catch (e, s) {
      _log.severe('알 수 없는 로그인 에러', e, s);
      throw UnknownSignInException(originalMessage: e.toString());
    }
  }

  /// [signOut] Firebase/Google 모두 로그아웃
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  /// [deleteAccount] 계정 삭제(재인증 후 데이터 삭제 → 계정 삭제)
  /// 최근 로그인 요구 상황을 줄이기 위해 Google 재인증 절차를 선행
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const UserNotSignedInException();
    }

    // 1) Google 재인증(취소 시 중단)
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const GoogleSignInCancelledException();
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await user.reauthenticateWithCredential(credential);
    } on PlatformException catch (e, s) {
      _log.severe('재인증 플랫폼 에러: ${e.code}', e, s);
      if (e.code == 'sign_in_canceled') {
        throw const GoogleSignInCancelledException();
      }
      throw UnknownSignInException(originalMessage: e.message);
    } on FirebaseAuthException catch (e, s) {
      _log.severe('재인증 실패: ${e.code}', e, s);
      throw UnknownSignInException(originalMessage: e.message);
    }

    // 2) 사용자 데이터 삭제(하위 컬렉션 포함) → 3) 계정 삭제
    try {
      final dbService = _ref.read(databaseServiceProvider);
      await dbService.deleteUserData(user.uid); // 하위 컬렉션 포함 삭제
      await user.delete(); // 계정 삭제
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e, s) {
      _log.severe('계정 삭제 실패: ${e.code}', e, s);
      if (e.code == 'requires-recent-login') {
        // 재인증 직후에도 발생할 수 있어 상위에서 처리하도록 노출
        throw UnknownSignInException(originalMessage: e.message);
      }
      throw UnknownSignInException(originalMessage: e.message);
    }
  }
}

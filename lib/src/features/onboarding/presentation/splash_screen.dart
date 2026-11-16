import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sleepy/src/core/services/auth_service.dart';
import 'package:sleepy/src/core/services/database_service.dart';
import 'package:sleepy/src/core/errors/error_utils.dart';

/// 앱 시작 시 사용자의 인증 상태를 확인하고 적절한 화면으로 안내하는 스플래시 화면입니다.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // authStateChangesProvider를 watch하여 인증 상태의 변화를 감지합니다.
    // 이 Provider는 AsyncValue<User?> 타입을 반환합니다.
    final authState = ref.watch(authStateChangesProvider);

    // AsyncValue의 when 메소드를 사용하여 로딩, 데이터, 에러 상태에 따라
    // 다른 UI를 렌더링합니다.
    return authState.when(
      data: (user) {
        // 인증 상태 확인이 완료되었을 때(데이터가 도착했을 때) 호출됩니다.
        // build 메소드 내에서 직접 화면을 전환하면 에러가 발생할 수 있으므로,
        // WidgetsBinding.instance.addPostFrameCallback을 사용하여
        // 현재 빌드 사이클이 끝난 직후에 코드를 실행하도록 예약합니다.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (user != null) {
            // 사용자가 로그인 상태이면, 아동 프로필이 있는지 확인하여 분기합니다.
            ref
                .read(databaseServiceProvider)
                .getChildProfiles(user.uid)
                .then((profiles) {
              if (context.mounted) {
                if (profiles.isNotEmpty) {
                  // 로그인 O, 프로필 O -> 홈 화면으로 이동
                  context.go('/home');
                } else {
                  // 로그인 O, 프로필 X -> 온보딩 화면으로 이동
                  context.go('/onboarding/welcome');
                }
              }
            }).catchError((e, stackTrace) {
              // 프로필 조회 중 에러 발생 시 안전하게 로그인 화면으로 이동
              if (context.mounted) context.go('/login');
            });
          } else {
            // 사용자가 로그아웃 상태이면 로그인 화면으로 이동합니다.
            context.go('/login');
          }
        });

        // 화면 전환이 일어나는 동안 잠시 보여줄 로딩 인디케이터입니다.
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      // 인증 상태를 확인하는 동안(로딩 중) 보여줄 UI입니다.
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      // 에러가 발생했을 때 보여줄 UI입니다.
      error: (err, stack) => Scaffold(
        body: Center(
            child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('오류가 발생했습니다: ${parseFirebaseException(err)}',
              textAlign: TextAlign.center),
        )),
      ),
    );
  }
}
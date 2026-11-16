import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// [ErrorScreen]
/// [message] 사용자에게 보여줄 오류 메시지.
/// [title] 앱바 타이틀 텍스트(기본: '오류').
/// [icon] 오류를 표현할 아이콘(기본: [Icons.error_outline_rounded]).
/// [actionLabel] 기본 버튼 라벨(기본: '홈으로 돌아가기').
/// [onAction] 사용자 정의 버튼 동작(제공 시 이 콜백이 우선 실행됨).
/// [homeLocation] 뒤로 갈 수 없을 때 이동할 라우트 경로(기본: '/home').
class ErrorScreen extends StatelessWidget {
  final String message;
  final String title;
  final IconData icon;
  final String actionLabel;
  final VoidCallback? onAction;
  final String homeLocation;

  const ErrorScreen({
    super.key,
    this.message = '알 수 없는 오류가 발생했습니다. 다시 시도해주세요.',
    this.title = '오류',
    this.icon = Icons.error_outline_rounded,
    this.actionLabel = '홈으로 돌아가기',
    this.onAction,
    this.homeLocation = '/home',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Semantics(
              liveRegion: true,
              label: '오류 화면',
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    // 오류 톤과 조화를 위해 error 색상 계열 사용
                    color: theme.colorScheme.error,
                    size: 80,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 32),
                  // Material 3 권장: FilledButton
                  FilledButton(
                    onPressed: () => _handlePrimaryAction(context),
                    child: Text(actionLabel),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// [_handlePrimaryAction]
  void _handlePrimaryAction(BuildContext context) {
    if (onAction != null) {
      onAction!.call();
      return;
    }
    if (GoRouter.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go(homeLocation);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sleepy/src/core/services/auth_service.dart';

import 'package:flutter/foundation.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.child_care_outlined),
              title: const Text('아동 프로필 관리'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push('/settings/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('보호자 계정 관리'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push('/settings/account');
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('기기 연결'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                context.push('/settings/device-connection');
              },
            ),
            const Divider(),
            if (kDebugMode)
              ListTile(
                leading: const Icon(Icons.build_circle_outlined),
                title: const Text('개발자 도구'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.push('/settings/developer-tools');
                },
              ),
            ListTile(
              leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
              title: Text(
                '로그아웃',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () async {
                 try {
                  // 1. AuthService를 통해 로그아웃 실행
                  await ref.read(authServiceProvider).signOut();
                  // 2. 위젯이 마운트된 상태인지 확인 후 화면 이동
                  if (context.mounted) {
                    // 3. 로그인 화면으로 이동하고, 이전 기록은 모두 삭제
                    context.go('/login');
                  }
                } catch (e) {
                  // 에러 처리 (예: 스낵바 표시)
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('로그아웃에 실패했습니다: ${e.toString()}')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
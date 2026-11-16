import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sleepy/src/core/services/auth_service.dart'; // AuthService import

class AccountManagementScreen extends ConsumerWidget { // StatelessWidget을 ConsumerWidget으로 변경
  const AccountManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) { // WidgetRef 추가
    return Scaffold(
      appBar: AppBar(
        title: const Text('계정 관리'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('회원 탈퇴', style: TextStyle(color: Colors.red)),
            onTap: () async {
              // 1. 사용자에게 탈퇴 여부를 다시 한번 확인
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('회원 탈퇴'),
                  content: const Text('정말로 계정을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('탈퇴', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              // 2. 사용자가 '탈퇴'를 눌렀을 경우에만 로직 실행
              if (confirm == true && context.mounted) {
                try {
                  // 3. AuthService를 통해 회원 탈퇴 실행
                  await ref.read(authServiceProvider).deleteAccount();
                  // 4. 로그인 화면으로 이동하고, 이전 기록은 모두 삭제
                  if (!context.mounted) return;
                  context.go('/login');
                } catch (e) {
                  // 에러 처리
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('회원 탈퇴에 실패했습니다: ${e.toString()}')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
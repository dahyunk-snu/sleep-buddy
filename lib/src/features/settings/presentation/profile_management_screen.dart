import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sleepy/src/core/models/child_profile.dart';
import 'package:sleepy/src/core/services/auth_service.dart';
import 'package:sleepy/src/core/services/database_service.dart';
import 'package:sleepy/src/features/onboarding/application/onboarding_controller.dart';

/// 현재 로그인된 사용자의 모든 아동 프로필 목록을 비동기적으로 가져오는 Provider
final childProfilesProvider = FutureProvider<List<ChildProfile>>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final databaseService = ref.watch(databaseServiceProvider);
  final user = authService.currentUser;

  if (user == null) {
    // 이 화면은 인증된 사용자만 접근 가능하므로, 이 예외는 발생하지 않아야 합니다.
    throw Exception('User not logged in');
  }
  return databaseService.getChildProfiles(user.uid);
});

class ProfileManagementScreen extends ConsumerWidget {
  const ProfileManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsyncValue = ref.watch(childProfilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('아동 프로필 관리'),
      ),
      body: SafeArea(
        child: profilesAsyncValue.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('오류가 발생했습니다: $err')),
          data: (profiles) {
            if (profiles.isEmpty) {
              return const Center(
                child: Text(
                  '아직 등록된 아동 프로필이 없습니다.\n아래 버튼을 눌러 추가해주세요.',
                  textAlign: TextAlign.center,
                ),
              );
            }
            return ListView.builder(
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                final profile = profiles[index];
                return ListTile(
                  leading: const Icon(Icons.face_retouching_natural),
                  title: Text(profile.lastName + profile.firstName),
                  subtitle: Text(
                      '${DateFormat.yMMMd('ko_KR').format(profile.birthDate)} (${profile.gender})'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () {
                          ref.read(onboardingControllerProvider.notifier).startEditing(profile);
                          context.push('/onboarding/step1');
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: Theme.of(context).colorScheme.error),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('프로필 삭제'),
                              content: Text(
                                  '${profile.firstName}(이)의 프로필을 정말로 삭제하시겠습니까? 관련된 모든 데이터가 삭제됩니다.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('취소'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('삭제',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            final user = ref.read(authServiceProvider).currentUser;
                            if (user != null) {
                              await ref
                                  .read(databaseServiceProvider)
                                  .deleteChildProfile(user.uid, profile.id);
                              ref.invalidate(childProfilesProvider);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(onboardingControllerProvider.notifier).startCreating();
          context.push('/onboarding/step1');
        },
        label: const Text('프로필 추가'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
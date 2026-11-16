import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sleepy/src/core/services/auth_service.dart';
import 'package:sleepy/src/core/services/database_service.dart';
import 'package:sleepy/src/features/dream_friend/application/dream_friend_controller.dart';
import 'package:sleepy/src/features/dream_friend/domain/dream_friend.dart';

// 현재 로그인된 사용자의 꿈친구 목록을 실시간으로 가져오는 Provider
final dreamFriendsStreamProvider = StreamProvider<List<DreamFriend>>((ref) {
  // 현재 사용자 ID 가져오기
  final userId = ref.watch(authServiceProvider).currentUser?.uid;
  if (userId == null) {
    // 로그인하지 않은 경우 빈 목록 반환
    return Stream.value([]);
  }
  // DatabaseService를 통해 스트림을 가져옴
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.getDreamFriendsStream(userId);
});


/// 꿈친구 선택 다이얼로그를 화면에 표시하는 함수
void showDreamFriendSelectionDialog(BuildContext context) {
  showDialog(
    context: context,
    // 다이얼로그 바깥을 탭해도 닫히도록 설정
    barrierDismissible: true, 
    builder: (context) => const DreamFriendSelectionDialog(),
  );
}


/// 꿈친구 선택/관리 다이얼로그의 본체 위젯
class DreamFriendSelectionDialog extends ConsumerWidget {
  const DreamFriendSelectionDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 꿈친구 목록 스트림을 watch하여 데이터 변경 시 자동으로 UI를 다시 그림
    final dreamFriendsAsync = ref.watch(dreamFriendsStreamProvider);
    final controller = ref.read(dreamFriendControllerProvider.notifier);
    
    return AlertDialog(
      title: const Text('꿈친구 선택'),
      // 스크롤 가능한 콘텐츠 영역
      content: SizedBox(
        width: double.maxFinite, // 다이얼로그 폭을 꽉 채움
        // 데이터 상태(로딩, 에러, 데이터 있음)에 따라 다른 UI를 보여줌
        child: dreamFriendsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('꿈친구를 불러오는 데 실패했어요: $err'),
          data: (friends) {
            // 꿈친구가 한 명도 없을 때 안내 메시지 표시
            if (friends.isEmpty) {
              return const Center(
                child: Text('아직 추가된 꿈친구가 없어요.\n아래 버튼으로 새 친구를 추가해보세요!'),
              );
            }
            // 꿈친구 목록을 ListView로 표시
            return ListView.builder(
              shrinkWrap: true, // 콘텐츠 크기에 맞게 높이 조절
              itemCount: friends.length,
              itemBuilder: (context, index) {
                final friend = friends[index];
                return ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(friend.name),
                  // 페르소나 미리보기 (두 줄까지만 표시)
                  subtitle: Text(
                    friend.persona,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // 리스트 타일을 탭했을 때의 동작
                  onTap: () {
                    controller.selectFriend(friend); // 컨트롤러에 친구 정보 저장
                    context.pop(); // 다이얼로그 닫기
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${friend.name}(와)과 이야기할 준비가 됐어요!')),
                    );
                  },
                  // 수정 버튼
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_note),
                    onPressed: () {
                      context.pop(); // 다이얼로그를 먼저 닫고
                      // 수정 화면으로 이동 (friend 객체를 함께 전달)
                      context.push('/dream-friend/edit', extra: friend);
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      // 다이얼로그 하단 버튼 영역
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('취소'),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('새 친구 추가'),
          onPressed: () {
            context.pop(); // 다이얼로그를 닫고
            // 추가 화면으로 이동 (extra 없이 호출)
            context.push('/dream-friend/edit');
          },
        ),
      ],
    );
  }
}
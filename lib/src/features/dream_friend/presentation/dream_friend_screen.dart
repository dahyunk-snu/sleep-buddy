import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sleepy/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:sleepy/src/features/dream_friend/application/dream_friend_controller.dart';
import 'package:sleepy/src/features/dream_friend/presentation/widgets/chat_view.dart';
import 'package:sleepy/src/features/dream_friend/domain/dream_content.dart';
import 'package:sleepy/src/core/services/device_connection_service.dart';
import 'package:sleepy/src/core/services/audio_player_service.dart';
import 'package:sleepy/src/core/services/database_service.dart';
import 'package:sleepy/src/features/dream_friend/presentation/widgets/dream_friend_selection_dialog.dart';

final dreamContentProvider = StreamProvider.family<List<DreamContent>, String>((
  ref,
  category,
) {
  final dbService = ref.watch(databaseServiceProvider);
  return dbService.getDreamContentStream(category);
});

class DreamFriendScreen extends ConsumerWidget {
  const DreamFriendScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardNotifierProvider);
    final childProfiles = dashboardState.childProfiles.asData?.value;
    final selectedChildId = dashboardState.selectedChildId;
    String childName = '아이'; // 기본 이름

    // null 체크 및 'isNotEmpty' 오류 수정된 부분
    if (childProfiles != null &&
        selectedChildId != null &&
        selectedChildId.isNotEmpty) {
      try {
        final selectedProfile = childProfiles.firstWhere(
          (p) => p.id == selectedChildId,
        );
        childName = selectedProfile.firstName;
      } on StateError {
        // 일치하는 프로필이 없으면 기본 이름을 사용합니다.
      }
    }

    final dreamFriendState = ref.watch(dreamFriendControllerProvider);
    final bluetoothState = ref.watch(bluetoothDeviceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('꿈친구')),
      body: SafeArea(
        child: _buildDreamFriendView(
          context,
          ref,
          childName,
          bluetoothState,
          dreamFriendState,
        ),
      ),
    );
  }

  // 3. 연결 완료 후 UI
  Widget _buildDreamFriendView(
    BuildContext context,
    WidgetRef ref,
    String childName,
    BLEDeviceState bluetoothState,
    DreamFriendState dreamFriendState,
  ) {
    final selectedFriend = dreamFriendState.selectedFriend;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  // 1. selectedFriend가 null인지 확인
                  selectedFriend == null
                      // 2. null이면 "어떤 친구와 함께할까요?" 표시
                      ? '오늘은 어떤 친구와 함께할까요?'
                      // 3. null이 아니면 기존 문구에 꿈친구 이름 표시
                      : '$childName이가 ${selectedFriend.name}(와)과\n친구가 되었어요!',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    // 기기가 연결되지 않았을 경우, 기기 연결 페이지로 이동합니다.
                    if (bluetoothState.connectedDevice == null) {
                      context.push('/settings/device-connection');
                    }
                  },
                  child: _buildDeviceStatus(context, bluetoothState),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  // 1. onPressed: 다이얼로그를 띄우도록 변경
                  onPressed: () {
                    showDreamFriendSelectionDialog(context);
                  },
                  icon: const Icon(Icons.cloud_queue),
                  // 2. label: 선택된 친구에 따라 텍스트 변경
                  label: Text(
                    selectedFriend == null
                        ? '꿈친구 소환하기'
                        : '${selectedFriend.name}(와)과 대화하기',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.music_note), text: '자장가'),
              Tab(icon: Icon(Icons.book_outlined), text: '동화'),
              Tab(icon: Icon(Icons.chat_bubble_outline), text: '감정 대화'),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _ContentList(category: 'lullabies'),
                _ContentList(category: 'fairy_tales'),
                ChatView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 기기 상태 (배터리, 연결 상태 등) 표시 위젯
  Widget _buildDeviceStatus(BuildContext context, BLEDeviceState btState) {
    IconData icon;
    String text;
    Color color = Colors.green;

    if (btState.connectedDevice != null) {
      switch (btState.powerStatus) {
        case PowerStatus.discharging:
          icon = Icons.battery_std;
          text = '배터리: ${btState.batteryLevel}%';
          break;
        case PowerStatus.charging:
          icon = Icons.battery_charging_full;
          text = '배터리 충전 중';
          break;
        case PowerStatus.usbPower:
          icon = Icons.power;
          text = 'USB 전원 사용 중';
          break;
        case PowerStatus.unknown:
          icon = Icons.battery_unknown;
          text = '배터리 정보 확인 중...';
          color = Colors.grey;
          break;
      }
    } else {
      icon = Icons.bluetooth_disabled;
      text = '연결 끊김(탭하여 연결)';
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            btState.connectedDevice != null ? Icons.check_circle : Icons.error,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            btState.connectedDevice?.platformName ?? '기기',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(width: 16),
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _ContentList extends ConsumerWidget {
  const _ContentList({required this.category});
  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(dreamContentProvider(category));

    return contentAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('콘텐츠를 불러올 수 없습니다.\n$err')),
      data: (contents) {
        if (contents.isEmpty) {
          return Center(
            child: Text('${_getCategoryName(category)} 콘텐츠가 없습니다.'),
          );
        }
        return ListView.builder(
          itemCount: contents.length,
          itemBuilder: (context, index) {
            final content = contents[index];
            return ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: Text(content.title),
              subtitle: Text(content.artist ?? '정보 없음'),
              onTap: () {
                // 탭하면 AudioPlayerService를 통해 재생 목록을 로드하고 재생 시작
                ref
                    .read(audioPlayerServiceProvider.notifier)
                    .loadPlaylist(contents, initialIndex: index);
              },
            );
          },
        );
      },
    );
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'lullabies':
        return '자장가';
      case 'fairy_tales':
        return '동화';
      default:
        return '알 수 없는';
    }
  }
}

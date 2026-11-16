import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sleepy/src/features/dream_friend/presentation/widgets/mini_player.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: child),
          const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _calculateSelectedIndex(context),
        onTap: (int index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '기록'),
          BottomNavigationBarItem(
            icon: Icon(Icons.nightlight_round),
            label: '잠자기',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.music_note), label: '꿈친구'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }

  /// 현재 경로를 기반으로 선택 인덱스 계산
  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/report')) return 1;
    if (location.startsWith('/routine')) return 2;
    if (location.startsWith('/dream-friend')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0; // 기본값으로 홈을 선택
  }

  /// 탭 선택 시 해당 경로로 이동
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/report');
        break;
      case 2:
        context.go('/routine');
        break;
      case 3:
        context.go('/dream-friend');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sleepy/src/core/services/audio_player_service.dart';
import 'package:go_router/go_router.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioPlayerServiceProvider);
    final playerNotifier = ref.read(audioPlayerServiceProvider.notifier);

    // 현재 재생 중인 곡이 없으면 아무것도 표시하지 않음
    if (playerState.currentContent == null) {
      return const SizedBox.shrink();
    }

    final currentContent = playerState.currentContent!;
    final totalDuration = playerState.total ?? Duration.zero;
    final position = playerState.position;

    final progress = (totalDuration.inMilliseconds > 0)
        ? position.inMilliseconds / totalDuration.inMilliseconds
        : 0.0;

    return Material(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withAlpha(200),
      child: InkWell(
        onTap: () {
          context.push('/player');
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: progress,
              minHeight: 2,
              backgroundColor: Colors.transparent,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  const Icon(Icons.music_note, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currentContent.title,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (currentContent.artist != null &&
                            currentContent.artist!.isNotEmpty)
                          Text(
                            currentContent.artist!,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 재생/일시정지 버튼
                  IconButton(
                    iconSize: 32,
                    icon: Icon(
                      playerState.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                    ),
                    onPressed: () {
                      if (playerState.isPlaying) {
                        playerNotifier.pause();
                      } else {
                        playerNotifier.play();
                      }
                    },
                  ),
                  // 닫기(X) 버튼 추가
                  IconButton(
                    icon: const Icon(Icons.close, size: 32),
                    onPressed: () {
                      playerNotifier.stop(); // 음악 정지 및 플레이어 닫기
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

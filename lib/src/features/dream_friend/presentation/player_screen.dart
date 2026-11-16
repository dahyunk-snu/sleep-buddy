import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sleepy/src/core/services/audio_player_service.dart';
import 'dart:math';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioPlayerServiceProvider);
    final playerNotifier = ref.read(audioPlayerServiceProvider.notifier);
    final currentContent = playerState.currentContent;

    // 현재 재생중인 곡이 없으면 빈 화면을 표시 (오류 방지)
    if (currentContent == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('재생할 콘텐츠가 없습니다.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('현재 재생 중'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        // 배경 그라데이션
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withAlpha(128),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.4],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // 1. 앨범 아트 (임시 아이콘)
              Container(
                width: MediaQuery.of(context).size.width * 0.7,
                height: MediaQuery.of(context).size.width * 0.7,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(51),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(Icons.music_note, size: 100, color: Colors.white70),
              ),
              const SizedBox(height: 48),

              // 2. 곡 정보
              Text(
                currentContent.title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                currentContent.artist ?? '알 수 없는 아티스트', 
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // 3. 재생 시간 및 슬라이더
              _SeekBar(
                duration: playerState.total ?? Duration.zero,
                position: playerState.position,
                bufferedPosition: playerState.buffered,
                onChangeEnd: (newPosition) {
                  playerNotifier.seek(newPosition);
                },
              ),
              const SizedBox(height: 16),

              // 4. 재생 컨트롤 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 셔플 버튼
                  Expanded(
                    flex: 2,
                    child: IconButton(
                      icon: Icon(
                        playerState.isShuffle ? Icons.shuffle_on : Icons.shuffle,
                        color: playerState.isShuffle
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      onPressed: () => playerNotifier.setShuffleMode(!playerState.isShuffle),
                    ),
                  ),
                  // 이전 곡
                  Expanded(
                    flex: 2,
                    child: IconButton(
                      icon: const Icon(Icons.skip_previous),
                      iconSize: 40,
                      onPressed: playerNotifier.seekToPrevious,
                    ),
                  ),
                  // 재생/일시정지 (가운데 버튼)
                  Expanded(
                    flex: 3, // 중앙 버튼에 더 큰 공간 할당
                    child: IconButton(
                      iconSize: 64,
                      icon: Icon(
                        playerState.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      ),
                      onPressed: () {
                        if (playerState.isPlaying) {
                          playerNotifier.pause();
                        } else {
                          playerNotifier.play();
                        }
                      },
                    ),
                  ),
                  // 다음 곡
                  Expanded(
                    flex: 2,
                    child: IconButton(
                      icon: const Icon(Icons.skip_next),
                      iconSize: 40,
                      onPressed: playerNotifier.seekToNext,
                    ),
                  ),
                  // 반복 버튼
                  Expanded(
                    flex: 2,
                    child: IconButton(
                      icon: Icon(
                        playerState.loopMode == LoopMode.one ? Icons.repeat_one_on :
                        playerState.loopMode == LoopMode.all ? Icons.repeat_on : Icons.repeat,
                        color: playerState.loopMode != LoopMode.off
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      onPressed: () {
                        final nextMode = LoopMode.values[
                          (playerState.loopMode.index + 1) % LoopMode.values.length
                        ];
                        playerNotifier.setLoopMode(nextMode);
                      },
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}


/// 재생 슬라이더 위젯
class _SeekBar extends StatefulWidget {
  final Duration duration;
  final Duration position;
  final Duration bufferedPosition;
  final ValueChanged<Duration>? onChangeEnd;

  const _SeekBar({
    required this.duration,
    required this.position,
    required this.bufferedPosition,
    this.onChangeEnd,
  });

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  double? _dragValue;

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final max = widget.duration.inMilliseconds.toDouble();
    if (max.isNaN || max.isInfinite || max <= 0) {
      return const SizedBox.shrink(); // max 값이 유효하지 않으면 슬라이더를 숨김
    }

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 15.0),
          ),
          child: Slider(
            min: 0.0,
            max: max,
            value: min(
              _dragValue ?? widget.position.inMilliseconds.toDouble(),
              max, // position 값이 max를 넘지 않도록 보장
            ),
            secondaryTrackValue: min(
              widget.bufferedPosition.inMilliseconds.toDouble(),
              max,
            ),
            onChanged: (value) {
              setState(() {
                _dragValue = value;
              });
            },
            onChangeEnd: (value) {
              if (widget.onChangeEnd != null) {
                widget.onChangeEnd!(Duration(milliseconds: value.round()));
              }
              _dragValue = null;
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(widget.position)),
              Text(_formatDuration(widget.duration)),
            ],
          ),
        ),
      ],
    );
  }
}
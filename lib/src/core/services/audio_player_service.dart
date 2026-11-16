import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sleepy/src/features/dream_friend/domain/dream_content.dart';

/// [AudioPlayerState] 현재 오디오 플레이어의 모든 상태
/// [playlist] 재생 목록
/// [currentContent] 현재 콘텐츠
/// [isPlaying] 재생 여부
/// [position] 현재 위치
/// [buffered] 버퍼된 위치
/// [total] 총 길이
/// [isShuffle] 셔플 여부
/// [loopMode] 반복 모드
class AudioPlayerState {
  final List<DreamContent> playlist;
  final DreamContent? currentContent;
  final bool isPlaying;
  final Duration position;
  final Duration buffered;
  final Duration? total;
  final bool isShuffle;
  final LoopMode loopMode;

  AudioPlayerState({
    this.playlist = const [],
    this.currentContent,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.buffered = Duration.zero,
    this.total,
    this.isShuffle = false,
    this.loopMode = LoopMode.off,
  });

  /// [copyWith] 불변 복사
  AudioPlayerState copyWith({
    List<DreamContent>? playlist,
    DreamContent? currentContent,
    bool? isPlaying,
    Duration? position,
    Duration? buffered,
    Duration? total,
    bool? isShuffle,
    LoopMode? loopMode,
  }) {
    return AudioPlayerState(
      playlist: playlist ?? this.playlist,
      currentContent: currentContent ?? this.currentContent,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      buffered: buffered ?? this.buffered,
      total: total ?? this.total,
      isShuffle: isShuffle ?? this.isShuffle,
      loopMode: loopMode ?? this.loopMode,
    );
  }
}

/// [AudioPlayerService] 오디오 재생을 총괄하는 서비스
class AudioPlayerService extends Notifier<AudioPlayerState> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _sequenceStateSubscription;
  StreamSubscription? _combinedStreamSubscription;

  @override
  AudioPlayerState build() {
    // 서비스가 소멸될 때 플레이어도 함께 소멸
    ref.onDispose(() {
      _playerStateSubscription?.cancel();
      _sequenceStateSubscription?.cancel();
      _combinedStreamSubscription?.cancel();
      _audioPlayer.dispose();
    });

    _listenToPlayerState();
    return AudioPlayerState();
  }

  void _listenToPlayerState() {
    // 재생 상태(playing/paused/completed 등) 감지
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((
      playerState,
    ) {
      if (state.isPlaying != playerState.playing) {
        state = state.copyWith(isPlaying: playerState.playing);
      }
    });

    // 현재 재생중인 곡 정보 감지(태그/총 길이)
    _sequenceStateSubscription = _audioPlayer.sequenceStateStream.listen((
      sequenceState,
    ) {
      if (sequenceState == null) return;
      final currentItem = sequenceState.currentSource?.tag as DreamContent?;
      final totalDuration = sequenceState.currentSource?.duration;
      state = state.copyWith(currentContent: currentItem, total: totalDuration);
    });

    // 재생 시간/버퍼/총길이
    _combinedStreamSubscription =
        Rx.combineLatest3(
          _audioPlayer.positionStream,
          _audioPlayer.bufferedPositionStream,
          _audioPlayer.durationStream,
          (pos, buff, dur) =>
              state.copyWith(position: pos, buffered: buff, total: dur),
        ).listen((newState) {
          state = newState;
        });
  }

  /// [loadPlaylist] 새 재생 목록을 로드하고 첫 곡 재생
  /// [playlist] 재생 목록
  /// [initialIndex] 시작 인덱스
  Future<void> loadPlaylist(
    List<DreamContent> playlist, {
    int initialIndex = 0,
  }) async {
    if (playlist.isEmpty) return;

    state = state.copyWith(playlist: playlist);

    final audioSource = ConcatenatingAudioSource(
      useLazyPreparation: true, // 초기 지연 최소화
      children: playlist.map((content) {
        return AudioSource.uri(Uri.parse(content.audioUrl), tag: content);
      }).toList(),
    );

    await _audioPlayer.setAudioSource(audioSource, initialIndex: initialIndex);
    await _audioPlayer.play();
  }

  /// [play] 재생
  Future<void> play() async => await _audioPlayer.play();

  /// [pause] 일시정지
  Future<void> pause() async => await _audioPlayer.pause();

  /// [seek] 위치 이동
  /// [position] 이동할 위치
  Future<void> seek(Duration position) async =>
      await _audioPlayer.seek(position);

  /// [seekToNext] 다음 트랙
  Future<void> seekToNext() async => await _audioPlayer.seekToNext();

  /// [seekToPrevious] 이전 트랙
  Future<void> seekToPrevious() async => await _audioPlayer.seekToPrevious();

  /// [stop] 정지 및 상태 초기화(미니 플레이어 숨김)
  Future<void> stop() async {
    await _audioPlayer.stop();
    state = AudioPlayerState();
  }

  /// [setLoopMode] 자동 재생(반복) 모드 설정
  /// [mode] LoopMode
  Future<void> setLoopMode(LoopMode mode) async {
    await _audioPlayer.setLoopMode(mode);
    state = state.copyWith(loopMode: mode);
  }

  /// [setShuffleMode] 셔플 모드 설정(활성화 시 실제 섞기)
  /// [enabled] 셔플 활성화 여부
  Future<void> setShuffleMode(bool enabled) async {
    await _audioPlayer.setShuffleModeEnabled(enabled);
    if (enabled) {
      await _audioPlayer.shuffle(); // 순서 실제 랜덤화
    }
    state = state.copyWith(isShuffle: enabled);
  }
}

/// [audioPlayerServiceProvider] 앱 전역 오디오 서비스
final audioPlayerServiceProvider =
    NotifierProvider<AudioPlayerService, AudioPlayerState>(() {
      return AudioPlayerService();
    });

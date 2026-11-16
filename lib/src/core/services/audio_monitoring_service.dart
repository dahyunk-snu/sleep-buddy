import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

import 'package:sleepy/src/core/models/sleep_data.dart';
import 'package:sleepy/src/core/models/problematic_event.dart';
import 'package:logging/logging.dart';

final _log = Logger('RoutineController');

/// [AudioMonitoringResult] 자동 감지 이벤트와 녹음 파일 경로 컨테이너
/// [events] 감지된 문제 이벤트 목록
/// [recordingPath] 재생/삭제를 위한 WAV 파일 경로
class AudioMonitoringResult {
  final List<ProblematicEvent> events;
  final String? recordingPath;
  const AudioMonitoringResult({required this.events, this.recordingPath});
}

/// [AudioMonitoringConfig] 감지 파이프라인의 런타임 설정
/// [snoringScoreThreshold] 코골이 스코어 임계치
/// [restlessnessScoreThreshold] 뒤척임/움직임 스코어 임계치
/// [sleepApneaScoreThreshold] 호흡/기침 문제 스코어 임계치
/// [highNoiseDbThreshold] 고소음 dBFS 임계치(초과 시 1회 이벤트)
/// [minInterval] 동일 타입 이벤트 쿨다운 간격
/// [hopDuration] 슬라이딩 윈도우 이동 간격(프레임은 0.975s 고정)
class AudioMonitoringConfig {
  /// YAMNet 점수 임계치
  final double snoringScoreThreshold;
  final double restlessnessScoreThreshold;
  final double sleepApneaScoreThreshold;

  /// 고소음(dBFS): 한 번 넘으면 바로 기록
  final double highNoiseDbThreshold;

  /// 동일 타입 중복 억제 최소 간격
  final Duration minInterval;

  /// 슬라이딩 윈도우 설정
  final Duration hopDuration;

  const AudioMonitoringConfig({
    this.snoringScoreThreshold = 0.35,
    this.restlessnessScoreThreshold = 0.35,
    this.sleepApneaScoreThreshold = 0.35,
    this.highNoiseDbThreshold = -20.0,
    this.minInterval = const Duration(minutes: 5),
    this.hopDuration = const Duration(milliseconds: 500),
  });

  /// [copyWith] 부분 수정 반영된 새 설정 반환
  AudioMonitoringConfig copyWith({
    double? snoringScoreThreshold,
    double? restlessnessScoreThreshold,
    double? sleepApneaScoreThreshold,
    double? bruxismScoreThreshold,
    double? highNoiseDbThreshold,
    Duration? minInterval,
    Duration? hopDuration,
  }) {
    return AudioMonitoringConfig(
      snoringScoreThreshold:
          snoringScoreThreshold ?? this.snoringScoreThreshold,
      restlessnessScoreThreshold:
          restlessnessScoreThreshold ?? this.restlessnessScoreThreshold,
      sleepApneaScoreThreshold:
          sleepApneaScoreThreshold ?? this.sleepApneaScoreThreshold,
      highNoiseDbThreshold: highNoiseDbThreshold ?? this.highNoiseDbThreshold,
      minInterval: minInterval ?? this.minInterval,
      hopDuration: hopDuration ?? this.hopDuration,
    );
  }
}

/// [_SessionMeta] 세션 메타데이터(타임스탬프 복원/라벨링 용)
/// [userId] 보호자/소유자 ID
/// [childId] 아동 ID
/// [sessionId] 세션 식별자(예: YYYYMMDD-sessionType)
/// [sessionType] 세션 유형(낮잠/야간 등)
/// [startTime] 세션 시작 시각
class _SessionMeta {
  final String userId;
  final String childId;
  final String sessionId;
  final SleepSessionType sessionType;
  final DateTime startTime;
  const _SessionMeta({
    required this.userId,
    required this.childId,
    required this.sessionId,
    required this.sessionType,
    required this.startTime,
  });
}

/// [AudioMonitoringService] 오디오 모니터링 인터페이스
/// [start] 16kHz 모노 WAV 녹음 시작
/// [stopAndCollect] 녹음 중지 후 배치 분석 → 이벤트/경로 반환
/// [deleteRecording] 파일 삭제
/// [configure] 설정 변경
abstract class AudioMonitoringService {
  Future<void> start({
    required String userId,
    required String childId,
    required String sessionId, // YYYYMMDD-sessionType
    required SleepSessionType sessionType,
    required DateTime startTime,
  });

  /// 세션 종료 후: 자동 감지 이벤트 + 녹음 파일 경로 반환
  Future<AudioMonitoringResult> stopAndCollect();

  /// 재생 후 파일 삭제
  Future<void> deleteRecording(String path);

  /// 런타임에 임계치 조정
  void configure(AudioMonitoringConfig config);
}

/// [_YamnetClassifier] YAMNet(TFLite) 실행기
/// [load] 모델/라벨 자산 로딩 및 텐서 준비([1,15600])
/// [infer] 입력 프레임(15600 샘플, 16k) → [521] 스코어
class _YamnetClassifier {
  static const int targetSr = 16000;
  static const int frameSamples = 15600; // 0.975s * 16k
  late final tfl.Interpreter _interpreter;
  late final List<String> _labels;

  bool _ready = false;

  // 레이블 → 인덱스
  late final Map<String, int> _labelToIndex;

  Future<void> load({
    required String modelAssetPath,
    required String labelAssetPath,
  }) async {
    _log.info(
      '[YAMNet] load(model=$modelAssetPath, labels=$labelAssetPath) 로딩 시작',
    );
    try {
      _interpreter = await tfl.Interpreter.fromAsset(modelAssetPath);
    } catch (e, s) {
      _log.severe('[YAMNet] Interpreter 로딩 실패', e, s);
      rethrow;
    }

    final raw = await rootBundle.loadString(labelAssetPath);
    _labels = raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    _labelToIndex = {for (int i = 0; i < _labels.length; i++) _labels[i]: i};
    // 입력 길이 고정 [15600]
    _interpreter.resizeInputTensor(0, [1, frameSamples]);
    _interpreter.allocateTensors();
    _ready = true;

    _log.info(
      '[YAMNet] ready: labels=${_labels.length}, frameSamples=$frameSamples',
    );
  }

  bool get isReady => _ready;

  Float32List infer(Float32List mono15600) {
    if (!_ready) {
      throw StateError('YAMNet classifier not loaded.');
    }
    final input = [mono15600]; // shape [1,15600]
    final output = List.generate(1, (_) => List.filled(521, 0.0)); // [1,521]
    _interpreter.run(input, output);
    final scores = Float32List.fromList((output[0] as List).cast<double>());
    return scores;
  }

  int? indexOf(String label) => _labelToIndex[label];

  /// [indicesOf] 라벨 이름 목록을 인덱스 집합으로 변환
  /// [labels] 라벨 이름 목록
  Set<int> indicesOf(Iterable<String> labels) {
    final out = <int>{};
    for (final name in labels) {
      final idx = _labelToIndex[name];
      if (idx != null) out.add(idx);
    }
    return out;
  }
}

/// [_WavData] 간단 WAV 컨테이너
/// [sampleRate] 샘플레이트
/// [channels] 채널 수
/// [mono] 모노 PCM float32 데이터([-1,1])
class _WavData {
  final int sampleRate;
  final int channels;
  final Float32List mono; // [-1,1]
  _WavData(this.sampleRate, this.channels, this.mono);
}

class _WavReader {
  static Future<_WavData> readPcm16Mono(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();
    final bd = ByteData.sublistView(bytes);

    // RIFF/WAVE 최소 검증
    if (bd.getUint32(0, Endian.little) != 0x46464952 /* 'RIFF' */ ||
        bd.getUint32(8, Endian.little) != 0x45564157 /* 'WAVE' */ ) {
      throw FormatException('Not a RIFF/WAVE file');
    }

    int offset = 12;
    int sampleRate = 16000;
    int channels = 1;
    int bitsPerSample = 16;
    int dataOffset = -1;
    int dataSize = -1;

    while (offset + 8 <= bd.lengthInBytes) {
      final chunkId = bd.getUint32(offset, Endian.little);
      final chunkSize = bd.getUint32(offset + 4, Endian.little);
      final next = offset + 8 + chunkSize;

      if (chunkId == 0x20746d66 /* 'fmt ' */ ) {
        final audioFormat = bd.getUint16(offset + 8, Endian.little);
        channels = bd.getUint16(offset + 10, Endian.little);
        sampleRate = bd.getUint32(offset + 12, Endian.little);
        bitsPerSample = bd.getUint16(offset + 22, Endian.little);
        if (audioFormat != 1 || bitsPerSample != 16) {
          throw FormatException(
            'Only PCM16 supported (fmt=$audioFormat, bps=$bitsPerSample)',
          );
        }
      } else if (chunkId == 0x61746164 /* 'data' */ ) {
        dataOffset = offset + 8;
        dataSize = chunkSize;
      }

      offset = next;
    }

    if (dataOffset < 0 || dataSize <= 0) {
      throw FormatException('WAV data chunk not found');
    }

    final sampleCount = dataSize ~/ 2; // 16bit
    final out = Float32List(sampleCount ~/ channels);

    // downmix to mono (average channels)
    int outIdx = 0;
    for (int i = 0; i < sampleCount; i += channels) {
      int acc = 0;
      for (int ch = 0; ch < channels; ch++) {
        final v = bd.getInt16(dataOffset + ((i + ch) * 2), Endian.little);
        acc += v;
      }
      final avg = acc / channels;
      out[outIdx++] = (avg / 32768.0).clamp(-1.0, 1.0).toDouble();
    }
    return _WavData(sampleRate, channels, out);
  }
}

/// [_resampleLinear] 선형 리샘플
/// [x] 입력 신호
/// [fromSr] 원 샘플레이트
/// [toSr] 목표 샘플레이트
Float32List _resampleLinear(Float32List x, int fromSr, int toSr) {
  if (fromSr == toSr) return x;
  final ratio = toSr / fromSr;
  final outLen = (x.length * ratio).floor();
  final out = Float32List(outLen);
  for (int i = 0; i < outLen; i++) {
    final srcPos = i / ratio;
    final i0 = srcPos.floor();
    final i1 = math.min(i0 + 1, x.length - 1);
    final frac = srcPos - i0;
    final y = x[i0] * (1 - frac) + x[i1] * frac;
    out[i] = y;
  }
  return out;
}

/// [_rmsDbFS] RMS → dBFS 추정(참조 진폭 1.0)
/// [x] 입력 프레임
double _rmsDbFS(Float32List x) {
  double sum = 0;
  for (var v in x) {
    sum += v * v;
  }
  final rms = math.sqrt(sum / (x.isEmpty ? 1 : x.length));
  final eps = 1e-12;
  return 20 * math.log(rms / 1.0 + eps) / math.ln10; // ref amplitude 1.0
}

/// [RecordAudioMonitoringService] YAMNet 기반 오디오 모니터링 구현
/// [start] 권한 확인 → 16kHz 모노 WAV 녹음 시작
/// [stopAndCollect] 녹음 중지 → 모델/라벨 로딩 → 파일 검증 → 슬라이딩 윈도우 분류 → 이벤트 방출
/// [_tryFire] 타입별 쿨다운 적용
class RecordAudioMonitoringService implements AudioMonitoringService {
  final AudioRecorder _rec = AudioRecorder();
  final _YamnetClassifier _clf = _YamnetClassifier();

  AudioMonitoringConfig _cfg = const AudioMonitoringConfig();
  _SessionMeta? _meta;
  String? _currentPath;

  /// [_lastFired] 타입별 최근 트리거 시각(쿨다운 계산용)
  final Map<ProblematicEventType, DateTime> _lastFired = {};

  /// [configure] 런타임 설정 변경 및 로깅
  /// [config] 새 설정
  @override
  void configure(AudioMonitoringConfig config) {
    _cfg = config;
    _log.fine(
      '[CFG] 업데이튼 내용: '
      'snore=${config.snoringScoreThreshold}, '
      'rest=${config.restlessnessScoreThreshold}, '
      'apnea=${config.sleepApneaScoreThreshold}, '
      'noise=${config.highNoiseDbThreshold}dBFS, '
      'hop=${config.hopDuration.inMilliseconds}ms, '
      'cooldown=${config.minInterval.inSeconds}s',
    );
  }

  /// [_makeSessionFilePath] 세션 WAV 저장 경로 생성
  /// [sessionId] 세션 식별자
  Future<String> _makeSessionFilePath(String sessionId) async {
    final dir = await getApplicationDocumentsDirectory();
    final safe = sessionId.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    return '${dir.path}/sleep_$safe.wav';
    // WAV로 저장 → stop에서 바로 읽어 분류
  }

  // 레이블 매핑 셋(라벨 txt에서 인덱스 매핑 후 사용)
  late Set<int> _snoreIdx;
  late Set<int> _restIdx;
  late Set<int> _apneaIdx;

  /// [_ensureClassifierLoaded] 분류기 준비(1회 로딩)
  Future<void> _ensureClassifierLoaded() async {
    if (_clf.isReady) return;

    await _clf.load(
      modelAssetPath: 'assets/models/yamnet.tflite',
      labelAssetPath: 'assets/models/yamnet_label_list.txt',
    );

    _snoreIdx = _clf.indicesOf(const ['Snoring']);

    _restIdx = _clf.indicesOf(const [
      'Thump, thud',
      'Thunk',
      'Rustle',
      'Creak',
      'Crumpling, crinkling',
      'Bouncing',
      'Squeak',
      'Clicking',
      'Clickety-clack',
      'Scratch',
      'Scrape',
      'Rub',
      'Roll',
      'Whack, thwack',
      'Bang',
      'Slap, smack',
    ]);

    _apneaIdx = _clf.indicesOf(const [
      'Cough',
      'Sneeze',
      'Wheeze',
      'Gasp',
      'Pant',
      'Snort',
      'Throat clearing',
      'Breathing',
    ]);

    _log.fine(
      '[YAMNet] label groups: '
      'snore=${_snoreIdx.length}, rest=${_restIdx.length}, apnea=${_apneaIdx.length}',
    );
  }

  /// [start] 16kHz 모노 WAV 녹음 시작(실패 시 StateError)
  /// [userId] 보호자/소유자 ID
  /// [childId] 아동 ID
  /// [sessionId] 세션 식별자(예: YYYYMMDD-sessionType)
  /// [sessionType] 세션 유형
  /// [startTime] 세션 시작 시각
  @override
  Future<void> start({
    required String userId,
    required String childId,
    required String sessionId,
    required SleepSessionType sessionType,
    required DateTime startTime,
  }) async {
    _lastFired.clear(); // 쿨다운 초기화

    _meta = _SessionMeta(
      userId: userId,
      childId: childId,
      sessionId: sessionId,
      sessionType: sessionType,
      startTime: startTime,
    );

    // 녹음 권한 확인
    final hasPerm = await _rec.hasPermission();
    if (!hasPerm) {
      _log.warning('[REC] microphone 권한 거부');
      throw StateError('microphone-permission-denied');
    }

    _currentPath = await _makeSessionFilePath(sessionId);

    _log.info('[REC] 녹음 시작: path=$_currentPath, sessionId=$sessionId');
    await _rec.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 256000,
      ),
      path: _currentPath!,
    );

    if (!await _rec.isRecording()) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (!await _rec.isRecording()) {
      _log.severe('[REC] 녹음 시작 실패');
      throw StateError('recording-not-started');
    }
    _log.info('[REC] 녹음 시작');
  }

  /// [stopAndCollect] 녹음 중지 후 배치 분석 → 이벤트/파일경로 반환
  /// @return [AudioMonitoringResult] 이벤트 목록/파일 경로
  @override
  Future<AudioMonitoringResult> stopAndCollect() async {
    try {
      _log.info('[REC] 녹음 중단 시도');
      if (await _rec.isRecording()) {
        await _rec.stop();
      }
    } catch (e, s) {
      _log.warning('[REC] stop() 실패', e, s);
    }

    final meta = _meta;
    final path = _currentPath;

    _meta = null;
    _currentPath = null;

    if (meta == null || path == null) {
      _log.warning(
        '[stopAndCollect] meta/path is null (meta=$meta, path=$path)',
      );
      return const AudioMonitoringResult(events: [], recordingPath: null);
    }

    await _ensureClassifierLoaded();

    final f = File(path);
    if (!await f.exists()) {
      _log.warning('[stopAndCollect] 파일이 존재하지 않음: $path');
      return AudioMonitoringResult(events: const [], recordingPath: path);
    }
    // 파일 읽어서 배치 분류
    final events = await _analyzeFile(path, meta);
    _log.info('[stopAndCollect] 분석 종료: events=${events.length}');
    return AudioMonitoringResult(events: events, recordingPath: path);
  }

  /// [deleteRecording] WAV 파일 삭제(재생 후 호출)
  /// [path] 삭제할 파일 경로
  @override
  Future<void> deleteRecording(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) {
        await f.delete();
        _log.fine('[REC] deleted: $path');
      }
    } catch (e, s) {
      _log.warning('[REC] delete failed: $path', e, s);
    }
  }

  /// [_analyzeFile] WAV → (리샘플) → 프레임 분할 → YAMNet 추론 → 임계치 비교 → 이벤트 방출
  /// [path] 분석할 파일 경로
  /// [meta] 세션 메타(타임스탬프 복원)
  Future<List<ProblematicEvent>> _analyzeFile(
    String path,
    _SessionMeta meta,
  ) async {
    final wav = await _WavReader.readPcm16Mono(path);

    // 필요시 16k로 리샘플
    final mono16k = _resampleLinear(
      wav.mono,
      wav.sampleRate,
      _YamnetClassifier.targetSr,
    );

    // 슬라이딩 윈도우
    const frameLen = _YamnetClassifier.frameSamples; // 15600
    final hopSamples =
        (_cfg.hopDuration.inMilliseconds * _YamnetClassifier.targetSr / 1000)
            .round()
            .clamp(1, frameLen);

    final out = <ProblematicEvent>[];
    int pos = 0;
    while (pos + frameLen <= mono16k.length) {
      final frame = Float32List.sublistView(mono16k, pos, pos + frameLen);

      // 1) 분류 점수
      final scores = _clf.infer(frame);

      // 그룹별 스코어 합
      double sum(Set<int> idxs) {
        double s = 0;
        for (final i in idxs) {
          if (i >= 0 && i < scores.length) s += scores[i];
        }
        return s;
      }

      final snoreScore = sum(_snoreIdx);
      final restScore = sum(_restIdx);
      final apneaScore = sum(_apneaIdx);

      // 프레임 중간 시점을 기준으로 이벤트 타임스탬프 계산
      final secondsFromStart =
          (pos + frameLen ~/ 2) / _YamnetClassifier.targetSr;
      final ts = meta.startTime.add(
        Duration(milliseconds: (secondsFromStart * 1000).round()),
      );

      // 2) 고소음(dBFS) 판단
      final db = _rmsDbFS(frame);
      if (db > _cfg.highNoiseDbThreshold) {
        _tryFire(
          out,
          ProblematicEventType.noise,
          ts,
          note: '고소음(dBFS=${db.toStringAsFixed(1)})',
        );
      }

      // 3) 분류 결과 임계치 비교 → 이벤트
      if (snoreScore >= _cfg.snoringScoreThreshold) {
        _tryFire(
          out,
          ProblematicEventType.snoring,
          ts,
          note: 'YAMNet snore=${snoreScore.toStringAsFixed(2)}',
        );
      }
      if (restScore >= _cfg.restlessnessScoreThreshold) {
        _tryFire(
          out,
          ProblematicEventType.restlessness,
          ts,
          note: 'YAMNet move=${restScore.toStringAsFixed(2)}',
        );
      }
      if (apneaScore >= _cfg.sleepApneaScoreThreshold) {
        _tryFire(
          out,
          ProblematicEventType.breathingIssue,
          ts,
          note: 'YAMNet resp=${apneaScore.toStringAsFixed(2)}',
        );
      }

      pos += hopSamples;
    }

    // 시간순 정렬 및 5분 병합은 호출측(컨트롤러) 규칙에 따르므로 여기선 정렬만
    out.sort();
    return out;
  }

  /// [_tryFire] 쿨다운 적용 후 이벤트 추가
  /// [sink] 이벤트 수집 리스트
  /// [type] 이벤트 타입
  /// [when] 이벤트 시각
  /// [note] 부가 메모
  void _tryFire(
    List<ProblematicEvent> sink,
    ProblematicEventType type,
    DateTime when, {
    String? note,
  }) {
    final last = _lastFired[type];
    if (last != null && when.difference(last) < _cfg.minInterval) {
      return; // 쿨다운 중
    }
    _lastFired[type] = when;
    sink.add(ProblematicEvent.auto(type, when, note: note));
  }
}

/// [audioMonitoringServiceProvider] DI 바인딩
/// 반환: [AudioMonitoringService] 구현 인스턴스
final audioMonitoringServiceProvider = Provider<AudioMonitoringService>(
  (ref) => RecordAudioMonitoringService(),
);

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:sleepy/src/core/models/accelerometer_data.dart';
import 'package:sleepy/src/core/models/problematic_event.dart';
import 'package:sleepy/src/core/models/sleep_data.dart';
import 'package:sleepy/src/core/services/device_connection_service.dart';

final _log = Logger('SleepMonitoring');

/// 가속도 기반 뒤척임 감지 설정값
class SleepMotionConfig {
  /// 이벤트 재발행 쿨다운
  final Duration cooldown;

  const SleepMotionConfig({this.cooldown = const Duration(seconds: 10)});
}

/// 세션 메타
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

/// 외부에 제공할 API
abstract class SleepMonitoringService {
  Future<void> start({
    required String userId,
    required String childId,
    required String sessionId,
    required SleepSessionType sessionType,
    required DateTime startTime,
  });

  /// 세션 종료 후: 감지된 이벤트 리스트 반환
  Future<List<ProblematicEvent>> stopAndCollect();

  /// 런타임 설정 변경
  void configure(SleepMotionConfig config);
}

/// BLE 가속도 스트림을 구독해 뒤척임 이벤트를 감지하는 구현체
class _BleSleepMonitoringService implements SleepMonitoringService {
  _BleSleepMonitoringService({
    required Stream<AccelerometerData> accelerometerStream,
    SleepMotionConfig config = const SleepMotionConfig(),
  }) : _src = accelerometerStream,
       _cfg = config;

  final Stream<AccelerometerData> _src;
  SleepMotionConfig _cfg;

  _SessionMeta? _meta;
  StreamSubscription<AccelerometerData>? _sub;

  // 감지 상태
  DateTime? _lastFiredAt;

  // 세션 동안 누적된 이벤트 버퍼(세션 종료 시 반환)
  final List<ProblematicEvent> _buffer = [];

  @override
  void configure(SleepMotionConfig config) {
    _cfg = config;
  }

  @override
  Future<void> start({
    required String userId,
    required String childId,
    required String sessionId,
    required SleepSessionType sessionType,
    required DateTime startTime,
  }) async {
    if (_sub != null) return; // 중복 시작 방지

    _meta = _SessionMeta(
      userId: userId,
      childId: childId,
      sessionId: sessionId,
      sessionType: sessionType,
      startTime: startTime,
    );

    // 상태 초기화
    _buffer.clear();
    _lastFiredAt = null;

    _sub = _src.listen(
      _onSample,
      onError: (e, s) {
        _log.warning('[start] accelerometer stream error', e, s);
      },
    );

    _log.fine(
      '[start] motion pipeline opened: session=$sessionId, type=$sessionType',
    );
  }

  @override
  Future<List<ProblematicEvent>> stopAndCollect() async {
    try {
      await _sub?.cancel();
    } catch (_) {}
    _sub = null;

    final events = List<ProblematicEvent>.from(_buffer);
    _buffer.clear();

    _log.fine('[stopAndCollect] events=${events.length}');
    _meta = null;
    return events;
  }

  void _onSample(AccelerometerData s) {
    if (_meta == null) return; // 안전 가드(세션 외 수신 무시)

    // 트리거 + 쿨다운
    final now = DateTime.now();
    final cooled =
        _lastFiredAt == null || now.difference(_lastFiredAt!) >= _cfg.cooldown;

    if (cooled) {
      final evt = ProblematicEvent.auto(
        ProblematicEventType.restlessness,
        now,
        note: 'time: $now',
      );
      _buffer.add(evt);
      _lastFiredAt = now;

      _log.fine('[fire] restlessness @ $now');
    }
  }
}

final sleepMonitoringServiceProvider = Provider<SleepMonitoringService>((ref) {
  final accelStream = ref.watch(accelerometerStreamProvider);
  return _BleSleepMonitoringService(accelerometerStream: accelStream);
});

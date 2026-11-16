import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sleepy/src/core/models/accelerometer_data.dart';

final _log = Logger('DeviceConnection');

// 블루투스 어댑터(하드웨어)의 현재 상태를 알려주는 스트림 프로바이더
final bluetoothAdapterStateProvider = StreamProvider<BluetoothAdapterState>((
  ref,
) {
  return FlutterBluePlus.adapterState;
});

enum PowerStatus { unknown, discharging, charging, usbPower }

// 고빈도 가속도는 상태 대신 이벤트 스트림으로 노출
final accelerometerStreamProvider = Provider<Stream<AccelerometerData>>((ref) {
  final notifier = ref.watch(bluetoothDeviceProvider.notifier);
  return notifier.accelerometerStream;
});

final bluetoothDeviceProvider =
    StateNotifierProvider<BluetoothDeviceNotifier, BLEDeviceState>((ref) {
      return BluetoothDeviceNotifier();
    });

class BluetoothDeviceNotifier extends StateNotifier<BLEDeviceState> {
  // 표준 배터리 서비스 및 특성 UUID
  final Guid _batteryServiceUUID = Guid("0000180f-0000-1000-8000-00805f9b34fb");
  final Guid _batteryCharacteristicUUID = Guid(
    "00002a19-0000-1000-8000-00805f9b34fb",
  );
  final Guid _sleepServiceUUID = Guid("19B10000-E8F2-537E-4F6C-D104768A1214");
  final Guid _accelerometerCharacteristicUUID = Guid(
    "19B10001-E8F2-537E-4F6C-D104768A1214",
  );
  final Guid _lightCharacteristicUUID = Guid(
    "19B10002-E8F2-537E-4F6C-D104768A1214",
  );
  final Guid _sessionControlCharacteristicUUID = Guid(
    "19B10003-E8F2-537E-4F6C-D104768A1214",
  );

  BluetoothDeviceNotifier() : super(BLEDeviceState());

  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionStateSubscription;
  StreamSubscription? _batteryValueSubscription;
  StreamSubscription? _accelerometerValueSubscription;
  BluetoothCharacteristic? _lightCharacteristic;
  BluetoothCharacteristic? _sessionControlCharacteristic;

  // 고빈도 센싱용 브로드캐스트 스트림
  final _accelCtrl = StreamController<AccelerometerData>.broadcast();
  Stream<AccelerometerData> get accelerometerStream => _accelCtrl.stream;

  Future<void> startScan() async {
    if (state.isScanning) return;
    if (Platform.isAndroid) {
      if (!(await Permission.bluetoothScan.request().isGranted &&
          await Permission.bluetoothConnect.request().isGranted &&
          await Permission.location.request().isGranted)) {
        _log.warning('필수 권한(블루투스, 위치)이 거부되었습니다.');
        return;
      }
    }

    state = state.copyWith(isScanning: true, scanResults: [], clearError: true);
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      final uniqueResults = <DeviceIdentifier, ScanResult>{};
      for (var r in results) {
        if (r.device.platformName.isNotEmpty) {
          uniqueResults[r.device.remoteId] = r;
        }
      }
      state = state.copyWith(scanResults: uniqueResults.values.toList());
    }, onError: (e) => stopScan());

    try {
      await FlutterBluePlus.startScan(
        withServices: [Guid("0000180f-0000-1000-8000-00805f9b34fb")],
        timeout: const Duration(seconds: 8),
      );
    } catch (e, s) {
      _log.severe('startScan 실패', e, s);
    } finally {
      if (mounted && state.isScanning) {
        state = state.copyWith(isScanning: false);
      }
    }
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    if (mounted) {
      state = state.copyWith(isScanning: false);
    }
  }

  Future<void> connect(BluetoothDevice device) async {
    if (state.isConnecting) return;

    state = state.copyWith(
      isConnecting: true,
      targetDeviceId: device.remoteId,
      clearError: true,
    );
    stopScan();

    try {
      await device.connect(timeout: const Duration(seconds: 15));

      _connectionStateSubscription = device.connectionState.listen((
        status,
      ) async {
        if (status == BluetoothConnectionState.disconnected) {
          state = state.copyWith(clearConnectedDevice: true);
          _connectionStateSubscription?.cancel();
          _batteryValueSubscription?.cancel();
          _accelerometerValueSubscription?.cancel();
        } else if (status == BluetoothConnectionState.connected) {
          state = state.copyWith(connectedDevice: device, isConnecting: false);
          await discoverServices(device);
        }
      });
    } catch (e) {
      state = state.copyWith(
        isConnecting: false,
        error: '기기 연결에 실패했습니다. 기기가 켜져 있고 가까이 있는지 확인해주세요.',
      );
    }
  }

  Future<void> disconnect() async {
    _batteryValueSubscription?.cancel();
    _accelerometerValueSubscription?.cancel();
    _sessionControlCharacteristic = null;
    _lightCharacteristic = null;
    await state.connectedDevice?.disconnect();
    state = state.copyWith(clearConnectedDevice: true);
  }

  Future<void> discoverServices(BluetoothDevice device) async {
    final current = await device.connectionState.first;
    if (current != BluetoothConnectionState.connected) {
      _log.warning('discoverServices 호출 시 비연결 상태');
      return;
    }

    try {
      await device.requestMtu(512);
      await Future.delayed(const Duration(milliseconds: 300));

      List<BluetoothService> services;
      try {
        services = await device.discoverServices();
      } catch (e, s) {
        _log.info('discoverServices 1차 실패, 300ms 후 재시도', e, s);
        await Future.delayed(const Duration(milliseconds: 300));
        services = await device.discoverServices();
      }
      BluetoothCharacteristic? batteryCharacteristic;
      BluetoothCharacteristic? accelerometerCharacteristic;

      for (var service in services) {
        if (service.uuid == _batteryServiceUUID) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid == _batteryCharacteristicUUID) {
              batteryCharacteristic = characteristic;
              break;
            }
          }
        }
        if (service.uuid == _sleepServiceUUID) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid == _accelerometerCharacteristicUUID) {
              accelerometerCharacteristic = characteristic;
            } else if (characteristic.uuid == _lightCharacteristicUUID) {
              _lightCharacteristic = characteristic;
            } else if (characteristic.uuid ==
                _sessionControlCharacteristicUUID) {
              _sessionControlCharacteristic = characteristic;
            }
          }
        }
        if (batteryCharacteristic != null &&
            accelerometerCharacteristic != null) {
          break;
        }
      }

      if (batteryCharacteristic != null) {
        _batteryValueSubscription?.cancel();
        _batteryValueSubscription = batteryCharacteristic.onValueReceived
            .listen(
              (value) {
                _updateBatteryState(value);
              },
              onError: (e) {
                state = state.copyWith(error: '배터리 정보 수신 중 오류가 발생했습니다.');
              },
            );
        await batteryCharacteristic.setNotifyValue(true);
        await Future.delayed(const Duration(milliseconds: 200)); // 안정화 시간
        await readBatteryLevel(batteryCharacteristic);
      } else {
        state = state.copyWith(error: '배터리 서비스를 찾을 수 없습니다. 지원되는 기기인지 확인해주세요.');
        await disconnect();
        return;
      }
      if (accelerometerCharacteristic != null) {
        _accelerometerValueSubscription?.cancel();
        _accelerometerValueSubscription = accelerometerCharacteristic
            .onValueReceived
            .listen((value) {
              _updateAccelerometerState(value); // 가속도계 데이터 처리 함수 호출
            });
        await accelerometerCharacteristic.setNotifyValue(true);
      } else {
        state = state.copyWith(error: '가속도 정보를 받을 수 없습니다. 다시 시도해주세요.');
        await disconnect();
        return;
      }
    } catch (e) {
      state = state.copyWith(
        isConnecting: false,
        error: '기기 서비스 검색에 실패했습니다. 다시 시도해주세요.',
      );
      await state.connectedDevice?.disconnect();
    }
  }

  Future<void> readBatteryLevel(BluetoothCharacteristic characteristic) async {
    try {
      List<int> value = await characteristic.read();
      _updateBatteryState(value);
    } catch (e, s) {
      _log.severe('배터리 읽기 실패', e, s);
      state = state.copyWith(error: '배터리 정보를 읽어올 수 없습니다.');
    }
  }

  Future<void> startSessionOnDevice() async {
    final c = _sessionControlCharacteristic;
    if (c == null) {
      _log.warning('SESSION_CONTROL characteristic not found');
      return;
    }
    try {
      await c.write([0x01], withoutResponse: false);
      _log.fine('[BLE] session START written');
    } catch (e, s) {
      _log.severe('session START write failed', e, s);
    }
  }

  Future<void> stopSessionOnDevice() async {
    final c = _sessionControlCharacteristic;
    if (c == null) {
      _log.warning('SESSION_CONTROL characteristic not found');
      return;
    }
    try {
      await c.write([0x00], withoutResponse: false);
      _log.fine('[BLE] session STOP written');
    } catch (e, s) {
      _log.severe('session STOP write failed', e, s);
    }
  }

  Future<void> setLightByDLMO(bool on) async {
    final c = _lightCharacteristic;
    if (c == null) {
      _log.warning('LIGHT characteristic not found');
      return;
    }
    try {
      await c.write([on ? 0x10 : 0x11], withoutResponse: false);
      _log.fine('[BLE] light(DLMO) ${on ? 'ON' : 'OFF'} written');
    } catch (e, s) {
      _log.severe('light write failed', e, s);
    }
  }

  Future<void> setLightBySleepLatency(bool on) async {
    final c = _lightCharacteristic;
    if (c == null) {
      _log.warning('LIGHT characteristic not found');
      return;
    }
    try {
      await c.write([on ? 0x01 : 0x00], withoutResponse: false);
      _log.fine('[BLE] light(SL) ${on ? 'ON' : 'OFF'} written');
    } catch (e, s) {
      _log.severe('light write failed', e, s);
    }
  }

  void _updateBatteryState(List<int> value) {
    if (value.isNotEmpty) {
      final int level = value.first;
      PowerStatus newStatus = PowerStatus.unknown;
      int? newLevel = level;

      if (level >= 0 && level <= 100) {
        newStatus = PowerStatus.discharging;
      } else if (level == 101) {
        newStatus = PowerStatus.charging;
        newLevel = 100;
      } else if (level == 102) {
        newStatus = PowerStatus.usbPower;
        newLevel = null;
      }

      final bool changed =
          (state.powerStatus != newStatus || state.batteryLevel != newLevel);

      if (mounted && changed) {
        state = state.copyWith(
          batteryLevel: newLevel,
          powerStatus: newStatus,
          connectedDevice: state.connectedDevice,
        );
      }
    }
  }

  void _updateAccelerometerState(List<int> value) {
    // 아두이노에서 float 3개 (x, y, z)는 총 12바이트입니다.
    if (value.length == 12) {
      // 받은 byte 리스트를 ByteData로 변환하여 float으로 쉽게 파싱합니다.
      final byteData = ByteData.sublistView(Uint8List.fromList(value));

      // Little Endian 형식으로 4바이트씩 읽어 double(float)로 변환합니다.
      final x = byteData.getFloat32(0, Endian.little);
      final y = byteData.getFloat32(4, Endian.little);
      final z = byteData.getFloat32(8, Endian.little);

      // 상태 갱신 대신 이벤트로 발행 (UI 리빌드 최소화)
      if (!_accelCtrl.isClosed) {
        _accelCtrl.add(AccelerometerData(x: x, y: y, z: z));
      }
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _batteryValueSubscription?.cancel();
    _accelerometerValueSubscription?.cancel();
    _accelCtrl.close();
    super.dispose();
  }
}

class BLEDeviceState {
  final bool isScanning;
  final List<ScanResult> scanResults;
  final BluetoothDevice? connectedDevice;
  final int? batteryLevel;
  final PowerStatus powerStatus;
  final bool isConnecting;
  final DeviceIdentifier? targetDeviceId;
  final String? error;

  BLEDeviceState({
    this.isScanning = false,
    this.scanResults = const [],
    this.connectedDevice,
    this.batteryLevel,
    this.powerStatus = PowerStatus.unknown,
    this.isConnecting = false,
    this.targetDeviceId,
    this.error,
  });

  BLEDeviceState copyWith({
    bool? isScanning,
    List<ScanResult>? scanResults,
    BluetoothDevice? connectedDevice,
    int? batteryLevel,
    PowerStatus? powerStatus,
    bool? isConnecting,
    DeviceIdentifier? targetDeviceId,
    String? error,
    bool clearConnectedDevice = false,
    bool clearError = false,
  }) {
    return BLEDeviceState(
      isScanning: isScanning ?? this.isScanning,
      scanResults: scanResults ?? this.scanResults,
      connectedDevice: clearConnectedDevice
          ? null
          : connectedDevice ?? this.connectedDevice,
      batteryLevel: clearConnectedDevice
          ? null
          : batteryLevel ?? this.batteryLevel,
      powerStatus: clearConnectedDevice
          ? PowerStatus.unknown
          : powerStatus ?? this.powerStatus,
      isConnecting: clearConnectedDevice
          ? false
          : isConnecting ?? this.isConnecting,
      targetDeviceId: clearConnectedDevice
          ? null
          : targetDeviceId ?? this.targetDeviceId,
      error: clearError ? null : error ?? this.error,
    );
  }
}

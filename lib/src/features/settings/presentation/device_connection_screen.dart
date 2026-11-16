import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:sleepy/src/core/services/device_connection_service.dart';

class DeviceConnectionScreen extends ConsumerWidget {
  const DeviceConnectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adapterState = ref.watch(bluetoothAdapterStateProvider);

    ref.listen<BLEDeviceState>(bluetoothDeviceProvider, (previous, next) {
      if (next.error != null && previous?.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('기기 연결')),
      body: adapterState.when(
        data: (state) => state == BluetoothAdapterState.on
            ? const DeviceScanner()
            : const BluetoothOffScreen(),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('블루투스 상태를 확인할 수 없습니다: $e')),
      ),
    );
  }
}

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bluetooth_disabled, size: 100.0, color: Colors.grey),
          const SizedBox(height: 20),
          Text(
            '블루투스가 꺼져 있습니다',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          const Text(
            '기기를 검색하고 연결하려면\n스마트폰의 블루투스를 켜주세요.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class DeviceScanner extends ConsumerWidget {
  const DeviceScanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final btState = ref.watch(bluetoothDeviceProvider);
    final btNotifier = ref.read(bluetoothDeviceProvider.notifier);

    return btState.connectedDevice == null
        ? _buildDeviceScannerView(context, btState, btNotifier)
        : _buildConnectedDeviceView(context, btState, btNotifier);
  }

  Widget _buildDeviceScannerView(
    BuildContext context,
    BLEDeviceState btState,
    BluetoothDeviceNotifier btNotifier,
  ) {
    return Scaffold(
      body: AbsorbPointer(
        absorbing: btState.isConnecting,
        child: Column(
          children: [
            if (btState.isScanning || btState.isConnecting)
              const LinearProgressIndicator(),
            Expanded(
              child: btState.scanResults.isEmpty && !btState.isScanning
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          '아래 버튼을 눌러 기기를 검색하세요.\n\n(처음 검색 시 블루투스 및 위치 권한을 허용해야 합니다)',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: btState.scanResults.length,
                      itemBuilder: (context, index) {
                        final result = btState.scanResults[index];
                        final device = result.device;
                        return ListTile(
                          leading: const Icon(Icons.bluetooth),
                          title: Text(device.platformName),
                          subtitle: Text(device.remoteId.toString()),
                          trailing:
                              btState.isConnecting &&
                                  btState.targetDeviceId == device.remoteId
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : null,
                          onTap: () => btNotifier.connect(device),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => (btState.isScanning || btState.isConnecting)
            ? null
            : btNotifier.startScan(),
        backgroundColor: (btState.isScanning || btState.isConnecting)
            ? Colors.grey
            : null,
        icon: Icon(btState.isScanning ? Icons.stop : Icons.search),
        label: Text(
          btState.isConnecting
              ? '연결 중...'
              : (btState.isScanning ? '검색 중...' : '기기 검색'),
        ),
      ),
    );
  }

  Widget _buildConnectedDeviceView(
    BuildContext context,
    BLEDeviceState btState,
    BluetoothDeviceNotifier btNotifier,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 80),
          const SizedBox(height: 24),
          Text(
            btState.connectedDevice!.platformName,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          Text(
            '연결됨',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.green),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildPowerStatusWidget(context, btState),
          const Spacer(),
          ElevatedButton(
            onPressed: () => btNotifier.disconnect(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('연결 해제'),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerStatusWidget(BuildContext context, BLEDeviceState btState) {
    IconData icon;
    String text;
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
        break;
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 30),
        const SizedBox(width: 8),
        Text(text, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}

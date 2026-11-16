import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sleepy/src/features/onboarding/application/onboarding_controller.dart';
import 'package:sleepy/src/features/onboarding/presentation/widgets/step_header.dart';
import 'package:sleepy/src/features/onboarding/presentation/widgets/pill_chip.dart';
import 'package:sleepy/src/features/onboarding/presentation/widgets/label.dart';
import 'package:sleepy/src/features/onboarding/presentation/widgets/time_card.dart';

class OnboardingStep3Times extends ConsumerStatefulWidget {
  const OnboardingStep3Times({super.key});

  @override
  ConsumerState<OnboardingStep3Times> createState() => _OnboardingStep3TimesState();
}

TimeOfDay _parse(String hhmm) {
    final p = hhmm.split(':'); return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

class _OnboardingStep3TimesState extends ConsumerState<OnboardingStep3Times> {
  TimeOfDay? _bedtime;
  TimeOfDay? _wakeup;
  String? _sleepLatency; // '몇 분' | '10분 이내' | '20~40분 이내' | '잠들기 어려움'

  @override
  void initState() {
    super.initState();
    final d = ref.read(onboardingControllerProvider);
    if (d.avgBedTime.isNotEmpty) _bedtime = _parse(d.avgBedTime);
    if (d.avgWakeUpTime.isNotEmpty) _wakeup = _parse(d.avgWakeUpTime);
    if (d.timeToSleep.isNotEmpty) _sleepLatency = d.timeToSleep;
  }

  static const List<String> _latencyOptions = [
    '몇 분',
    '10분 이내',
    '20~40분 이내',
    '잠들기 어려움',
  ];

  Future<void> _pickTime({
    required bool isBedtime,
  }) async {
    final initial = isBedtime
        ? (_bedtime ?? const TimeOfDay(hour: 22, minute: 0))
        : (_wakeup ?? const TimeOfDay(hour: 7, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      initialEntryMode: TimePickerEntryMode.dial, // 다이얼 모드 고정
      helpText: isBedtime ? '취침 시간 선택' : '기상 시간 선택',
      builder: (context, child) {
        // 다이얼을 조금 더 또렷하게 보이도록(선택 사항)
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: const TimePickerThemeData(
              helpTextStyle: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isBedtime) {
          _bedtime = picked;
        } else {
          _wakeup = picked;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool get _canProceed => _bedtime != null && _wakeup != null && _sleepLatency != null;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final notifier = ref.read(onboardingControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            const StepHeader(current: 3, total: 4),
            const SizedBox(height: 12),
            Text(
              '평소 취침/기상 시간과\n잠드는 데 걸리는 시간을\n알려주세요',
              style: tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.black,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 24),

            // 취침 시간
            const Label(text: '평균 취침 시간'),
            const SizedBox(height: 10),
            TimeCard(
              icon: Icons.nightlight_round,
              label: _bedtime == null ? '시간 선택' : _formatTimeOfDay(_bedtime!),
              onTap: () => _pickTime(isBedtime: true),
            ),

            const SizedBox(height: 20),

            // 기상 시간
            const Label(text: '평균 기상 시간'),
            const SizedBox(height: 10),
            TimeCard(
              icon: Icons.wb_sunny_rounded,
              label: _wakeup == null ? '시간 선택' : _formatTimeOfDay(_wakeup!),
              onTap: () => _pickTime(isBedtime: false),
            ),

            const SizedBox(height: 24),

            // 잠드는 데 걸리는 시간
            const Label(text: '잠드는 데 걸리는 시간'),
            const SizedBox(height: 10),
            _LatencyChips(
              options: _latencyOptions,
              selected: _sleepLatency,
              onSelect: (v) => setState(() => _sleepLatency = v),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _canProceed ? Colors.black : const Color(0xFFCFD3DA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            onPressed: !_canProceed
                ? null
                : () {
                    notifier.updateAvgBedtime(_formatTimeOfDay(_bedtime!));
                    notifier.updateAvgWakeUpTime(_formatTimeOfDay(_wakeup!));
                    notifier.updateTimeToSleep(_sleepLatency!);
                    context.push('/onboarding/step4');
                  },
            child: const Text('다음'),
          ),
        ),
      ),
    );
  }
}

// ---- UI 보조 위젯들 ----
class _LatencyChips extends StatelessWidget {
  const _LatencyChips({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: options.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,      // 2열 균등
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 3.6,
      ),
      itemBuilder: (context, index) {
        final opt = options[index];
        final isSel = opt == selected;
        return PillChipSignle(
          label: opt,
          selected: isSel,
          onTap: () => onSelect(opt),
        );
      },
    );
  }
}



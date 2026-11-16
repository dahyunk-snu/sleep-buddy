import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sleepy/src/features/onboarding/application/onboarding_controller.dart';
import 'package:sleepy/src/features/onboarding/presentation/widgets/step_header.dart';
import 'package:sleepy/src/features/onboarding/presentation/widgets/label.dart';
import 'package:sleepy/src/features/onboarding/presentation/widgets/time_card.dart';
import 'package:sleepy/src/features/onboarding/presentation/widgets/tip_card.dart';

class OnboardingStep4Goals extends ConsumerStatefulWidget {
  const OnboardingStep4Goals({super.key});

  @override
  ConsumerState<OnboardingStep4Goals> createState() => _OnboardingStep4GoalsState();
}

class _OnboardingStep4GoalsState extends ConsumerState<OnboardingStep4Goals> {
  // 목표 값 (화면 로컬 상태)
  TimeOfDay? _goalBedtime;            // 목표 취침
  TimeOfDay? _goalWakeup;             // 목표 기상

  // --- 시간 유틸 ---
  String _formatTod(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  TimeOfDay _parseHHmm(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  void initState() {
    super.initState();
    final d = ref.read(onboardingControllerProvider);
    if (d.goalBedTime.isNotEmpty) _goalBedtime = _parseHHmm(d.goalBedTime);
    if (d.goalWakeUpTime.isNotEmpty) _goalWakeup = _parseHHmm(d.goalWakeUpTime);
  }

  /// 자정 넘김을 고려한 수면 시간 계산 (예: 23:00 -> 07:00 = 8시간)
  Duration _sleepDuration(TimeOfDay bed, TimeOfDay wake) {
    final bedMin = bed.hour * 60 + bed.minute;
    final wakeMin = wake.hour * 60 + wake.minute;
    final diff = (wakeMin - bedMin + 24 * 60) % (24 * 60);
    return Duration(minutes: diff == 0 ? 24 * 60 : diff);
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return m == 0 ? '$h시간' : '$h시간 $m분';
  }

  /// 만 나이 추정(연-월-일 기준, 대략)
  int _ageInYears(DateTime birth) {
    final now = DateTime.now();
    int age = now.year - birth.year;
    final beforeBirthday = (now.month < birth.month) ||
        (now.month == birth.month && now.day < birth.day);
    if (beforeBirthday) age--;
    return age.clamp(0, 120);
  }

  /// 나이에 따른 권장 수면 시간 범위(시간). (AASM/CDC 가이드라인을 단순화)
  /// 1–2세: 11–14, 3–5세: 10–13, 6–12세: 9–12, 13–18세: 8–10, 성인: 7–9
  (double minH, double maxH, String label) _recommendedRange(int age) {
    if (age <= 2) return (11, 14, '1–2세 권장');
    if (age <= 5) return (10, 13, '3–5세 권장');
    if (age <= 12) return (9, 12, '6–12세 권장');
    if (age <= 18) return (8, 10, '13–18세 권장');
    return (7, 9, '성인 권장');
  }

  Future<void> _pickTime({required bool isBedtime}) async {
    final initial = isBedtime
        ? (_goalBedtime ?? const TimeOfDay(hour: 22, minute: 0))
        : (_goalWakeup ?? const TimeOfDay(hour: 7, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      initialEntryMode: TimePickerEntryMode.dial,
      helpText: isBedtime ? '목표 취침 시간 선택' : '목표 기상 시간 선택',
      builder: (context, child) {
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
          _goalBedtime = picked;
        } else {
          _goalWakeup = picked;
        }
      });
    }
  }

  bool get _canProceed => _goalBedtime != null && _goalWakeup != null;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final data = ref.watch(onboardingControllerProvider); // OnboardingData

    // 평소 값(이전 단계 입력) 읽기
    final avgBedStr = data.avgBedTime;        // 'HH:mm'
    final avgWakeStr = data.avgWakeUpTime;    // 'HH:mm'
    final birth = data.childBirthDate;

    final TimeOfDay? avgBed = (avgBedStr.isNotEmpty) ? _parseHHmm(avgBedStr) : null;
    final TimeOfDay? avgWake = (avgWakeStr.isNotEmpty) ? _parseHHmm(avgWakeStr) : null;

    // 비교/Tip 계산
    final int? age = (birth != null) ? _ageInYears(birth) : null;
    final (double minR, double maxR, String label) rec =
        (age != null) ? _recommendedRange(age) : (7, 9, '권장 수면(연령 정보 필요)');

    final Duration? avgSleepDur =
        (avgBed != null && avgWake != null) ? _sleepDuration(avgBed, avgWake) : null;

    final Duration? goalSleepDur =
        (_goalBedtime != null && _goalWakeup != null) ? _sleepDuration(_goalBedtime!, _goalWakeup!) : null;

    final double? goalHours = (goalSleepDur != null) ? goalSleepDur.inMinutes / 60.0 : null;
    final double? avgHours = (avgSleepDur != null) ? avgSleepDur.inMinutes / 60.0 : null;

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
            const StepHeader(current: 4, total: 4),
            const SizedBox(height: 12),
            Text(
              '목표 수면 시간과\n목표 취침/기상 시간을 정해요',
              style: tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.black,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 24),
            // Tip 카드
            if (avgBed != null && avgWake != null)
              TipCard(
                recLabel: rec.$3,
                recMin: rec.$1,
                recMax: rec.$2,
                avgBed: avgBed,
                avgWake: avgWake,
                avgHours: avgHours,
                goalBed: _goalBedtime,
                goalWake: _goalWakeup,
                goalHours: goalHours,
                fmtTod: _formatTod,
                fmtDur: _fmtDuration,
              ),
            const SizedBox(height: 20),
            // 목표 취침/기상
            const Label(text: '목표 취침 시간'),
            const SizedBox(height: 10),
            TimeCard(
              icon: Icons.nightlight_round,
              label: _goalBedtime == null ? '시간 선택' : _formatTod(_goalBedtime!),
              onTap: () => _pickTime(isBedtime: true),
            ),
            const SizedBox(height: 16),
            const Label(text: '목표 기상 시간'),
            const SizedBox(height: 10),
            TimeCard(
              icon: Icons.wb_sunny_rounded,
              label: _goalWakeup == null ? '시간 선택' : _formatTod(_goalWakeup!),
              onTap: () => _pickTime(isBedtime: false),
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
                    // 저장
                    notifier.updateGoalBedtime(_formatTod(_goalBedtime!));
                    notifier.updateGoalWakeUpTime(_formatTod(_goalWakeup!));

                    notifier.saveOnboardingData();
                  },
            child: const Text('완료'),
          ),
        ),
      ),
    );
  }
}
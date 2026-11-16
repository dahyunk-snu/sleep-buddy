import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sleepy/src/features/onboarding/application/onboarding_controller.dart';
import 'package:sleepy/src/features/onboarding/presentation/widgets/step_header.dart';
import 'package:sleepy/src/features/onboarding/presentation/widgets/pill_chip.dart';

class OnboardingStep2Habits extends ConsumerStatefulWidget {
  const OnboardingStep2Habits({super.key});

  @override
  ConsumerState<OnboardingStep2Habits> createState() => _OnboardingStep2HabitsState();
}

class _OnboardingStep2HabitsState extends ConsumerState<OnboardingStep2Habits> {
  Set<String> sleepBehaviors = {};
  Set<String> sleepConcerns = {};
  Set<String> activityLevels = {};
  String behaviorOtherText = '';
  String concernOtherText = '';

  // 수면 중 행동 옵션
  static const List<String> _behaviorOptions = [
    '자주 깸',
    '몸부림이 심함',
    '코골이/이갈이',
    '잠꼬대',
    '악몽',
    '야경증',
    '모르겠음',
    '기타',
  ];

  // 수면 우려 사항 옵션
  static const List<String> _concernOptions = [
    '잠들기 어려워함',
    '밤에 자주 깸',
    '너무 일찍 일어남',
    '악몽/야경증',
    '수면 환경',
    '분리 불안',
    '모르겠음',
    '기타',
  ];

  @override
  void initState() {
    super.initState();
    final onboardingData = ref.read(onboardingControllerProvider);

    sleepBehaviors = Set<String>.from(onboardingData.sleepBehaviors);
    sleepConcerns  = Set<String>.from(onboardingData.sleepConcerns);

    // --- 수면 행동: 옵션 외 값 → '기타' + 텍스트로 매핑
    final behaviorsExtra = sleepBehaviors.where(
      (e) => !_behaviorOptions.contains(e) && e.trim().isNotEmpty,
    ).toList();
    if (behaviorsExtra.isNotEmpty) {
      behaviorOtherText = behaviorsExtra.first;
      sleepBehaviors.removeAll(behaviorsExtra);
    }

    // --- 수면 우려: 옵션 외 값 → '기타' + 텍스트로 매핑
    final concernsExtra = sleepConcerns.where(
      (e) => !_concernOptions.contains(e) && e.trim().isNotEmpty,
    ).toList();
    if (concernsExtra.isNotEmpty) {
      concernOtherText = concernsExtra.first;
      sleepConcerns.removeAll(concernsExtra);
    }
  }

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
            const StepHeader(current: 2, total: 4),
            const SizedBox(height: 12),
            Text(
              '안좋은 수면습관도 알려주시면\n수면 기록에 도움이 돼요',
              style: tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.black,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 24),
            _Label(text: '수면 중 행동'),
            const SizedBox(height: 12),
            _buildOptionGridChips(_behaviorOptions, sleepBehaviors, isBehavior: true),

            const SizedBox(height: 24),
            _Label(text: '수면 우려 사항'),
            const SizedBox(height: 12),
            _buildOptionGridChips(_concernOptions, sleepConcerns, isBehavior: false),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            onPressed: () {
              final behaviorsFinal = Set<String>.from(sleepBehaviors);
              if (behaviorsFinal.contains('기타') && behaviorOtherText.isNotEmpty) {
                behaviorsFinal
                  ..remove('기타')
                  ..add(behaviorOtherText);
              }

              final concernsFinal = Set<String>.from(sleepConcerns);
              if (concernsFinal.contains('기타') && concernOtherText.isNotEmpty) {
                concernsFinal
                  ..remove('기타')
                  ..add(concernOtherText);
              }
              notifier.updateSleepBehaviors(behaviorsFinal);
              notifier.updateSleepConcerns(concernsFinal);
              context.push('/onboarding/step3');
            },
            child: const Text('다음'),
          ),
        ),
      ),
    );
  }

  static const String _unknown = '모르겠음';
  void _toggleSelection(Set<String> set, String value) {
    setState(() {
      const other = '기타';

      // '모르겠음' 처리
      if (value == _unknown) {
        set
          ..clear()
          ..add(_unknown);
        return;
      }

      // 다른 항목 선택 시 '모르겠음' 제거
      set.remove(_unknown);

      // '기타' 선택
      if (value == other) {
        if (set.contains(other)) {
          // 이미 선택된 상태에서 해제 → 텍스트 초기화
          set.remove(other);
          if (set == sleepBehaviors) behaviorOtherText = '';
          if (set == sleepConcerns) concernOtherText = '';
        } else {
          set.add(other);
        }
        return;
      }

      // 일반 토글
      if (set.contains(value)) {
        set.remove(value);
      } else {
        set.add(value);
      }
    });
  }

  Widget _buildOptionGridChips(List<String> options, Set<String> selectedSet, {bool isBehavior = false}) {
    final isUnknownSelected = selectedSet.contains('모르겠음');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: options.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 3.6,
          ),
          itemBuilder: (context, index) {
            final opt = options[index];
            final selected = selectedSet.contains(opt);

            return PillChipMultiple(
              label: opt,
              selected: selected,
              onTap: () => _toggleSelection(selectedSet, opt),
              dimmed: isUnknownSelected && opt != '모르겠음', // 흐림 처리
            );
          },
        ),
        if (selectedSet.contains('기타'))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: '기타 내용을 입력하세요',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (val) {
                setState(() {
                  if (isBehavior) {
                    behaviorOtherText = val;
                  } else {
                    concernOtherText = val;
                  }
                });
              },
            ),
          ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF9DA3AE),
              fontWeight: FontWeight.w600,
            ));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sleepy/src/features/onboarding/application/onboarding_controller.dart';
import 'package:sleepy/src/features/onboarding/presentation/widgets/step_header.dart';

class OnboardingStep1Basic extends ConsumerStatefulWidget {
  const OnboardingStep1Basic({super.key});

  @override
  ConsumerState<OnboardingStep1Basic> createState() => _OnboardingStep1BasicState();
}

class _OnboardingStep1BasicState extends ConsumerState<OnboardingStep1Basic> {
  late final TextEditingController _lastNameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _dateController;
  String? gender;           // 'female' | 'male'
  String? activity;         // 'very_low' | 'low' | 'mid' | 'high' 등

  @override
  void initState() {
    super.initState();
    final onboardingData = ref.read(onboardingControllerProvider);

    _lastNameController = TextEditingController(text: onboardingData.childLastName);
    _firstNameController = TextEditingController(text: onboardingData.childFirstName);
    _dateController = TextEditingController(
      text: onboardingData.childBirthDate == null
          ? ''
          : DateFormat('yyyy년 MM월 dd일').format(onboardingData.childBirthDate!),
    );
    gender = onboardingData.childGender.isEmpty ? null : onboardingData.childGender;
    activity = onboardingData.activityLevel.isEmpty ? null : onboardingData.activityLevel;
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _firstNameController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  bool get isValid {
    return (gender != null) &&
        (activity != null) &&
        _lastNameController.text.trim().isNotEmpty &&
        _firstNameController.text.trim().isNotEmpty &&
        _dateController.text.trim().isNotEmpty;
  }

  Future<void> _pickBirthDate() async {
    final notifier = ref.read(onboardingControllerProvider.notifier);
    final initialDate =
        ref.read(onboardingControllerProvider).childBirthDate ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000, 1, 1), // 적절히 범위 조절
      lastDate: DateTime.now(),
      helpText: '생년월일을 선택해주세요',
      confirmText: '확인',
      cancelText: '취소',
    );
    if (picked != null) {
      notifier.updateChildBirthDate(picked);
      _dateController.text = DateFormat('yyyy년 MM월 dd일').format(picked);
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
            const StepHeader(current: 1, total: 4),
            const SizedBox(height: 12),
            Text(
              '맞춤 목표 기록 시작!\n기본 정보를 알려주세요',
              style: tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.black,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 24),

            // 1) 성/이름 - 성별 위로 이동
            Row(
              children: [
                Expanded(
                  child: _RoundedField(
                    controller: _lastNameController,
                    label: '성',
                    inputType: TextInputType.name,
                    hintText: '예: 홍',
                    onChanged: notifier.updateChildLastName,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RoundedField(
                    controller: _firstNameController,
                    label: '이름',
                    inputType: TextInputType.name,
                    hintText: '예: 길동',
                    onChanged: notifier.updateChildFirstName,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2) 성별 (이모티콘 제거)
            _Label(text: '성별'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SelectCircleCard(
                    label: '여성',
                    selected: gender == 'female',
                    onTap: () => setState(() => gender = 'female'),
                    color: const Color(0xFFFFE8EC),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SelectCircleCard(
                    label: '남성',
                    selected: gender == 'male',
                    onTap: () => setState(() => gender = 'male'),
                    color: const Color(0xFFF1F3F5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3) 생년월일 (나이 입력 대체)
            _Label(text: '생년월일'),
            const SizedBox(height: 8),
            TextField(
              controller: _dateController,
              readOnly: true,
              onTap: _pickBirthDate,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF6F7FA),
                hintText: '예: 2018년 01월 15일',
                suffixIcon: const Icon(Icons.calendar_today_outlined),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 활동량
            _Label(text: '평소 활동량'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              children: [
                _ActivityChip(
                  emoji: '🛌', title: '매우 적음', subtitle: '활동이 거의 없는',
                  selected: activity == 'very_low',
                  onTap: () => setState(() => activity = 'very_low'),
                ),
                _ActivityChip(
                  emoji: '🪑', title: '적음', subtitle: '주로 앉아있는',
                  selected: activity == 'low',
                  onTap: () => setState(() => activity = 'low'),
                ),
                _ActivityChip(
                  emoji: '🚶', title: '보통', subtitle: '주 2~3회 정도',
                  selected: activity == 'mid',
                  onTap: () => setState(() => activity = 'mid'),
                ),
                _ActivityChip(
                  emoji: '🏃', title: '많음', subtitle: '매일 운동',
                  selected: activity == 'high',
                  onTap: () => setState(() => activity = 'high'),
                ),
              ],
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
              backgroundColor:
                  isValid ? Colors.black : Colors.black.withValues(alpha: 0.12),
              foregroundColor: isValid ? Colors.white : Colors.white.withValues(alpha: 0.9),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            onPressed: isValid ? () {
              notifier.updateChildGender(gender!);
              notifier.updateActivityLevel(activity!);
              context.push('/onboarding/step2');
            } : null,
            child: const Text('다음'),
          ),
        ),
      ),
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

/// 성별 선택 카드
class _SelectCircleCard extends StatelessWidget {
  const _SelectCircleCard({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.transparent;
    final textColor  = selected ? Colors.black : const Color(0xFFB6BCC6);
    final bgTint = selected ? color.withValues(alpha: 0.55) : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: bgTint,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}

/// 라운드 인풋
class _RoundedField extends StatelessWidget {
  const _RoundedField({
    required this.controller,
    required this.label,
    required this.inputType,
    this.hintText,
    this.onChanged,
  });
  final TextEditingController controller;
  final String label;
  final TextInputType inputType;
  final String? hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(text: label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: inputType,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF6F7FA),
            hintText: hintText,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

/// 활동량 칩 (동그란 아이콘 + 제목/보조)
class _ActivityChip extends StatelessWidget {
  const _ActivityChip({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? Colors.black : const Color(0xFFF6F7FA);
    final fg = selected ? Colors.white : const Color(0xFF8D95A1);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 32))),
            ),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: fg.withValues(alpha: 0.7), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

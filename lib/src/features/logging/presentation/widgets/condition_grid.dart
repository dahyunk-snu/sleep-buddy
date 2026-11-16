import 'package:flutter/material.dart';
import 'package:sleepy/src/core/models/sleep_data.dart';

/// 아침 컨디션 카드 그리드
class ConditionGrid extends StatelessWidget {
  const ConditionGrid({
    super.key,
    required this.value,
    required this.onChanged,
    required this.iconOf,
    required this.colorOf,
    required this.labelOf,
    required this.activated,
  });

  final MorningCondition value;
  final ValueChanged<MorningCondition> onChanged;
  final IconData Function(MorningCondition) iconOf;
  final Color Function(MorningCondition) colorOf;
  final String Function(MorningCondition) labelOf;
  final bool activated;

  @override
  Widget build(BuildContext context) {
    // 무채색 팔레트(비활성/비선택 기본값)
    const neutralIcon = Color(0xFF606770);
    const neutralChipBg = Color(0xFFF2F4F7);
    const neutralBorder = Color(0xFFE8EBF0);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: MorningCondition.values.map((c) {
        final selected = c == value;
        final base = colorOf(c);
        final isActiveSelected = activated && selected;

        final iconColor = isActiveSelected ? base : neutralIcon;
        final circleBg = isActiveSelected
            ? base.withValues(alpha: 0.18)
            : neutralChipBg;
        final borderCol = isActiveSelected
            ? base.withValues(alpha: 0.60)
            : neutralBorder;
        final tileBg = isActiveSelected
            ? base.withValues(alpha: 0.08)
            : Colors.white;

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onChanged(c),
          child: Container(
            width: 96,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: tileBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderCol),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: circleBg,
                  ),
                  child: Icon(iconOf(c), color: iconColor, size: 26),
                ),
                const SizedBox(height: 8),
                Text(
                  labelOf(c),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: isActiveSelected
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

import 'package:flutter/material.dart';

/// 상단 스텝 인디케이터 (1 2 3 4)
class StepHeader extends StatelessWidget {
  const StepHeader({super.key, required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final items = List<Widget>.generate(total, (i) {
      final active = (i + 1) == current;
      return Container(
        width: 28, height: 28,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: active ? Colors.black : const Color(0xFFEDEFF2),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text('${i + 1}',
            style: TextStyle(
              color: active ? Colors.white : const Color(0xFF8C939F),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      );
    });
    return Row(children: items);
  }
}
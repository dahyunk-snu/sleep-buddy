import 'package:flutter/material.dart';

/// 기존에 쓰던 스타일과 맞춘 필 칩 (단일 선택)
class PillChipSignle extends StatelessWidget {
  const PillChipSignle({
    super.key, 
    required this.label,
    required this.selected,
    required this.onTap,
    this.dimmed = false,
  });

  final String label;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  static const _h = 44.0;
  static const _r = 14.0;
  static const _iconW = 18.0;

  @override
  Widget build(BuildContext context) {
    final selBg = Colors.black;
    const norBg = Color(0xFFF6F7FA);
    const norFg = Color(0xFF111827);
    final selFg = Colors.white;
    const norBorder = Color(0xFFE5E7EB);

    return Opacity(
      opacity: dimmed ? 0.5 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_r),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            height: _h,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: selected ? selBg : norBg,
              borderRadius: BorderRadius.circular(_r),
              border: Border.all(
                width: 1,
                color: selected ? Colors.black : norBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(
                  width: _iconW,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 120),
                    opacity: selected ? 1 : 0,
                    child: const Icon(Icons.check, size: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected ? selFg : norFg,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 기존에 쓰던 스타일과 맞춘 필 칩 (다중 선택)
class PillChipMultiple extends StatelessWidget {
  const PillChipMultiple({
    super.key, 
    required this.label,
    required this.selected,
    required this.onTap,
    this.dimmed = false, // 흐림 여부
  });

  final String label;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  static const _h = 44.0;
  static const _r = 14.0;
  static const _iconW = 18.0;

  @override
  Widget build(BuildContext context) {
    final selBg = Colors.black;
    const norBg = Color(0xFFF6F7FA);
    const norFg = Color(0xFF111827);
    final selFg = Colors.white;
    const norBorder = Color(0xFFE5E7EB);

    return Opacity(
      opacity: dimmed ? 0.5 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_r),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            height: _h,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: selected ? selBg : norBg,
              borderRadius: BorderRadius.circular(_r),
              border: Border.all(
                width: 1,
                color: selected ? Colors.black : norBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(
                  width: _iconW,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 120),
                    opacity: selected ? 1 : 0,
                    child: const Icon(Icons.check, size: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected ? selFg : norFg,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
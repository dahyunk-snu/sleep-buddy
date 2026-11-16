import 'package:flutter/material.dart';

/// [PrimaryButton] 앱 전역 기본 버튼
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.onPressed, required this.text});

  final VoidCallback? onPressed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: Theme.of(context).textTheme.titleMedium,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Center(child: Text(text)),
      ),
    );
  }
}

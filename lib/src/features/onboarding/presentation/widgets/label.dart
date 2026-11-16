import 'package:flutter/material.dart';

class Label extends StatelessWidget {
  const Label({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFF9DA3AE),
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
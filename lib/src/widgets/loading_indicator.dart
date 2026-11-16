import 'package:flutter/material.dart';

/// [LoadingIndicator] 화면 중앙에 원형 진행 표시기
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

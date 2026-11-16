import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sleepy/src/core/services/circadian_rhythm_service.dart';

class AnalysisProgressDialog extends StatefulWidget {
  final Stream<AnalysisEvent> stream;

  const AnalysisProgressDialog({super.key, required this.stream});

  @override
  State<AnalysisProgressDialog> createState() => _AnalysisProgressDialogState();
}

class _AnalysisProgressDialogState extends State<AnalysisProgressDialog> {
  late final StreamSubscription<AnalysisEvent> _subscription;
  String _message = '분석을 시작합니다...';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _subscription = widget.stream.listen((event) {
      if (!mounted) return;

      setState(() {
        _message = event.message;
        _progress = event.progress ?? _progress;
      });

      // 최종 결과가 도착하면 다이얼로그를 닫고 결과값을 반환
      if (event.latency != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop(event.latency);
          }
        });
      } else if (event.message.contains('건너뛰기') ||
          event.message.contains('오류')) {
        // 데이터가 부족하거나 오류 발생 시 1초 후 null을 반환하며 닫힘
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('DLMO 추정 시작', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(),
          ),
          const SizedBox(height: 24),
          Text(
            _message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

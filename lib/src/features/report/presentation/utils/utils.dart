import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sleepy/src/features/report/application/report_controller.dart';

String periodLabel(ReportType type, DateTime date) {
  if (type == ReportType.weekly) {
    final dayOfMonth = date.day;
    final weekOfMonth = (dayOfMonth - 1) ~/ 7 + 1;
    return '${DateFormat('yyyy년 MM월').format(date)} $weekOfMonth주차';
  } else {
    return DateFormat('yyyy년 MM월').format(date);
  }
}

TimeOfDay parseHHmm(String s) {
  final p = s.split(':');
  return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
}

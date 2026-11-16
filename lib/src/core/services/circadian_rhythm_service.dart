import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sleepy/src/core/services/database_service.dart';

part 'circadian_rhythm_service.g.dart';

class AnalysisEvent {
  final String message;
  final double? progress;
  final int? latency;

  AnalysisEvent(this.message, {this.progress, this.latency});
}

@riverpod
CircadianRhythmService circadianRhythmService(Ref ref) {
  return CircadianRhythmService(ref.read(databaseServiceProvider));
}

/// DLMO 추정 및 입면 잠복기 계산 서비스
class CircadianRhythmService {
  final DatabaseService _db;

  CircadianRhythmService(this._db);

  /// 아동의 고유 입면 잠복기(L)를 추정하여 분 단위로 반환
  Stream<AnalysisEvent> estimateLatency(String userId, String childId) async* {
    const int maxIter = 100;
    const int totalSteps = 2 + maxIter + 1;
    int currentStep = 0;

    try {
      currentStep++;
      yield AnalysisEvent('데이터 수집 중...', progress: currentStep / totalSteps);
      // 1. 데이터 수집
      final sleepDataList = await _db.getRecentSleepData(
        userId,
        childId,
        limit: 30,
      );

      // 2. 데이터 유효성 검사
      if (sleepDataList.length < 7) {
        yield AnalysisEvent('분석 건너뛰기: 데이터 부족', progress: 1.0);
        return;
      }

      // 3. 데이터 전처리
      currentStep++;
      yield AnalysisEvent('데이터 전처리 중...', progress: currentStep / totalSteps);
      final observations = sleepDataList
          .map((data) {
            final tst = data.duration.inMinutes / 60.0;
            double so = data.startTime.hour + data.startTime.minute / 60.0;
            // 정오 이전의 입면은 다음 날 주기에 속할 가능성이 있으므로 24를 더해줌
            if (so < 12) so += 24;
            return {'so': so, 'tst': tst};
          })
          .toList()
          .reversed
          .toList(); // 시간순(오름차순)으로 정렬

      // 4. 초기값 설정
      const double lPrior = 2.0;
      double l = lPrior;
      double sigmaR = 1.0;
      double sigmaQ = 0.5;
      const double tolerance = 1e-4;

      // 5. EM 알고리즘 기반 반복 최적화
      for (int i = 0; i < maxIter; i++) {
        currentStep++;
        yield AnalysisEvent('DLMO 추정 중...', progress: currentStep / totalSteps);
        final double lOld = l;

        final smoothed = _rtsSmoother(observations, l, sigmaR, sigmaQ);
        if (smoothed == null) throw Exception('RTS Smoother failed');

        sigmaR = _updateSigmaR(observations, smoothed, l);
        sigmaQ = _updateSigmaQ(smoothed);
        l = _updateL(observations, smoothed, sigmaR, lPrior);

        if ((l - lOld).abs() < tolerance) break;
        await Future.delayed(const Duration(milliseconds: 100));
      }

      final estimatedLInHours = l % 24;
      final estimatedLatency = (estimatedLInHours * 60).round().abs();
      yield AnalysisEvent('분석 완료', progress: 1.0, latency: estimatedLatency);
    } catch (e) {
      yield AnalysisEvent('오류: 분석 실패', progress: 1.0);
      debugPrint('Latency estimation error: $e');
    }
  }

  Map<String, List<double>>? _rtsSmoother(
    List<Map<String, double>> observations,
    double l,
    double sigmaR,
    double sigmaQ,
  ) {
    try {
      final T = observations.length;
      final y = observations.map((e) => e['so']! - l).toList();
      final r = pow(sigmaR, 2).toDouble();
      final q = pow(sigmaQ, 2).toDouble();

      final xPred = List<double>.filled(T, 0);
      final pPred = List<double>.filled(T, 0);
      final xFilt = List<double>.filled(T, 0);
      final pFilt = List<double>.filled(T, 0);

      xFilt[0] = y[0];
      pFilt[0] = r;

      for (int d = 1; d < T; d++) {
        xPred[d] = xFilt[d - 1];
        pPred[d] = pFilt[d - 1] + q;
        final s = pPred[d] + r;
        final k = pPred[d] / s;
        xFilt[d] = xPred[d] + k * (y[d] - xPred[d]);
        pFilt[d] = (1 - k) * pPred[d];
      }

      final xSmooth = List<double>.filled(T, 0);
      final pSmooth = List<double>.filled(T, 0);
      final pCov = List<double>.filled(T - 1, 0);

      xSmooth[T - 1] = xFilt[T - 1];
      pSmooth[T - 1] = pFilt[T - 1];

      for (int d = T - 2; d >= 0; d--) {
        final g = pFilt[d] / pPred[d + 1];
        xSmooth[d] = xFilt[d] + g * (xSmooth[d + 1] - xPred[d + 1]);
        pSmooth[d] = pFilt[d] + g * g * (pSmooth[d + 1] - pPred[d + 1]);
        pCov[d] = g * pSmooth[d + 1];
      }

      return {'x': xSmooth, 'p': pSmooth, 'pCov': pCov};
    } catch (e) {
      debugPrint('Error in RTS Smoother: $e');
      return null;
    }
  }

  double _updateSigmaR(
    List<Map<String, double>> observations,
    Map<String, List<double>> smoothed,
    double l,
  ) {
    final T = observations.length;
    final x = smoothed['x']!;
    final p = smoothed['p']!;
    double sum = 0;
    for (int d = 0; d < T; d++) {
      sum += (pow(observations[d]['so']! - l - x[d], 2) + p[d]);
    }
    return sqrt(sum / T);
  }

  double _updateSigmaQ(Map<String, List<double>> smoothed) {
    final T = smoothed['x']!.length;
    final x = smoothed['x']!;
    final p = smoothed['p']!;
    final pCov = smoothed['pCov']!;
    double sum = 0;
    for (int d = 1; d < T; d++) {
      sum += (pow(x[d] - x[d - 1], 2) + p[d] + p[d - 1] - 2 * pCov[d - 1]);
    }
    return sqrt(sum / (T - 1));
  }

  /// 위상각(L) 업데이트 (가중치 및 규제 항 추가)
  double _updateL(
    List<Map<String, double>> observations,
    Map<String, List<double>> smoothed,
    double sigmaR,
    double lPrior, // L의 사전 믿음 (e.g., 2.0 시간)
  ) {
    final T = observations.length;
    final x = smoothed['x']!;

    // --- 하이퍼파라미터 ---
    const double delta = 1.5; // 이상치 판단 기준 (Huber loss)
    const double lambdaL = 2.0; // 규제 강도 (값이 클수록 초기값에 가깝게 유지됨)

    double weightedSum = 0;
    double weightTotal = 0;
    final r = pow(sigmaR, 2); // 관측 노이즈 분산

    for (int d = 0; d < T; d++) {
      final residual = observations[d]['so']! - x[d];

      // 이상치에 강건한 가중치(omega) 계산
      final alpha = (residual - lPrior).abs() <= delta
          ? 1.0
          : delta / (residual - lPrior).abs();
      final weight = alpha / r;

      weightedSum += weight * residual;
      weightTotal += weight;
    }

    // 규제가 적용된 최종 L 값 계산
    if (weightTotal == 0) return lPrior; // 데이터가 없는 극단적인 경우

    final lHat = (weightedSum + lambdaL * lPrior) / (weightTotal + lambdaL);
    return lHat;
  }
}

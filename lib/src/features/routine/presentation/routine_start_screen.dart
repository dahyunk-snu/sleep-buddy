import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sleepy/src/core/models/sleep_data.dart';
import 'package:sleepy/src/core/models/sleep_routine.dart';
import 'package:sleepy/src/features/onboarding/presentation/widgets/label.dart';
import 'package:sleepy/src/features/routine/application/routine_controller.dart';
import 'package:sleepy/src/core/services/device_connection_service.dart';
import 'package:go_router/go_router.dart';

class RoutineStartScreen extends ConsumerStatefulWidget {
  const RoutineStartScreen({super.key});

  @override
  ConsumerState<RoutineStartScreen> createState() => _RoutineStartScreenState();
}

class _RoutineStartScreenState extends ConsumerState<RoutineStartScreen>
    with SingleTickerProviderStateMixin {
  // --- 로컬 폼 상태 ---
  bool _drinkWater = false;
  bool _stretch = false;
  bool _screenOff = false;
  bool _overeating = false;

  bool _brushedTeeth = false;
  bool _showered = false;
  LightCondition _light = LightCondition.dark;
  SoundCondition _sound = SoundCondition.quiet;

  SleepSessionType _sessionType = SleepSessionType.night;

  // 추적 화면 애니메이션
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    final s = ref.read(routineControllerProvider);
    _drinkWater = s.drinkWater;
    _stretch = s.stretch;
    _screenOff = s.screenOff;
    _overeating = s.overeating;

    _brushedTeeth = s.brushedTeeth;
    _showered = s.showered;
    _light = s.light;
    _sound = s.sound;

    _sessionType = s.sessionType;

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(
      begin: 0.96,
      end: 1.04,
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(_pulseCtrl);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  List<Color> _bgForSession(SleepSessionType t) {
    if (t == SleepSessionType.night) {
      return const [Color(0xFF0D1B2A), Color(0xFF192A46), Color(0xFF304C78)];
    } else {
      return const [Color(0xFF87CEFA), Color(0xFFE6F3FF), Color(0xFFFFF2CC)];
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '$h시간 $m분째 수면 중';
  }

  Widget _card(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EBF0)),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _chipGroup<T>({
    required List<T> values,
    required T selected,
    required String Function(T) labelOf,
    required void Function(T) onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((v) {
        final sel = v == selected;
        return ChoiceChip(
          label: Text(labelOf(v)),
          selected: sel,
          onSelected: (_) => onSelected(v),
          shape: const StadiumBorder(),
          labelStyle: TextStyle(
            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }

  Widget _switchTile({
    required String title,
    required bool value,
    required void Function(bool) onChanged,
    String? subtitle,
  }) {
    return SwitchListTile.adaptive(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle == null ? null : Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  // ===== 입력 화면 =====
  Widget _buildInputScreen(BuildContext context, RoutineState state) {
    final tt = Theme.of(context).textTheme;
    final isNight = _sessionType == SleepSessionType.night;
    final bluetoothState = ref.watch(bluetoothDeviceProvider);

    return Stack(
      children: [
        // 배경
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _bgForSession(_sessionType),
            ),
          ),
        ),
        // 내용
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              const SizedBox(height: 12),
              // 헤더 문구 (AppBar 타이틀 제거하여 겹침 방지)
              Text(
                '오늘의 생활 루틴을 기록하고\n수면을 시작해요',
                style: tt.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isNight ? Colors.white : Colors.black,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 20),

              // 세션 종류
              const Label(text: '세션 종류'),
              const SizedBox(height: 10),
              _card(
                _chipGroup<SleepSessionType>(
                  values: const [SleepSessionType.night, SleepSessionType.nap],
                  selected: _sessionType,
                  labelOf: (t) => t == SleepSessionType.night ? '밤잠' : '낮잠',
                  onSelected: (t) => setState(() => _sessionType = t),
                ),
              ),

              const SizedBox(height: 20),

              // 수면 환경
              const Label(text: '수면 환경 점검'),
              const SizedBox(height: 10),
              _card(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _switchTile(
                      title: '양치',
                      value: _brushedTeeth,
                      onChanged: (v) => setState(() => _brushedTeeth = v),
                    ),
                    _switchTile(
                      title: '샤워',
                      value: _showered,
                      onChanged: (v) => setState(() => _showered = v),
                    ),
                    const SizedBox(height: 6),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Text(
                      '조명 상태',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _chipGroup<LightCondition>(
                      values: LightCondition.values,
                      selected: _light,
                      labelOf: (v) {
                        switch (v) {
                          case LightCondition.nightLight:
                            return '수면등';
                          case LightCondition.dark:
                            return '어둡게';
                          case LightCondition.dim:
                            return '희미한 조명';
                          case LightCondition.normal:
                            return '보통';
                          case LightCondition.bright:
                            return '밝게';
                        }
                      },
                      onSelected: (v) => setState(() => _light = v),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '소리 환경',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _chipGroup<SoundCondition>(
                      values: const [
                        SoundCondition.quiet,
                        SoundCondition.whiteNoise,
                        SoundCondition.noisy,
                      ],
                      selected: _sound,
                      labelOf: (v) {
                        switch (v) {
                          case SoundCondition.quiet:
                            return '조용';
                          case SoundCondition.whiteNoise:
                            return '백색소음';
                          case SoundCondition.noisy:
                            return '시끄러움';
                        }
                      },
                      onSelected: (v) => setState(() => _sound = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 체크리스트
              const Label(text: '수면 전 체크리스트'),
              const SizedBox(height: 10),
              _card(
                Column(
                  children: [
                    _switchTile(
                      title: '수분 섭취 조절',
                      value: _drinkWater,
                      onChanged: (v) => setState(() => _drinkWater = v),
                    ),
                    _switchTile(
                      title: '가벼운 스트레칭 및 호흡 운동',
                      value: _stretch,
                      onChanged: (v) => setState(() => _stretch = v),
                    ),
                    _switchTile(
                      title: '전자기기 시청 중단',
                      value: _screenOff,
                      onChanged: (v) => setState(() => _screenOff = v),
                    ),
                    _switchTile(
                      title: '잠들기 전 과식',
                      value: _overeating,
                      onChanged: (v) => setState(() => _overeating = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ▶ CTA 버튼: 고정 해제(리스트 하단에 배치, 스크롤로 접근)
              Builder(
                builder: (innerCtx) => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.isSaving
                        ? null
                        : () {
                            if (bluetoothState.connectedDevice == null) {
                              ScaffoldMessenger.of(innerCtx).showSnackBar(
                                const SnackBar(
                                  content: Text('수면 추적을 위해 먼저 기기를 연결해주세요.'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 1),
                                ),
                              );
                              context.push('/settings/device-connection');
                            } else {
                              () async {
                                final messenger = ScaffoldMessenger.of(
                                  innerCtx,
                                );
                                try {
                                  final controller = ref.read(
                                    routineControllerProvider.notifier,
                                  );
                                  controller.setRoutineBulk(
                                    drinkWater: _drinkWater,
                                    stretch: _stretch,
                                    screenOff: _screenOff,
                                    overeating: _overeating,
                                    brushedTeeth: _brushedTeeth,
                                    showered: _showered,
                                    light: _light,
                                    sound: _sound,
                                    sessionType: _sessionType,
                                  );
                                  await controller.saveRoutineAndStartSleep();
                                } catch (e) {
                                  if (!innerCtx.mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('오류: $e')),
                                  );
                                }
                              }();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.isSaving
                          ? const Color(0xFFCFD3DA)
                          : Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    child: state.isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('수면 기록 시작하기'),
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        ),
      ],
    );
  }

  // ===== 추적 중 화면 =====
  Widget _buildTrackingScreen(BuildContext context, RoutineState state) {
    final tt = Theme.of(context).textTheme;
    final isNight = state.sessionType == SleepSessionType.night;

    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _bgForSession(state.sessionType),
            ),
          ),
        ),
        SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(),
                  ScaleTransition(
                    scale: _pulseScale,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        isNight
                            ? Icons.nightlight_round
                            : Icons.wb_sunny_rounded,
                        size: 72,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    _formatDuration(state.elapsed),
                    style: tt.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isNight ? '깊은 밤, 편안한 호흡으로' : '포근한 낮잠, 천천히 충전 중',
                    style: tt.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
        // 추적 화면: 하단 CTA는 유지
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await ref
                      .read(routineControllerProvider.notifier)
                      .endSleepSession();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: const Text('수면 종료'),
              ),
            ),
          ),
        ),
        // 상단 타이틀은 유지 (추적 중엔 겹침 없음)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
            title: const Text('수면 추적 중'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(routineControllerProvider);
    if (state.isTracking) {
      return _buildTrackingScreen(context, state);
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _buildInputScreen(context, state),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sleepy/src/core/models/sleep_analysis.dart';

import 'package:sleepy/src/core/models/sleep_data.dart';
import 'package:sleepy/src/core/models/problematic_event.dart';
import 'package:sleepy/src/features/onboarding/presentation/widgets/label.dart';
import 'package:sleepy/src/features/logging/application/post_sleep_logging_controller.dart';
import 'package:sleepy/src/features/logging/presentation/widgets/utils.dart';
import 'package:sleepy/src/features/logging/presentation/widgets/condition_grid.dart';
import 'package:sleepy/src/features/logging/presentation/widgets/event_editor_list.dart';

class PostSleepLoggingScreen extends ConsumerStatefulWidget {
  const PostSleepLoggingScreen({super.key, required this.sleepDataId});
  final String sleepDataId;

  @override
  ConsumerState<PostSleepLoggingScreen> createState() =>
      _PostSleepLoggingScreenState();
}

class _PostSleepLoggingScreenState extends ConsumerState<PostSleepLoggingScreen>
    with SingleTickerProviderStateMixin {
  // --- 로컬 폼 상태(원샷 커밋용) ---
  MorningCondition _condition = MorningCondition.neutral;
  int _timeToFallAsleepMinutes = 0;
  List<AwakeTime?> _awakeningTimes = <AwakeTime?>[];
  List<ProblematicEvent> _events = <ProblematicEvent>[];

  // 메타(루틴 화면과 비주얼 연결)
  SleepSessionType _sessionType = SleepSessionType.night;
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now();

  bool _initializedForm = false;
  bool _condActivated = false;

  final _hhmm = DateFormat('HH:mm');

  // Quick chips for duration
  final List<int> _quickMinutes = const [5, 10, 15, 20];

  Future<void> _pickDuration(BuildContext context) async {
    // 현재 값을 H/M(5분 단위)로 분해
    int initH = (_timeToFallAsleepMinutes ~/ 60).clamp(0, 12);
    int initM = (_timeToFallAsleepMinutes % 60);
    initM = (initM / 5).round() * 5; // 5분 단위 스냅
    final hours = List<int>.generate(13, (i) => i); // 0~12시간
    final minutes = List<int>.generate(12, (i) => i * 5); // 0,5,...55

    int selH = initH;
    int selM = initM;

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SizedBox(
          height: 320,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '잠들기까지 소요 시간',
                style: Theme.of(
                  ctx,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: selH,
                        ),
                        itemExtent: 36,
                        onSelectedItemChanged: (i) => selH = hours[i],
                        children: hours
                            .map((h) => Center(child: Text('$h시간')))
                            .toList(),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: minutes.indexOf(selM),
                        ),
                        itemExtent: 36,
                        onSelectedItemChanged: (i) => selM = minutes[i],
                        children: minutes
                            .map((m) => Center(child: Text('$m분')))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final total = selH * 60 + selM;
                      setState(() => _timeToFallAsleepMinutes = total);
                      Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: const Text('적용'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmtHhmmFromMinutes(int total) {
    final h = total ~/ 60;
    final m = total % 60;
    if (h == 0) return '$m분';
    if (m == 0) return '$h시간';
    return '$h시간 $m분';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    final state = ref.watch(
      postSleepLoggingControllerProvider(widget.sleepDataId),
    );
    final controller = ref.read(
      postSleepLoggingControllerProvider(widget.sleepDataId).notifier,
    );

    return state.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('데이터 로딩 오류: $err')),
      ),
      data: (log) {
        // 컨트롤러 → 폼 초기화 (최초 1회)
        if (!_initializedForm) {
          _condition = log.condition;
          _timeToFallAsleepMinutes = log.timeToFallAsleepInMinutes;
          _awakeningTimes = List<AwakeTime?>.from(log.awakeTimes);
          _events = List<ProblematicEvent>.from(log.events);
          _sessionType = log.sessionType;
          _startTime = log.startTime;
          _endTime = log.endTime;
          _initializedForm = true;
        }

        final isNight = _sessionType == SleepSessionType.night;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // 배경 그라데이션
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: bgForSession(_sessionType),
                  ),
                ),
              ),

              // 콘텐츠
              SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: Icon(
                            Icons.arrow_back,
                            color: isNight ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 헤더 타이포
                    Text(
                      '오늘 하루도 힘내요!\n기상 후 기록을 남겨볼까요?',
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isNight ? Colors.white : Colors.black,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 섹션: 수면 구간(시작/종료) — 다이얼 피커
                    const Label(text: '수면 구간'),
                    const SizedBox(height: 8),
                    card(
                      Column(
                        children: [
                          _timeTile(
                            context: context,
                            icon: Icons.login_rounded,
                            label: '시작',
                            time: _startTime,
                            onPick: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(_startTime),
                                initialEntryMode: TimePickerEntryMode.dial,
                                helpText: '수면 시작 시각',
                              );
                              if (picked != null && context.mounted) {
                                setState(() {
                                  _startTime = DateTime(
                                    _startTime.year,
                                    _startTime.month,
                                    _startTime.day,
                                    picked.hour,
                                    picked.minute,
                                  );
                                  if (_endTime.isBefore(_startTime)) {
                                    _endTime = _startTime;
                                  }
                                });
                              }
                            },
                          ),
                          const Divider(height: 16),
                          _timeTile(
                            context: context,
                            icon: Icons.logout_rounded,
                            label: '종료',
                            time: _endTime,
                            onPick: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(_endTime),
                                initialEntryMode: TimePickerEntryMode.dial,
                                helpText: '수면 종료 시각',
                              );
                              if (picked != null && context.mounted) {
                                setState(() {
                                  _endTime = DateTime(
                                    _endTime.year,
                                    _endTime.month,
                                    _endTime.day,
                                    picked.hour,
                                    picked.minute,
                                  );
                                  if (_endTime.isBefore(_startTime)) {
                                    _endTime = _startTime;
                                  }
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 섹션: 아침 컨디션 (이모지 → 벡터 아이콘 카드)
                    const Label(text: '아침 컨디션'),
                    const SizedBox(height: 8),
                    card(
                      ConditionGrid(
                        value: _condition,
                        activated: _condActivated,
                        onChanged: (c) => setState(() {
                          _condition = c;
                          _condActivated = true;
                        }),
                        iconOf: condIcon,
                        colorOf: condColor,
                        labelOf: (c) => c.displayName,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 섹션: 잠들기까지 소요 시간 (퀵 칩 + 바텀시트 피커)
                    const Label(text: '잠들기까지 소요 시간'),
                    const SizedBox(height: 8),
                    card(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 예쁜 큰 수치 표기
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF101828,
                                  ).withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE8EBF0),
                                  ),
                                ),
                                child: Text(
                                  _fmtHhmmFromMinutes(_timeToFallAsleepMinutes),
                                  style: tt.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => _pickDuration(context),
                                icon: const Icon(Icons.timer_outlined),
                                label: const Text('설정'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _quickMinutes.map((m) {
                              final selected = _timeToFallAsleepMinutes == m;
                              return ChoiceChip(
                                label: Text(m == 0 ? '0' : '$m분'),
                                selected: selected,
                                onSelected: (_) => setState(
                                  () => _timeToFallAsleepMinutes = m,
                                ),
                                shape: const StadiumBorder(),
                                labelStyle: TextStyle(
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 섹션: 밤중에 깸
                    const Label(text: '밤중에 깸'),
                    const SizedBox(height: 8),
                    card(
                      Column(
                        children: [
                          if (_awakeningTimes.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('기록된 깨어남이 없습니다.'),
                            ),
                          ..._awakeningTimes.asMap().entries.map((entry) {
                            final i = entry.key;
                            final t = entry.value;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: const Icon(Icons.access_time_filled),
                                title: Text(
                                  t != null
                                      ? '${_hhmm.format(t.start)} – ${_hhmm.format(t.end)}'
                                      : '시간 미지정',
                                  style: tt.bodyLarge,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit_calendar_outlined,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                      onPressed: () => _editAwakeAt(i),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.remove_circle_outline,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                      onPressed: () => setState(
                                        () => _awakeningTimes.removeAt(i),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final idx = _awakeningTimes.length;
                                setState(() => _awakeningTimes.add(null));
                                WidgetsBinding.instance.addPostFrameCallback(
                                  (_) => _editAwakeAt(idx),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('깨어남 추가'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 섹션: 이상행동 (타입/시간/메모)
                    const Label(text: '이상행동'),
                    const SizedBox(height: 8),
                    card(
                      EventEditorList(
                        events: _events,
                        baseDate: _startTime,
                        onChanged: (list) => setState(() => _events = list),
                        hhmm: _hhmm,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ▶ 저장(원샷 커밋)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: log.isSaving
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                try {
                                  controller.setLogBulk(
                                    condition: _condition,
                                    timeToFallAsleepInMinutes:
                                        _timeToFallAsleepMinutes,
                                    awakeTimes: _awakeningTimes,
                                    events: _events,
                                    startTime: _startTime,
                                    endTime: _endTime,
                                  );
                                  await controller.saveLog(context);
                                } catch (e) {
                                  if (!context.mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('오류: $e')),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: log.isSaving
                              ? const Color(0xFFCFD3DA)
                              : Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        child: log.isSaving
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('기록 완료'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<AwakeTime?> _pickAwakeInterval({
    DateTime? initialStart,
    DateTime? initialEnd,
  }) async {
    // 베이스가 되는 전체 수면 시작 시각
    final base = _startTime;

    // --- 1. '깬 시각' 선택 ---
    final startTod = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialStart ?? base),
      initialEntryMode: TimePickerEntryMode.dial,
      helpText: '깬 시각',
    );
    if (startTod == null) return null;

    // 비동기 작업 후 위젯이 여전히 유효한지 확인
    if (!mounted) return null;

    // '깬 시각'의 날짜 계산:
    // 선택한 시간이 수면 시작 시간(base)보다 이전이면, 다음 날로 처리합니다.
    var start = DateTime(
      base.year,
      base.month,
      base.day,
      startTod.hour,
      startTod.minute,
    );
    if (start.isBefore(base)) {
      start = start.add(const Duration(days: 1));
    }

    // --- 2. '다시 잠든 시각' 선택 ---
    final defEnd = initialEnd ?? start.add(const Duration(minutes: 5));
    final endTod = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(defEnd),
      initialEntryMode: TimePickerEntryMode.dial,
      helpText: '다시 잠든 시각',
    );

    // 두 번째 비동기 작업 후 위젯 유효성 확인
    if (!mounted) return null;

    DateTime end;
    if (endTod == null) {
      // 사용자가 '다시 잠든 시각' 선택을 취소하면, 깬 시각과 동일하게 설정하여
      // 0분짜리 구간으로 처리합니다.
      end = start;
    } else {
      // '다시 잠든 시각'의 날짜 계산:
      // 먼저 '깬 시각(start)'과 같은 날짜로 설정합니다.
      end = DateTime(
        start.year,
        start.month,
        start.day,
        endTod.hour,
        endTod.minute,
      );
      // 만약 계산된 시간이 '깬 시각(start)'보다 이전이면, 다음 날로 처리합니다.
      if (end.isBefore(start)) {
        end = end.add(const Duration(days: 1));
      }
    }

    return AwakeTime(start: start, end: end);
  }

  // ② 호출부에서 BuildContext 인자 제거
  void _editAwakeAt(int index) async {
    final cur = _awakeningTimes[index];
    final picked = await _pickAwakeInterval(
      initialStart: cur?.start,
      initialEnd: cur?.end,
    );
    if (!mounted || picked == null) return;
    setState(() => _awakeningTimes[index] = picked);
  }

  /// 공용: 시간 선택 행
  Widget _timeTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required DateTime time,
    required VoidCallback onPick,
  }) {
    final tt = Theme.of(context).textTheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(
        label,
        style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(_hhmm.format(time)),
      trailing: TextButton.icon(
        onPressed: onPick,
        icon: const Icon(Icons.access_time),
        label: const Text('수정'),
      ),
    );
  }
}

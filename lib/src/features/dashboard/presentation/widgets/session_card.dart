import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sleepy/src/core/models/sleep_data.dart';
import 'package:go_router/go_router.dart';
import 'package:sleepy/src/core/models/child_profile.dart';

class SessionPalette {
  final Color cardBg;
  final Color badgeBg;
  final Color badgeFg;
  final Color ringBg;
  final Color ringFg;
  const SessionPalette({
    required this.cardBg,
    required this.badgeBg,
    required this.badgeFg,
    required this.ringBg,
    required this.ringFg,
  });
}

class SessionSection extends StatefulWidget {
  const SessionSection({
    super.key,
    required this.nightData,
    required this.napData,
    required this.profile,
    this.initialType = SleepSessionType.night,
    this.onEditNight,
    this.onDeleteNight,
    this.onEditNap,
    this.onDeleteNap,
  });

  final SleepData? nightData;
  final SleepData? napData;
  final ChildProfile profile;
  final SleepSessionType initialType;

  final VoidCallback? onEditNight;
  final VoidCallback? onDeleteNight;
  final VoidCallback? onEditNap;
  final VoidCallback? onDeleteNap;

  @override
  State<SessionSection> createState() => _SessionSectionState();
}

class _SessionSectionState extends State<SessionSection> {
  late SleepSessionType _tab = widget.initialType;

  // 팔레트: 밤/낮에 따라 자동 변경
  SessionPalette _paletteFor(SleepSessionType t) => t == SleepSessionType.night
      ? const SessionPalette(
          cardBg: Color(0xFFEEF2FF), // indigo-50
          badgeBg: Color(0xFF0F172A),
          badgeFg: Colors.white,
          ringBg: Color(0xFFC7D2FE), // indigo-300
          ringFg: Color(0xFF1E3A8A), // indigo-900
        )
      : const SessionPalette(
          cardBg: Color(0xFFFFFBEB), // amber-50
          badgeBg: Color(0xFFFFEDD5),
          badgeFg: Color(0xFF9A3412),
          ringBg: Color(0xFFFDE68A), // amber-300
          ringFg: Color(0xFFB45309), // orange-700
        );

  TimeOfDay _parseHHmm(String s) {
    final p = s.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  /// 목표 수면 시간
  int _goalNightMinutes(ChildProfile c) {
    final bed = _parseHHmm(widget.profile.goalBedTime);
    final wake = _parseHHmm(widget.profile.goalWakeUpTime);
    final bedMin = bed.hour * 60 + bed.minute;
    final wakeMin = wake.hour * 60 + wake.minute;
    return wakeMin <= bedMin
        ? (24 * 60 - bedMin) + wakeMin
        : (wakeMin - bedMin);
  }

  /// 적정 낮잠 시간 결정
  int _recommendedNapMinutes(DateTime birthDate) {
    int months =
        (DateTime.now().year - birthDate.year) * 12 +
        (DateTime.now().month - birthDate.month);
    if (DateTime.now().day < birthDate.day) months -= 1;

    months = months.clamp(0, 200);
    if (months <= 3) return 300;
    if (months <= 5) return 210;
    if (months <= 8) return 180;
    if (months <= 14) return 150;
    if (months <= 24) return 120;
    if (months <= 36) return 90;
    if (months <= 60) return 60;
    return 45;
  }

  String _fmtHm(DateTime t) => DateFormat('HH:mm').format(t);

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final palette = _paletteFor(_tab);

    // 현재 탭의 데이터/기준값 결정
    final bool isNight = _tab == SleepSessionType.night;
    final SleepData? data = isNight ? widget.nightData : widget.napData;
    final int maxMin = isNight
        ? _goalNightMinutes(widget.profile)
        : _recommendedNapMinutes(widget.profile.birthDate);

    // 시간/진행률 계산
    final dur = data == null
        ? Duration.zero
        : data.endTime.difference(data.startTime);
    final h = dur.inHours;
    final m = dur.inMinutes % 60;
    final totalMin = dur.inMinutes.clamp(0, maxMin);
    final ratio = maxMin == 0 ? 0.0 : (totalMin / maxMin).clamp(0.0, 1.0);

    final score = data?.sleepScore;
    final condition = data?.morningCondition;
    final bool canStart = data == null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: data == null
            ? null
            : () => context.go('/home/report', extra: (data, widget.profile)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            children: [
              // 상단: 좌측 토글(밤/낮) + 우측 편집/삭제(해당 탭 데이터 있을 때만)
              Row(
                children: [
                  _SmallToggle(
                    value: _tab,
                    onChanged: (t) => setState(() => _tab = t),
                    activeBg: palette.badgeBg,
                    activeFg: palette.badgeFg,
                  ),
                  const Spacer(),
                  if (data != null) ...[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: '수정',
                      onPressed: isNight
                          ? widget.onEditNight
                          : widget.onEditNap,
                      splashRadius: 20,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade300,
                      ),
                      tooltip: '삭제',
                      onPressed: isNight
                          ? widget.onDeleteNight
                          : widget.onDeleteNap,
                      splashRadius: 20,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // 링
              SizedBox(
                width: 280,
                height: 280,
                child: _RingGauge(
                  ratio: ratio,
                  bgColor: palette.ringBg,
                  fgColor: palette.ringFg,
                  stroke: 18,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '총 수면 시간',
                        style: tt.labelLarge?.copyWith(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data == null
                            ? '--시간 --분'
                            : '${h.toString().padLeft(2, '0')}시간 ${m.toString().padLeft(2, '0')}분',
                        style: tt.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _kv(
                            tt,
                            '수면 시작',
                            data == null ? '--:--' : _fmtHm(data.startTime),
                          ),
                          _kv(
                            tt,
                            '수면 종료',
                            data == null ? '--:--' : _fmtHm(data.endTime),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 지표(수면 점수 / 아침 컨디션)
              _Metrics(score: score, condition: condition),

              const SizedBox(height: 16),
              _StartSleepButton(
                enabled: canStart,
                palette: palette,
                onPressed: () => context.go('/routine'),
                tooltipWhenDisabled: isNight
                    ? '이미 밤 수면이 기록되어 있어요'
                    : '이미 낮잠이 기록되어 있어요',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(TextTheme tt, String k, String v) {
    return Column(
      children: [
        Text(k, style: tt.bodySmall?.copyWith(color: const Color(0xFF475467))),
        const SizedBox(height: 2),
        Text(v, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

/// 점수 + 아침 컨디션
class _Metrics extends StatelessWidget {
  const _Metrics({required this.score, required this.condition});

  final int? score; // null → '--'
  final MorningCondition? condition;

  Color _scoreColor(int s) {
    if (s >= 85) return const Color(0xFF16A34A);
    if (s >= 70) return const Color(0xFF22C55E);
    if (s >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  // 컨디션 팔레트(매우 나쁨=빨강)
  ({Color bg, Color border, Color active}) _conditionColors(
    MorningCondition? c,
  ) {
    switch (c) {
      case MorningCondition.veryBad:
        return (
          bg: const Color(0xFFFEE2E2),
          border: const Color(0xFFFECACA),
          active: const Color(0xFFEF4444),
        );
      case MorningCondition.bad:
        return (
          bg: const Color(0xFFFFEDD5),
          border: const Color(0xFFFED7AA),
          active: const Color(0xFFF97316),
        );
      case MorningCondition.neutral:
        return (
          bg: const Color(0xFFF3F4F6),
          border: const Color(0xFFE5E7EB),
          active: const Color(0xFF9CA3AF),
        );
      case MorningCondition.good:
        return (
          bg: const Color(0xFFECFDF5),
          border: const Color(0xFFA7F3D0),
          active: const Color(0xFF10B981),
        );
      case MorningCondition.veryGood:
        return (
          bg: const Color(0xFFDCFCE7),
          border: const Color(0xFFBBF7D0),
          active: const Color(0xFF22C55E),
        );
      default:
        return (
          bg: const Color(0xFFF3F4F6),
          border: const Color(0xFFE5E7EB),
          active: const Color(0xFF9CA3AF),
        );
    }
  }

  int _level(MorningCondition? c) {
    switch (c) {
      case MorningCondition.veryBad:
        return 1;
      case MorningCondition.bad:
        return 2;
      case MorningCondition.neutral:
        return 3;
      case MorningCondition.good:
        return 4;
      case MorningCondition.veryGood:
        return 5;
      default:
        return 0; // 데이터 없음
    }
  }

  String _label(MorningCondition? c) {
    return c?.displayName ?? '--';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final lvl = _level(condition);
    final col = _conditionColors(condition);
    final scoreStr = score?.toString() ?? '--';
    final condStr = _label(condition);

    return Row(
      children: [
        // 수면 점수
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '수면 점수: $scoreStr',
                  style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (score ?? 0).clamp(0, 100) / 100.0,
                    minHeight: 10,
                    color: _scoreColor(score ?? 0),
                    backgroundColor: const Color(0xFFE5E7EB),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // 아침 컨디션
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: col.bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: col.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '컨디션: $condStr',
                  style: tt.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: col.active,
                  ),
                ),
                const SizedBox(height: 8),
                _FiveBar(level: lvl, active: col.active),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 5단계 막대 인디케이터(색상 주입)
class _FiveBar extends StatelessWidget {
  const _FiveBar({required this.level, required this.active});
  final int level; // 0~5
  final Color active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final on = i < level;
        return Expanded(
          child: Container(
            height: 8,
            margin: EdgeInsets.only(right: i == 4 ? 0 : 4),
            decoration: BoxDecoration(
              color: on ? active : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        );
      }),
    );
  }
}

/// 링 게이지(색/두께 지정 가능)
class _RingGauge extends StatelessWidget {
  const _RingGauge({
    required this.ratio,
    required this.center,
    this.bgColor = const Color(0xFFBFD6FF),
    this.fgColor = const Color(0xFF0F1E57),
    this.stroke = 16,
  });

  final double ratio; // 0~1
  final Widget center;
  final Color bgColor;
  final Color fgColor;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RingPainter(
        ratio: ratio,
        bg: bgColor,
        fg: fgColor,
        stroke: stroke,
      ),
      child: Center(child: center),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.ratio,
    required this.bg,
    required this.fg,
    required this.stroke,
  });
  final double ratio;
  final Color bg;
  final Color fg;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - stroke) / 2;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = bg;

    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = fg;

    canvas.drawCircle(center, radius, bgPaint);
    final start = -90 * 3.14159265 / 180;
    final sweep = 2 * 3.14159265 * ratio;
    final rectArc = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rectArc, start, sweep, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.ratio != ratio ||
      old.bg != bg ||
      old.fg != fg ||
      old.stroke != stroke;
}

class _SmallToggle extends StatelessWidget {
  const _SmallToggle({
    required this.value,
    required this.onChanged,
    required this.activeBg,
    required this.activeFg,
  });

  final SleepSessionType value;
  final ValueChanged<SleepSessionType> onChanged;
  final Color activeBg;
  final Color activeFg;

  @override
  Widget build(BuildContext context) {
    Widget pill(String label, SleepSessionType t) {
      final bool selected = value == t;
      return Expanded(
        child: InkWell(
          onTap: () => onChanged(t),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? activeBg : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: selected ? activeFg : const Color(0xFF334155),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      width: 120,
      child: Row(
        children: [
          pill('밤', SleepSessionType.night),
          pill('낮', SleepSessionType.nap),
        ],
      ),
    );
  }
}

/// [수면 시작하기] 프라이머리 버튼.
/// [enabled]가 false면 회색 비활성 스타일로 표시하고, 툴팁을 제공.
/// 카드의 부모 InkWell로 탭 이벤트가 전파되지 않도록 비활성 시 AbsorbPointer로 감싼다.
class _StartSleepButton extends StatelessWidget {
  const _StartSleepButton({
    required this.enabled,
    required this.palette,
    required this.onPressed,
    this.tooltipWhenDisabled,
  });

  /// [enabled] 버튼 활성 여부(데이터 없음이면 true).
  final bool enabled;

  /// [palette] 현재 탭(밤/낮)에 따른 색상 팔레트.
  final SessionPalette palette;

  /// [onPressed] 활성 시 동작.
  final VoidCallback onPressed;

  /// [tooltipWhenDisabled] 비활성 시 노출되는 툴팁 메시지.
  final String? tooltipWhenDisabled;

  @override
  Widget build(BuildContext context) {
    final btn = SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: const Icon(Icons.bedtime_rounded),
        label: const Text('수면 시작하기'),
        style: ButtonStyle(
          padding: WidgetStatePropertyAll(
            const EdgeInsets.symmetric(vertical: 16),
          ),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          // 활성/비활성 배경색
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const Color(0xFFE5E7EB); // gray-200
            }
            return palette.badgeBg; // 팔레트 기반
          }),
          // 활성/비활성 전경색(텍스트/아이콘)
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const Color(0xFF9CA3AF); // gray-400
            }
            return palette.badgeFg; // 팔레트 기반
          }),
          // hover/pressed 오버레이: 링 배경색 톤을 은은히 더함
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed)) {
              return palette.ringBg.withValues(alpha: 0.24);
            }
            return Colors.transparent;
          }),
          elevation: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled) ? 0 : 1,
          ),
        ),
      ),
    );

    if (enabled) return btn;

    // 비활성 시: 툴팁 + AbsorbPointer로 상위 InkWell 전파 차단
    return Tooltip(
      message: tooltipWhenDisabled ?? '이미 기록이 있어요',
      waitDuration: const Duration(milliseconds: 300),
      child: AbsorbPointer(child: btn),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sleepy/src/core/models/child_profile.dart';
import 'package:sleepy/src/core/models/sleep_data.dart';
import 'package:sleepy/src/features/dashboard/application/dashboard_notifier.dart';
import 'package:sleepy/src/features/dashboard/presentation/widgets/session_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardNotifierProvider.notifier).refreshData();
    });
  }

  void _changeDate(int days) {
    final currentDate = ref.read(dashboardNotifierProvider).selectedDate;
    final newDate = currentDate.add(Duration(days: days));
    ref.read(dashboardNotifierProvider.notifier).changeDate(newDate);
  }

  String _fmtDay(DateTime d) => DateFormat('M월 d일 EEEE', 'ko_KR').format(d);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardNotifierProvider);
    final notifier = ref.read(dashboardNotifierProvider.notifier);
    final tt = Theme.of(context).textTheme;

    // 선택된 child
    final profiles =
        state.childProfiles.asData?.value ?? const <ChildProfile>[];
    final ChildProfile? selectedChild = profiles.isEmpty
        ? null
        : profiles.firstWhere(
            (p) => p.id == state.selectedChildId,
            orElse: () => profiles.first,
          );

    return Scaffold(
      appBar: AppBar(
        title: state.childProfiles.when(
          data: (profiles) {
            if (profiles.isEmpty) return const Text('아이를 추가해주세요.');
            return DropdownButton<String>(
              value: state.selectedChildId,
              onChanged: (String? newId) {
                if (newId != null) notifier.selectChild(newId);
              },
              items: profiles
                  .map<DropdownMenuItem<String>>(
                    (ChildProfile p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.lastName + p.firstName),
                    ),
                  )
                  .toList(),
              underline: const SizedBox.shrink(),
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              icon: const Icon(Icons.arrow_drop_down_rounded),
              isDense: true,
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (err, stack) => const Text('오류'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 날짜 네비게이터
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => _changeDate(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    _fmtDay(state.selectedDate),
                    style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => _changeDate(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 본문: 데이터 유무와 관계없이 두 섹션 항상 노출
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: state.sleepDataList.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, st) =>
                        Center(child: Text('오류: ${e.toString()}')),
                    data: (list) {
                      SleepData? night, nap;
                      for (final d in list) {
                        if (d.sessionType == SleepSessionType.night) {
                          night ??= d;
                        }
                        if (d.sessionType == SleepSessionType.nap) nap ??= d;
                      }

                      if (selectedChild == null) {
                        return const Center(child: Text('아이를 추가해주세요.'));
                      }

                      return ListView(
                        children: [
                          // 기존 두 개의 SessionSection → 하나로 교체
                          SessionSection(
                            initialType: SleepSessionType.night, // 기본 '밤'
                            profile: selectedChild, // 현재 선택된 아이 프로필
                            nightData: night, // 리스트에서 뽑은 밤잠 데이터
                            napData: nap, // 리스트에서 뽑은 낮잠 데이터
                            onEditNight: () async {
                              final id = night?.id;
                              if (id != null) {
                                await context.push('/logging/post-sleep/$id');
                                await ref
                                    .read(dashboardNotifierProvider.notifier)
                                    .refreshData();
                              }
                            },
                            onDeleteNight: () {
                              final id = night?.id;
                              if (id != null) {
                                ref
                                    .read(dashboardNotifierProvider.notifier)
                                    .deleteSleepData(id);
                              }
                            },
                            onEditNap: () async {
                              final id = nap?.id;
                              if (id != null) {
                                await context.push('/logging/post-sleep/$id');
                                await ref
                                    .read(dashboardNotifierProvider.notifier)
                                    .refreshData();
                              }
                            },
                            onDeleteNap: () {
                              final id = nap?.id;
                              if (id != null) {
                                ref
                                    .read(dashboardNotifierProvider.notifier)
                                    .deleteSleepData(id);
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sleepy/src/core/models/child_profile.dart';
import 'package:sleepy/src/core/models/sleep_data.dart';
import 'package:sleepy/src/core/services/auth_service.dart';
import 'package:sleepy/src/core/services/database_service.dart';
import 'package:sleepy/src/features/settings/presentation/profile_management_screen.dart';

class DashboardState extends Equatable {
  const DashboardState({
    required this.selectedDate,
    this.sleepDataList = const AsyncValue.loading(),
    this.childProfiles = const AsyncValue.loading(),
    this.selectedChildId,
  });

  final DateTime selectedDate;
  final AsyncValue<List<SleepData>> sleepDataList;
  final AsyncValue<List<ChildProfile>> childProfiles;
  final String? selectedChildId;

  DashboardState copyWith({
    DateTime? selectedDate,
    AsyncValue<List<SleepData>>? sleepDataList,
    AsyncValue<List<ChildProfile>>? childProfiles,
    String? selectedChildId,
    bool clearSelectedChildId = false,
  }) {
    return DashboardState(
      selectedDate: selectedDate ?? this.selectedDate,
      sleepDataList: sleepDataList ?? this.sleepDataList,
      childProfiles: childProfiles ?? this.childProfiles,
      selectedChildId: clearSelectedChildId
          ? null
          : (selectedChildId ?? this.selectedChildId),
    );
  }

  @override
  List<Object?> get props => [
    selectedDate,
    sleepDataList,
    childProfiles,
    selectedChildId,
  ];
}

final dashboardNotifierProvider =
    NotifierProvider<DashboardNotifier, DashboardState>(() {
      return DashboardNotifier();
    });

class DashboardNotifier extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    final profilesAsync = ref.watch(childProfilesProvider);
    final prev = stateOrNull;

    String? selectedId = prev?.selectedChildId;

    profilesAsync.whenData((profiles) {
      if (profiles.isEmpty) {
        selectedId = null;
      } else if (selectedId == null ||
          !profiles.any((p) => p.id == selectedId)) {
        selectedId = profiles.first.id;
      }
    });

    // 최초 빌드 시 한 번만 프리페치
    if (prev == null && selectedId != null) {
      Future.microtask(() => _fetchDataListForDate(DateTime.now(), selectedId));
    }

    return DashboardState(
      selectedDate: prev?.selectedDate ?? DateTime.now(),
      childProfiles: profilesAsync,
      selectedChildId: selectedId,
      sleepDataList: selectedId == null
          ? const AsyncLoading()
          : prev?.sleepDataList ?? const AsyncLoading(),
    );
  }

  Future<void> _fetchDataListForDate(DateTime date, String? childId) async {
    final user = ref.read(authStateChangesProvider).valueOrNull;
    if (user == null || childId == null) {
      state = state.copyWith(sleepDataList: const AsyncData(<SleepData>[]));
      return;
    }

    state = state.copyWith(sleepDataList: const AsyncLoading());

    final db = ref.read(databaseServiceProvider);
    try {
      final list = await db.getSleepDataListForDate(user.uid, childId, date);
      state = state.copyWith(sleepDataList: AsyncData(list));
    } catch (e, st) {
      state = state.copyWith(sleepDataList: AsyncError(e, st));
    }
  }

  Future<void> changeDate(DateTime newDate) async {
    state = state.copyWith(selectedDate: newDate);
    await _fetchDataListForDate(newDate, state.selectedChildId);
  }

  Future<void> selectChild(String childId) async {
    if (state.selectedChildId == childId) return;
    state = state.copyWith(
      selectedChildId: childId,
      sleepDataList: const AsyncLoading(),
    );
    await _fetchDataListForDate(state.selectedDate, childId);
  }

  Future<void> deleteSleepData(String sleepDataId) async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null || state.selectedChildId == null) {
      state = state.copyWith(sleepDataList: const AsyncData(<SleepData>[]));
      return;
    }
    final db = ref.read(databaseServiceProvider);
    try {
      await db.deleteSleepData(user.uid, state.selectedChildId!, sleepDataId);
      await _fetchDataListForDate(state.selectedDate, state.selectedChildId);
    } catch (e, st) {
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> updateMorningCondition(
    String sleepDataId,
    MorningCondition condition,
  ) async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null || state.selectedChildId == null) {
      state = state.copyWith(sleepDataList: const AsyncData(<SleepData>[]));
      return;
    }
    final db = ref.read(databaseServiceProvider);
    try {
      await db.updateSleepData(user.uid, state.selectedChildId!, sleepDataId, {
        'morningCondition': condition.name,
      });
      await _fetchDataListForDate(state.selectedDate, state.selectedChildId);
    } catch (e, st) {
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> refreshData() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      state = DashboardState(
        selectedDate: DateTime.now(),
        sleepDataList: const AsyncData(<SleepData>[]),
        childProfiles: const AsyncData(<ChildProfile>[]),
        selectedChildId: null,
      );
      return;
    }

    state = state.copyWith(childProfiles: const AsyncLoading());
    try {
      final profiles = await ref
          .read(databaseServiceProvider)
          .getChildProfiles(user.uid);
      state = state.copyWith(childProfiles: AsyncData(profiles));

      if (state.selectedChildId != null) {
        state = state.copyWith(sleepDataList: const AsyncLoading());
        await _fetchDataListForDate(state.selectedDate, state.selectedChildId);
      }
    } catch (e, st) {
      state = state.copyWith(childProfiles: AsyncError(e, st));
    }
  }
}

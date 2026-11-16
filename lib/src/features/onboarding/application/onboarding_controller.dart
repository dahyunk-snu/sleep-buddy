import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sleepy/src/core/models/child_profile.dart';
import 'package:sleepy/src/core/router/app_router.dart';
import 'package:sleepy/src/core/services/auth_service.dart';
import 'package:sleepy/src/core/services/database_service.dart';
import 'package:sleepy/src/features/onboarding/domain/onboarding_data.dart';
import 'package:sleepy/src/features/settings/presentation/profile_management_screen.dart';

part 'onboarding_controller.g.dart';

final _log = Logger('OnboardingController');

@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  OnboardingData build() {
    ref.keepAlive();
    // 컨트롤러가 처음 생성될 때의 초기 상태를 반환합니다.
    return const OnboardingData();
  }

  // 각 필드를 업데이트하는 메소드들
  void startEditing(ChildProfile p) {
    state = state.copyWith(
      profileId: p.id,
      childFirstName: p.firstName,
      childLastName: p.lastName,
      childGender: p.gender,
      childBirthDate: p.birthDate,
      activityLevel: p.activityLevel,
      avgBedTime: p.avgBedTime,
      avgWakeUpTime: p.avgWakeUpTime,
      timeToSleep: p.timeToSleep,
      sleepBehaviors: p.sleepBehaviors.toSet(),
      sleepConcerns: p.sleepConcerns.toSet(),
      goalBedTime: p.goalBedTime,
      goalWakeUpTime: p.goalWakeUpTime,
    );
  }

  bool get isEditing =>
      (state.profileId != null && state.profileId!.isNotEmpty);

  void startCreating() {
    state = const OnboardingData(); // 기본값으로 리셋
  }

  void updateChildFirstName(String firstName) {
    state = state.copyWith(childFirstName: firstName);
  }

  void updateChildLastName(String lastName) {
    state = state.copyWith(childLastName: lastName);
  }

  void updateChildGender(String gender) {
    state = state.copyWith(childGender: gender);
  }

  void updateChildBirthDate(DateTime date) {
    state = state.copyWith(childBirthDate: date);
  }

  void updateActivityLevel(String level) {
    state = state.copyWith(activityLevel: level);
  }

  void updateAvgBedtime(String time) {
    state = state.copyWith(avgBedTime: time);
  }

  void updateAvgWakeUpTime(String time) {
    state = state.copyWith(avgWakeUpTime: time);
  }

  void updateTimeToSleep(String time) {
    state = state.copyWith(timeToSleep: time);
  }

  /// 수면 중 행동을 한 번에 반영
  void updateSleepBehaviors(Set<String> behaviors) {
    state = state.copyWith(sleepBehaviors: behaviors);
  }

  /// 수면 우려 사항을 한 번에 반영
  void updateSleepConcerns(Set<String> concerns) {
    state = state.copyWith(sleepConcerns: concerns);
  }

  void updateGoalBedtime(String time) {
    state = state.copyWith(goalBedTime: time);
  }

  void updateGoalWakeUpTime(String time) {
    state = state.copyWith(goalWakeUpTime: time);
  }

  Future<void> saveOnboardingData() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      // 이 로직은 일반적으로 인증 상태에 따라 UI 접근이 제어되므로 실행되지 않아야 합니다.
      // 하지만 안전을 위해 방어 코드를 추가합니다.
      throw Exception('User not logged in. Cannot save onboarding data.');
    }

    // OnboardingData를 ChildProfile 객체로 변환합니다.
    final profile = ChildProfile(
      id: state.profileId ?? '', // ID는 DatabaseService에서 자동으로 생성합니다.
      firstName: state.childFirstName,
      lastName: state.childLastName,
      gender: state.childGender,
      birthDate: state.childBirthDate!, // 위에서 null 체크 완료
      activityLevel: state.activityLevel,
      avgBedTime: state.avgBedTime,
      avgWakeUpTime: state.avgWakeUpTime,
      timeToSleep: state.timeToSleep,
      sleepBehaviors: state.sleepBehaviors.toList(),
      sleepConcerns: state.sleepConcerns.toList(),
      goalBedTime: state.goalBedTime,
      goalWakeUpTime: state.goalWakeUpTime,
      latencyTimeinMinutes: 120,
    );

    try {
      // DatabaseService를 통해 변환된 프로필을 Firestore에 저장합니다.
      final dbService = ref.read(databaseServiceProvider);
      if (isEditing) {
        await dbService.updateChildProfile(user.uid, profile);
      } else {
        await dbService.addChildProfile(user.uid, profile);
      }
      ref.invalidate(childProfilesProvider);

      // 편집이면 프로필 목록으로, 신규면 홈으로
      if (isEditing) {
        ref.read(appRouterProvider).go('/settings');
        ref.read(appRouterProvider).push('/settings/profile');
      } else {
        ref.read(appRouterProvider).go('/home');
      }

      // 저장 후 상태 정리(선택)
      state = const OnboardingData();
    } catch (e, stackTrace) {
      // Firestore 저장 또는 라우팅 중 발생한 에러를 처리합니다.
      // UI 레이어에서 이 에러를 잡아 사용자에게 피드백을 제공해야 합니다.
      _log.severe('온보딩 데이터 저장 실패', e, stackTrace);
      rethrow; // 호출한 쪽에서 에러를 인지할 수 있도록 다시 던집니다.
    }
  }
}

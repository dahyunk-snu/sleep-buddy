import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sleepy/src/core/models/sleep_data.dart';
import 'package:sleepy/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:sleepy/src/features/logging/presentation/post_sleep_logging_screen.dart';
import 'package:sleepy/src/features/onboarding/presentation/login_screen.dart';
import 'package:sleepy/src/features/onboarding/presentation/screens/onboarding_step3_times.dart';
import 'package:sleepy/src/features/onboarding/presentation/screens/onboarding_step4_goals.dart';
import 'package:sleepy/src/features/onboarding/presentation/splash_screen.dart';
import 'package:sleepy/src/features/routine/presentation/routine_start_screen.dart';
import 'package:sleepy/src/features/settings/presentation/account_management_screen.dart';
import 'package:sleepy/src/features/settings/presentation/profile_management_screen.dart';
import 'package:sleepy/src/features/settings/presentation/settings_screen.dart';
import 'package:sleepy/src/features/report/presentation/daily_report_screen.dart';
import 'package:sleepy/src/features/report/presentation/weekly_report_screen.dart';
import 'package:sleepy/src/features/settings/presentation/developer_tools_screen.dart';
import 'package:sleepy/src/features/dream_friend/presentation/dream_friend_screen.dart';
import 'package:sleepy/src/features/settings/presentation/device_connection_screen.dart';
import 'package:sleepy/src/features/dream_friend/presentation/player_screen.dart';
import 'package:sleepy/src/features/dream_friend/presentation/dream_friend_edit_screen.dart';
import 'package:sleepy/src/features/dream_friend/domain/dream_friend.dart';
import 'package:sleepy/src/features/onboarding/presentation/welcome_screen.dart';
import 'package:sleepy/src/features/onboarding/presentation/screens/onboarding_step1_basic.dart';
import 'package:sleepy/src/features/onboarding/presentation/screens/onboarding_step2_habits.dart';
import 'package:sleepy/src/widgets/error_screen.dart';
import 'package:sleepy/src/widgets/main_scaffold.dart';
import 'package:sleepy/src/core/models/sleep_report.dart';
import 'package:sleepy/src/core/models/child_profile.dart';

/// [RoutePaths] 앱 내 경로 상수 모음
class RoutePaths {
  static const splash = '/splash';
  static const login = '/login';

  static const onboarding = '/onboarding';
  static const onboardingWelcome = '/onboarding/welcome';
  static const onboardingStep1 = '/onboarding/step1';
  static const onboardingStep2 = '/onboarding/step2';
  static const onboardingStep3 = '/onboarding/step3';
  static const onboardingStep4 = '/onboarding/step4';

  static const home = '/home';
  static const homeReport = 'report'; // 실제 경로: /home/report

  static const report = '/report';
  static const routine = '/routine';
  static const routineStart = '/routine/start';

  static const dreamFriend = '/dream-friend';
  static const dreamFriendEdit = '/dream-friend/edit';
  static const player = '/player';

  static const settings = '/settings';
  static const developerTools = 'developer-tools'; // /settings/developer-tools
  static const deviceConnection =
      'device-connection'; // /settings/device-connection

  static const postSleep = '/logging/post-sleep/:sleepDataId';
  static const settingsProfile = '/settings/profile';
  static const settingsAccount = '/settings/account';
}

/// [ _rootNavigatorKey ] 앱 최상위 네비게이터 키
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// [ _shellNavigatorKey ] 하단 탭(Shell) 네비게이터 키
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// [ _ntp ] NoTransitionPage 헬퍼(전환 애니 없음)
/// [child] 페이지 위젯
Page<void> _ntp(Widget child) => NoTransitionPage(child: child);

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.splash,
    navigatorKey: _rootNavigatorKey,
    errorBuilder: (context, state) =>
        ErrorScreen(message: state.error?.toString() ?? '페이지를 찾을 수 없습니다.'),
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        pageBuilder: (context, state) => _ntp(const SplashScreen()),
      ),
      GoRoute(
        path: RoutePaths.login,
        pageBuilder: (context, state) => _ntp(const LoginScreen()),
      ),
      // Onboarding 화면 라우팅
      GoRoute(
        path: '/onboarding',
        redirect: (context, state) => '/onboarding/welcome',
      ),

      /// [onboarding] 온보딩 루트
      GoRoute(
        path: RoutePaths.onboarding,
        redirect: (context, state) => RoutePaths.onboardingWelcome,
      ),
      GoRoute(
        path: RoutePaths.onboardingWelcome,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _ntp(const WelcomeScreen()),
      ),
      GoRoute(
        path: RoutePaths.onboardingStep1,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _ntp(const OnboardingStep1Basic()),
      ),
      GoRoute(
        path: RoutePaths.onboardingStep2,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _ntp(const OnboardingStep2Habits()),
      ),
      GoRoute(
        path: RoutePaths.onboardingStep3,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _ntp(const OnboardingStep3Times()),
      ),
      GoRoute(
        path: RoutePaths.onboardingStep4,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _ntp(const OnboardingStep4Goals()),
      ),

      /// [ShellRoute] 하단 탭 포함 메인 화면
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.home,
            pageBuilder: (context, state) => _ntp(const DashboardScreen()),
            routes: [
              /// [home/report] 일간 리포트
              GoRoute(
                path: 'report', //  경로: /home/report
                // root 네비게이터를 사용하여 전체 화면으로 표시 (하단 탭 숨김)
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  if (state.extra is! (SleepData, ChildProfile)) {
                    return const ErrorScreen(
                      message: '리포트를 표시할 데이터가 올바르지 않습니다.',
                    );
                  }
                  final (sleepData, child) =
                      state.extra as (SleepData, ChildProfile);
                  final dailyReportData = DailyReportData.fromSleepData(
                    sleepData,
                  );
                  return DailyReportScreen(
                    child: child,
                    report: dailyReportData,
                  );
                },
              ),
            ],
          ),

          /// [report] 주간 리포트 탭
          GoRoute(
            path: RoutePaths.report,
            pageBuilder: (context, state) => _ntp(const WeeklyReportScreen()),
          ),

          /// [routine] 루틴 탭
          GoRoute(
            path: RoutePaths.routine,
            pageBuilder: (context, state) => _ntp(const RoutineStartScreen()),
          ),

          /// [dream-friend] 꿈친구 탭
          GoRoute(
            path: RoutePaths.dreamFriend,
            pageBuilder: (context, state) => _ntp(const DreamFriendScreen()),
          ),

          /// [settings] 설정 탭
          GoRoute(
            path: RoutePaths.settings,
            pageBuilder: (context, state) => _ntp(const SettingsScreen()),
            routes: [
              /// [settings/developer-tools] 개발자 도구 (디버그 빌드에서만 등록)
              if (kDebugMode)
                GoRoute(
                  path: RoutePaths.developerTools,
                  parentNavigatorKey: _rootNavigatorKey,
                  pageBuilder: (context, state) =>
                      _ntp(const DeveloperToolsScreen()),
                ),

              /// [settings/device-connection] 디바이스 연결
              GoRoute(
                path: RoutePaths.deviceConnection,
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) =>
                    _ntp(const DeviceConnectionScreen()),
              ),
            ],
          ),
        ],
      ),

      /// [routine/start] 수면 기록 시작
      GoRoute(
        path: RoutePaths.routineStart,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _ntp(const RoutineStartScreen()),
      ),

      /// [post-sleep] 기상 후 수면 기록
      GoRoute(
        path: RoutePaths.postSleep,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final sleepDataId = state.pathParameters['sleepDataId'];
          if (sleepDataId == null || sleepDataId.isEmpty) {
            return const ErrorScreen(message: '잘못된 접근입니다: 수면 데이터 ID가 없습니다.');
          }
          return PostSleepLoggingScreen(sleepDataId: sleepDataId);
        },
      ),

      /// [settings/profile] 아동 프로필 관리
      GoRoute(
        path: RoutePaths.settingsProfile,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _ntp(const ProfileManagementScreen()),
      ),

      /// [settings/account] 보호자 계정 관리
      GoRoute(
        path: RoutePaths.settingsAccount,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _ntp(const AccountManagementScreen()),
      ),

      /// [player] 재생 플레이어
      GoRoute(
        path: RoutePaths.player,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => _ntp(const PlayerScreen()),
      ),

      /// [dream-friend/edit] 꿈친구 편집
      GoRoute(
        path: RoutePaths.dreamFriendEdit,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          if (extra != null && extra is! DreamFriend) {
            return const ErrorScreen(
              message: '잘못된 접근입니다: DreamFriend 데이터가 올바르지 않습니다.',
            );
          }
          return DreamFriendEditScreen(friend: extra as DreamFriend?);
        },
      ),
    ],
  );
});

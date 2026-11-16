import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sleepy/src/core/services/auth_service.dart';
import 'package:sleepy/src/core/services/database_service.dart';
import 'package:sleepy/src/widgets/primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 배경 그라데이션 + 은은한 장식
          const _Background(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  // 앱 아이콘 (원형 카드)
                  Center(
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white10, width: 1),
                        boxShadow: const [
                          BoxShadow(blurRadius: 24, color: Colors.black26),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.bedtime_outlined,
                          size: 52,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 타이틀/서브타이틀
                  Text(
                    '매일밤 찾아오는 내 아이의 친구,\nZzz:Sleep Buddy',
                    textAlign: TextAlign.center,
                    style: tt.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '아이의 수면을 빠르게 기록하고,\nAI로 쉽게 분석해요.',
                    textAlign: TextAlign.center,
                    style: tt.bodyLarge?.copyWith(
                      color: Colors.white70,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 포인트 배지 3개 (요약 카드 느낌)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      _Badge(text: '수면 기록'),
                      SizedBox(width: 8),
                      _Badge(text: '권장 비교'),
                      SizedBox(width: 8),
                      _Badge(text: '습관 코칭'),
                    ],
                  ),

                  const Spacer(),

                  // 로그인 카드
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '시작해볼까요?',
                          style: tt.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Google 계정으로 간편하게 로그인할 수 있어요.',
                          style: tt.bodyMedium?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 14),
                        PrimaryButton(
                          text: _loading ? '진행 중…' : 'Google 계정으로 시작하기',
                          onPressed: _loading
                              ? null
                              : () async {
                                  final router = GoRouter.of(context);
                                  setState(() => _loading = true);
                                  try {
                                    final authService = ref.read(
                                      authServiceProvider,
                                    );
                                    final dbService = ref.read(
                                      databaseServiceProvider,
                                    );
                                    final user = await authService
                                        .signInWithGoogle();

                                    if (user == null || !mounted) return;
                                    final hasCompletedOnboarding =
                                        await dbService.hasChildProfiles(
                                          user.uid,
                                        );
                                    if (!mounted) return;

                                    if (hasCompletedOnboarding) {
                                      router.go('/home');
                                    } else {
                                      await dbService.createNewUser(user);
                                      if (!mounted) return;
                                      router.go('/onboarding');
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _loading = false);
                                    }
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 로딩 오버레이(버튼 비활성화와 별개로 살짝 어둡게)
          if (_loading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

// ── 보조 위젯들 ─────────────────────────────────────────────────────────────

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 그라데이션
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0B1220), // 상단 딥 네이비
                Color(0xFF111827), // 중간
                Color(0xFF0F172A), // 하단 살짝 어둡게
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF374151), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

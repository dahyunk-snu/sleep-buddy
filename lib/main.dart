import 'package:firebase_core/firebase_core.dart'; // Firebase Initialize
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Flutter UI Widget
import 'package:flutter_localizations/flutter_localizations.dart'; // Localizations
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod
import 'package:intl/date_symbol_data_local.dart'; // Date/Time Format
import 'package:logging/logging.dart';
import 'package:sleepy/firebase_options.dart'; // Firebase Options
import 'package:sleepy/src/core/router/app_router.dart'; // GoRouter Routing Setting
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void _setupLogging() {
  Logger.root.level = Level.ALL; // 모든 레벨의 로그를 수신
  Logger.root.onRecord.listen((record) {
    // 디버그 모드일 때만 콘솔에 출력
    if (kDebugMode) {
      debugPrint(
        '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}',
      );
      if (record.error != null) {
        debugPrint('  Error: ${record.error}');
      }
      if (record.stackTrace != null) {
        debugPrint('  Stack trace: ${record.stackTrace}');
      }
    }
  });
}

void main() async {
  // 1. Initialize the Firebase Engine
  WidgetsFlutterBinding.ensureInitialized();
  // await dotenv.load(fileName: ".env");
  // BLE(FBP) 로그 억제: warning 이상만
  FlutterBluePlus.setLogLevel(LogLevel.warning, color: false);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Initialize the intl package
  await initializeDateFormatting();

  // 로깅 설정
  _setupLogging();

  // 3. Use Riverpod to supervise all states in the app
  runApp(const ProviderScope(child: MyApp()));
}

// ROOT WIDGET
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. appRouterProvider: 앱 전역의 라우팅 설정을 가져옴
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: "Zzz",
      theme: ThemeData(
        fontFamily: 'LeeSeoyun',
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white, // App background is white
        primaryColor: const Color(0xFF4A90E2), // Soft blue
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black54),
          titleLarge: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(color: Colors.black87),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90E2),
          brightness: Brightness.light,
          primary: const Color(0xFF4A90E2),
          secondary: const Color(0xFF50E3C2),
          surface: Colors.white, // Background for components like Cards
          onSurface: const Color(
            0xFF333333,
          ), // Text/icons on top of surface color
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF4A90E2)),
          titleTextStyle: TextStyle(
            color: Color(0xFF333333),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        useMaterial3: true,
      ),
      // 2. 다국어 지원을 위한 로케일 설정
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate, // Material 위젯용
        GlobalWidgetsLocalizations.delegate, // 일반 위젯용
        GlobalCupertinoLocalizations.delegate, // Cupertino(iOS 스타일) 위젯용
      ],
      supportedLocales: const [
        Locale('ko', 'KR'), // 한국어 지원
        Locale('en', 'US'), // 영어 지원
      ],
      locale: const Locale('ko', 'KR'), // 앱의 기본 언어를 한국어로 설정
      // 3. 라우팅 설정 적용
      routerConfig: router,
    );
  }
}

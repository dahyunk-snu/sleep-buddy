import 'package:equatable/equatable.dart';

/// [LightCondition] 조명 상태
enum LightCondition { nightLight, dark, dim, normal, bright }

/// [SoundCondition] 소리 환경
enum SoundCondition { quiet, whiteNoise, noisy }

/// [SleepEnvironment] 수면 환경 점검(양치/샤워/조명/소리)
/// [brushedTeeth] 양치 여부
/// [showered] 샤워 여부
/// [light] 조명 상태
/// [sound] 소리 환경
class SleepEnvironment extends Equatable {
  final bool brushedTeeth;
  final bool showered;
  final LightCondition light;
  final SoundCondition sound;

  const SleepEnvironment({
    this.brushedTeeth = false,
    this.showered = false,
    this.light = LightCondition.dark,
    this.sound = SoundCondition.quiet,
  });

  /// [copyWith] 불변 복사
  /// [brushedTeeth] 변경할 양치 여부
  /// [showered] 변경할 샤워 여부
  /// [light] 변경할 조명 상태
  /// [sound] 변경할 소리 환경
  SleepEnvironment copyWith({
    bool? brushedTeeth,
    bool? showered,
    LightCondition? light,
    SoundCondition? sound,
  }) {
    return SleepEnvironment(
      brushedTeeth: brushedTeeth ?? this.brushedTeeth,
      showered: showered ?? this.showered,
      light: light ?? this.light,
      sound: sound ?? this.sound,
    );
  }

  /// [SleepEnvironment.fromJson] Firestore/JSON 맵 → 모델(안전 파싱)
  /// [json] 원본 맵
  factory SleepEnvironment.fromJson(Map<String, dynamic> json) {
    return SleepEnvironment(
      brushedTeeth: (json['brushedTeeth'] as bool?) ?? false,
      showered: (json['showered'] as bool?) ?? false,
      light: _parseLight(json['light'] as String?),
      sound: _parseSound(json['sound'] as String?),
    );
  }

  /// [SleepEnvironment.toJson] 모델 → Firestore/JSON 맵
  Map<String, dynamic> toJson() {
    return {
      'brushedTeeth': brushedTeeth,
      'showered': showered,
      'light': light.name,
      'sound': sound.name,
    };
  }

  /// [_parseLight] 문자열 → [LightCondition] (실패 시 dark)
  /// [v] 원본 문자열
  static LightCondition _parseLight(String? v) {
    if (v == null || v.isEmpty) return LightCondition.dark;
    return LightCondition.values.firstWhere(
      (e) => e.name == v,
      orElse: () => LightCondition.dark,
    );
  }

  /// [_parseSound] 문자열 → [SoundCondition] (실패 시 quiet)
  /// [v] 원본 문자열
  static SoundCondition _parseSound(String? v) {
    if (v == null || v.isEmpty) return SoundCondition.quiet;
    return SoundCondition.values.firstWhere(
      (e) => e.name == v,
      orElse: () => SoundCondition.quiet,
    );
  }

  @override
  List<Object?> get props => [brushedTeeth, showered, light, sound];
}

/// [SleepRoutine] 수면 전 체크리스트
/// [drinkWater] 수분 섭취 조절
/// [sleepEnv] 수면 환경(양치/샤워/조명/소리)
/// [stretch] 가벼운 스트레칭/호흡
/// [screenOff] 전자기기 시청 중단
/// [overeating] 잠들기 전 과식
class SleepRoutine extends Equatable {
  final bool drinkWater;
  final SleepEnvironment sleepEnv;
  final bool stretch;
  final bool screenOff;
  final bool overeating;

  const SleepRoutine({
    this.drinkWater = false,
    this.sleepEnv = const SleepEnvironment(),
    this.stretch = false,
    this.screenOff = false,
    this.overeating = false,
  });

  /// [copyWith] 불변 복사
  /// [drinkWater] 변경할 수분 섭취
  /// [sleepEnv] 변경할 수면 환경
  /// [stretch] 변경할 스트레칭
  /// [screenOff] 변경할 화면 중단
  /// [overeating] 변경할 과식
  SleepRoutine copyWith({
    bool? drinkWater,
    SleepEnvironment? sleepEnv,
    bool? stretch,
    bool? screenOff,
    bool? overeating,
  }) {
    return SleepRoutine(
      drinkWater: drinkWater ?? this.drinkWater,
      sleepEnv: sleepEnv ?? this.sleepEnv,
      stretch: stretch ?? this.stretch,
      screenOff: screenOff ?? this.screenOff,
      overeating: overeating ?? this.overeating,
    );
  }

  /// [SleepRoutine.fromJson] Firestore/JSON 맵 → 모델(스키마 호환)
  /// [json] 원본 맵
  factory SleepRoutine.fromJson(Map<String, dynamic> json) {
    bool drinkWater = (json['drinkWater'] as bool?) ?? false;
    bool stretch = (json['stretch'] as bool?) ?? false;
    bool screenOff = (json['screenOff'] as bool?) ?? false;
    bool overeating = (json['overeating'] as bool?) ?? false;

    final envMap = json['environment'] as Map<String, dynamic>?;
    SleepEnvironment env = envMap != null
        ? SleepEnvironment.fromJson(envMap)
        : SleepEnvironment();

    return SleepRoutine(
      drinkWater: drinkWater,
      sleepEnv: env,
      stretch: stretch,
      screenOff: screenOff,
      overeating: overeating,
    );
  }

  /// [toJson] 모델 → Firestore/JSON 맵
  Map<String, dynamic> toJson() => {
    'drinkWater': drinkWater,
    'environment': sleepEnv.toJson(),
    'stretch': stretch,
    'screenOff': screenOff,
    'overeating': overeating,
  };

  @override
  List<Object?> get props => [
    drinkWater,
    sleepEnv,
    stretch,
    screenOff,
    overeating,
  ];
}

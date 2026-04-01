import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/mandala_state.dart';
import 'providers/mandala_providers.dart';
import 'services/context_service.dart';
import 'screens/login_screen.dart';
import 'screens/age_select_screen.dart';
import 'screens/character_select_screen.dart';
import 'screens/player_home_screen.dart';
import 'screens/parent_dashboard_screen.dart';

// [DEBUG] 0=login, 1=ageSelect, 2=player(stage4), 3=player(stage8), 4=parent-dashboard
const int kDebugMode = 0;

void main() {
  // デバッグ用: 天気・時間帯オーバーライド（本番は null）
  // ContextService.debugWeatherOverride = WeatherHint.rainy;
  // ContextService.debugTimeOverride = DayTimeSlot.night;

  runApp(ProviderScope(
    overrides: kDebugMode >= 2
        ? [
            mandalaProvider.overrideWith(
              (ref) => MandalaNotifier(ref.read(audioMixerProvider))
                ..setAge(AgeMode.age5)
                ..debugSetStage(kDebugMode == 3 || kDebugMode == 4 ? 8 : 4),
            ),
          ]
        : [],
    child: const MandalaAlphaApp(),
  ));
}

class MandalaAlphaApp extends StatelessWidget {
  const MandalaAlphaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'マンダラα',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFFFB74D),
        useMaterial3: true,
        fontFamily: 'HiraginoMaruGothic',
        fontFamilyFallback: const ['Hiragino Maru Gothic ProN', 'HiraginoSans', 'Rounded Mplus 1c'],
      ),
      home: switch (kDebugMode) {
        4    => const ParentDashboardScreen(),
        >= 2 => const PlayerHomeScreen(),
        1    => const CharacterSelectScreen(),
        _    => const LoginScreen(),
      },
    );
  }
}

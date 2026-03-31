import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/mandala_providers.dart';
import 'screens/login_screen.dart';
import 'screens/resonance_screen.dart';

// [DEBUG] 0=login, 1=resonance(locked), 2=resonance(stage4), 3=resonance(stage8)
const int kDebugMode = 0; // 0=本番(login), 1=resonance, 2=stage4, 3=stage8

void main() {
  runApp(ProviderScope(
    overrides: kDebugMode >= 2
        ? [
            mandalaProvider.overrideWith(
              (ref) => MandalaNotifier(ref.read(audioMixerProvider))
                ..debugSetStage(kDebugMode == 3 ? 8 : 4),
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
        colorSchemeSeed: const Color(0xFF7C4DFF),
        useMaterial3: true,
        fontFamily: 'HiraginoSans',
      ),
      home: kDebugMode >= 1 ? const ResonanceScreen() : const LoginScreen(),
    );
  }
}

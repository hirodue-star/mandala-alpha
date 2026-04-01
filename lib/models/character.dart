// ─────────────────────────────────────────────────────────
// Character — マルチキャラクター定義
// ─────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

enum CharacterId { puppy, gaogao }

class CharacterDef {
  final CharacterId id;
  final String name;
  final String emoji;
  final String desc;
  final Color primaryColor;
  final Color accentColor;
  final List<Color> bgGradient;
  final List<StageTheme> stageThemes;
  final String particleEmoji;

  const CharacterDef({
    required this.id, required this.name, required this.emoji, required this.desc,
    required this.primaryColor, required this.accentColor, required this.bgGradient,
    required this.stageThemes, required this.particleEmoji,
  });
}

class StageTheme {
  final String name;
  final String emoji;
  final Color topColor;
  final Color bottomColor;
  const StageTheme(this.name, this.emoji, this.topColor, this.bottomColor);
}

// ── プピィ（うさぎ） ─────────────────────────────────────

const puppyDef = CharacterDef(
  id: CharacterId.puppy,
  name: 'プピィ',
  emoji: '🐰',
  desc: 'やさしい うさぎの おともだち',
  primaryColor: Color(0xFFFFB3DE),
  accentColor: Color(0xFFFFB74D),
  bgGradient: [Color(0xFFFFF8E7), Color(0xFFFFF0D0)],
  particleEmoji: '✨',
  stageThemes: [
    StageTheme('おへや',        '🏠', Color(0xFFFFF8E7), Color(0xFFFFF0D0)),
    StageTheme('にじのもり',    '🌈', Color(0xFFE8F5E9), Color(0xFFB9F6CA)),
    StageTheme('ほしぞらのうみ','🌊', Color(0xFFE3F2FD), Color(0xFFBBDEFB)),
    StageTheme('おかしのくに',  '🍭', Color(0xFFFFF0F5), Color(0xFFFFE0EC)),
    StageTheme('くものうえ',    '☁️', Color(0xFFE8EAF6), Color(0xFFC5CAE9)),
    StageTheme('おかしのうちゅう','🍩', Color(0xFF1A0A3D), Color(0xFF0A0520)),
  ],
);

// ── ガオガオ（恐竜） ─────────────────────────────────────

const gaogaoDef = CharacterDef(
  id: CharacterId.gaogao,
  name: 'ガオガオ',
  emoji: '🦕',
  desc: 'つよくて やさしい きょうりゅう',
  primaryColor: Color(0xFF81C784),
  accentColor: Color(0xFFFF8A65),
  bgGradient: [Color(0xFFF1F8E9), Color(0xFFDCEDC8)],
  particleEmoji: '🔥',
  stageThemes: [
    StageTheme('きょうりゅうのす', '🥚', Color(0xFFF1F8E9), Color(0xFFDCEDC8)),
    StageTheme('かざんのしま',    '🌋', Color(0xFFFFF3E0), Color(0xFFFFCC80)),
    StageTheme('ジャングル',      '🌴', Color(0xFFE8F5E9), Color(0xFF66BB6A)),
    StageTheme('ほねのどうくつ',  '🦴', Color(0xFFECEFF1), Color(0xFFB0BEC5)),
    StageTheme('そらのおうこく',  '⚡', Color(0xFFE3F2FD), Color(0xFF64B5F6)),
    StageTheme('うちゅうたんけん','☄️', Color(0xFF1A237E), Color(0xFF0D0D33)),
  ],
);

const allCharacters = [puppyDef, gaogaoDef];

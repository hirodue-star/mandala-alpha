// ─────────────────────────────────────────────────────────
// ContextService — 環境コンテキスト取得＋挨拶生成
//
// ソース: OS時刻/日付/季節 + 親入力トピック
// 外部ニュースAPI不使用（メンテコスト最小）
// ─────────────────────────────────────────────────────────

class EnvironmentContext {
  final DateTime now;
  final DayTimeSlot timeSlot;
  final Season season;
  final WeatherHint weather;
  final String? seasonalEvent;   // 七夕・クリスマスなど
  final String? parentTopic;     // 親が入力したトピック

  const EnvironmentContext({
    required this.now,
    required this.timeSlot,
    required this.season,
    required this.weather,
    this.seasonalEvent,
    this.parentTopic,
  });
}

enum DayTimeSlot { morning, daytime, evening, night }
enum Season { spring, summer, autumn, winter }
enum WeatherHint { sunny, cloudy, rainy, snowy }

class ContextService {
  // デバッグ用オーバーライド
  static DayTimeSlot? debugTimeOverride;
  static WeatherHint? debugWeatherOverride;

  static EnvironmentContext getContext({String? parentTopic}) {
    final now = DateTime.now();
    return EnvironmentContext(
      now: now,
      timeSlot: debugTimeOverride ?? _timeSlot(now),
      season: _season(now),
      weather: debugWeatherOverride ?? _guessWeather(now),
      seasonalEvent: _seasonalEvent(now),
      parentTopic: parentTopic,
    );
  }

  static DayTimeSlot _timeSlot(DateTime dt) {
    final h = dt.hour;
    if (h < 6)  return DayTimeSlot.night;
    if (h < 11) return DayTimeSlot.morning;
    if (h < 17) return DayTimeSlot.daytime;
    if (h < 21) return DayTimeSlot.evening;
    return DayTimeSlot.night;
  }

  static Season _season(DateTime dt) {
    return switch (dt.month) {
      3 || 4 || 5    => Season.spring,
      6 || 7 || 8    => Season.summer,
      9 || 10 || 11  => Season.autumn,
      _              => Season.winter,
    };
  }

  // 天気推測（API不使用：季節＋月から確率的に推定）
  static WeatherHint _guessWeather(DateTime dt) {
    if (dt.month == 6 || dt.month == 7 && dt.day < 20) return WeatherHint.rainy;  // 梅雨
    if (dt.month == 1 || dt.month == 2) return WeatherHint.snowy;
    return WeatherHint.sunny;
  }

  // 日本の季節行事
  static String? _seasonalEvent(DateTime dt) {
    final md = dt.month * 100 + dt.day;
    // 行事前5日以内
    if (_inRange(md, 101, 107)) return 'おしょうがつ';
    if (_inRange(md, 201, 204)) return 'せつぶん';
    if (_inRange(md, 301, 304)) return 'ひなまつり';
    if (_inRange(md, 501, 506)) return 'こどものひ';
    if (_inRange(md, 701, 708)) return 'たなばた';
    if (_inRange(md, 1028, 1101)) return 'ハロウィン';
    if (_inRange(md, 1220, 1226)) return 'クリスマス';
    if (_inRange(md, 1230, 1232)) return 'おおみそか';
    return null;
  }

  static bool _inRange(int md, int start, int end) => md >= start && md <= end;

  // ─── 挨拶テンプレート生成 ──────────────────────────────

  static String generateGreeting(EnvironmentContext ctx) {
    final parts = <String>[];

    // 時間帯挨拶
    parts.add(switch (ctx.timeSlot) {
      DayTimeSlot.morning  => 'おはよう！',
      DayTimeSlot.daytime  => 'こんにちは！',
      DayTimeSlot.evening  => 'おつかれさま！',
      DayTimeSlot.night    => 'おやすみまえの じかんだね',
    });

    // 天気コメント
    parts.add(switch (ctx.weather) {
      WeatherHint.sunny  => 'きょうは いいおてんき☀️',
      WeatherHint.cloudy => 'くもりだけど げんきにいこう！',
      WeatherHint.rainy  => 'あめの ひだね☔ おうちで たのしもう！',
      WeatherHint.snowy  => 'ゆきだ⛄ さむいけど わくわく！',
    });

    // 季節行事
    if (ctx.seasonalEvent != null) {
      parts.add('もうすぐ ${ctx.seasonalEvent}だね！');
    }

    // 親入力トピック（最優先で末尾に）
    if (ctx.parentTopic != null && ctx.parentTopic!.isNotEmpty) {
      parts.add('きょうは「${ctx.parentTopic}」だって！ たのしみだね！');
    }

    return parts.join(' ');
  }

  // ─── LLM用プロンプト生成（Claude API連携用） ────────────

  static String buildSafePrompt(EnvironmentContext ctx) {
    return '''
あなたは3〜5歳の幼児に話しかける、やさしいキャラクター「プピィ」です。
以下の環境情報を元に、ポジティブで知的好奇心を刺激する挨拶を1文（30文字以内）で生成してください。

時間帯: ${ctx.timeSlot.name}
季節: ${ctx.season.name}
天気: ${ctx.weather.name}
${ctx.seasonalEvent != null ? '近い行事: ${ctx.seasonalEvent}' : ''}
${ctx.parentTopic != null ? '今日のトピック: ${ctx.parentTopic}' : ''}

ルール:
- ひらがなのみ使用（カタカナは固有名詞のみ可）
- 否定的な表現は禁止
- 恐怖・暴力・悲しみに関する言葉は禁止
- 疑問形で好奇心を促すこと
''';
  }
}

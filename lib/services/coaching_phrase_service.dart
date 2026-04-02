// ─────────────────────────────────────────────────────────
// CoachingPhraseService — インスタント・コーチング
//
// 子供の回答に対して、親がそのまま読み上げるだけでOKな
// 3秒声かけフレーズを生成。AI不使用・全ローカル辞書。
// ─────────────────────────────────────────────────────────

class CoachingPhrase {
  final String phrase;       // 読み上げフレーズ
  final String emoji;
  final String category;     // 褒め/共感/深掘り

  const CoachingPhrase(this.phrase, this.emoji, this.category);
}

class CoachingPhraseService {
  CoachingPhraseService._();

  /// 子供の回答からコーチングフレーズを生成
  static CoachingPhrase generate(String childAnswer, {String? goal}) {
    if (childAnswer.isEmpty) return _defaultPhrase;

    // 感情系の回答
    if (_emotionWords.any((w) => childAnswer.contains(w))) {
      return _emotionPhrase(childAnswer);
    }
    // 食べ物系
    if (_foodWords.any((w) => childAnswer.contains(w))) {
      return CoachingPhrase(
        '「$childAnswer」がすきなんだね！どんな あじが すき？',
        '🍽️', '深掘り',
      );
    }
    // 動物系
    if (_animalWords.any((w) => childAnswer.contains(w))) {
      return CoachingPhrase(
        '「$childAnswer」をよく しってるね！どこで みたの？',
        '🐾', '深掘り',
      );
    }
    // 色系
    if (_colorWords.any((w) => childAnswer.contains(w))) {
      return CoachingPhrase(
        'いい いろだね！「$childAnswer」の ものを もっと さがしてみよう！',
        '🎨', '褒め',
      );
    }

    // 汎用: 回答の長さで分岐
    if (childAnswer.length >= 5) {
      return CoachingPhrase(
        'たくさん かんがえたね！「$childAnswer」って すてきだね！',
        '⭐', '褒め',
      );
    }
    if (goal != null && goal.isNotEmpty) {
      return CoachingPhrase(
        '「$childAnswer」は「$goal」と どう つながるかな？',
        '🔗', '深掘り',
      );
    }
    return CoachingPhrase(
      '「$childAnswer」！いいね！もっと おしえて！',
      '💪', '共感',
    );
  }

  /// 1日分のキラリ語録を生成
  static List<String> dailyHighlights(List<String> answers) {
    return answers
        .where((a) => a.isNotEmpty && a.length >= 2)
        .take(3)
        .map((a) => '「$a」')
        .toList();
  }

  /// 成長ニュース要約テキスト（音声読み上げ用）
  static String growthNewsSummary({
    required String charName,
    required List<String> goals,
    required List<String> answers,
    required int sessionCount,
  }) {
    final highlights = dailyHighlights(answers);
    final buf = StringBuffer();
    buf.writeln('きょうの せいちょう ニュース！');
    buf.writeln('${charName}と いっしょに ${sessionCount}かい チャレンジしました。');
    if (goals.isNotEmpty) {
      buf.writeln('テーマは「${goals.first}」。');
    }
    if (highlights.isNotEmpty) {
      buf.writeln('キラリ語録: ${highlights.join("、")}');
    }
    buf.writeln('あしたも がんばろうね！');
    return buf.toString();
  }

  static CoachingPhrase _emotionPhrase(String answer) {
    if (answer.contains('うれしい') || answer.contains('たのしい')) {
      return CoachingPhrase('$answerって きもち、すてきだね！なにが いちばん $answerかな？', '😊', '共感');
    }
    if (answer.contains('かなしい') || answer.contains('こわい')) {
      return CoachingPhrase('そうだったんだね。よく おしえてくれたね。えらいよ。', '🤗', '共感');
    }
    if (answer.contains('びっくり')) {
      return CoachingPhrase('びっくりしたんだ！なにに いちばん びっくりした？', '😲', '深掘り');
    }
    return CoachingPhrase('きもちを ことばにできて すごいね！', '💖', '褒め');
  }

  static const _defaultPhrase = CoachingPhrase('がんばってるね！すごいよ！', '👏', '褒め');

  static const _emotionWords = [
    'うれしい', 'かなしい', 'たのしい', 'こわい', 'びっくり', 'おこった', 'だいすき',
  ];
  static const _foodWords = [
    'りんご', 'バナナ', 'アイス', 'ケーキ', 'おにぎり', 'カレー', 'ラーメン',
    'みかん', 'いちご', 'パン', 'おすし', 'ピザ', 'チョコ',
  ];
  static const _animalWords = [
    'いぬ', 'ねこ', 'うさぎ', 'くま', 'ぞう', 'ライオン', 'きりん', 'ペンギン',
    'さかな', 'ちょうちょ', 'カブトムシ', 'かえる',
  ];
  static const _colorWords = [
    'あか', 'あお', 'きいろ', 'みどり', 'ピンク', 'むらさき', 'オレンジ', 'しろ', 'くろ',
  ];
}

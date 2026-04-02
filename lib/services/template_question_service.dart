import 'image_analysis_service.dart';

// ─────────────────────────────────────────────────────────
// TemplateQuestionService — テンプレート駆動型設問
//
// AI動的生成を最小化。画像タグ（色・形状・明暗）から
// 定義済み設問セットを呼び出す。
// ─────────────────────────────────────────────────────────

class TemplateQuestion {
  final String emoji;
  final String question;
  final List<String> choices; // 選択肢（空なら自由記述）

  const TemplateQuestion(this.emoji, this.question, [this.choices = const []]);
}

class TemplateQuestionService {
  TemplateQuestionService._();

  /// 画像タグから設問セットを生成（AI不要）
  static List<TemplateQuestion> fromTag(ImageTag tag) {
    final questions = <TemplateQuestion>[];

    // 1. 色ベースの設問
    questions.add(_colorQuestion(tag.dominantColor, tag.colorEmoji));

    // 2. 形状ベースの設問
    questions.add(_shapeQuestion(tag.estimatedShape));

    // 3. 明るさベースの設問
    questions.add(_brightnessQuestion(tag.brightness));

    // 4. 組み合わせ設問（色×形）
    questions.add(_comboQuestion(tag.dominantColor, tag.estimatedShape));

    // 5. メタ認知設問（共通）
    questions.add(const TemplateQuestion(
      '🧠', 'この えを みて どんな きもちに なった？',
      ['うれしい', 'かなしい', 'びっくり', 'たのしい', 'ふしぎ'],
    ));

    // 6. 創造設問（共通）
    questions.add(const TemplateQuestion(
      '✨', 'この えに なまえを つけるとしたら？',
    ));

    return questions;
  }

  // ── 色ベース設問 ─────────────────────────────────────────

  static TemplateQuestion _colorQuestion(String color, String emoji) {
    final colorQuestions = <String, TemplateQuestion>{
      'あか': TemplateQuestion(emoji, 'あかい ものを 3つ おもいだそう！',
          ['りんご', 'トマト', 'しょうぼうしゃ', 'いちご', 'ポスト']),
      'あお': TemplateQuestion(emoji, 'あおい ものを 3つ おもいだそう！',
          ['うみ', 'そら', 'あじさい', 'ドラえもん', 'くじら']),
      'きいろ': TemplateQuestion(emoji, 'きいろい ものを 3つ おもいだそう！',
          ['バナナ', 'レモン', 'ひまわり', 'おほしさま', 'ひよこ']),
      'みどり': TemplateQuestion(emoji, 'みどりの ものを 3つ おもいだそう！',
          ['はっぱ', 'カエル', 'きゅうり', 'メロン', 'しんごう']),
      'オレンジ': TemplateQuestion(emoji, 'オレンジいろの ものを 3つ おもいだそう！',
          ['みかん', 'にんじん', 'ゆうやけ', 'かぼちゃ', 'きつね']),
      'ピンク': TemplateQuestion(emoji, 'ピンクの ものを 3つ おもいだそう！',
          ['さくら', 'フラミンゴ', 'もも', 'リボン', 'わたあめ']),
      'むらさき': TemplateQuestion(emoji, 'むらさきの ものを 3つ おもいだそう！',
          ['ぶどう', 'ラベンダー', 'なす', 'あじさい', 'あめじすと']),
      'しろ': TemplateQuestion(emoji, 'しろい ものを 3つ おもいだそう！',
          ['くも', 'ゆき', 'うさぎ', 'ぎゅうにゅう', 'おこめ']),
      'くろ': TemplateQuestion(emoji, 'くろい ものを 3つ おもいだそう！',
          ['カラス', 'よるのそら', 'ピアノのけんばん', 'タイヤ', 'くつ']),
    };
    return colorQuestions[color] ??
        TemplateQuestion(emoji, 'この いろと おなじ ものは なに？',
            ['おはな', 'むし', 'どうぶつ', 'たべもの', 'のりもの']);
  }

  // ── 形状ベース設問 ───────────────────────────────────────

  static TemplateQuestion _shapeQuestion(String shape) {
    return switch (shape) {
      'まる' => const TemplateQuestion('⭕', 'まるい ものを さがしてみよう！',
          ['ボール', 'おつきさま', 'とけい', 'ドーナツ', 'コイン']),
      'しかく' => const TemplateQuestion('🔷', 'しかくい ものを さがしてみよう！',
          ['ほん', 'まど', 'テレビ', 'チョコレート', 'ビル']),
      'ながい' => const TemplateQuestion('📏', 'ながい ものを さがしてみよう！',
          ['えんぴつ', 'でんしゃ', 'ヘビ', 'かわ', 'はし']),
      _ => const TemplateQuestion('🔍', 'どんな かたちに みえる？',
          ['まる', 'さんかく', 'しかく', 'ほし', 'ハート']),
    };
  }

  // ── 明るさベース設問 ─────────────────────────────────────

  static TemplateQuestion _brightnessQuestion(String brightness) {
    return switch (brightness) {
      'あかるい' => const TemplateQuestion('☀️', 'あかるい ばしょは どこ？',
          ['こうえん', 'うみ', 'おへや', 'おそと', 'おみせ']),
      'くらい' => const TemplateQuestion('🌙', 'くらい ときは なにする？',
          ['ねる', 'えほんよむ', 'おほしさまみる', 'おふろ', 'ゆめみる']),
      _ => const TemplateQuestion('🌤️', 'いま おそとは どんな てんき？',
          ['はれ', 'くもり', 'あめ', 'ゆき', 'かぜ']),
    };
  }

  // ── 組み合わせ設問 ───────────────────────────────────────

  static TemplateQuestion _comboQuestion(String color, String shape) {
    if (color == 'あか' && shape == 'まる') {
      return const TemplateQuestion('🍎', 'あかくて まるい たべものは？',
          ['りんご', 'トマト', 'いちご', 'さくらんぼ']);
    }
    if (color == 'きいろ' && shape == 'まる') {
      return const TemplateQuestion('🌻', 'きいろくて まるい ものは？',
          ['おひさま', 'ひまわり', 'レモン', 'ボール']);
    }
    if (color == 'あお' && shape == 'ながい') {
      return const TemplateQuestion('🌊', 'あおくて ながい ものは？',
          ['かわ', 'うみ', 'そら', 'でんしゃ']);
    }
    return TemplateQuestion('🎨', '$color で $shape のものは なに？');
  }
}

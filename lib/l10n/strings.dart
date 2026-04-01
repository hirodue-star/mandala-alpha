// ─────────────────────────────────────────────────────────
// AppStrings — 全テキスト一元管理（i18n 準備層）
//
// 使い方: AppStrings.current.XXX でアクセス。
// 将来は _En / _Zh 等を追加し、
// InheritedWidget または flutter_localizations に移行する。
// ─────────────────────────────────────────────────────────

// ignore_for_file: prefer_single_quotes

abstract base class AppStringsBase {
  const AppStringsBase();
  // ── アプリ共通 ──────────────────────────────────────────
  String get appName;
  String get appTagline;

  // ── ログイン画面 ────────────────────────────────────────
  String get loginEmail;
  String get loginPassword;
  String get loginButton;
  String get loginOr;
  String get loginApple;
  String get loginGoogle;

  // ── プレイヤー画面（子供向け） ───────────────────────────
  String get characterName;
  String get hintLocked;
  String get hintStart;
  String hintProgress(int n);
  String hintAlmost(int rem);
  String get hintAllDone;
  String get hintHatching;
  String get hintHatched;
  String get goalDialogTitleFirst;
  String get goalDialogTitleEdit;
  String get goalDialogHint;
  String get goalDialogConfirmFirst;
  String get goalDialogConfirmEdit;
  String get cellDialogTitle;
  String goalSubtitle(String g);
  String get cellDialogHint;
  String get cellDialogConfirm;
  String get cellDialogReset;
  String get hatchedTitle;
  String goalLabel(String g);
  String get hatchedRestart;
  String progressLabel(int n);
  String get puppyBornLabel;

  // ── 保護者ゲート ────────────────────────────────────────
  String get gateTitle;
  String get gateHoldInstruct;
  String get gateHoldParent;
  String get gateHoldKeeping;
  String get gateHoldPressMe;
  String get gateHoldSuccess;
  String get gateSwitchToMath;
  String get gateSwitchToHold;
  String get gateMathParent;
  String get gateMathInstruct;
  String get gateMathHint;
  String get gateMathConfirm;
  String get gateMathWrong;

  // ── 保護者ダッシュボード ─────────────────────────────────
  String get dashTitle;
  String get methodName;
  String get methodSubtitle;
  String get todayGoal;
  String get metricsTitle;
  String get metricsEmpty;
  String get metricsAnalyzed;
  String get metaLabel;
  String get metaDesc;
  String get focusLabel;
  String get focusDesc;
  String get logicLabel;
  String get logicDesc;
  String logCount(int n);
  String get logCustomTag;
  String logTime(int m, int s);
  String get evidenceTitle;
  String get evidenceBody;
  List<({String title, String body})> get evidenceItems;
  List<String> get radarLabels;
}

// ── 日本語 ────────────────────────────────────────────────

final class _Ja extends AppStringsBase {
  const _Ja() : super();

  @override String get appName        => 'マンダラα';
  @override String get appTagline     => 'こどもの力を育てる 曼荼羅チャート';

  @override String get loginEmail     => 'メールアドレス';
  @override String get loginPassword  => 'パスワード';
  @override String get loginButton    => 'ログイン';
  @override String get loginOr        => 'または';
  @override String get loginApple     => 'Appleでログイン';
  @override String get loginGoogle    => 'Googleでログイン';

  @override String get characterName  => 'プピィ';
  @override String get hintLocked     => '🥚 まんなかをタップして「ゆめ」をきめよう！';
  @override String get hintStart      => '🎵 マスをタップしてやることをかこう！';
  @override String hintProgress(int n)  => '💪 ${n}つ できたね！もっとやろう！';
  @override String hintAlmost(int rem)  => '✨ すごい！あと $rem マスで たまごがかえる！';
  @override String get hintAllDone    => '🏆 ぜんぶできた！たまごが かえるよ…！';
  @override String get hintHatching   => '🌟 プピィが うまれてくる…！';
  @override String get hintHatched    => '🐥 プピィが うまれたよ！';

  @override String get goalDialogTitleFirst => 'きょうの「ゆめ」をおしえて！';
  @override String get goalDialogTitleEdit  => 'ゆめをかえる';
  @override String get goalDialogHint       => 'れい：ピアノが ひけるようになる';
  @override String get goalDialogConfirmFirst => 'はじめる！🐣';
  @override String get goalDialogConfirmEdit  => 'かえる';

  @override String get cellDialogTitle    => 'やることを かこう！';
  @override String goalSubtitle(String g) => 'ゆめ: $g';
  @override String get cellDialogHint     => 'ゆめにむかって やること';
  @override String get cellDialogConfirm  => 'できた！♪';
  @override String get cellDialogReset    => 'もどす';

  @override String get hatchedTitle       => 'プピィが うまれたよ！';
  @override String goalLabel(String g)    => 'ゆめ: $g';
  @override String get hatchedRestart     => 'もういちど！';
  @override String progressLabel(int n)   => '⭐ $n / 8';
  @override String get puppyBornLabel     => 'プピィ たんじょう！';

  @override String get gateTitle          => '保護者確認';
  @override String get gateHoldInstruct   => 'ボタンを3秒間\n長押ししてください';
  @override String get gateHoldParent     => '保護者の方へ';
  @override String get gateHoldKeeping    => 'そのまま押し続けて…';
  @override String get gateHoldPressMe    => '押し続けてください';
  @override String get gateHoldSuccess    => '認証できました！';
  @override String get gateSwitchToMath   => '計算で確認する';
  @override String get gateSwitchToHold   => '長押しで確認する';
  @override String get gateMathParent     => '保護者の方へ';
  @override String get gateMathInstruct   => '答えを入力してください';
  @override String get gateMathHint       => '答えを入力';
  @override String get gateMathConfirm    => '確認する';
  @override String get gateMathWrong      => 'ちがいます。もう一度。';

  @override String get dashTitle          => '保護者ダッシュボード';
  @override String get methodName         => 'Nine Matrix Method™';
  @override String get methodSubtitle     => '9マス思考メソッド — 幼児向け最適化版';
  @override String get todayGoal          => '今日のゴール';
  @override String get metricsTitle       => '🧠 能力指標';
  @override String get metricsEmpty       => 'マスを完了するとグラフが表示されます';
  @override String get metricsAnalyzed    => '今日の取り組みから分析しました';
  @override String get metaLabel          => '🔍 メタ認知（自己客観視）';
  @override String get metaDesc           => 'アクションを自分の言葉で表現する力';
  @override String get focusLabel         => '⚡ 集中力';
  @override String get focusDesc          => '継続して取り組む持続力';
  @override String get logicLabel         => '🔗 論理的思考';
  @override String get logicDesc          => '系統的に物事を進める力';
  @override String logCount(int n)        => '📝 取り組み記録 ($n/8)';
  @override String get logCustomTag       => '自分の言葉';
  @override String logTime(int m, int s)  => '${m}分${s}秒';
  @override String get evidenceTitle      => '📖 Nine Matrix Method™ とは';
  @override String get evidenceBody       =>
      '大谷翔平選手も高校時代に活用したことで知られる「9マス思考メソッド」を、'
      '幼児教育の認知発達研究に基づき3〜6歳向けに最適化したプログラムです。'
      '\n一生モノの地頭を育む科学的アプローチです。';

  @override
  List<({String title, String body})> get evidenceItems => [
    (
      title: '🔍 メタ認知能力',
      body:  'Flavell (1979) による研究で、自己の思考を客観視する力が学習効果を最大40%向上させると報告されています。',
    ),
    (
      title: '⚡ 実行機能の発達',
      body:  'Diamond (2013) の研究では、3〜6歳における目標志向的活動が前頭前野の発達を促すことが示されています。',
    ),
    (
      title: '🔗 構造化思考',
      body:  '9マスのフレームワークが、ゴール分解能力と論理的思考の基礎を幼児期に形成します。',
    ),
  ];

  @override
  List<String> get radarLabels => ['メタ認知', '集中力', '論理的思考'];
}

// ── 公開エントリポイント ───────────────────────────────────

class AppStrings {
  const AppStrings._();

  static const AppStringsBase current = _Ja();
}

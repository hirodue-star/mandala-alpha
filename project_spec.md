# マンダラα — プロジェクト仕様書

## アプリ概要
- 対象：3〜6歳児 + 保護者
- コンセプト：私立小学校受験を見据えた曼荼羅チャート育児アプリ
- 収益モデル：月額サブスクリプション（RevenueCat）

---

## Firebase コレクション設計

### users（保護者アカウント）
```
users/{userId}
  - email: string
  - plan: "free" | "premium"
  - createdAt: timestamp
```

### children（子供プロフィール）
```
users/{userId}/children/{childId}
  - name: string
  - birthDate: timestamp
  - avatarUrl: string
  - createdAt: timestamp
```

### charts（曼荼羅チャート）
```
users/{userId}/children/{childId}/charts/{chartId}
  - theme: string          // 中央テーマ（例：「じぶん」）
  - weekOf: timestamp      // その週の開始日
  - cells: map[8]          // 8マスの記録
    - category: string     // カテゴリ名
    - status: "empty" | "trying" | "done"
    - voiceMemo: string    // 音声テキスト（OpenAI変換後）
    - completedAt: timestamp
  - createdAt: timestamp
```

### reports（親向けレポート）
```
users/{userId}/children/{childId}/reports/{reportId}
  - weekOf: timestamp
  - summary: string        // Claude生成テキスト
  - scores: map            // 非認知能力スコア
    - selfControl: number
    - communication: number
    - persistence: number
    - creativity: number
  - generatedAt: timestamp
```

---

## 曼荼羅の8カテゴリ（MVP版）

| マス | カテゴリ | アイコン | 非認知能力との対応 |
|------|---------|---------|------------------|
| 上   | あいさつ | 👋 | コミュニケーション |
| 右上 | おきがえ | 👕 | 自律性 |
| 右   | たいそう | 🤸 | 身体・忍耐力 |
| 右下 | おてつだい | 🧹 | 協調性 |
| 下   | えほん   | 📚 | 言語・知的好奇心 |
| 左下 | かずあそび | 🔢 | 論理思考 |
| 左   | おえかき  | 🎨 | 創造性 |
| 左上 | きもちメモ | 💬 | 自己表現 |

中央：「きょうのじぶん」（その日の主役テーマ）

---

## FlutterFlow 画面構成

### Screen 1: SplashScreen
- アプリロゴ + 「マンダラα」ロゴタイプ
- 認証チェック → Home or Login へ遷移

### Screen 2: LoginScreen
- メールログイン / Apple Sign-In / Google Sign-In
- 初回 → OnboardingScreen へ

### Screen 3: OnboardingScreen（3ステップ）
- 子供の名前・生年月日入力
- アバター選択（動物キャラ5種）
- プラン選択画面（無料 / プレミアム）

### Screen 4: HomeScreen（曼荼羅チャート）★メイン
- 中央に大きな「今週のテーマ」ボタン
- 周囲8マス：タップで InputScreen へ
- 右上：親用ダッシュボードボタン
- 完了マスは金色に光る演出

### Screen 5: InputScreen（子供用）
- 大きなマイクボタン（タップで録音）
- 録音後 → OpenAI Whisper でテキスト変換
- 「できた！」アニメーション（星が飛ぶ）

### Screen 6: DashboardScreen（保護者用）
- ペアレンタルゲート（「3×4は？」）
- 今週の達成率グラフ
- Claude生成レポート表示
- 過去レポート履歴

---

## Claude API プロンプト（レポート生成）

```
system: あなたは私立小学校受験の専門家であり、
        幼児教育カウンセラーです。

user: 以下は{child_name}（{age}歳）の今週の曼荼羅チャート記録です。
      {chart_data}

      以下の形式でレポートを生成してください：
      1. 今週のがんばりポイント（具体的に・褒める表現で）
      2. 伸びている非認知能力（上位2つ）
      3. 来週取り組むとよいこと（1つだけ）
      4. 受験に向けた成長コメント（保護者へ）

      ※文体は「〜ですね」「〜しましょう」の丁寧語。
      ※子供を主語にした温かい表現で。
```

---

## MVP スコープ（1ヶ月）

- [x] プロジェクト名・設計確定
- [x] Flutter：4画面（Home / Input / Dashboard / Login）
- [ ] Firebase：collections設定・Auth連携
- [x] OpenAI Whisper：音声→テキスト（WhisperService）
- [x] Claude API：週次レポート生成（ClaudeService）
- [ ] RevenueCat：月額課金導線
- [x] ペアレンタルゲート実装

# ENGINEERING_ROADMAP: プロ級へ詰めるための導線

Status: **planning / active roadmap**
Date: 2026-06-26

この文書は、`bqn-ledger` を「生活会計の数字を預けられる秤」として
プロ級に詰めるために **可能かつやる価値のある項目** を列挙する。

それぞれに「なぜやるか」「どこから始めるか」「何を変えるか」を示す。
いずれも既存のアーキテクチャ（Posting IR → Cube → TBDS → ViewModel → Format）を
壊さずに追加できる。

---

## 1. 動的勘定科目空間 (Dynamic Account Space) ✅ 完了 (2026-06-26)

### 結果

`src_next/` は既に `≠accounts` による動的勘定科目空間へ完全移行済みだった。
`256` リテラルは `src_next/` 内にゼロ。`cube.Materialize` は `ak_count` パラメータを受け取り、すべての配列確保が動的。

残作業として以下を実施:
- `docs/ARCHITECTURE.md` の「256スロットの勘定空間」→「動的勘定科目空間」に更新
- `docs/CANONICAL_DAILY_CUBE.md` の Account 軸説明を更新
- `docs/CONVENTIONS.md` の256上限記述を削除

### やったこと（コードは変更不要）

1. `src_next/loader.bqn` で `≠accounts` を返す → 既存（`account_key.bqn` の `Resolve.count`）
2. `src_next/cube.bqn` の `Materialize`、空 cube 生成で `≠accounts` を使う → 既存
3. `src_next/tbds.bqn` 以下の集計も動的サイズに対応 → 既存
4. `256` リテラルを `src_next/` から完全除去 → 既存（ゼロ件）
5. fixture / golden output が変わらないことを確認 → `src_next/` golden check は既存の動的出力を使用
6. `docs/ARCHITECTURE.md` の256スロット節を更新 → 完了

---

## 2. 取消・修正UI (Journal Reversal in Go Editor) ✅ 完了 (2026-06-26)

### 結果

`journal reverse` サブコマンドを Go editor に追加。
`tools/add-ui.sh` に reverse モード追加。

### やったこと

1. ✅ `editor/journal.go` に `runJournalReverse` 関数追加
   - `--id <txn_id>` または `--index <number>` で対象指定
   - from/to を入れ替え、memo に `[reverse]` プレフィックス
   - 通常の safe append フローで追記
   - `--date` で日付指定可（デフォルト: today）
   - `--yes` で確認スキップ可
2. ✅ `editor/main.go` に `journal reverse` サブコマンド追加
3. ✅ テスト追加（8 tests）:
   - ByIndex, ByID, DuplicateIDError, NotFoundError, InvalidIndexError,
   - PreservesMetadata, UsesTodayWhenNoDate, SameFromToError
4. ✅ `tools/add-ui.sh` に reverse モード追加
   - journal.tsv の一覧を fzf で選択
   - 日付指定（デフォルト: today）
   - Go editor 経由で安全追記

---

## 3. TUI (Terminal UI)

### なぜやるか

今の `tools/main-ui.sh`（fzf でセクション切り替え）は動くが、
section → detail → action の導線がバラバラ。

TUI で「レポートを見る → 気になる数字を深掘り → 仕訳を追加する」を
一画面で完結させたい。

### 導線

- 現状: `tools/main-ui.sh` — fzf セクションセレクタ（今回高速化済み）
- 現状: `tools/add-ui.sh` — 対話式入力（今回修正済み）
- 設計: `docs/APPLICATION_FOUNDATION.md` — TUI/GUI 外装の境界契約
- 設計: `docs/COMMAND_HUB_DESIGN.md` — 単一エントリポイントの設計メモ
- 候補: `libvaxis` (Zig) — `docs/APPLICATION_FOUNDATION.md` で本命候補

### やること

#### Phase A: 設計確定

1. `docs/TUI_DESIGN.md` を作成
   - 画面構成（レポート表示 / セクション一覧 / アクションパネル）
   - BQN との境界（計算は BQN、表示は TUI）
   - キーバインド
2. Zig libvaxis の PoC（`src_next/report.bqn` の出力をパースして表示）

#### Phase B: 最小実装

1. レポートセクション一覧 + 選択表示
2. `tools/edit journal add` を TUI から呼び出す導線
3. `tools/add-ui.sh` 相当の対話フローを TUI に内蔵

#### Phase C: 仕上げ

1. 日次トレンドのグラフ表示（libvaxis の canvas/widget）
2. 封筒残高のカラー警告

### 難易度: 中〜高（新規コードだが責務境界は明確）

### 注意

TUI は BQN の計算責務を奪わない。`src_next/report.bqn` の出力を読んで表示するだけ。
source TSV へは Go editor 経由でのみ書き込む。

---

## 4. 多通貨・為替 (Multi-Currency)

### なぜやるか

今は単一通貨（JPY）前提。外貨取引や海外サービス支払いの記録が正確にできない。

### 導線

- 現状: `src_next/projection.bqn` — Posting IR への投影。amount は1軸
- 現状: `src_next/tbds.bqn` — opening/movement/closing は amount 1軸
- 現状: `docs/POSTING_IR_CONTRACT.md` — Posting IR のフィールド定義

### やること

#### Phase A: スキーマ設計

1. `config/meta_schema.tsv` に `currency=...` と `base_amount=...` を追加
2. `docs/POSTING_IR_CONTRACT.md` に `currency`, `base_amount` フィールド追加
3. 設計文書 `docs/MULTI_CURRENCY_DESIGN.md` 作成

#### Phase B: データ層

1. `src_next/projection.bqn` の Posting IR に `currency` フィールド追加
2. `src_next/loader.bqn` で `currency=` メタデータを読み取り
3. `src_next/tbds.bqn` に `base_amount` 軸追加（amount は元通貨、base_amount は基準通貨換算）
4. `data/config.tsv` に `BASE_CURRENCY=JPY` 追加

#### Phase C: 表示層

1. `src_next/snapshot.bqn` で通貨別表示
2. `src_next/balances.bqn` で `amount` / `base_amount` 両表示
3. 非JPY取引のハイライト

### 難易度: 中（設計が肝。実装は軸追加で吸収できる）

---

## 5. コントリビュータ向け文書 (Contributor Documentation)

### なぜやるか

現状の docs は moko と pit 向けに最適化されていて、
外部の人が読むには入口が多すぎる。整理すれば8割はできている。

### やること

1. `CONTRIBUTING.md` を repo 直下に作成
   - セットアップ（BQN, Go, 依存）
   - 最初に読む docs の導線
   - テストの走らせ方（`tools/check.sh`）
   - アーキテクチャの概要（`docs/ARCHITECTURE.md` へのリンク）
2. `docs/README.md` の「まず読む」セクションを整理
   - 現状12項目 → 5項目に圧縮
3. `docs/AI_CODEMAP.md` を人間向けに補足
4. 各モジュールの先頭コメントを整備（すでに多くのファイルにある）

### 難易度: 低（既存 docs の再編が主）

---

## 6. Failure Fixtures / Safety Profile 強化 ✅ 完了 (2026-06-26)

### 結果

既存の failure fixture（2-5は既存）:
- `src-next-stale-plan/` — stale plan ✓
- `src-next-anchor-unmet/` — future anchor 欠け ✓
- `src-next-zero-vs-unavailable/` — 0 vs unavailable ✓
- `src-next-unknown-account/` — unknown account ✓
- `src-next-invalid-posting/` — invalid posting ✓
- `src-next-empty-projection/` — empty projection ✓
- `src-next-missing-plan/` — missing plan.tsv ✓

新規追加 (1, 4):
- `src-next-missing-budget-mapping/` — budget mapping 欠け（封筒消費はあるが budget= なし）
- `src-next-broken-empty-columns/` — 空列保持が壊れた journal 行（SplitKeepEmpty 検証）

両方 `check-src-next-golden.sh` に接続済み。`tools/check.sh` 全PASS。

### やったこと

1. ✅ 封筒消費はあるが budget mapping がない fixture 追加 → `src-next-missing-budget-mapping/`
2. ✅ stale plan が残っている fixture → 既存 `src-next-stale-plan/`
3. ✅ future anchor が欠けている fixture → 既存 `src-next-anchor-unmet/`
4. ✅ 空列保持が壊れている fixture 追加 → `src-next-broken-empty-columns/`
5. ✅ `0` に見えるが実際は unavailable → 既存 `src-next-zero-vs-unavailable/`
6. ✅ 各 fixture を check-src-next-golden.sh に接続 → `tools/check.sh` に追加

---

## 7. Household Policy Layer 完成

### なぜやるか

Phase 0〜4 は完了しているが、まだ「moko の生活スタイル」が色濃い。
policy profile の切り替えをもっと実用的にする。

### 導線

- 現状: `docs/HOUSEHOLD_POLICY_LAYER_PLAN.md`
- 現状: `src_next/household_policy.bqn`
- 現状: `fixtures/household-moko/` `fixtures/household-monthly-salary/`
- 現状: `docs/HOUSEHOLD_POLICY_PHASE3_PROOF.md` — 2-style fixture proof 済み

### やること

1. `config/meta_schema.tsv` に policy 設定キーを正式定義
2. `data/config.tsv` で policy profile を選択できるように
3. household views の `UNAVAILABLE` 状態をもっと細かく分類
4. 欠損時に policy を推測しない（fail visible）

### 難易度: 低〜中（設計は済、実装の積み残し）

---

## 着手順の提案

```text
1. 動的勘定科目空間        ← コードベースの健全性、mental overhead 低減
2. Failure Fixtures        ← 安全網を先に張る
3. 取消・修正UI            ← 実用性がすぐ上がる
4. TUI Phase A（設計のみ） ← 次の大きい一手の準備
5. コントリビュータ文書    ← 並行して進められる
6. 多通貨                  ← 設計が固まってから
7. Household Policy 完成   ← 実装の積み残し
```

---

## やらないと決めたこと

- **データベース化**: TSV + git で十分。同時編集も個人なら不要
- **多ユーザー対応**: 別カテゴリのプロダクト。目指さない
- **期間ロック・監査証跡**: 個人利用では「自分が過去を変えない」で十分
- **BQN → Rust/Zig 移植**: 別プロジェクト。今の BQN の表現力は維持する

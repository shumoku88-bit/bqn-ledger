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

`journal reverse` サブコマンドを BQN editor に追加。
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
   - BQN editor 経由で安全追記

---

## 3. 多通貨・為替 (Multi-Currency)

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

## 7. Household Policy Layer 完成 ✅ 一部完了 (2026-06-28)

### 結果

以下のサブタスクが完了し、mokoの個別生活前提がエンジンから剥離されました。
*   **BQNコード内の日本語表示文字列の外部化**: `config/report_labels.tsv` と `src_next/report_labels.bqn` を新設し、セクション名やテーブルヘッダー、レポート表示用の日本語文字列をすべて外部化しました。
*   **Prefix Fallback（接頭辞による暗黙の役割推測）の廃止**: アカウント接頭辞（`expenses:` など）による暗黙判定を完全に廃止し、`accounts.tsv` に指定された `role=` 属性のみを厳密に適用するように変更しました（`valid_roles` からの空文字除去完了）。

### 導線

- 現状: `docs/archive/active-plans/HOUSEHOLD_POLICY_LAYER_PLAN.md`
- 現状: `src_next/household_policy.bqn`
- 現状: `fixtures/household-moko/` `fixtures/household-monthly-salary/`
- 現状: `docs/archive/completed-plans/HOUSEHOLD_POLICY_PHASE3_PROOF.md` — 2-style fixture proof 済み

### 残っているやること

1. `config/meta_schema.tsv` に policy 設定キーを正式定義
2. `data/config.tsv` で policy profile を選択できるように
3. household views の `UNAVAILABLE` 状態をもっと細かく分類
4. 欠損時に policy を推測しない（fail visible）
5. `report_sections.tsv` や `account_display.tsv` の将来的な導入判断

---

## 8. Command Hub (日常操作ランチャー) ✅ 完了 (2026-06-28)

### 結果

日常操作の確認・閲覧・実行導線を一元化する `tools/bl` (Command Hub) を実装しました。

### やったこと

*   **Phase 1: 閲覧・確認**: レポート選択、fzf / gum によるプレビュー（`tools/main-ui.sh` 連携）、および一時キャッシュによる preview 状態復元を実装。
*   **Phase 2: アクション連携**: 仕訳追加・取消UI（`tools/add-ui.sh` 連携）や、新設された懸案事項 (`issues.tsv`) を対話的に安全追加する BQN editor 連携ルートの実装。
*   **デザイン分離**: gum / fzf 等の装飾レイヤーとPlain出力テキストの完全な分離（BQNエンジンは色を持たず、UI層がANSI制御を担当する契約を厳守）。

---

## 着手順の提案

```text
1. 動的勘定科目空間        ← 完了 (2026-06-26)
2. Failure Fixtures        ← 完了 (2026-06-26)
3. 取消・修正UI            ← 完了 (2026-06-26)
4. コントリビュータ文書    ← 進行中 (docs/AI_CODEMAP.md の補完)
5. 多通貨                  ← 設計が固まってから
6. Household Policy 完成   ← 一部完了 (ラベル外部化・Prefix Fallback廃止完了)
7. Command Hub 導入        ← 完了 (2026-06-28)
```

---

## やらないと決めたこと

- **データベース化**: TSV + git で十分。同時編集も個人なら不要
- **多ユーザー対応**: 別カテゴリのプロダクト。目指さない
- **期間ロック・監査証跡**: 個人利用では「自分が過去を変えない」で十分
- **BQN → Rust/Zig 移植**: 別プロジェクト。今の BQN の表現力は維持する

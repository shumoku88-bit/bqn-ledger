# Current State Reference: 現行エンジン比較基準

> **Status: historical / superseded (2026-06-26)**
> **Note (2026-06-26):** Old engine has been deleted. References in this doc are historical. Current engine is src_next/.
> この文書は phase 0 baseline としての履歴価値があるため残します。
> 現行の情報は `docs/AI_CODEMAP.md` と `docs/ARCHITECTURE.md` を参照してください。

Status: draft
Branch: `refactor/cycle-ledger-core`
Scope: Phase 0 baseline for cycle-ledger-core refactor

## 1. 目的

この文書は、`refactor/cycle-ledger-core` ブランチで新しい実装と比較するための現行エンジンの基準（baseline）を文書化する。

Phase 0 の成果物であり、以下の情報を一箇所にまとめる：

- 現行レポートの主要コマンド
- 確認用コマンド・チェックの有無
- fixture / expected output / golden output の場所と構造
- 新実装と比較すべき最小 baseline
- 不明点・未確認点

参照する設計文書：
- `docs/ARCHITECTURE_NEXT.md`
- `docs/DATA_CONTRACT.md`
- `docs/AXIS_CONTRACT.md`
- `docs/PROJECTION_CONTRACT.md`
- `docs/REPORT_CONTRACT.md`
- `docs/REPORT_VALUE_CONTRACT.md`
- `docs/MIGRATION_PLAN.md`
- `docs/CYCLE_LEDGER_DECISIONS.md`
- [SRC_NEXT_STAGE4A_OBSERVATION_INVENTORY.md](file:///Users/user/Projects/moko/bqn-ledger/docs/SRC_NEXT_STAGE4A_OBSERVATION_INVENTORY.md) — Stage 4a 検証面棚卸し
- [SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md](file:///Users/user/Projects/moko/bqn-ledger/docs/SRC_NEXT_SNAPSHOT_EQUIVALENCE_CRITERIA.md) — production-equivalent Snapshot criteria 定義
- [SRC_NEXT_STAGE4B_READINESS_GATE.md](file:///Users/user/Projects/moko/bqn-ledger/docs/SRC_NEXT_STAGE4B_READINESS_GATE.md) — Stage 4b validation run readiness gate 定義
- [SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md](file:///Users/user/Projects/moko/bqn-ledger/docs/SRC_NEXT_MANUAL_COMPARISON_PROCEDURE.md) — 手動比較手順の正本（Gate B 充足の手順書）


## 2. 現行レポートの主要コマンド

### 2.1 エントリポイント

現行システムには複数のエントリポイントがある：

| エントリポイント | 用途 | 実体 |
|---|---|---|
| `bqn main.bqn` | 最上位エントリポイント。安定した人間向けレポート。 | `src/reports/main_impl.bqn` に委譲 |
| `bqn src/reports/main.bqn` | 同上（旧エントリポイント） | 同上 |
| `bqn src/reports/exporters/*.bqn` | 機械可読 TSV エクスポート | 各 exporter ファイル |

### 2.2 日常使用の最小コマンド

```sh
# デフォルトデータディレクトリでフルレポート
bqn main.bqn

# 特定ベースディレクトリでフルレポート
bqn main.bqn --base data

# 特定セクションのみ
bqn main.bqn --base data --section outlook
bqn main.bqn --base data --section envelopes
bqn main.bqn --base data --section check
bqn main.bqn --base data --section actual-comparison

# セクション一覧表示（fzf/gum ラッパー用）
bqn main.bqn --base data --list-sections

# 対話型セクション選択
bqn main.bqn --base data --toc

# 特定日付を基準にレポート（fixture 用）
bqn main.bqn --base fixtures/basic --as-of 2026-01-03

# 機械可読エクスポート（AI 検索光用）
bqn src/reports/exporters/export-report-numbers.bqn --base data
bqn src/reports/exporters/export-envelope-summary.bqn --base data
bqn src/reports/exporters/export-liquid-assets-summary.bqn --base data
bqn src/reports/exporters/export-cycle-summary.bqn --base data
bqn src/reports/exporters/export-plan-summary.bqn --base data
bqn src/reports/exporters/export-residual-summary.bqn --base data
bqn src/reports/exporters/export-actual-comparison.bqn --base data
bqn src/reports/exporters/export-balances.bqn --base data
bqn src/reports/exporters/export-planned.bqn --base data
bqn src/reports/exporters/export-tx-updates.bqn --base data
bqn src/reports/exporters/export-day-balances.bqn --base data
bqn src/reports/exporters/export-envelope-flow.bqn --base data
bqn src/reports/exporters/export-canonical-snapshot.bqn --base data
bqn src/reports/exporters/export-liquid-assets-summary.bqn --base data
bqn src/reports/exporters/export-cycle-summary.bqn --base data
bqn src/reports/exporters/export-plan-summary.bqn --base data
bqn src/reports/exporters/export-envelope-summary.bqn --base data
bqn src/reports/exporters/export-ui-accounts.bqn --base data --role asset
bqn src/reports/exporters/export-section-status.bqn --base data
```

### 2.3 AI 向け軽量クエリツール（query）

`tools/query` は `tools/report-next-summary` の machine-readable 出力をフィルタする薄いラッパー。計算はしない。

```sh
# 全キーと値の一覧
tools/query fixtures/src-next-golden --list

# キー一覧のみ
tools/query fixtures/src-next-golden --keys

# 特定の値をクエリ
tools/query fixtures/src-next-golden src_next_cycle_range

# パターン検索（キー側）
tools/query fixtures/src-next-golden --grep 'cycle'
```

削除済みの旧 `tools/sqz-report` については `docs/OUTPUT_SQUEEZER_DESIGN.md` 参照。

### 2.4 レポートセクション一覧（12セクション）

| インデックス | キー | ラベル |
|---|---|---|
| 0 | `snapshot` | 1. 全体サマリ (Snapshot) |
| 1 | `ytd` | 2. 年初来サマリ (YTD Summary) |
| 2 | `balances` | 3. 勘定科目一覧 (Balances) |
| 3 | `cycle` | 4. 今サイクル集計 (Cycle Summary) |
| 4 | `envelopes` | 5. 封筒・予算残高 (Envelopes & Balances) |
| 5 | `planned` | 6. 未来の支払い等予定 (Planned Payments) |
| 6 | `recent` | 7. 直近の取引 (Recent Journal: last 10) |
| 7 | `check` | 8. チェック (Check) |
| 8 | `outlook` | 9. 見通し・日割り (Outlook / Daily Amount) |
| 9 | `daily-trend` | 10. 日割り推移 (Daily Trend) |
| 10 | `actual-comparison` | 11. Actual比較検証 (Actual Comparison) |
| 11 | `debug` | 12. デバッグ・由来 (Debug & Provenance) |

セクションエイリアス： `summary`, `accounts`, `budget`, `plan`, `compare`, `trend` など（`report_sections.bqn` 参照）。

### 2.5 既存の `residual` セクション

`residual` セクション（Plan vs Actual 履行確認）は人間向けレポートから削除済み。
`residual_table` と `export-residual-summary.bqn` は互換用の派生エクスポートとして残っている。

### 2.6 入力系コマンド

```sh
# 対話型トランザクション追加（fzf/gum 使用）
tools/add-ui.sh --base data

# 予算生成
bqn src/input/gen-budget.bqn --base data

# トランザクション一覧
bqn src/input/txn.bqn data
```

## 3. 確認用コマンド・チェックの有無

### 3.1 統合チェック（check.sh）

`checks/check.sh` がすべての確認を統合している（`tools/check.sh` は同一ファイルへの symlink またはコピー）。5ステップ構成：

1. **Unit tests**: `tests/test_*.bqn` 全12ファイル + Go editor tests
2. **Lint**: `checks/lint_accounts.bqn` による account metadata 整合性チェック
3. **Main report**: レポート生成がクラッシュしないことのスモークテスト（5パターン）
4. **Machine outputs**: 全17エクスポーター + 各種チェックスクリプト + 6つの src_next golden check（計40以上の検査）
5. **Fixtures**: fixture に対する lint + レポート + golden check など

実行方法：
```sh
bash tools/check.sh
```

詳細出力用：
```sh
bash checks/check_verbose.sh
```

### 3.2 単体テスト（BQN）

| ファイル | テスト対象 |
|---|---|
| `tests/test_core.bqn` | `core.bqn` (Split, ToNum, DateToNum, CheckRow, GetTxUpd) |
| `tests/test_config.bqn` | `config.bqn` (LoadConfig) |
| `tests/test_cycle.bqn` | `cycle.bqn` (ResolveFrom, fixed cycle) |
| `tests/test_account_space.bqn` | `account_space.bqn` |
| `tests/test_actual_comparison.bqn` | `actual_comparison_view.bqn` |
| `tests/test_build_cube_provenance.bqn` | `build_cube.bqn` + `account_space.bqn` |
| `tests/test_cashflow_obligation.bqn` | `cashflow_obligation_view.bqn` |
| `tests/test_find_section.bqn` | セクション検索ロジック |
| `tests/test_lint_accounts.bqn` | `lint_accounts.bqn` |
| `tests/test_residual.bqn` | `residual_view.bqn` |
| `tests/test_simple.bqn` | 最小 BQN 構文テスト（◶ など） |
| `tests/test_src_next_cube.bqn` | `src_next/cube.bqn` valid/skipped row partition, cube materialize boundary, validation summary |

テスト実行：
```sh
bqn tests/test_core.bqn
# 各ファイルが "OK" を出力すれば成功
```

### 3.3 Go エディターテスト

```sh
(cd editor && go test ./...)
```

### 3.4 BQN-only レポートスモークテスト

```sh
bash checks/check-bqn-only-report.sh
```

`fixtures/basic` と `fixtures/generalization-moko` に対して `--list-sections`, `--toc`, 全セクション, `--section` 指定の全パターンを実行し、出力が空でないことを確認。

### 3.5 ドキュメントドリフトチェック

```sh
bash checks/check-docs-drift.sh data
```

以下の整合性を検証：
- `report_engine.bqn` の PUBLIC RECORD CONTRACT と `docs/REPORT_FIELD_MAP.md` のフィールド一覧
- `report_engine.bqn` のフィールド数と `docs/REPORT_FIELD_MAP.md` の宣言数
- `main.bqn --list-sections` と `docs/MAIN_SECTIONS.md` のセクションキー
- ドキュメント内のデッドリンク
- legacy TSV パス参照

### 3.6 チェック一覧（check.sh ステップ4より抜粋）

| カテゴリ | コマンド/スクリプト |
|---|---|
| 不変条件 | `checks/invariants.bqn` |
| 人的一貫性 | `checks/check-human-consistency.sh` |
| 封筒一貫性 | `checks/check-envelope-consistency.sh` |
| 流動性トレンド | `checks/check-trend-liquid.bqn` |
| 封筒プラン | `checks/check-envelope-plan.bqn` |
| 行動ドリフト比較 | `checks/check-behavior-drift-comparison.bqn` |
| マルチタイムカード | `checks/check-multi-time-card.bqn` |
| 封筒ブートストラップ | `checks/check-envelope-bootstrap.bqn` |
| サイクル境界 | `checks/check-cycle-boundary.bqn` |
| 過去サイクル | `checks/check-historical-cycle.bqn` |
| 空ジャーナル | `checks/check-empty-journal.bqn` |
| セクションステータス | `checks/check-section-status.bqn` + `.sh` |
| キューブ開始前 | `checks/check-cube-before-start.bqn` |
| キューブ形状 | `checks/check-cube-shape.sh` |
| プロジェクションゼロサム | `checks/check-projection-zero-sum.sh` |
| 予測ゼロ | `checks/check-forecast-zero.bqn` |
| 封筒リザーブ | `checks/check-envelope-reserve.bqn` |
| 予算行リント | `checks/check-budget-row-lint.sh` |
| 未来ジャーナルリント | `checks/check-future-journal-lint.sh` |
| 不明アカウントリント | `checks/check-unknown-account-lint.sh` |
| 予算マッピング欠落 | `checks/check-missing-budget-mapping.sh` |
| サイクル表示 | `checks/check-cycle-display.sh` |
| 無効化機能 | `checks/check-disabled-features.sh` |
| today 参照 | `checks/check-today-references.sh` |
| リポジトリインデックス | `checks/check-repo-index.sh` |
| ネガティブチェック | `checks/check-negative.sh` |

## 4. Fixture / Expected Output / Golden Output

### 4.1 構造

各フィクスチャは `fixtures/<name>/` に以下の構成を持つ：

```
fixtures/<name>/
  accounts.tsv
  budget_alloc.tsv
  cycle.tsv
  journal.tsv
  plan.tsv
  [config.tsv]          # generalization 系のみ
  README.md
  expected/              # golden output（ある場合のみ）
    report_numbers.tsv
    envelope_summary.tsv
    liquid_assets_summary.tsv
    cycle_summary.tsv
    plan_summary.tsv
    residual_summary.tsv
    actual_comparison.tsv
    report.txt
```

### 4.2 フィクスチャ一覧と golden output 有無

| フィクスチャ | as-of | golden output | 用途 |
|---|---|---|---|
| `basic` | 2026-06-16 | ✅ あり | 最小だが一通り揃った安定確認用 |
| `future-journal-as-of` | 2026-01-03 | ✅ あり | 未来日付の journal 行を含むケース |
| `envelope-month-boundary` | 2026-02-02 | ✅ あり | 月境界での封筒計算 |
| `envelope-plan` | 2026-01-04 | ✅ あり | 封筒 + 予定の組み合わせ |
| `empty-fields` | 2026-01-03 | ✅ あり | 空フィールドを含むデータ |
| `multi-time-card` | 2026-01-05 | ✅ あり | 複数タイムカード |
| `envelope-bootstrap` | 2026-01-05 | ✅ あり | 封筒のブートストラップ |
| `behavior-drift-comparison` | 2026-01-06 | ✅ あり | 行動ドリフト比較 |
| `empty-journal` | 2026-01-01 | ✅ あり | 空ジャーナル |
| `cube-before-start` | 2025-01-01 | ✅ あり | キューブ開始前 |
| `forecast-zero` | 2026-01-05 | ✅ あり | 予測ゼロ |
| `plan-completion` | 2026-01-16 | ✅ あり | プラン完了 |
| `envelope-reserve` | 2026-01-05 | ✅ あり | 封筒リザーブ |
| `generalization-calendar` | 2026-02-10 | ✅ あり | カレンダーモードでの一般化テスト |
| `generalization-moko` | 2026-06-16 | ✅ あり | 実データに近い一般化テスト |
| `actual-comparison-min` | — | ❌ なし | actual-comparison 最小ケース |
| `budget-row-boundary` | — | ❌ なし | 予算行の境界テスト |
| `cycle-end-exclusive` | — | ❌ なし | サイクル終端（exclusive）テスト |
| `future-journal-hard-error` | — | ❌ なし | 未来ジャーナルハードエラー |
| `historical-cycle` | — | ❌ なし | 過去サイクルテスト |
| `liability` | — | ❌ なし | 負債テスト |
| `missing-budget-mapping` | — | ❌ なし | 予算マッピング欠落テスト |
| `non-prefix-roles` | — | ❌ なし | prefix なしロールテスト |
| `unknown-account` | — | ❌ なし | 不明アカウントテスト |
| `src-next-golden` | — | ✅ あり | `src_next` 用: 最小 golden (Phase 8.1) |
| `src-next-missing-plan` | — | ✅ あり | `src_next` 用: plan.tsv 欠落 (Phase 8.2) |
| `src-next-empty-projection` | — | ✅ あり | `src_next` 用: 空 journal/plan (Phase 8.2) |
| `src-next-unknown-account` | — | ✅ あり | `src_next` 用: unknown account skipped-row (Phase 8.2) |
| `src-next-out-of-cycle-journal` | — | ✅ あり | `src_next` 用: out-of-cycle journal row (Phase 8.2) |
| `src-next-currency-accountkey` | — | ✅ あり | `src_next` 用: AccountKey currency metadata (Phase 8.2) |
| `src-next-expense-role-metadata` | — | ✅ あり | `src_next` 用: explicit role=expense metadata |
| `src-next-household-mapping-policy` | — | ✅ あり | `src_next` 用: household metadata / policy-shape diagnostics |
| `src-next-income-anchor-golden` | — | ✅ あり | `src_next` 用: incomeAnchor cycle golden |
| `src-next-plan-overlap` | — | ❌ なし | `src_next` 用: plan/journal overlap diagnostics (Phase 8.7) |
| `src-next-envelope-computation` | — | ✅ あり | `src_next` 用: fixture-scoped envelope computation implementation (Stage 4a) |

合計: 35 fixture。うち 26 が `expected/` を持つ（src_next 用 `src_next_summary.txt` を含む）。

### 4.3 Golden check の仕組み

`checks/golden_check.sh` がフィクスチャの出力を expected/ と比較する。

```sh
# 使用例
bash checks/golden_check.sh fixtures/basic 2026-06-16
```

比較対象（8ファイル）。golden check が使用するエクスポーター：
1. `report_numbers.tsv` ← `export-report-numbers.bqn`
2. `envelope_summary.tsv` ← `export-envelope-summary.bqn`
3. `liquid_assets_summary.tsv` ← `export-liquid-assets-summary.bqn`
4. `cycle_summary.tsv` ← `export-cycle-summary.bqn`
5. `plan_summary.tsv` ← `export-plan-summary.bqn`
6. `residual_summary.tsv` ← `export-residual-summary.bqn`
7. `actual_comparison.tsv` ← `export-actual-comparison.bqn`
8. `report.txt` ← `src/reports/main.bqn`

全エクスポーター一覧（17ファイル）：
`export-report-numbers`, `export-envelope-summary`, `export-liquid-assets-summary`,
`export-cycle-summary`, `export-plan-summary`, `export-residual-summary`,
`export-actual-comparison`, `export-balances`, `export-planned`,
`export-tx-updates`, `export-day-balances`, `export-envelope-flow`,
`export-canonical-snapshot`, `export-section-status`, `export-ui-accounts`,
`export-cashflow-due`, `export-events`

### 4.4 Golden 更新

```sh
bash tools/update-golden.sh
```

15フィクスチャすべての expected/ を再生成する。
表示変更が意図的な場合のみ実行。

### 4.5 src_next golden check（Phase 8）

`src_next/` パス用の compact golden check は `checks/check-src-next-golden.sh` で実行する。

`tools/golden_check.sh` とは異なり、`src_next/main.bqn` の全出力のうち `grep -E` で抽出したキー行のみを比較する compact golden 方式を採用している。

```sh
# 個別実行
bash checks/check-src-next-golden.sh fixtures/src-next-golden
bash checks/check-src-next-golden.sh fixtures/src-next-missing-plan
bash checks/check-src-next-golden.sh fixtures/src-next-empty-projection
bash checks/check-src-next-golden.sh fixtures/src-next-unknown-account
bash checks/check-src-next-golden.sh fixtures/src-next-out-of-cycle-journal
bash checks/check-src-next-golden.sh fixtures/src-next-currency-accountkey
bash checks/check-src-next-envelope-computation.sh fixtures/src-next-envelope-computation
bash checks/check-src-next-envelope-production-guard.sh
```

`check-src-next-envelope-production-guard.sh` は production data の `tools/report-next-summary data` で envelope implementation が `unavailable/src_next` に留まり、polished remaining / safe_remaining / daily_amount / per-day allowance を出さないことを固定する。

`check.sh` ステップ4 に統合済み。compact summary には `src_next_*` の最小レポート比較用フィールド（cycle range、valid/skipped counts、actual/plan totals、expense totals、非ゼロ account totals）も含める。

主な src_next fixture でカバーするケース：

| fixture | plan.tsv | journal data | 確認対象 |
|---|---|---|---|
| `src-next-golden` | 2行（うち1行 out-of-cycle） | 2行 | 基本パス + skipped projection row |
| `src-next-missing-plan` | なし | 2行 | optional plan.tsv 欠落耐性 |
| `src-next-empty-projection` | 0行 | 0行 | 空 projection + all-zero cube |
| `src-next-unknown-account` | 0行 | 2行（うち1行 unknown account） | unknown account skipped-row reason |
| `src-next-out-of-cycle-journal` | 0行 | 2行（うち1行 out-of-cycle） | out-of-cycle journal row skip |
| `src-next-currency-accountkey` | 0行 | 3行（うち1行 USD account） | AccountKey currency metadata |
| `src-next-plan-overlap` | 2行（うち1行 exact match） | 2行（うち1行 exact match） | plan/journal overlap diagnostics (Phase 8.7) |
| `src-next-envelope-computation` | 1行（planned spending ignored by remaining） | 4行（target + non-target + missing metadata） | fixture-only `allocated`, `actual_spent`, `remaining = allocated - actual_spent` |

### 4.6 Snapshot（ドキュメント用）

`docs/snapshots/basic_main.txt` が `fixtures/basic` のレポート出力のスナップショットとして保存されている。

## 5. 現行エンジンのアーキテクチャ概要

### 5.1 データフロー

```text
canonical TSV (data/*.tsv)
  → parse (src/input/parse_*.bqn)
  → account space + cube build (src/core/account_space.bqn, build_cube.bqn)
  → views (src/views/*.bqn)
  → report_engine.BuildAt (src/reports/report_engine.bqn)
  → report_sections.Make → Render (src/reports/report_sections.bqn, sections/sec_*.bqn)
  → CLI text output
  └→ exporters (src/reports/exporters/export-*.bqn) → derived TSV
```

### 5.2 主要な内部構造

- **Canonical Daily Cube**: `256 × Day × 4 layers (actual, plan, budget, forecast)` の3次元配列
- **BuildAt の戻り値**: 約99フィールドの巨大な単一 Record Namespace
- **セクション**: 12の表示セクションが Render で stdout に出力
- **外部プロセス依存**: `date.bqn` で `•SH "date"`、`core.bqn` で `•SH "cat"` を使用

### 5.3 依存関係

| カテゴリ | 依存 | 必須/オプショナル |
|---|---|---|
| BQN ランタイム | CBQN | 必須 |
| シェル | bash | オーケストレーション用 |
| Go | editor/ (`tools/edit`) | 安全な TSV 追記・編集用。BQN フォールバックあり |
| fzf / gum | 対話型選択 UI | `add-ui.sh` でオプショナル |
| awk / perl / diff | チェックスクリプト | テスト・検証用 |

### 5.4 設計上の既知の課題（hardening notes より）

1. `BuildAt` が約99フィールドの巨大な単一 Record を返す。セクション依存関係が見えにくい
2. `report_engine.bqn` が実装コードと長大な public field listing を混在させている
3. プロジェクション関数に繰り返しパターンが存在する
4. ハードコードされた `256` が複数箇所に散在している
5. 外部プロセス呼び出し（`•SH "cat"`, `•SH "date"`）がモジュール境界に隠れている

## 6. 新実装と比較すべき最小 baseline

### 6.1 比較基準となる最小コマンド

```sh
# 単一 fixture に対してフルレポート + 全エクスポート
FIXTURE=fixtures/basic
AS_OF=2026-01-03

bqn main.bqn --base $FIXTURE --as-of $AS_OF
bqn src/reports/exporters/export-report-numbers.bqn --base $FIXTURE --as-of $AS_OF
bqn src/reports/exporters/export-envelope-summary.bqn --base $FIXTURE --as-of $AS_OF
bqn src/reports/exporters/export-liquid-assets-summary.bqn --base $FIXTURE --as-of $AS_OF
bqn src/reports/exporters/export-cycle-summary.bqn --base $FIXTURE --as-of $AS_OF
bqn src/reports/exporters/export-plan-summary.bqn --base $FIXTURE --as-of $AS_OF
```

### 6.2 最小 baseline フィクスチャ（推奨順）

1. **`fixtures/basic`** — 最小完全ケース。golden output 完備。新実装の最初の比較対象として最適。
2. **`fixtures/empty-fields`** — エッジケース。空フィールドへの耐性確認。
3. **`fixtures/empty-journal`** — エッジケース。データなし時の挙動確認。
4. **`fixtures/envelope-plan`** — 封筒 + 予定の組み合わせ。
5. **`fixtures/generalization-moko`** — 実データに近い規模と構成。

### 6.2b src_next 専用 baseline（Phase 8 で追加）

`src_next/main.bqn` は現行エンジンとは独立したcandidate pathであり、
独自の compact golden check を持つ。

1. **`fixtures/src-next-golden`** — 最小ケース（plan.tsv あり、out-of-cycle skipped row あり）
2. **`fixtures/src-next-missing-plan`** — plan.tsv 欠落時の耐性確認
3. **`fixtures/src-next-empty-projection`** — 空 journal/plan 時の all-zero cube 確認
4. **`fixtures/src-next-unknown-account`** — unknown account 行の skipped-row reason 確認
5. **`fixtures/src-next-out-of-cycle-journal`** — out-of-cycle journal 行の skipped-row reason 確認
6. **`fixtures/src-next-currency-accountkey`** — AccountKey の currency metadata 反映確認
7. **`fixtures/src-next-envelope-computation`** — fixture-scoped envelope computation implementation。`allocated` / `actual_spent` / `remaining = allocated - actual_spent` を確認

これらは現行エンジンの golden output とは比較しない。
`src_next` 独自の数値的正しさを確認するための独立した baseline である。

2026-06-25: `docs/SRC_NEXT_ENVELOPE_COMPUTATION_CONTRACT.md` を追加し、Section 5 / Section 9 の境界として `allocated` / `actual_spent` / `remaining`、`safe_remaining` later work、`daily_amount` later work、unavailable / fallback 境界を文書化した。同日、`src_next/envelope_computation.bqn` と `fixtures/src-next-envelope-computation` を fixture-scoped implementation として追加した。production route は変えていない。

`src_next` projection rows are now ledger-like: one source journal/plan row normally expands into a debit row and a credit row. The derived rows keep the same `source_id`, expose `side`, and use signed deltas (`debit` positive, `credit` negative), so balanced source rows should sum to `0` by `source_id`. This remains an read-only production-candidate path.

`docs/ACCOUNTING_CAPABILITIES.md` documents future accounting-oriented capabilities considered for `src_next`.

### 6.3 比較すべき出力の種類（優先度順）

| 優先度 | 出力 | 理由 |
|---|---|---|
| 1 (最高) | `export-report-numbers.bqn` の TSV | 数値計算の正しさの根幹。約30キーの key=value |
| 2 | `export-cycle-summary.bqn` の TSV | サイクル集計（設計の中心概念） |
| 3 | `export-envelope-summary.bqn` の TSV | 封筒予算計算 |
| 4 | `export-liquid-assets-summary.bqn` の TSV | 流動性計算 |
| 5 | `export-plan-summary.bqn` の TSV | 予定計算 |
| 6 | `export-actual-comparison.bqn` の TSV | Actual 比較 |
| 7 | `export-residual-summary.bqn` の TSV | 残差（互換用） |
| 8 (最低) | `report.txt`（人間向けレポート全文） | 表示フォーマット。数値が合っていれば後回し可 |

### 6.4 比較方法

```sh
# 新実装の出力を取得
bqn src_next/exporters/export-report-numbers.bqn --base fixtures/basic --as-of 2026-01-03 > /tmp/new.tsv

# 現行の golden output と diff
diff -u fixtures/basic/expected/report_numbers.tsv /tmp/new.tsv
```

（旧 `tools/sqz-report --diff` は削除済み。現在は `tools/report-next-summary` + `diff` で代替）

### 6.5 比較時の注意点

- `report.txt` の表示フォーマットは変わりうるため、数値的正しさの確認には TSV 出力を優先する
- `--as-of` を指定しない場合、`date.bqn` が現在日付を取得するため、出力が変動する
- 新実装が `report.txt` のセクション順序やラベルを変えることは許容される（設計文書で明示的に許可されている場合）
- 新実装が `residual` 系の出力を削除することは許容される（既に人間向けレポートからは削除済み）

## 7. 不明点・未確認点

### 7.1 確認済み

- [x] 現行レポートの全エントリポイントと主要コマンド
- [x] `check.sh` の全検査内容
- [x] 全30 fixture と golden output の有無（21/30 が golden output 完備）
- [x] golden check の仕組み（8種類の出力比較）
- [x] sqz-report の機能（query, list, grep, diff）
- [x] 単体テストの場所と実行方法（12ファイル）
- [x] 依存関係（BQN, bash, Go, fzf/gum）
- [x] `residual` セクションの削除状況
- [x] 設計上の既知の課題（hardening notes）
- [x] `src_next/` パスの構成（6ファイル: loader, account_key, cycle, projection, cube, main）
- [x] `src_next/` の compact golden check（6 fixture, `check-src-next-golden.sh`）
- [x] `check.sh` への src_next golden check 統合
- [x] `data/` の全6 canonical ファイルの存在確認
- [x] `check.sh` の fixtures モード全通確認

### 7.2 未確認・要確認

- [ ] 実データでの `check.sh` 全通確認 → 本ドキュメント執筆時点では fixtures のみを対象に確認。実データ（`data/*.tsv`）を含む全通は実施していない
- [ ] 実データ（`data/*.tsv`）の内容確認。実データには個人情報が含まれるため、本ブランチでは直接確認しない方針
- [ ] 実データの `journal.tsv`（284行）の規模感。fixtures ではカバーしきれない実運用時のパフォーマンス・挙動の確認
- [ ] `fixtures/actual-comparison-min` など golden output を持たない9 fixture のカバレッジギャップの評価
- [ ] `editor/` (Go) の完全な責務範囲の確認。BQN だけで置き換え可能かどうか
- [ ] `tools/edit` (Go binary) のビルド方法
- [x] `checks/check-tx-updates.bqn` → ファイルは存在しない。`check_verbose.sh` では `export-tx-updates.bqn`（エクスポーター）を呼んでいる

### 7.3 設計文書との整合性確認事項

- [x] MIGRATION_PLAN.md Phase 0 exit condition: 「新パスと現行パスを比較するための明確な baseline があること」→ 本ドキュメント §6 で明確な baseline を定義済み。§4.5 で src_next golden check（6 fixture）も統合済み
- [ ] REPORT_CONTRACT.md の「第一レポート面」6セクションと現行12セクションの対応関係
- [x] DATA_CONTRACT.md の canonical TSV 定義と現行 `data/` のファイル構成の一致 → 一致確認済み（6ファイルすべて存在）
- [ ] 新実装が `AccountKey = (Account, Currency)` モデルを採用した場合の、現行（暗黙の JPY-only）との挙動差の評価。`src_next/` は既に AccountKey モデルを実装済み（Phase 1）

### 7.4 未解決の設計質問（設計文書より）

- `accounts.tsv` に currency カラムを追加すべきか（現行はすべて JPY が暗黙）
- [x] 最初の実装パスは `src_next/` か既存 `src/` モジュール内か → `src_next/` を採用済み
- 最初のユーザー向けスライスは `current cycle summary` か `food / daily remaining amount` か
- [x] AccountKey を `accounts.tsv` で明示的に宣言するか、ローダーで導出するか → ローダーで導出（`account_key.bqn` が AccountKey 解決を担当）
- どの current command を比較 baseline にするか（→ 本ドキュメントで `export-report-numbers.bqn` を最優先と推奨）
- [x] 既存の golden output で十分か、新しい fixture を先に追加すべきか → src_next 用に 6 fixture を追加済み（Phase 8.1–8.2）
- ドキュメントのみの変更をコード変更前に `main` にマージすべきか

## 8. 参考：現行ソースコードマップ

```
main.bqn                          # ルートエントリポイント
src_next/                         # 次期 engine candidate path（Phase 1-8）
  main.bqn                        # エントリポイント（cycle + AccountKey + projection + cube sanity）
  loader.bqn                      # TSV 読み取り（ReadLines, SplitTsv, ReadLinesOptional）
  account_key.bqn                 # AccountKey 解決（(Account, Currency) ペア）
  cycle.bqn                       # サイクル情報読み取り（ReadCycle, FormatCycleInfo）
  projection.bqn                  # ledger-like プロジェクション行生成（MakeRow, source_id/side, balance check, FormatProjTable）
  cube.bqn                        # valid/skipped row partition + cube materialize + minimal report summary + validation/sanity rendering
src/
  core/
    core.bqn                      # 基本ユーティリティ (Split, ToNum, etc.)
    config.bqn                    # 設定読み込み
    date.bqn                      # 日付処理 (•SH "date" に依存)
    context.bqn                   # コンテキスト
    account_space.bqn             # アカウント空間構築
    build_cube.bqn                # Canonical Daily Cube 構築
    cycle.bqn                     # サイクル解決
    layers.bqn                    # レイヤー構築
    test_lib.bqn                  # テスト用アサーションライブラリ
  input/
    parse_accounts.bqn            # accounts.tsv パース
    parse_journal.bqn             # journal.tsv パース
    parse_plan.bqn                # plan.tsv パース
    parse_budget_alloc.bqn        # budget_alloc.tsv パース
    add.bqn                       # トランザクション追加（レガシーBQNパス）
    txn.bqn                       # トランザクション一覧
    gen-budget.bqn                # 予算生成
  reports/
    main.bqn                      # 旧エントリポイント
    main_impl.bqn                 # CLI実装（引数解析・ディスパッチ）
    report_engine.bqn             # BuildAt: 全計算を1つの巨大Recordにまとめる
    report_sections.bqn           # セクション管理・レンダリング
    format_text.bqn               # テキストフォーマット
    export_tsv.bqn                # TSVエクスポート基盤
    exporters/                    # 機械可読エクスポーター（17ファイル）
    sections/                     # 人間向けセクション（12ファイル）
  views/                          # ビュー（view model）（12ファイル）
  checks/                         # チェック・リント・ゴールデン（約39ファイル）
  input/ui/                       # 対話型UI補助
tests/
  test_*.bqn                      # 単体テスト（12ファイル）
  fixtures/                       # テスト用追加fixtureデータ
fixtures/                         # フィクスチャ（30ディレクトリ、うち21がgolden output完備）
tools/
  check.sh                        # 統合チェック（5ステップ）
  update-golden.sh                # golden output 全更新
  sqz-report                      # AI向け軽量レポートクエリツール
  add-ui.sh                       # 対話型トランザクション追加
  edit                            # Go製安全TSVエディタ
  legacy/                         # 旧ツール
  lib/                            # 共有シェルライブラリ
editor/                           # Goエディタパッケージ
data/                             # 実データ（canonical TSV）
config/                           # 設定ファイル
out/                              # 派生出力
docs/                             # ドキュメント（90+ファイル）
  snapshots/                      # レポートスナップショット
```

## 9. 次のステップ

本ドキュメントが Phase 0 の完了条件を満たした後：

1. **Phase 1**: 設計文書の契約整合性確認（`MIGRATION_PLAN.md` §5） → 8文書の整合性確認は本ドキュメント §7.3 で一部完了。残タスクあり
2. **Phase 2**: 読み取り専用ローダーパスの作成 → `src_next/` として実装済み（Phase 1–8）
3. baseline 比較の自動化（新実装の出力を golden check で検証する CI 的仕組み）
   → `checks/check-src-next-golden.sh` で 6 fixture をカバー中。現行エンジンとの数値比較は未実施
4. **Phase 8.2**: src_next fixture セット完了（7 fixture: golden, missing-plan, empty-projection, unknown-account, out-of-cycle-journal, currency-accountkey, plan-overlap）
5. **Phase 5**: Projection sanity check → `src_next/cube.bqn` で cube materialize + sanity + numeric verification まで実装済み
6. **Phase 6–8**: 最小レポート state + SectionResult + レポート面拡張 → 未着手

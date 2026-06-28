# VIEW_CONTRACTS.md

> **Note (2026-06-26):** 旧エンジン (, , ) は削除されました。この文書内の旧エンジンへの参照は履歴として残ります。現行エンジンは  です。
この文書は、`src/core/` が提供する Canonical Daily Cube を、特定のドメイン（封筒、流動資産など）の視点で解釈し直した **View 層の出力インターフェース（API契約）** を定義します。

View層は、Core由来の生の配列データを、レポートやツールが扱いやすい名前付きNamespace（Record）へと変換する責務を持ちます。

---

## EnvelopeView (`src/views/envelope_view.bqn`)

封筒（予算箱）ごとの配賦、消費、残高、および健康診断（枯渇予測）を提供します。

### 入力

```text
Build ⟨ as_of, cycle_start, cycle_end, meta, day_view ⟩
```

- `as_of`: String (YYYY-MM-DD)。観察時点。
- `cycle_start`: String (YYYY-MM-DD)。分析対象サイクルの開始日。
- `cycle_end`: String (YYYY-MM-DD)。分析対象サイクルの終了日（exclusive）。
- `meta`: `src/core/account_space.bqn` の Build 結果。
- `day_view`: `src/core/build_cube.bqn` の BuildCube 結果。

### 出力 (Namespace)

| フィールド名 | 型 | 内容 |
|:---|:---|:---|
| `env_names` | `[N] String` | 封筒名（prefix除去済み） |
| `env_groups` | `[N] String` | 封筒のグループ (`daily`, `flex`, `reserve` 等)。`daily`/`flex` は生活費として使う「生活封筒」、`reserve` は貯金・投資などの「仮確保封筒」。 |
| `current_bal` | `[N] Number` | `as_of` 時点の封筒残高 (Layer 2) |
| `env_cycle_allocated` | `[N] Number` | 当該サイクル内の累計配賦額 (Layer 3) |
| `env_cycle_spent` | `[N] Number` | 当該サイクル内の累計消費額 (Actual由来。reserve の場合は取り崩し額) |
| `avg_spend` | `[N] Number` | 1日あたりの平均消費額（サイクル開始〜`as_of`） |
| `target_daily` | `[N] Number` | 1日あたりの予算目標額 (allocated / サイクル全日数) |
| `days_until_empty` | `[N] Number` | 枯渇予測日数（(残高 + 予定消費) / avg_spend） |
| `env_status` | `[N] String` | 健康状態。日常封筒は `SAFE`/`WARN`/`SHORT`。仮確保封筒は `HELD`/`DONE`/`DRAWN`（HELD: 仮確保中、DONE: 期間終了時に維持確定、DRAWN: 取り崩しあり）。 |
| `days_left` | `Number` | サイクル終了までの残日数 |
| `trend_dates` | `[D] String` | 推移データの各日付 |
| `env_history_bal` | `[D x N] Number` | 封筒残高の履歴推移 |
| `env_history_daily` | `[D x N] Number` | 封筒別「その日の残高 / 残日数」の推移 |

---

## LiquidAssetsView (`src/views/liquid_view.bqn`)

流動資産の推移、固定費控除後の安全圏、および日割り可能額を提供します。

### 入力

```text
Build ⟨ as_of, journal_rows, plan_rows, cycle_start_dn, cycle_end_excl_dn, cycle_end, meta, day_view ⟩
```

- `as_of`: String (YYYY-MM-DD)。
- `journal_rows`: journal.tsv のパース済み行。
- `plan_rows`: plan.tsv のパース済み行。
- `cycle_start_dn`: サイクル開始日（YYYYMMDD数値）。
- `cycle_end_excl_dn`: サイクル終了日（exclusive, YYYYMMDD数値）。
- `cycle_end`: サイクル終了日（exclusive, String）。
- `meta`: アカウント定義。
- `day_view`: BuildCube 結果。

### 出力 (Namespace)

| フィールド名 | 型 | 内容 |
|:---|:---|:---|
| `trend_dates` | `[D] String` | 推移データの日付 |
| `trend_liquid` | `[D] Number` | `actual` レイヤーの流動資産合計推移 |
| `trend_fixed_reserve` | `[D] Number` | 固定費予約額（未決済の予定固定費） |
| `trend_daily_fund` | `[D] Number` | `liquid + planned_income - fixed_reserve`（生活原資） |
| `planned_future_income`| `Number` | `as_of` 以降のサイクル内予定収入合計 |
| `trend_days_left` | `[D] Number` | 各時点からのサイクル残日数 |
| `trend_daily` | `[D] Number` | その時点での日割り可能額 |
| `trend_delta` | `[D] Number` | 前日からの日割り額の変化 |
| `trend_variable` | `[D] Number` | その日の実績変動費支出 |
| `trend_saving` | `[D] Number` | その日の貯金・投資への移動額（負値は取り崩し） |
| `trend_fixed_paid` | `[D] Number` | その日の実績固定費支出 |
| `trend_drop_idx` | `[10] Index` | 日割り額が大きく下がった日のインデックス |

---

## CashflowObligationView (`src/views/cashflow_obligation_view.bqn`)

`plan.tsv` のうち、会計上は費用ではないが生活資金から固定的に確保すべきキャッシュアウトを抽出します。

### 入力

```text
Build ⟨ as_of, journal_rows, plan_rows, cycle_end_excl_dn, meta ⟩
```

- `as_of`: String (YYYY-MM-DD)。観察時点。
- `journal_rows`: journal.tsv のパース済み行。
- `plan_rows`: plan.tsv のパース済み行。
- `cycle_end_excl_dn`: サイクル終了日（exclusive, YYYYMMDD数値）。
- `meta`: アカウント定義。

### 出力 (Namespace)

| フィールド名 | 型 | 内容 |
|:---|:---|:---|
| `fixed_obligation_rows` | `[N] Row` | `cashflow=fixed_obligation` が付いた未履行の予定行。`from` が liquid account のものだけを対象にする。 |
| `fixed_obligation_reserve` | `Number` | `fixed_obligation_rows` の金額合計。 |
| `next_cycle_start_obligation_rows` | `[N] Row` | `cycle_end_exclusive` ちょうどの日付にある未履行の `cashflow=fixed_obligation` 予定行。次サイクル初日の参考表示用。 |
| `next_cycle_start_obligation_reserve` | `Number` | `next_cycle_start_obligation_rows` の金額合計。 |

---

## CycleView (`src/views/cycle_view.bqn`)

現在のサイクル期間における収入、支出、および収支合計を提供します。

### 入力

```text
Build ⟨ cycle_path, journal_rows, plan_rows, offset_override, meta ⟩
```

### 出力 (Namespace)

| フィールド名 | 型 | 内容 |
|:---|:---|:---|
| `cycle_start` | `String` | サイクル開始日 (inclusive) |
| `cycle_end` | `String` | サイクル終了日 (exclusive) |
| `cycle_mode` | `String` | サイクル解決モード (`fixed`, `incomeAnchor` 等) |
| `cycle_inc_total` | `Number` | サイクル内の実績収入合計 |
| `cycle_exp_total` | `Number` | サイクル内の実績支出合計 |
| `cycle_net` | `Number` | サイクル内の純収支 |
| `sorted_exp_names` | `[N] String` | 支出額の多い順のアカウント名 |
| `sorted_exp_sums` | `[N] Number` | 支出額の多い順の合計額 |

---

## PlanView (`src/views/plan_view.bqn`)

未来の予定収入、予定支出、および保守的な日割り見通しを提供します。

### 入力

```text
Build ⟨ as_of, names, journal_rows, plan_rows, cycle_end, active_acc, meta, liq_total, budget_balances, day_view ⟩
```

### 出力 (Namespace)

| フィールド名 | 型 | 内容 |
|:---|:---|:---|
| `future_payments` | `[N] Row` | `as_of` 以降の予定支出行 |
| `days_left` | `Number` | サイクル終了までの残日数 |
| `liq_daily` | `Number` | `(liquid + future_income) / days_left` |
| `liq_safe_daily` | `Number` | `(liquid + future_income - fixed_reserve) / days_left` |
| `budget_balances_updated` | `[A] Number` | 資産ベースで計算し直された封筒残高（未割当含む） |
| `budget_daily` | `[A] Number` | 封筒ごとの日割り可能額 |
| `journal_lag_days` | `Number` | `as_of` と journal 最終記録日の差 |

---

## ResidualView (`src/views/residual_view.bqn`)

当該サイクルにおける「予定 (Plan)」と「実績 (Actual)」の差異を勘定科目ごとに比較します。

### 入力

```text
Build ⟨ journal_rows, plan_status_table, cycle_start_dn, cycle_end_excl_dn, meta, as_of ⟩
```

### 出力 (Namespace)

| フィールド名 | 型 | 内容 |
|:---|:---|:---|
| `residual_table` | `[N] ⟨name, plan, actual, residual, status⟩` | 科目別の比較表 |

- `actual`: `cycle_start <= journal.date < cycle_end_exclusive` かつ `journal.date <= as_of` の実績支出。
- `plan`: `plan_status_table` のうち `completed` / `due_open` / `overdue_open` の予定支出。`future_open` は除外する。
- `residual`: `actual - plan`。支出が多ければ正、少なければ負。
- `status`: `"both"`, `"actual_only"`, `"plan_only"`, `"zero"`。

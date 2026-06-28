# REPORT_CONTRACTS

このドキュメントは、`bqn-ledger` の各レポートセクションが保証すべき「表示項目の契約」を定義します。
表示名や順序の変更は許容されますが、契約に含まれる項目を削除してはいけません。

## 全体原則

- すべてのレポート値は、可能な限り `report_numbers.tsv` に含まれる canonical な数値と一致させる。
- 計算式は `docs/CANONICAL_FORMULAS.md` に従う。
- 機械向け export と人間向け表示の乖離は `tools/check-human-consistency.sh` で防ぐ。

---

## 1. 全体サマリ (Snapshot)

目的: 現在の財政状態の最高位サマリ。

### 必須項目
- **流動資産 (liquid_assets_today)**: `type=liquid` の実効残高合計。
- **貯金 (savings_assets_today)**: `type=savings` の残高合計。
- **投資 (investment_assets_today)**: `type=invest` の残高合計。
- **総資産合計 (assets_total)**: 上記の合計。
- **負債合計 (liabilities_total)**: すべての負債口座の合計。
- **純資産 (net_worth)**: `assets_total + liabilities_total`。

---

## 4. 今サイクル集計 (Cycle Summary)

目的: 現在のサイクル内での収支実績の把握。

### 必須項目
- **サイクル期間**: 開始日（inclusive）と終了日（exclusive）。
- **サイクル収入 (cycle_actual_income)**: サイクル内の `income:*` 発生合計。
- **サイクル支出 (cycle_actual_expense)**: サイクル内の `expenses:*` 発生合計。
- **サイクル収支 (cycle_actual_net)**: 収入 - 支出。

---

## 5. 封筒・予算残高 (Envelopes & Balances)

目的: 予算（封筒）の執行状況と健康診断。

### 必須項目
- **封筒名 (account)**: `accounts.tsv` で定義された予算名。
- **配賦額 (allocated)**: 今サイクルにその封筒へ割り当てられた総額。
- **消費額 (spent)**: 今サイクルにその封筒から消費された実実績合計。
- **残高 (balance)**: `allocated - spent`。
- **健康状態 (health_status)**: 残日数と平均消費ペースに基づく SAFE/WARN/SHORT 等のラベル。
- **未割当 (unallocated_buffer)**: `seedable_budget - sum(envelope_balances)`。
- **固定的義務予定 (fixed_obligation_reserve)**: `cashflow=fixed_obligation` がある場合、費用に混ぜず補助表示する。
- **次サイクル初日義務 (next_cycle_start_obligation_reserve)**: `cycle_end_exclusive` ちょうどの固定的義務がある場合、現在サイクルのreserveには混ぜず参考表示する。

---

## 9. 見通し・日割り (Outlook)

目的: 次の収入日までの「一日に使えるお金」の可視化。

### 必須項目
- **残日数 (cycle_days_left)**: `as_of` からサイクル終了日までの日数。
- **流動資産合計 (liquid_assets_today)**: Snapshot と一致させること。
- **日割り金額 (liquid_assets_daily)**: `(liquid + future_income) / days_left`。
- **安全日割り (safe_liquid_assets_daily)**: `(liquid + future_income - fixed_reserve) / days_left`。
- **固定的cashout日割り (cash_out_safe_liquid_assets_daily)**: `cashflow=fixed_obligation` がある場合、固定費に加えて固定的義務予定も控除した補助日割り。
- **封筒別日割り**: `envelope_balance / days_left`。

---

## 10. 日割り推移 (Daily Trend)

目的: 支出ペースの変動と、大きな下落の特定。

### 必須項目
- **日次流動資産推移**: サイクル開始から `as_of` までの日次残高。
- **日割り金額の推移**: `liquid_assets_daily` の日次変化。
- **下落 Top 10**: 前日比で大きく日割りが下がった日のリストと理由。

---

## 11. サイクル相談 (Cycle Consultation)

目的: 次サイクルに向けた予算余力の検討。

### 必須項目
- **予算原資 (seedable_budget)**: 次サイクルに配賦可能な最大額。
- **固定費予約 (fixed_plan_reserve)**: すでに確定している将来の固定費支出。
- **おすすめ配分**: 前サイクル実績や設定に基づく、次サイクルの配分案。
  - ※ これは `consultation` 扱いであり、canonical な数値ではない。

---

## 12. 予定・履行状況 (Plan & Verification)

目的: 宣言された予定と、それに対する実績の履行状態の追跡。

### 必須項目
- **全予定 (plan_all)**: `plan.tsv` で宣言されたすべての予定行。履行・未履行にかかわらず履歴観察（Residual）やブレ分析のために保持する。
- **未履行予定 (plan_open)**: `plan_all` のうち、`journal.tsv` に同一の `plan_id` を持つ実績行が存在しないもの。将来の資金ショート予測や未来見通し（Outlook）の計算に使用する。

### 判定・抽出規則 (第一規則)
- **plan_id による除外**: `journal.tsv` に同一の `plan_id` が記録されている `plan.tsv` 行は、履行済みとみなして `plan_open` から除外する。
- **日付の扱い**: 予定日と実績日がずれても、同一の `plan_id` であれば履行済みとして扱う。
- **plan_id なし予定の扱い（非常口）**:
  - 実データ `plan.tsv` では、原則としてすべての予定行に `plan_id` を付与する（運用の基本）。
  - BQNエンジン側は互換性および手動運用の非常口として `plan_id` なし予定も許容する。`plan_id` なしの場合は「予定日が `as_of` 以降（未来予定）であれば未履行（`plan_open`）」として扱うフォールバックロジックを維持する。

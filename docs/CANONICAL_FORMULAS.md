# CANONICAL_FORMULAS

この文書は `bqn-ledger` の **計算式の目録** です。

目的は、BQNを「生活相談AI」ではなく、封筒予算・流動資産・予定・実績の **正本数値エンジン（秤）** として固定することです。

Datalog側の `docs/REPORT_TERMS.md` が「用語の戸籍簿」なら、この文書は BQN側の「式の校正証明書」です。

---

## Status / Source layer

### status

- `canonical`: 正本レポート値として扱ってよい。
- `derived`: canonical input から導出される派生値。式が固定されていれば report number として使ってよい。
- `check`: 検算用。
- `consultation`: 相談用の仮計算。正本ではない。
- `historical`: 過去参考。
- `deprecated`: 現在は使わない。

### source_layer

- `actual`: `journal.tsv` 由来の実績レイヤー。
- `plan`: `plan.tsv` 由来の予定レイヤー。
- `budget`: `budget_alloc.tsv` と journal支出map 由来の予算レイヤー。
- `derived`: 複数 layer またはメタ情報からの派生。

---

## F001 liquid_assets

- **status**: `canonical`
- **source_layer**: `actual`
- **定義**: `as_of` 時点で使える流動資産の合計。
- **入力**:
  - `journal.tsv`
  - `accounts.tsv` の `type=liquid`
  - Canonical Daily Cube layer 0 (`actual`)
- **式**:

```text
liquid_assets(as_of) =
  sum(actual_balance(as_of, account))
  where account.type = liquid
```

- **含める**:
  - `assets:*` かつ `type=liquid` の残高
- **含めない**:
  - future income
  - planned spending
  - envelope allocation
  - savings / investment accounts
- **使用レポート**:
  - Snapshot
  - Outlook
  - Envelopes seed可能額
  - Cashflow mock
  - future canonical export: `canonical_snapshot.tsv`, `liquid_assets_summary.tsv`, `report_numbers.tsv`
- **使用してはいけない意味**:
  - 封筒残高として扱わない。
  - 予定控除後の安全残高として扱わない。

---

## F002 savings_assets

- **status**: `canonical`
- **source_layer**: `actual`
- **定義**: `as_of` 時点の貯金資産合計。
- **入力**:
  - `journal.tsv`
  - `accounts.tsv` の `type=savings`
- **式**:

```text
savings_assets(as_of) =
  sum(actual_balance(as_of, account))
  where account.type = savings
```

- **使用してはいけない意味**:
  - 日常生活費の流動資産に混ぜない。
  - daily/flex envelope の投入可能額として自動加算しない。

---

## F003 investment_assets

- **status**: `canonical`
- **source_layer**: `actual`
- **定義**: `as_of` 時点の投資資産合計。
- **入力**:
  - `journal.tsv`
  - `accounts.tsv` の `type=invest`
- **式**:

```text
investment_assets(as_of) =
  sum(actual_balance(as_of, account))
  where account.type = invest
```

- **使用してはいけない意味**:
  - 現在の生活費余力として扱わない。

---

## F004 net_worth

- **status**: `canonical`
- **source_layer**: `actual`
- **定義**: `as_of` 時点の純資産。
- **入力**:
  - asset balances
  - liability balances
- **式**:

```text
net_worth(as_of) =
  assets_total(as_of) + liabilities_total(as_of)
```

BQN内部では liability は負符号の account balance として扱われるため、表示時は符号に注意する。

- **使用してはいけない意味**:
  - 流動資産や生活費余力として扱わない。

---

## F010 envelope_allocated

- **status**: `canonical`
- **source_layer**: `budget`
- **定義**: 現在サイクル内で封筒へ配賦された額。
- **入力**:
  - `budget_alloc.tsv`
  - Canonical Daily Cube layer 3 (`budget_alloc_sum`)
  - cycle start / cycle end
- **式**:

```text
envelope_allocated(envelope, cycle, as_of) =
  budget_alloc_sum_balance(as_of, envelope)
  - budget_alloc_sum_balance(day_before(cycle_start), envelope)
```

- **使用レポート**:
  - Envelopes `allocated`
  - future canonical export: `envelope_summary.tsv`
- **使用してはいけない意味**:
  - 封筒残高として扱わない。
  - 実際に使った額として扱わない。

---

## F011 envelope_spent

- **status**: `canonical`
- **source_layer**: `budget`
- **定義**: 現在サイクル内で、該当封筒にmapされた実績支出額。
- **入力**:
  - `journal.tsv`
  - `accounts.tsv` の `expenses:* budget=...`
  - Canonical Daily Cube layer 2 (`budget`)
  - Canonical Daily Cube layer 3 (`budget_alloc_sum`)
- **式**:

```text
envelope_spent(envelope, cycle, as_of) =
  envelope_allocated(envelope, cycle, as_of)
  - envelope_budget_balance_delta(envelope, cycle, as_of)

where
  envelope_budget_balance_delta =
    budget_balance(as_of, envelope)
    - budget_balance(day_before(cycle_start), envelope)
```

- **意味**:
  - `budget_alloc` の移動は消費ではない。
  - journal実績支出が `accounts.tsv` の budget map により封筒消費として投影されたもの。
- **使用レポート**:
  - Envelopes `spent`
  - Pace Status
- **使用してはいけない意味**:
  - 予算配賦・予算回収を消費として数えない。
  - plan.tsv の予定支出を実績支出に混ぜない。

---

## F012 envelope_balance

- **status**: `canonical`
- **source_layer**: `budget`
- **定義**: `as_of` 時点の封筒残高。
- **入力**:
  - `budget_alloc.tsv`
  - `journal.tsv` の mapped spending
  - Canonical Daily Cube layer 2 (`budget`)
- **式**:

```text
envelope_balance(envelope, as_of) =
  budget_balance(as_of, envelope)
```

またはサイクル内説明として:

```text
envelope_balance =
  previous_balance
  + envelope_allocated
  - envelope_spent
```

- **使用レポート**:
  - Envelopes `balance`
  - Outlook 封筒予算 日割り
  - future canonical export: `envelope_summary.tsv`
- **使用してはいけない意味**:
  - `liquid_assets` と同一視しない。
  - `remaining` 単独名で使わない。

---

## F013 envelope_balance_total

- **status**: `derived`
- **source_layer**: `budget`
- **定義**: 表示対象封筒の残高合計。
- **入力**:
  - F012 `envelope_balance`
  - `accounts.tsv` の `budget_group`
- **式**:

```text
envelope_balance_total(as_of) =
  sum(envelope_balance(envelope, as_of))
  where envelope is reportable budget account
```

- **注意**:
  - BQNでは `budget:opening`, `budget:spent`, `budget:未割当` などの特殊口座は表示対象封筒から除外する場面がある。
  - どの集合を合計したかを export では明示する。

---

## F020 fixed_plan_reserve

- **status**: `derived`
- **source_layer**: `plan` + `actual`
- **定義**: 現在サイクル内の固定費予定のうち、まだ reserve しておくべき額。
- **入力**:
  - `plan.tsv`
  - `journal.tsv`
  - `accounts.tsv` の `spend_class=fixed`
  - cycle start / cycle end
- **式**:

```text
fixed_plan_reserve(as_of) =
  total_fixed_plan_in_cycle
  - fixed_actual_paid_in_cycle_until_as_of
```

- **使用レポート**:
  - Envelopes seed可能額
  - Daily Trend
  - Cashflow mock
- **使用してはいけない意味**:
  - 実際に銀行から消えた金額として扱わない。
  - variable envelope の消費額に混ぜない。

---

## F020A fixed_obligation_reserve / fixed_cash_out_reserve

- **status**: `derived`
- **source_layer**: `plan` + `actual`
- **定義**: 会計上は費用ではないが、現在サイクル内で生活資金から固定的に確保すべきキャッシュアウト予定。
- **入力**:
  - `plan.tsv` の `cashflow=fixed_obligation`
  - `journal.tsv` の `plan_id`（履行済み判定）
  - `accounts.tsv` の liquid 判定
  - cycle end
- **式**:

```text
fixed_obligation_reserve(as_of) =
  sum(amount for open plan rows where
      as_of <= plan.date < cycle_end_exclusive
      and from is liquid account
      and cashflow=fixed_obligation)

fixed_cash_out_reserve(as_of) =
  fixed_plan_reserve(as_of)
  + fixed_obligation_reserve(as_of)

next_cycle_start_obligation_reserve(as_of) =
  sum(amount for open plan rows where
      plan.date = cycle_end_exclusive
      and from is liquid account
      and cashflow=fixed_obligation)
```

`next_cycle_start_obligation_reserve` は現在サイクルの reserve には混ぜず、次サイクル初日（例: 収入日に即返済する予定）の参考表示に使う。

- **使用レポート**:
  - Envelopes seed可能額の補助表示
  - Outlook / Cashflow mock の補助日割り
  - export: `report_numbers.tsv`, `liquid_assets_summary.tsv`（非0時）
- **使用してはいけない意味**:
  - expense total に混ぜない。
  - 封筒消費として自動計上しない。

---

## F021 safe_liquid_assets

- **status**: `derived`
- **source_layer**: `actual` + `plan`
- **定義**: 流動資産から、残り固定費予定を控除した保守的な生活原資。
- **入力**:
  - F001 `liquid_assets`
  - F020 `fixed_plan_reserve`
- **式**:

```text
safe_liquid_assets(as_of) =
  liquid_assets(as_of)
  - fixed_plan_reserve(as_of)
```

- **使用レポート**:
  - Outlook safe daily
  - Cashflow mock
  - future export: `liquid_assets_summary.tsv`, `report_numbers.tsv`
- **使用してはいけない意味**:
  - 現在の銀行残高として表示しない。
  - 封筒残高と同一視しない。

---

## F021A cash_out_safe_liquid_assets

- **status**: `derived`
- **source_layer**: `actual` + `plan`
- **定義**: 流動資産から、固定費予定と固定的義務予定を控除した生活原資。
- **入力**:
  - F001 `liquid_assets`
  - F020 `fixed_plan_reserve`
  - F020A `fixed_obligation_reserve`
- **式**:

```text
cash_out_safe_liquid_assets(as_of) =
  liquid_assets(as_of)
  - fixed_plan_reserve(as_of)
  - fixed_obligation_reserve(as_of)
```

- **使用レポート**:
  - Cashflow mock
  - future export: `liquid_assets_summary.tsv`, `report_numbers.tsv`（非0時）
- **使用してはいけない意味**:
  - 現在の銀行残高として表示しない。
  - 借金元本返済を費用化する根拠にしない。

---

## F022 seedable_budget

- **status**: `derived`
- **source_layer**: `actual` + `plan`
- **定義**: daily/flex/reserve などの封筒へ投入可能な上限として使う保守的な原資。
- **入力**:
  - F001 `liquid_assets`
  - F020 `fixed_plan_reserve`
  - cycle内 future income（現行では通常 0）
- **式**:

```text
seedable_budget(as_of) =
  liquid_assets(as_of)
  + planned_future_income_in_cycle(as_of)
  - fixed_plan_reserve(as_of)
```

- **使用レポート**:
  - Envelopes `[封筒 seed 可能額]`
  - Cashflow mock
  - future export: `report_numbers.tsv`
- **使用してはいけない意味**:
  - 実績残高そのものではない。
  - 新しい予算案を自動で正本化する根拠にしない。

---

## F023 unallocated_buffer

- **status**: `derived`
- **source_layer**: `actual` + `plan` + `budget`
- **定義**: seed可能額のうち、現在表示対象封筒の残高として拘束されていない余白。
- **入力**:
  - F022 `seedable_budget`
  - F013 `envelope_balance_total`
- **式**:

```text
unallocated_buffer(as_of) =
  seedable_budget(as_of)
  - envelope_balance_total(as_of)
```

- **重要**:
  - これは BQN report 上の asset-based derived value。
  - raw `budget:未割当` ledger balance と一致するよう管理するのが望ましいが、式としては seed可能額から導出する。
- **使用レポート**:
  - Envelopes `端数の未割り当て`
  - Outlook `budget:未割当` 表示
  - future export: `report_numbers.tsv`
- **使用してはいけない意味**:
  - consultation arithmetic の remainder と混同しない。
  - safety_buffer と呼ばない。
  - 実際の bank balance として扱わない。

---

## F030 planned_expense_remaining_in_cycle

- **status**: `derived`
- **source_layer**: `plan`
- **定義**: `as_of` 以降、現在サイクル終了前までに予定されている支出合計。
- **入力**:
  - `plan.tsv`
  - cycle start / cycle end
  - `as_of`
- **式**:

```text
planned_expense_remaining_in_cycle(as_of) =
  sum(plan.amount)
  where plan.to starts_with "expenses:"
    and as_of <= plan.date < cycle_end_exclusive
```

- **使用レポート**:
  - Planned Payments
  - Cycle Consultation
  - Cashflow mock
- **使用してはいけない意味**:
  - actual expense に混ぜない。
  - 決済済み予定と未決済予定を混ぜる場合は注記する。

---

## F031 planned_income_remaining_in_cycle

- **status**: `derived`
- **source_layer**: `plan`
- **定義**: `as_of` 以降、現在サイクル終了前までに予定されている収入合計。
- **式**:

```text
planned_income_remaining_in_cycle(as_of) =
  sum(plan.amount)
  where plan.from starts_with "income:"
    and as_of <= plan.date < cycle_end_exclusive
```

- **使用してはいけない意味**:
  - 実績収入として扱わない。
  - 予定収入依存の生活可能額を canonical actual として扱わない。

---

## F040 cycle_actual_income

- **status**: `canonical`
- **source_layer**: `actual`
- **定義**: 現在サイクル内の実績収入合計。
- **式**:

```text
cycle_actual_income(cycle) =
  sum(journal.amount)
  where journal.from starts_with "income:"
    and cycle_start <= journal.date < cycle_end_exclusive
```

- **使用レポート**:
  - Cycle Summary
  - Cycle Consultation recorded actuals

---

## F041 cycle_actual_expense

- **status**: `canonical`
- **source_layer**: `actual`
- **定義**: 現在サイクル内の実績支出合計。
- **式**:

```text
cycle_actual_expense(cycle) =
  sum(journal.amount)
  where journal.to starts_with "expenses:"
    and cycle_start <= journal.date < cycle_end_exclusive
```

- **使用レポート**:
  - Cycle Summary
  - Cycle Consultation recorded actuals
- **使用してはいけない意味**:
  - plan支出を含めない。

---

## F042 cycle_actual_net

- **status**: `canonical`
- **source_layer**: `actual`
- **定義**: 現在サイクル内の実績収支。
- **式**:

```text
cycle_actual_net =
  cycle_actual_income
  - cycle_actual_expense
```

- **注意**:
  - サイクル終了時の残額予測ではない。
  - 基準日以降の予定支出や未入力取引で変わる。

---

## F050 remaining_days

- **status**: `derived`
- **source_layer**: `derived`
- **定義**: `as_of` から cycle end exclusive までの残日数。
- **式**:

```text
remaining_days(as_of) =
  max(0, days_between(as_of, cycle_end_exclusive))
```

- **使用レポート**:
  - Outlook
  - Envelopes
  - Daily Trend
  - Cashflow mock
- **使用してはいけない意味**:
  - days_until_empty と混同しない。
  - `remaining` 単独名で使わない。

---

## F060 envelope_actual_daily

- **status**: `derived`
- **source_layer**: `budget`
- **定義**: サイクル開始日から `as_of` までの純消費額ベースの日平均。
- **式**:

```text
envelope_actual_daily(envelope, as_of) =
  floor(max(0, envelope_spent(envelope)) / elapsed_days)

where
  elapsed_days = max(0, as_of - cycle_start + 1)
```

- **使用レポート**:
  - Envelopes `avg/day`
  - Cashflow mock warning
- **使用してはいけない意味**:
  - 直近3日平均ではない。
  - budget allocation / budget回収を消費として数えない。

---

## F061 envelope_target_daily

- **status**: `derived`
- **source_layer**: `budget`
- **定義**: 封筒配賦額をサイクル全日数で割った目標日割り。
- **式**:

```text
envelope_target_daily(envelope) =
  floor(envelope_allocated(envelope) / cycle_total_days)

where
  cycle_total_days = max(1, days_between(cycle_start, cycle_end_exclusive))
```

- **使用レポート**:
  - Pace Status
  - future export: `envelope_summary.tsv`

---

## F062 pace_status

- **status**: `derived`
- **source_layer**: `budget`
- **定義**: 封筒の実消費ペースを目標日割りと比較した健康状態。
- **入力**:
  - F060 `envelope_actual_daily`
  - F061 `envelope_target_daily`
  - `accounts.tsv` の `budget_group`
- **式**:

```text
if budget_group = reserve:
  DONE
else if envelope_actual_daily >= floor(1.5 * envelope_target_daily):
  SHORT
else if envelope_actual_daily > envelope_target_daily:
  WARN
else:
  SAFE
```

BQN実装では整数計算の都合上、`1.5 * target` 相当を `floor(1.5×target)` として扱う。

- **表示意味**:
  - `SAFE`: ペース通り、または目標以下。
  - `WARN`: 目標より早いが、SHORT閾値未満。
  - `SHORT`: 目標日割りの1.5倍以上で危険。
  - `DONE`: reserve系。貯金・投資など使い切って（移動して）正解のカテゴリ。
- **使用レポート**:
  - Envelopes `health`
  - Cashflow mock `[封筒警戒]`
- **使用してはいけない意味**:
  - 正本残高ではない。
  - 生活判断の最終結論ではなく、表示用の derived signal。

---

## F070 days_until_empty

- **status**: `derived`
- **source_layer**: `budget`
- **定義**: 現在の封筒残高が、現在の消費ペースで何日持つか。
- **式**:

```text
days_until_empty(envelope) =
  if envelope_actual_daily = 0:
    999
  else:
    floor((envelope_balance + future_planned_envelope_updates) / envelope_actual_daily)
```

- **現在の位置づけ**:
  - 旧 `SHORT` 判定の中心だったが、現在の health 表示は F062 `pace_status` を使う。
  - debug / supplementary value としては利用可能。
- **使用してはいけない意味**:
  - `SHORT` の唯一の判定基準にしない。
  - reserve系の正常な移動を危険判定に使わない。

---

## F080 report_number

- **status**: `canonical` または `derived`
- **source_layer**: mixed
- **定義**: Datalog / AI / tests が参照するための機械向け正本サマリ。
- **出力予定**:

```tsv
key	value	source_layer	status	formula_id	note
```

- **ルール**:
  - `formula_id` はこの文書の Fxxx に対応させる。
  - consultation value は `status=consultation` と明記する。
  - 人間向け表示名が変わっても `key` は安定させる。

---

## Consultation values are not canonical

以下はBQN core の正本式に混ぜない。

- 次サイクルのおすすめ配分
- 食費を増やすべきかどうか
- 余ったら貯金すべきか
- 安全余白はいくらがよいか
- 行動改善アドバイス

BQNが出すのは、現在の数字・予定込みの数字・封筒別残額・残日数・過去実績まで。
判断・相談は外側の report / Datalog / AI に逃がす。

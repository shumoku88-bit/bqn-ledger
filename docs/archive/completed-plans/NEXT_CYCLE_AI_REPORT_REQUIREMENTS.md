# Next Cycle AI Consultation Report Requirements

Status: operation quarantine / deletion candidate. 数日運用して、AI次サイクル相談 export を残すか、削除またはarchiveするか判断する。判断基準は `docs/REPORT_DESIGN.md` の「レポート削除候補 / 数日運用して判断」を参照。

## 目的

このレポートは、人間向けの見栄えのよい表示ではなく、AI（pit）が次サイクルの予算配分案を作るために参照する **機械向け根拠レポート** である。

AIに相談したいこと:

- 次サイクルの封筒配分案を作る
- 固定支出以外の支出に対して、無理のない封筒配分を提案する
- 固定支出・貯金・投資を封筒配分と混ぜない
- 直近1サイクル分の実績支出を根拠として、増減理由を説明する
- 不確定要素や警告を明示する

## 非目的

このレポートは以下をしない。

- `journal.tsv` / `plan.tsv` / `budget_alloc.tsv` / `accounts.tsv` を書き換えない
- 自動で `budget_alloc.tsv` に配分行を追加しない
- AIの提案を正解として扱わない
- 税務判断をしない
- 初期版では `recur` メタを自動展開しない

## 出力方針

初期実装は、機械向けTSVを stdout に出す読み取り専用ツールとする。

```text
tools/export-next-cycle.bqn
```

推奨フォーマット:

```tsv
table	key1	key2	value	note
context	next_cycle_start		2026-06-15	inclusive
funding	available_seed_budget		106830	liquid-only, excludes savings/investment
expense_evidence	expenses:食費	actual_daily	584	journal actual in history cycle
warning	policy		Do not use savings/investment balances as envelope funding	
```

理由:

- AIへ貼りやすい
- TSV Source of Truth / export 系の思想と合う
- `main.bqn` の人間向け表示を汚さない
- 後から `main.bqn --section next-cycle` に展開しやすい

## サイクル境界ルール

内部計算は半開区間を使う。

```text
start <= date < end_exclusive
```

次サイクルは次のように定義する。

```text
next_cycle_start = current_cycle_end_exclusive
next_cycle_end_exclusive = next income anchor after next_cycle_start
```

例:

```text
現サイクル表示: 2026-04-15〜2026-06-14
次サイクル開始: 2026-06-15
```

この場合、`2026-06-15` の収入・支出はすべて次サイクルに含める。

```text
next_cycle_start <= date < next_cycle_end_exclusive
```

現在サイクルの残り予定は初期版では次を使う。

```text
as_of <= plan_date < next_cycle_start
```

注意:

- as_of 当日の予定は、まだ実行される可能性があるため含める
- plan が journal へ移行済みでも残っている場合は二重に見える可能性があるため warning を出す

## 封筒配分対象

封筒配分の相談対象は **固定支出以外の支出すべて** とする。

初期実装の判定:

```text
expense account where spend_class=variable
```

除外するもの:

- `spend_class=fixed` の固定支出
- 貯金
- 投資
- 資産間移動
- 封筒ではない負債・資産調整

`spend_class` が未設定の `expenses:*` は、勝手に含めず warning に出す。

## 貯金・投資の扱い

封筒予算と貯金・投資は別管理である。

方針:

```text
available_seed_budget は流動資産ベースで計算する。
貯金・投資残高を封筒原資として使わない。
```

理由:

- 貯金・投資から実際に封筒へ詰め替えるには手続きと時間がかかる
- 日常の封筒配分に使える即時資金とは性質が違う

AI向け policy / warning に必ず含める。

```text
Do not use savings/investment balances as envelope funding.
```

## 履歴根拠

封筒消費 (`budget` layer) ではなく、`journal.tsv` の実績支出を根拠にする。

履歴期間は **直近1サイクル分の該当支出** とする。

基本範囲:

```text
history_cycle_start = current_cycle_start
history_cycle_end_exclusive = current_cycle_end_exclusive
```

観測できる実績は `as_of` までなので、実績集計では次を使う。

```text
history_cycle_start <= journal_date <= as_of
journal_date < current_cycle_end_exclusive
```

レポートには、サイクル全体の範囲と、実際に観測できている範囲を分けて出す。

例:

```tsv
context	history_cycle_start		2026-04-15	inclusive
context	history_cycle_end_exclusive		2026-06-15	exclusive
context	history_observed_end		2026-06-13	as_of
context	history_observed_days		60	actual evidence window
```

## 必須テーブル

### 1. `context`

AIが期間を誤解しないための前提。

必須項目:

- `as_of`
- `current_cycle_start`
- `current_cycle_end_exclusive`
- `current_cycle_last_day`
- `next_cycle_start`
- `next_cycle_end_exclusive`
- `next_cycle_last_day`
- `next_cycle_days`
- `history_cycle_start`
- `history_cycle_end_exclusive`
- `history_observed_end`
- `history_observed_days`

### 2. `funding`

次サイクルに配れる原資。

必須項目:

- `current_liquid_today`
- `remaining_current_cycle_plan`
- `projected_carryover_at_start`
- `planned_income_total`
- `planned_fixed_expenses`
- `available_seed_budget`
- `base_daily_allowance`

計算:

```text
projected_carryover_at_start
= current_liquid_today + remaining_current_cycle_plan

available_seed_budget
= projected_carryover_at_start + planned_income_total - planned_fixed_expenses

base_daily_allowance
= floor(available_seed_budget / next_cycle_days)
```

注意:

- `planned_fixed_expenses` は固定支出のみ
- 貯金・投資は封筒原資に含めない
- 次サイクル収入予定が見つからない場合は warning を出す

### 3. `fixed_breakdown`

次サイクル内の固定支出予定一覧。

項目:

- `date`
- `memo`
- `account`
- `amount`
- `note/meta`

目的:

- AIが `planned_fixed_expenses` の根拠を確認できるようにする
- 重複や見積もりを warning に繋げる

### 4. `expense_evidence`

固定支出以外の支出科目ごとの配分根拠。

対象:

```text
journal.tsv の expenses:* 行
かつ account meta spend_class=variable
かつ history window 内
```

項目:

- `expense_account`
- `budget_name`（`accounts.tsv` の `budget=...` があれば）
- `spent_total`
- `history_observed_days`
- `actual_daily`
- `current_budget_balance`（可能なら）
- `suggestion_hint`（初期版では任意）

例:

```tsv
expense_evidence	expenses:食費	spent_total	35021	journal actual in history cycle
expense_evidence	expenses:食費	actual_daily	584	spent_total / history_observed_days
expense_evidence	expenses:食費	budget_name	daily	account meta budget=...
```

### 5. `warning`

AIが必ず読むべき注意。

初期版で必須の warning / policy:

- `Do not modify TSV files.`
- `Do not exceed available_seed_budget.`
- `Do not use savings/investment balances as envelope funding.`
- `Fixed expenses are reserved before ordinary envelope allocation.`
- `recur meta is not expanded in the initial version.`
- `remaining_current_cycle_plan includes as_of date plans and may double count if plan rows were already journaled.`

条件付き warning:

- 次サイクル収入予定がない
- 次サイクル終了が未確定
- `expenses:*` に `spend_class` がない
- `spend_class=variable` に `budget=` がない
- 固定支出予定が重複している可能性
- 履歴日数が少ない

## 実装方針

初期実装:

```text
tools/export-next-cycle.bqn
```

- 読み取り専用
- `report_engine.BuildAt` の結果を使う
- TSVを stdout に出す
- 実データTSVは変更しない
- `./tools/check.sh` に追加する
- 可能なら fixture で境界テストを追加する

将来拡張:

- `main.bqn --section next-cycle`
- `records/ai-consultations/YYYY-MM-DD-next-cycle.md`
- AI提案を `budget_alloc.tsv` 候補行として dry-run 生成

## 決定済み事項まとめ

- 次サイクルは `next_cycle_start <= date < next_cycle_end_exclusive`
- `next_cycle_start` 当日の収入・支出はすべて次サイクルに含める
- 現在サイクル残り予定は `as_of <= plan_date < next_cycle_start`
- 封筒予算と貯金・投資は別
- 貯金・投資は封筒原資にしない
- 封筒配分相談対象は固定支出以外の支出すべて
- 初期実装では `spend_class=variable` を対象にする
- 履歴根拠は直近1サイクル分の `journal.tsv` 実績支出
- 封筒消費ではなく、実績支出 journal を evidence に使う
- 出力はまず `tools/export-next-cycle.bqn` の機械向けTSV

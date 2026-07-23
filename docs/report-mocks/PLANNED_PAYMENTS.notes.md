# Planned Payments Mock Notes

Status: **adopted**
Review state: `adopted`
Date: 2026-06-26
Adopted: 2026-06-26

## Question answered

予定支払いは未来・今日・期限超過・完了のどれか。

## View type

```text
plan tracking (cycle-bounded)
```

今サイクル内の予定支払いがどこまで進んでいるか。支払い漏れや期限超過を検出するための画面。

## Relationship to other screens

- **Current Cycle Summary**: 予定支出(残) の合計値はここから来る。Planned Payments はその明細。
- **Envelope / Budget**: 未了の予定支出がどの封筒に影響するかの関連あり。

## Intended source when implemented

```text
plan.tsv → future/overdue/due entries in current cycle
configured native Journal → completed entries matched by plan_id
```

## Include

- 未了の支払い一覧（日付順）
- 完了済み支払い（直近のみ、または全件）
- 未了合計額
- ステータス: future / due / overdue / completed

## Exclude for now

- サイクル外の予定
- 収入予定（plan に income として入っているもの）
- 金額の増減比較（計画vs実績の差異）

## Review decisions (2026-06-26)

1. Category → 内部キーから prefix を剥がす（expenses:AIサブスク → AIサブスク） ✓
2. 未了/完了 → 分割 ✓
3. 未了合計 → 表示する ✓
4. ソート順 → 日付順 ✓
5. due / overdue → 区別する（future / due / overdue / completed） ✓
6. 完了済み表示数 → 全件 ✓

## Review questions (pending)

なし

## Decision log

```text
review_state: adopted
human_decision: adopted 2026-06-26
notes: Category=prefix剥がし, 未了/完了分割, 未了合計あり, due/overdue区別, 完了全件
```

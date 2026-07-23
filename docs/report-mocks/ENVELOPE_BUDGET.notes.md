# Envelope / Budget Mock Notes

Status: **adopted**
Review state: `adopted`
Date: 2026-06-26
Adopted: 2026-06-26

## Question answered

封筒ごとの allocated / spent / remaining / pace はどうか。

## View type

```text
budget tracking (envelope method)
```

封筒方式の家計管理におけるコア画面。各封筒（予算区分）にいくら割り当てて、いくら使い、あとどれだけ残っているか、ペースは適正か。

## Relationship to other screens

- **Account Balances**: stock view。budget account の残高も出るが、使途別の内訳はない。
- **Current Cycle Summary**: flow view。総額の収入・支出は見るが、封筒別の予算消化ペースは見ない。
- **Planned Payments**: 未来の支出予定と封筒残高の関係（特に flex 封筒で関連）。

## Intended source when implemented

```text
budget_alloc.tsv → allocated amounts (cycle-bounded)
configured native Journal actual layer → spent per envelope
plan.tsv plan layer → future planned spending
```

## Include

- Envelope groups (daily / flex / reserve)
- Per-envelope: allocated, spent, balance, avg/day, health
- Health status legend

## Exclude for now

- 前サイクルとの比較
- 年間トレンド
- 「あと何日もつか」予測
- アドバイス文言

## Review decisions (2026-06-26)

1. daily / flex / reserve の3グループ構造 → adopted
2. health 表記: SAFE/WARN/SHORT → adopted
3. avg/day 列 → adopted
4. 使った割合（%）→ adopted（spent/allocated %、列名 `%`）
5. 「残日数から見た1日あたりの許容支出」→ no（別画面の残日数と balance で逆算可能）
6. reserve の DRAWN 強調表示 → deferred（必要になったら検討）

## Decision log

```text
review_state: adopted
human_decision: adopted with revisions (added % column, declined remaining daily allowance)
notes: % column added (spent/allocated). Remaining daily allowance not included — can be derived from balance ÷ remaining days (shown on Current Cycle Summary).
```

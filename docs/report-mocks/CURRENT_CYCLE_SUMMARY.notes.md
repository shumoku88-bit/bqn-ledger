# Current Cycle Summary Mock Notes

Status: **adopted (tentative)**
Review state: `adopted`
Date: 2026-06-26
Adopted: 2026-06-26

## Question answered

今サイクルの収入・支出・収支・予定支出残はどうか。

## View type

```text
period flow (cycle-bounded income/expense statement)
```

This is the core daily-check screen: "今サイクル、収支は大丈夫か。"

- `Account Balances`: ある時点で account にいくら残っているか（stock）
- `Current Cycle Summary`: 今サイクルでいくら入って、いくら出て、あといくら予定があるか（flow）

## Intended source when implemented

```text
TBDS actual layer → income/expense amounts within current cycle boundary
TBDS plan layer → remaining planned expenses within cycle
```

## Include

- Cycle date range (start〜end_exclusive)
- Days remaining in cycle
- 収入合計 (actual income in this cycle)
- 支出合計 (actual expense in this cycle)
- 収支 (net)
- 予定支出(残) (plan expense not yet incurred this cycle)
- 支出内訳 by account (amount descending)

## Exclude for now

- 前期との比較 (belongs to Actual Comparison)
- 日割り計算 (belongs to Outlook / Daily Amount)
- アドバイステキスト (「このペースなら〜」等)
- サイクル外の取引
- YTD 累計 (belongs to YTD Summary)

## Relationship to other screens

- **Account Balances**: stock, not flow. 補完関係。
- **Expense Breakdown**: この画面の支出内訳部分をより詳細にしたもの。統合も検討可。
- **Envelope / Budget**: 封筒レベルでの予算管理。Cycle Summary は account レベル。
- **Outlook / Daily Amount**: 残日数×予定の日割り。Cycle Summary の「予定支出(残)」と密接。

## Review decisions (in progress)

1. 「あとN日」→ 表示する ✓
2. 収支がプラスの場合の意味づけ → しない（事実表示のみ） ✓
3. 支出内訳のソート順: 金額降順 ✓
4. 金額 0 の行 → 非表示 ✓
5. 収入内訳 → 表示する ✓
6. 負債返済（liabilities: への outflow）→ 支出内訳に含める ✓

## Review questions (pending)

なし（Expense Breakdown はこの画面に統合）

## Decision log

```text
review_state: adopted (tentative)
human_decision: adopted with pending items
notes: approved 2026-06-26. Pending: 日割り表示, Expense Breakdown merge.
```

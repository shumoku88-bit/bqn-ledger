# Recent Journal Mock Notes

Status: **adopted**
Review state: `adopted`
Date: 2026-06-26
Adopted: 2026-06-26

## Question answered

直近に何を記帳したか。

## View type

```text
activity log (newest first)
```

単純な活動履歴。家計簿の一番基本。「さっき何買ったっけ」「最後に記帳したのいつだっけ」に答える。

## Relationship to other screens

- **Account Balances**: この journal 行の積み重ねが残高になる
- **Current Cycle Summary**: この journal 行から集計される
- **Planned Payments**: plan と journal のマッチング

## Intended source when implemented

```text
journal.tsv → newest N rows (all-time or cycle-bounded)
```

## Include

- 日付（降順）
- From / To（表示ラベル）
- Memo
- Amount

## Exclude for now

- フィルタリング（勘定科目別など）
- 検索
- 編集導線（TUI で後付け）

## Review decisions (2026-06-26)

1. 表示件数 → 10件（後から調整可） ✓
2. From/To → prefix 剥がし ✓
3. txn_id → 表示する ✓

## Review questions (pending)

なし

## Decision log

```text
review_state: adopted
human_decision: adopted 2026-06-26
notes: 10件, prefix剥がし, txn_id表示。件数は後から調整可。
```

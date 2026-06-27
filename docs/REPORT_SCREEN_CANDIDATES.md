# Report Screen Candidates

Status: **candidate inventory / not adoption record**
Date: 2026-06-26

## Purpose

`bqn-ledger` / `src_next` の report screen 候補を洗い出すための一覧です。

この文書は「採用済み画面一覧」ではありません。各 screen は `docs/report-mocks/*.mock.txt` を作成し、人間が terminal 表示を確認してから採用・修正・不採用を決めます。

Review process: `docs/REPORT_SCREEN_REVIEW_LOOP.md`

## Principle

画面数を 12 個や 13 個に固定しません。

必要な問いから screen を決めます。

```text
question first
  -> screen candidate
  -> mock
  -> review
  -> adopt / revise / reject
```

## Important distinction

`Account Balances` と `YTD Summary` は別物です。

```text
Account Balances:
  point-in-time stock view
  ある時点で各 account にいくら残っているか

YTD Summary:
  period movement / flow view
  年初から今までにいくら動いたか
```

## Candidate groups

### Daily / operational candidates

| Candidate | Question | Initial state |
|---|---|---|
| Account Balances | 各 account key の現在残高はいくらか | adopted |
| ~~Balance Summary~~ | ~~流動資産・貯金・投資・負債・純資産はいくらか~~ | rejected（Account Balances の totals でカバー） |
| Current Cycle Summary | 今サイクルの収入・支出・収支・予定支出残はどうか | adopted |
| ~~Expense Breakdown~~ | ~~今サイクルで何に使ったか~~ | rejected（Current Cycle Summary で十分） |
| Envelope / Budget | 封筒ごとの allocated / spent / remaining / pace はどうか | adopted |
| Planned Payments | 予定支払いは未来・今日・期限超過・完了のどれか | adopted |
| Recent Journal | 直近に何を記帳したか | adopted |
| Outlook / Daily Amount | 残日数と予定を踏まえた日割りはいくらか | adopted |

### Observation / comparison candidates

| Candidate | Question | Initial state |
|---|---|---|
| Daily Trend | 日ごとの流動資産・reserve・日割り・支出はどう動いたか | adopted |
| Actual Comparison | 前サイクル同時点と比べて何が増減したか | adopted |
| YTD Summary | 年初来の収入・支出・収支・固定費/変動費累計はどうか | adopted |

### Diagnostic / accounting candidates

| Candidate | Question | Initial state |
|---|---|---|
| Readiness Check | 入力・metadata・予定/実績の状態は信頼できるか | adopted |
| Trial Balance / Accounting Check | TBDS の opening / movement / closing と zero-sum は成立するか | adopted |

## Possible future candidates

これらはすぐ作る候補ではありません。必要性がはっきりしたら mock を作ります。

| Candidate | Question |
|---|---|
| Food Pressure | 食費残高・残日数・最近平均から、食費の圧力はどうか |
| Cashflow Calendar | 日付順に予定・実績・残高影響を見ると何が起きるか |
| Plan vs Actual | 予定と実績はどれだけズレたか |
| Account Movement | 各 account の opening / increase / decrease / closing はどうか |
| Source Row Audit | TSV 行レベルの問題はどこにあるか |
| Reserve / Savings Protection | reserve / savings / investment は守られているか |

## Adoption record

採用判断はこの文書へ直接書き込まず、各 `*.notes.md` に記録します。

Example:

```text
docs/report-mocks/ACCOUNT_BALANCES.notes.md
review_state: pending_review
```

採用済み screen が増えたら、別途 `docs/REPORT_SCREEN_ADOPTION_RECORD.md` を作成してもよいです。

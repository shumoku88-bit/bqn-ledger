# Report Screen Review Loop

Status: **completed（mock review phase）**
Date: 2026-06-26
Completed: 2026-06-26

## Purpose

`src_next` の report screen / report lens を、一つずつ terminal mock として確認し、採用・不採用・修正を決めるための運用ルールです。

この計画は、13 個または 12 個の report screen を一括で完成させる計画ではありません。

## Core idea

```text
one screen mock
  -> human review
  -> adopt / revise / reject
  -> record decision
  -> next screen
```

一度に全画面を作らない。画面ごとに、実際の terminal 表示を見てから判断します。

## Why this exists

現在の `src_next/report.bqn` は複数の section を順番に表示しますが、各 section の完成度・目的・日常利用価値が混在しています。

そのため、まず terminal mock で以下を確認します。

- この画面は本当に必要か
- 何を問う画面なのか
- 情報量は多すぎないか
- 他画面と統合すべきか、独立させるべきか
- default report に出すべきか、optional / diagnostic に回すべきか

## Non-goals

- 一括で 13 screen mock を作らない
- mock を production report に接続しない
- real calculation をこの段階で実装しない
- `data/*.tsv` を編集しない
- 生活アドバイスを canonical numeric output に混ぜない
- old engine removal 作業と混ぜて code migration を始めない

## Directory convention

```text
docs/report-mocks/
  README.md
  ACCOUNT_BALANCES.mock.txt
  ACCOUNT_BALANCES.notes.md
```

各 mock は必ずペアで作ります。

| File | Role |
|---|---|
| `*.mock.txt` | terminal output の静的モック |
| `*.notes.md` | 目的、問い、表示項目、非表示項目、review 状態 |

## Review states

| State | Meaning |
|---|---|
| `pending_review` | mock 作成済み、人間確認待ち |
| `adopted` | この画面を正式候補として採用 |
| `revise` | 方針は残すが表示・項目を修正 |
| `rejected` | この画面は採用しない |
| `merged_into_other_screen` | 独立画面にせず別画面へ統合 |
| `deferred` | 必要かもしれないが今は後回し |

## Review checklist for each screen

各 screen について、確認時に以下を見る。

1. この画面が答える問いは明確か
2. 今の生活・会計確認に本当に必要か
3. 表示項目は多すぎないか
4. その数字は stock / flow / forecast / diagnostic のどれか
5. 他 screen と重複しすぎていないか
6. default report に出すか、optional / diagnostic に回すか
7. 実装する場合、source data を新しく要求するか
8. fixture / check は何で守るか

## First screen

最初に review する screen は `Account Balances` です。

理由:

- 各 account key の現在残高は、家計簿として最初に必要な観測値
- これは YTD summary ではなく point-in-time balance / stock view
- `Balance Summary` や `YTD Summary` との責務分離を最初に確認できる

Files:

```text
docs/report-mocks/ACCOUNT_BALANCES.mock.txt
docs/report-mocks/ACCOUNT_BALANCES.notes.md
```

## Candidate list

候補一覧は `docs/REPORT_SCREEN_CANDIDATES.md` に置きます。

ただし、候補一覧は採用済み一覧ではありません。採用するには個別 mock review が必要です。

## Acceptance criteria for this docs-only setup

- Review loop が docs として明文化されている
- Candidate list がある
- Mock storage directory がある
- First mock (`Account Balances`) がある
- `docs/README.md` から導線がある
- `data/*.tsv` を触らない

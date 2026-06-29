# src_next 現在地メモ

Status: **historical / superseded by `docs/SRC_NEXT_CURRENT.md`**

> 現在の `src_next` 普段使い入口は `docs/SRC_NEXT_CURRENT.md` を正とします。
> この文書内の「production default は `bqn main.bqn`」「Stage 4b 未開始」などの記述は移行期の履歴です。

この文書は、英語の `src_next` readiness docs を読む前に、当時の現在地を日本語で確認するための入口でした。

英語 docs は AI 作業員・GitHub・将来の保守向けの契約書として扱います。この文書は、日々の運用で迷わないための日本語ガイドです。

## 1. いまの結論

- production default はまだ `bqn main.bqn` です。
- `tools/report-next` は次期 ledger engine candidate を明示的に実行する validation entrypoint です。
- `src_next` は default switch 前の production-candidate path として扱います。
- Stage 1 / Stage 2 / Stage 3 は完了しています。
- Stage 4b validation run はまだ開始していません。現在は start decision 前の条件整理中です。
- Stage 5 default switch はまだ許可されていません。
- 実データの金額や生活判断メモは public repo に書きません。
- `food` / `daily` / `safe` / `allocated remaining` はまだ実装しません。
- `budget_group=` は production data にまだ追加しません。
- Stage 4b を始めるには、別の明示的な start decision が必要です。

## 2. 普段信じるコマンド

生活判断に使う trusted path は、default switch まで引き続き current production です。

```sh
bqn main.bqn
```

`src_next` は default switch 前の検証対象です。

```sh
tools/report-next
```

`tools/report-next` は `src_next` を明示的に呼ぶ validation wrapper です。これを実行しても `bqn main.bqn` の意味は変わりません。

## 3. いま進んでいる Stage

| stage | 状態 | 意味 |
|---|---|---|
| Stage 1: shadow run | 完了 | `src_next` が production data で fatal error なく走る |
| Stage 2: comparison output | 完了 | 比較可能な基本フィールドは current engine と一致済み |
| Stage 3: optional entrypoint | 完了 | `tools/report-next` から明示的に `src_next` を実行できる |
| Stage 4b: validation run | 未開始 | 別の明示的な start decision 後に、default switch 前の candidate として少なくとも1 full cycle 検証する |
| Stage 5: default switch | 禁止中 | `bqn main.bqn` を `src_next` に切り替える段階ではない |

## 4. Stage 4 でやること

Stage 4b を始める前に、validation docs で条件と記録場所を整理します。

- `bqn main.bqn` が production default のままであることを確認する。
- `tools/report-next` / `src_next` は default switch 前の validation path として扱う。
- Stage 4b を開始した場合の private log path は `docs/SRC_NEXT_STAGE4B_DAILY_USE_TRIAL_LOG_POLICY.md` で定義する。
- 差分は readiness docs の分類に従って整理する。
- 別の明示的な start decision なしに validation run 開始と書かない。

## 5. Stage 4 でやらないこと

- `main.bqn` を `src_next` に切り替えない。
- `tools/report-next` を production command にしない。
- `tools/check.sh` に `tools/report-next` を急いで組み込まない。
- TSV format を変えない。
- production data を検証途中で急いで直さない。
- fixtures / golden outputs を目的なく変更しない。
- `food` / `daily` / `safe` / `allocated remaining` を勢いで実装しない。
- `daily` / `flex` / `reserve` を engine concept として hard-code しない。

## 6. private log に置くもの

実データの金額や生活判断メモは public repo に入れません。

Future Stage 4b validation log path:

```text
private/src-next-validation/validation-log.md
```

この path は private-only です。この文書は path を案内するだけで、Stage 4b を開始しません。

private/local log に置くもの:

- 実際の金額。
- 日々の検証値。
- 生活判断に影響したかどうかのメモ。
- `bqn main.bqn` と `tools/report-next` の具体的な差分。

public repo に置くもの:

- 検証手順。
- checklist template。
- divergence classification の形式。
- 実データを含まない設計判断。

## 7. いま見えている注意点

### cycle end date の1日差

`main.bqn` の表示と `src_next` の half-open boundary 表示で、cycle end date が1日違って見える場合があります。

これは回帰とは限りません。inclusive end date 表示と half-open end boundary の表示契約として、後で文書化候補です。

### food / daily remaining

現時点では `src_next` 側で未実装です。

これは既知の missing feature です。ただし生活判断に直結するため、急いで実装しません。household report policy contract に沿って後で設計します。

### budget_group missing

`budget_group=` が production data にない場合、`src_next` は household metadata gap として可視化できます。

これはすぐ `accounts.tsv` を変更する合図ではありません。Stage 4 検証中は、metadata gap が見えている診断結果として扱います。

### plan / journal 重複チェック

current production が出している警告を `src_next` がまだ出さない場合があります。

これは小さな診断候補です。まずは missing feature として記録し、実装は急ぎません。

## 8. 次に動くタイミング

次に意味がある検証タイミングは、主に次のどれかです。

- journal に新しい取引を追加したあと。
- 日付が進んで残日数などが変わったあと。
- cycle-end review のタイミング。

それまでは、作らない・直さない・検証する、が作業です。

## 9. 英語 docs との関係

この文書は翻訳ではありません。日本語の現在地メモです。

詳しい契約や判定基準は、以下の英語 docs を参照します。

- `docs/SRC_NEXT_REPLACEMENT_READINESS.md` — default switch 前の gate checklist。
- `docs/SRC_NEXT_STAGE4_TRIAL_LOG.md` — Stage 4 検証手順と checklist template。
- `docs/SRC_NEXT_STAGE3_ENTRYPOINT_CONTRACT.md` — `tools/report-next` の entrypoint contract。
- `docs/SRC_NEXT_CURRENT_ENGINE_COMPARISON.md` — current engine と `src_next` の比較記録。
- `docs/SRC_NEXT_HOUSEHOLD_REPORT_POLICY_CONTRACT.md` — food / daily remaining などを実装する前の policy boundary。

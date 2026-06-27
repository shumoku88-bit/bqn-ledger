# src_next Snapshot 観測画面デザイン

状態: **設計メモ / 日本語を正本 / 本番動作の変更なし**

この文書は、`src_next` の Snapshot を「ただの数値一覧」から「毎日最初に見る観測画面」へ育てるための設計メモです。

ここでいう Snapshot は、現在の本番レポート section 1 `全体サマリ (Snapshot)` の後継候補です。
ただし、すぐに本番置き換えをするものではありません。
Stage 4a の中で画面を育て、Stage 4b の daily-use trial で実際に読めるか確認します。

---

## 1. 目的

Snapshot を、次のような画面へ育てます。

- 日々の家計確認で、最初に見る入口になる。
- 資産・cycle・予算・注意点を短く読める。
- 数字だけではなく、状態ラベルと短い観測コメントを出す。
- 必要なら ASCII art を表示できる。
- ただし、計算の信頼性を曇らせない。

この方向は、以前の案3に近い「観測画面」案です。
数字の壁ではなく、生活状態を読むための端末画面として育てます。

---

## 2. 基本方針

Snapshot は、次の4層に分けます。

| 層 | 役割 | 注意 |
|---|---|---|
| 計算層 | cycle summary / balances / envelopes / outlook などを計算する | ASCII art や表示文は混ぜない |
| snapshot view model 層 | Snapshot に出す値・状態・コメントをまとめる | 表示に必要な中間データを作る |
| rendering 層 | text report として整形する | 数字と説明を読みやすく並べる |
| ASCII art 層 | 状態ラベルに応じて art を選ぶ | 表示専用。計算結果には影響させない |

重要:

- ASCII art は計算結果ではありません。
- ASCII art は表示専用です。
- 状態ラベルを先に決め、そのラベルから art を選びます。
- 金額計算の中に art string を混ぜてはいけません。

---

## 3. Snapshot に置きたい情報

最初の到達目標では、次の情報を出します。

### A. 画面 header

- report name
- as-of date
- active cycle range
- next income date / remaining days

例:

```text
--- SrcNext Snapshot ---
as_of: 2026-06-24
cycle: 2026-06-15 .. 2026-08-15 exclusive
next_income: 2026-08-15
remaining_days: 52
```

### B. 状態ラベル

数字から、短い状態ラベルを作ります。

候補:

| label | 意味 |
|---|---|
| `reset` | cycle 開始直後。新しい周期。 |
| `stable` | 大きな注意なし。安定。 |
| `caution` | 支出 pace や予定消化に注意。 |
| `tight` | 残額・日割り・食費などが厳しい。 |
| `unknown` | 必要な情報が足りず判断できない。 |

状態ラベルは、最初は保守的でよいです。
迷ったら `unknown` にします。

### C. 主要数字

- total assets / net worth 相当
- liquid assets 相当
- savings / investments 相当
- cycle income actual
- cycle expense actual
- cycle net actual
- plan expense
- Daily / food remaining
- flex / reserve remaining

ただし、`src_next` がまだ計算できない項目は無理に作らない。
必要なら current engine fallback として扱います。

### D. 観測コメント

状態ラベルと主要数字から、短いコメントを出します。

例:

```text
notes:
- 今サイクルの支出はまだ観察中です
- 食費 / Daily 残額は current engine fallback を参照してください
- 未完了の予定支払いがあります
```

コメントは断定しすぎないこと。
AI 的な意味づけを増やしすぎず、数字の由来が分かる短文にします。

### E. ASCII art

状態ラベルに応じて、1つだけ表示します。

例:

```text
   [stable]
    /\_/\\
   ( o.o )
    > ^ <
```

ASCII art は控えめにします。
画面の主役は、あくまで家計判断に必要な数字です。

---

## 4. ASCII art の扱い

ASCII art は、Snapshot の顔として使えます。
ただし、次の制約を守ります。

### やってよいこと

- 状態ラベルごとに small art を選ぶ。
- cycle 開始直後、安定、注意、厳しめ、unknown で絵を変える。
- art を非表示にできる余地を残す。
- text-only terminal で崩れにくい幅にする。

### やってはいけないこと

- 金額計算の中に ASCII art を混ぜる。
- art の有無で check 結果を変える。
- art を出すために TSV format を変える。
- art を理由に本番 section parity を省略する。
- 派手な logo を主役にして、数字を読みにくくする。

---

## 5. 最初の mockup

最初に目指す画面例です。
実際の値や private な金額は docs に書きません。

```text
--- SrcNext Snapshot ---
as_of: YYYY-MM-DD
cycle: YYYY-MM-DD .. YYYY-MM-DD exclusive
status: stable

   /\_/\\
  ( o.o )   今日の入口
   > ^ <

assets:
  liquid:        <amount or fallback>
  savings:       <amount or fallback>
  investments:   <amount or fallback>
  net_worth:     <amount or fallback>

cycle:
  income_actual:   <amount>
  expense_actual:  <amount>
  net_actual:      <amount>
  plan_expense:    <amount>

living:
  daily_remaining:   <amount or fallback>
  food_remaining:    <amount or fallback>
  flex_remaining:    <amount or fallback>
  reserve_remaining: <amount or fallback>

notes:
  - compact summary は Stage 4a の観察面です
  - 足りない生活判断項目は current engine fallback を使います

section_source:
  snapshot_base: src_next
  envelopes: fallback/current-engine
  outlook_daily: fallback/current-engine
```

---

## 6. 実装段階

### Step 1: 表示設計だけ固定する

- この文書で、Snapshot に置く情報を固定する。
- まだ BQN code は変えなくてよい。
- `src_next` の本番化とは言わない。

### Step 2: src_next で取れる値だけ出す

- cycle range
- cycle income / expense / net
- plan expense
- nonzero actual account totals
- readiness counts

ここまでは compact summary から近い。

### Step 3: fallback を明示する

`src_next` がまだ持たないが日々の判断に必要な値は、current engine fallback として扱う。

候補:

- Daily / food remaining
- envelope balances
- outlook / daily amount
- daily trend
- actual comparison

fallback は画面内で明示する。
黙って混ぜない。

### Step 4: status label を追加する

最初は単純でよい。

例:

- 必要な値がない → `unknown`
- cycle 開始直後 → `reset`
- 大きな warning がない → `stable`
- 未完了予定や skipped rows がある → `caution`

### Step 5: ASCII art を追加する

- status label から art key を選ぶ。
- art は rendering 層だけで扱う。
- `--no-art` のような逃げ道を将来残してもよい。

---

## 7. 実装済み範囲（2026-06-24）

`src_next/snapshot.bqn` と `tools/report-next-summary` に、Stage 4a 用の最小 Snapshot surface を追加しました。
本番既定 route は変えていません。

実装済み:

- `--- SrcNext Snapshot ---` section
- `as_of`
  - 現時点では `src_next` に `--as-of` がないため、latest in-cycle actual journal date として表示する。
  - 該当する actual がない場合は `unavailable/src_next` と表示する。
- active cycle range
- `next_income`
  - 現時点では cycle end equivalent として表示する。
- `remaining_days`
  - `as_of` が unavailable の場合は `unavailable/src_next` と表示する。
- cycle income actual / expense actual / net actual / plan expense
- nonzero actual account totals (`src_next/partial`)
- readiness counts
- fallback/current-engine 境界の明示
- notes
- status label

status label の最小ルール:

| label | 現在の使い方 |
|---|---|
| `unknown` | cycle/as_of が不足する場合。 |
| `reset` | cycle 開始直後で、大きな skipped / unknown がない場合。 |
| `stable` | 大きな skipped / unknown がなく、最低限の cycle 値が出ている場合。 |
| `caution` | skipped rows、unknown account、out-of-cycle skipped などの注意材料がある場合。 |

未実装 / fallback:

- Daily remaining
- food remaining
- flex remaining
- reserve remaining
- envelope balances
- outlook / daily amount
- daily trend
- actual comparison の本実装
- current engine と同等の liquid assets / savings / investments / net worth

これらは、Snapshot 画面では `fallback/current-engine` または `unavailable/src_next` として明示します。
黙って 0 にしたり、推測で値を作ったりしません。
Envelope / food / daily / outlook の計算境界は `docs/SRC_NEXT_ENVELOPE_COMPUTATION_CONTRACT.md` を参照します。

ASCII art:

- `src_next/snapshot.bqn` には `SelectArt` の層だけあります。
- 2026-06-24 時点では空文字を返す placeholder で、画面には art を表示しません。
- 将来追加する場合も、status label から rendering 層で選び、計算層や check result には混ぜません。

この実装は Stage 4a の最小観測画面です。
Stage 4b の daily-use trial 開始ではありません。

---

## 8. Stage 4a / 4b との関係

この Snapshot 観測画面は、Stage 4a の主要作業です。

Stage 4a では、毎日使える画面の形を作ります。
ただし、生活判断に必要な情報が欠けている間は、Stage 4b の daily-use trial とは呼びません。

Stage 4b に進むには、Snapshot で次が分かる必要があります。

- どの数字が `src_next` 由来か。
- どの数字が current engine fallback 由来か。
- どの section がまだ missing か。
- その missing が日々の判断に影響するか。

---

## 9. Non-goals

この文書では、次をしません。

- `main.bqn` を置き換えない。
- TSV format を変えない。
- ASCII art を計算ロジックに入れない。
- Snapshot だけで本番 12 section parity が完了したとは言わない。
- fancy dashboard / GUI を作らない。
- AI の自由作文で家計状態を断定しない。

---

## 10. 関連文書

- `docs/SRC_NEXT_REPLACEMENT_READINESS.md` — Stage 4a / 4b / Stage 5 の移行 gate
- `docs/SRC_NEXT_REPORT_SECTION_PARITY.md` — 本番 12 section の parity matrix
- `docs/SRC_NEXT_STAGE4_TRIAL_LOG.md` — Stage 4a / 4b の観察ログ template
- `docs/MAIN_SECTIONS.md` — 現在の本番 section map
- `docs/SRC_NEXT_HOUSEHOLD_REPORT_POLICY_CONTRACT.md` — household policy と envelope / budget group の契約
- `docs/SRC_NEXT_ENVELOPE_COMPUTATION_CONTRACT.md` — envelope computation / remaining / daily amount の境界契約

# Phase 4 handoff: base-aware Context と Go 前の境界整理

作成日: 2026-06-19

この文書は、次に作業するAIが `docs/GENERALIZATION_TODO.md` の Phase 4 に自然に入れるように、現時点で確認済みの注意点を省略せずまとめた引き継ぎである。

対象リポジトリ: `bqn-ledger`

---

## 0. この文書の目的

現在の `bqn-ledger` は、BQN を read-only canonical engine として守り、Go を source-of-truth TSV editor として追加する段階に入りつつある。

ただし Go 入力層へ進む前に、BQN 側で次の境界を固める必要がある。

1. `--base <dir>` を正式な共通 CLI 契約にする。
2. `config.tsv` / `accounts.tsv` / `cycle.tsv` など、データセットごとに変わる設定を base directory から読む。
3. `LoadContext(base)` の最小 record を作り、設定値を module へ明示的に渡す。
4. Go editor が独自に設定解決や会計判定を持ち始めないようにする。
5. 旧 `Build / BuildDays` 経路と canonical `BuildCube` 経路の違いを棚卸しし、どの export / check がどちらを使うか明確にする。
6. Go の `finish.go` が acceptance criteria 通り `plan_open` だけを候補にするよう、`plan_id` open/closed 判定を実装する。

これは機能追加ではなく、**次の作業者が安全に Go 入力層へ進むための境界整理**である。

---

## 1. 現在の大きな方針

既存方針は変えない。

- Source of Truth は TSV。
- BQN は read-only canonical engine。
- BQN は `journal.tsv` / `plan.tsv` / `budget_alloc.tsv` / `accounts.tsv` / `cycle.tsv` / `config.tsv` を読み、検証・計算・report・export を行う。
- BQN は source TSV を勝手に変更しない。
- Go editor は TSV の閲覧・preview・diff・confirm・backup・atomic write を担当する予定だが、会計エンジンにはしない。
- Datalog / Prolog / AI は BQN export を読む相談・検算・説明レイヤに置く。

Phase 4 で守るべき境界:

```text
TSV source data
  -> LoadContext(base)
  -> Load events
  -> Event IR
  -> Projection IR
  -> Canonical Daily Cube
  -> Views / Reports / Exports / Checks
```

`LoadContext(base)` は巨大な万能 namespace にしない。最初は次のような最小値だけを持つ。

```text
context
  paths
  config values needed by core/report/input/check/export
  account metadata / role predicates
  budget policy values
  cycle policy values
```

Context に入れてはいけないもの:

- Canonical Daily Cube の Layer 定義そのもの
- 任意の計算式
- 任意の BQN コード
- 生活相談ロジック
- AI 用の提案生成ロジック

---

## 2. 注意点1: `config.bqn` が current directory の `config.tsv` を固定参照している

### 2.1 現状

`src/core/config.bqn` は import 時に次のように `config.tsv` を読む。

```bqn
raw ← lib.LoadLines "config.tsv"
```

この読み込みは `base` を受け取らない。

そのため、`--base fixtures/foo` のように別 base directory を指定しても、`config.bqn` が読む `config.tsv` は実行時の current directory 側になる。

一方で `src/core/build_cube.bqn` の `BuildCube` は base を受け取り、次のように source TSV を base 配下から読む。

```bqn
base ← 0 ⊑ args
meta ← 1 ⊑ args
base2 ← (0 < ≠ base) ◶ ⟨ { 𝕊 ⋄ "." }, { 𝕊 ⋄ base } ⟩ @
Path ← { base2 ∾ "/" ∾ 𝕩 }
accs ← pacc.Init ⟨ (Path "accounts.tsv"), conf.BudgetSpent @, conf.BudgetPrefix @ ⟩

j_events ← LoadEvents (Path "journal.tsv")
p_events ← LoadEvents (Path "plan.tsv")
b_events ← LoadEvents (Path "budget_alloc.tsv")
```

ここで問題になるのは、`accounts.tsv` / `journal.tsv` / `plan.tsv` / `budget_alloc.tsv` は base 配下を読むのに、`conf.BudgetSpent @` / `conf.BudgetPrefix @` は current directory 側の `config.tsv` から来る点である。

つまり、現在は次のようなねじれがある。

```text
accounts.tsv         -> base-aware
journal.tsv          -> base-aware
plan.tsv             -> base-aware
budget_alloc.tsv     -> base-aware
config.tsv           -> current directory fixed
```

これは Phase 4 で最初に直すべき箇所である。

### 2.2 なぜ先に直す必要があるか

Go editor は将来、少なくとも次を扱う。

```text
--base <dir>
plan.tsv
journal.tsv
accounts.tsv
cycle.tsv
config.tsv
post-write lint/check
```

もし BQN 側の config 解決が曖昧なまま Go に進むと、Go が独自に `config.tsv` の場所や budget prefix を解釈し始める危険がある。

これは避ける。

Go は会計エンジンではない。Go は BQN が決めた base / Context 契約を使う TSV editor である。

### 2.3 目標状態

Phase 4 の最初の到達点は次。

```text
LoadConfig(base)
LoadContext(base)
```

`config.bqn` は import 時に固定 `config.tsv` を読まない。

候補:

```text
config.bqn
  LoadConfig(path_or_base)
  Get(config, key)
  Required(config, key)
  BudgetPrefix(config)
  BudgetOpening(config)
  BudgetUnassigned(config)
  BudgetSpent(config)
```

または:

```text
context.bqn
  LoadContext(base)
    paths
    config
    accounts/meta
    budget policy
    cycle policy
```

最初は小さくてよい。巨大設計にしない。

### 2.4 実装時の注意

- 既存の `conf.BudgetPrefix @` のような 0-arg accessor は、最終的には Context 経由に置き換える。
- 一気に全 module を変更しない。
- まず `build_cube.bqn` / export / check で必要な budget config 値だけを Context 経由にする。
- 実データ TSV は変更しない。
- Canonical Daily Cube の意味を変えない。
- `./tools/check.sh` が通る状態を維持する。

### 2.5 最小 acceptance

- `--base <dir>` のような base 指定時に、その base 配下の `config.tsv` があればそれを読む。
- base 配下に `config.tsv` がない場合の扱いについて、リポジトリルート (repo root) の `config.tsv` に fallback して読み込むことを正式な仕様とする。
- `accounts.tsv` / `cycle.tsv` / `config.tsv` が同じ base から読まれる（config.tsv がない場合は上記 fallback に従う）。
- `repo root` の生活設定を fixture が暗黙参照しない。

---

## 3. 注意点2: `Build / BuildDays` legacy path が生きている

### 3.1 現状

`src/core/build_cube.bqn` の末尾に、次の legacy compatibility path が残っている。

```bqn
# --- Legacy Compatibility: Build / BuildDays ---

Build ← { ... }
BuildDays ← { ... }

{ LoadEvents ⇐ LoadEvents, Build ⇐ Build, BuildDays ⇐ BuildDays, BuildCube ⇐ BuildCube }
```

`BuildCube` は canonical engine の主経路である。

```text
BuildCube
  source TSV
  -> Event IR
  -> Projection IR
  -> Day × Account × Layer updates
  -> Day × Account × Layer balances
```

一方 `Build / BuildDays` は旧 `256×2` 系の tx/day updates を返す。

```text
Build
  tx_updates
  tx_update_mats
  journal_update_mats
  budget_alloc_update_mats
  tx_meta
  bal_final as 256×2

BuildDays
  day_updates as Day × 256 × 2
  day_balances as Day × 256 × 2
```

つまり現在は、canonical cube と legacy day balances の2経路が生きている。

### 3.2 現在 `BuildDays` を呼んでいるファイル

確認済みの呼び出し元:

```text
src/reports/exporters/export-day-balances.bqn
src/reports/exporters/export-envelope-flow.bqn
checks/check-tx-updates.bqn
checks/check-trend-liquid.bqn
```

それぞれの現状:

#### `export-day-balances.bqn`

- `rtx.BuildDays ⟨ base, meta ⟩` を呼ぶ。
- cumulative end-of-day balances を TSV 出力する。
- `Day × 256 × 2` の legacy `day_balances` を使う。
- `sign` 判定にまだ Prefix 依存が残っている。

該当例:

```bqn
sign ← {
  n ← 𝕩
  (("income:" ≡ 7 ↑ n) ∨ ("equity:" ≡ 7 ↑ n)) ? ¯1 ; 1
} ¨ names
```

これは account role 解決一元化方針とズレる。legacy export として残すなら、その位置づけを明記する。

#### `export-envelope-flow.bqn`

- `rtx.BuildDays ⟨ base, meta ⟩` を呼ぶ。
- day-level envelope flow を出す。
- `conf ← •Import "../../core/config.bqn"` も使っている。
- そのため、ここも base-aware config 化の影響を受ける。

#### `check-tx-updates.bqn`

- `rep.Build base`
- `txmod.BuildDays ⟨ base, r_old.meta ⟩`
- `txmod.BuildCube ⟨ base, r_old.meta ⟩`

の3つを読み、legacy tx/day updates と canonical cube の整合性を検査する。

この check は、legacy path が残っている間は価値がある。

ただし将来 legacy path を廃止するなら、check の役割も変える必要がある。

#### `check-trend-liquid.bqn`

- `as_of rep.BuildAt base` を読む。
- `txmod.BuildDays ⟨ base, r_report.meta ⟩` を読む。
- report trend と day_balances 由来 liquid total を比較する。

ここは `--as-of` を扱っているが、`BuildDays` 自体は as_of を知らない。check 側が日付を切って比較している。

### 3.3 なぜ棚卸しが必要か

現在の canonical engine は `Day × Account × Layer` である。

しかし一部 export/check はまだ `Day × Account × 2` の legacy path を使う。

このままだと将来、次の混乱が起きやすい。

```text
- この export は canonical cube 由来なのか？
- この export は legacy day_balances 由来なのか？
- as_of が効くのか？
- 全期間確定値なのか？
- plan layer を含むのか？
- budget layer の意味は canonical layer=2 と同じなのか？
```

Go editor そのものを止めるほど急ぎではないが、Phase 4 の前後で必ず棚卸しする価値がある。

### 3.4 方針案

選択肢は3つ。

#### A. すぐ canonical cube export へ移行する

- `export-day-balances.bqn` を `BuildCube` の `cube_balances` から作る。
- `export-envelope-flow.bqn` を `cube_updates` / `cube_balances` から作る。
- legacy `Build / BuildDays` を削除または archive する。

利点:

- 正本経路が一本化される。
- as_of / base-aware context の整理がしやすい。

欠点:

- 変更範囲が広くなる。
- golden / check 修正が増える。

#### B. legacy compatibility として残すが明示する

- `Build / BuildDays` に `Legacy` 名を付ける。
- docs に「compatibility export / check 専用」と書く。
- canonical report / canonical export は `BuildCube` のみを正本とする。

利点:

- 変更範囲が小さい。
- 既存 check を壊しにくい。

欠点:

- 2経路が残る。
- 後で混乱しやすい。

#### C. Phase 4 では棚卸しだけして、移行は別Phaseにする

推奨は C。

理由:

- Phase 4 の本丸は base-aware Context。
- 同時に legacy export を大きく変えると、原因切り分けが難しくなる。
- ただし docs と TODO に「legacy path が残っている」と明示し、次の作業者が見落とさないようにする。

### 3.5 最小 acceptance

Phase 4 中に最低限やること:

- `Build / BuildDays` が legacy compatibility path であることを docs に明記する。
- `BuildDays` 呼び出し元一覧を更新する。
- canonical export / canonical report と legacy export の境界を書く。
- `BuildDays` が as_of を受け取らないことを明記する。
- `export-day-balances.bqn` の Prefix `sign` 判定は、legacy cleanup の TODO として残す。

---

## 4. 注意点3: `finish.go` が `plan_id` による open/closed 判定をしていない

### 4.1 現状

`src/input/finish.go` は Go editor の最初期 preview 実装である。

現在の処理はおおむね次。

```text
load accounts.tsv
load plan.tsv
print all plan rows
user selects row
ask actual date
print journal candidate
no files modified
```

現在の `loadPlan` は `plan.tsv` の全行を読み、valid な行をそのまま `rows` に追加する。

`journal.tsv` を読む処理はない。

そのため、すでに `journal.tsv` に同じ `plan_id` を持つ実績行が存在していても、`finish.go` はその plan 行を候補として表示する。

### 4.2 acceptance criteria とのズレ

`docs/GO_EDITOR_FIRST_IMPLEMENTATION_ACCEPTANCE.md` では、最初のターゲットとして次が書かれている。

- `plan list` は `plan_open` のもののみを対象にする、または明確に区別して表示する。
- `plan finish preview` は `plan_open` のみを履行候補として提示する。
- すでに `journal.tsv` に同一 `plan_id` の行が存在する予定は、二重記帳を防ぐため候補に出さない。
- 提案する journal 行には元の `plan_id` を引き継ぐ。
- file write はしない。read-only preview に徹する。

現状の `finish.go` は read-only preview という点は守っている。

しかし `plan_id` による open/closed 判定が未実装である。

### 4.3 Go 実装前に必要な修正

Go editor の実装へ進む前に、少なくとも `finish.go` preview は acceptance criteria と一致させる。

最小実装案:

```text
1. journal.tsv を読む。
2. journal rows の meta から plan_id を抽出する。
3. completedPlanIDs set を作る。
4. plan.tsv 各行の meta から plan_id を抽出する。
5. plan_id があり、completedPlanIDs に含まれる行は closed と判定する。
6. list/finish 候補には open のみを出す。
7. 必要なら --all で closed も表示するが、finish 候補にはしない。
```

plan_id がない既存 plan 行の扱い:

- 既存方針では、既存 `plan.tsv` 行は `plan_id` backfill 対象。
- `plan_id` なし互換規則を増やさず、ID付与で揃える方針。
- したがって Go 側は、`plan_id` なし行をどう扱うか明示する必要がある。

候補:

```text
A. plan_id なし行は open として表示するが、warning を出す。
B. plan_id なし行は finish preview 対象外にして、backfill を促す。
```

推奨:

- 最初は A。
- ただし表示に `missing-plan-id` を出す。
- 二重記帳防止を強くするなら、backfill 後に B へ移行する。

### 4.4 実装でやらないこと

- `journal.tsv` へ書き込まない。
- `plan.tsv` を削除しない。
- `plan.tsv` に `status=done` や `actual_date=...` を自動追記しない。
- BQN の plan completion logic と別の意味を Go 側に作らない。

### 4.5 最小 acceptance

- `journal.tsv` に同じ `plan_id` を持つ行がある plan は finish 候補に出ない。
- `--list` では open/closed が区別できる。
- `plan_id` は journal candidate に引き継がれる。
- `recur`, `months`, `anchor`, `offset` は journal candidate から除外される。
- `series`, `plan_id`, `tax`, `receipt`, `party`, `note` は保持される。
- ファイルは一切変更しない。

---

## 5. 推奨作業順序

明日以降のAIは、次の順で作業する。

### Step 1: Phase 4 最小設計を確認する

読むもの:

```text
TODO.md
README.md
docs/README.md
docs/GENERALIZATION_TODO.md
docs/ACCOUNT_ROLE_CONTRACT.md
docs/GO_SOURCE_TSV_EDITOR_DESIGN.md
docs/GO_SOURCE_TSV_EDITOR_APPEND_ONLY_DECISIONS.md
docs/GO_EDITOR_FIRST_IMPLEMENTATION_ACCEPTANCE.md
docs/PHASE4_BASE_AWARE_CONTEXT_INVESTIGATION.md
この文書
```

確認すること:

```text
- Phase 4 の目的は base-aware Context である。
- 汎用会計ライブラリ化ではない。
- Go 実装ではなく、Go 前の境界整理である。
- source TSV は変更しない。
```

### Step 2: `config.bqn` の base-aware 化から始める

最初の作業候補:

```text
src/core/config.bqn
  import時固定読み込みをやめる
  LoadConfig(base_or_path) を追加する
  accessor は config record を受け取る形へ寄せる
```

ただし、いきなり全 module を変えない。

最初に触る可能性が高い場所:

```text
src/core/build_cube.bqn
src/reports/exporters/export-envelope-flow.bqn
checks/check-tx-updates.bqn
src/input/add.bqn
src/input/gen-budget.bqn
```

`conf.BudgetPrefix @` / `conf.BudgetSpent @` / `conf.BudgetOpening @` / `conf.BudgetUnassigned @` がどこで使われているかを検索してから変更する。

### Step 3: `LoadContext(base)` の最小 record を作る

候補 module:

```text
src/core/context.bqn
```

最小 record 例:

```text
{
  base ⇐ base,
  path ⇐ Path,
  config ⇐ config_record,
  budget_prefix ⇐ ...,
  budget_opening ⇐ ...,
  budget_unassigned ⇐ ...,
  budget_spent ⇐ ...
}
```

account role predicates はすでに `account_space.bqn` / meta 側にあるため、最初から全部 Context に移さなくてよい。

### Step 4: fixture で base-aware config を証明する

必要な fixture:

```text
fixtures/base-aware-config-minimal
```

または既存 fixture に `config.tsv` を追加してもよい。

証明したいこと:

```text
- root config.tsv ではなく fixture config.tsv を読む。
- budget prefix / special budget ids が base ごとに切り替わる。
- repo root の生活設定を fixture が暗黙参照しない。
```

### Step 5: `finish.go` の `plan_id` open/closed 判定を直す

これは Go 本格実装前に直す。

ただし Phase 4 作業と同じ commit に混ぜなくてもよい。

推奨 commit 分割:

```text
commit 1: docs: document Phase 4 handoff and pre-Go cleanup
commit 2: refactor: make config loading base-aware
commit 3: test: add base-aware config fixture
commit 4: fix: filter finished plans in finish.go preview
commit 5: docs: document legacy BuildDays boundary
```

### Step 6: `Build / BuildDays` は棚卸しだけでもよい

Phase 4 中に全部移行しなくてよい。

ただし以下は必ず明記する。

```text
- BuildCube が canonical path。
- Build / BuildDays は legacy compatibility path。
- BuildDays は as_of を受け取らない。
- 呼び出し元は export-day-balances / export-envelope-flow / check-tx-updates / check-trend-liquid。
- canonical export を増やすなら BuildCube 由来にする。
```

---

## 6. 変更禁止・注意事項

Phase 4 でやってはいけないこと:

```text
- journal.tsv / plan.tsv / budget_alloc.tsv / accounts.tsv を勝手に変更する
- Canonical Daily Cube の shape を変える
- Layer 数や Layer 意味を設定化する
- BuildCube の計算意味を相談都合で変える
- Go 側に残高計算・封筒残高計算・cycle計算を実装する
- plan finish apply を実装する
- plan.tsv から行削除する
- status=done を自動追記する
- legacy path 削除と base-aware Context 化を同じ大変更に混ぜる
```

Phase 4 でやってよいこと:

```text
- config.tsv の base-aware loading
- LoadContext(base) の最小導入
- module の直接 config import を段階的に減らす
- fixture で base 切替を証明する
- BuildDays legacy path の棚卸しと文書化
- finish.go read-only preview の plan_id open/closed 判定修正
```

---

## 7. 完了条件

Phase 4 最小完了条件:

```text
- `--base <dir>` が共通 CLI 契約として説明されている。
- `config.tsv` が base-aware に読まれる。
- `accounts.tsv` / `cycle.tsv` / `config.tsv` の base が揃う。
- `LoadContext(base)` の最小 record が文書化または実装されている。
- fixture が root config 暗黙参照を防いでいる。
- `./tools/check.sh` が通る。
- legacy `Build / BuildDays` の残存理由と呼び出し元が docs に書かれている。
- Go `finish.go` の read-only preview が `plan_open` 候補を守る。
```

Go editor へ進める条件:

```text
- BQN側で base / Context / config の責務が曖昧でない。
- Go が独自 config 解決を持つ必要がない。
- `finish.go` preview が plan_id 二重記帳を避ける。
- 書き込み apply はまだ実装しない。
```

---

## 8. 最終判断

次に進むべき作業は、Go editor 本実装ではなく、まず **Phase 4: Base-aware Context** である。

理由:

- `config.bqn` だけ current directory に浮いており、base-aware の契約が未完成。
- Go editor は base / config / accounts / cycle の境界が固まってから載せた方が安全。
- legacy `Build / BuildDays` はすぐ削除不要だが、canonical path との境界を明記する必要がある。
- `finish.go` は read-only preview としては良いが、acceptance criteria の `plan_open` 判定が未実装。

短く言うと:

```text
先に Context の土台を作る。
そのあと Go の read-only preview を acceptance criteria に合わせる。
legacy day path は棚卸しして、canonical path と混同しないように札を付ける。
```

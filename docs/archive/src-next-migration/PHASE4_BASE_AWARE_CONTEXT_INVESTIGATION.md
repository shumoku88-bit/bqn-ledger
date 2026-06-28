# Phase 4 Base-aware Context Investigation

作成日: 2026-06-19  
目的: `docs/GENERALIZATION_TODO.md` Phase 4 を実装する前に、現行コードの `--base` / `config.tsv` / Context 境界を調査し、次の pit が安全に作業へ入れるようにする。

この文書は実装計画ではなく、**実装前調査と引き継ぎメモ**である。実データ TSV は変更しない。

---

## 0. 結論

次に進めるべき作業は、Go editor 本実装ではなく、BQN 側の **Base-aware Context 最小導入**。

最初の実装ターゲットは以下。

1. `src/core/config.bqn` が import 時に current directory の `config.tsv` を読む構造をやめる。
2. `LoadConfig(base_or_path)` と、config record を受け取る accessor を追加する。
3. `src/core/context.bqn` などに `LoadContext(base)` の最小 record を作る。
4. `BuildCube` / lint / canonical report から、少なくとも budget prefix / special budget account を Context 経由にする。
5. fixture で「root config ではなく base 配下 config を読んでいる」ことを証明する。

重要な発見:

- `accounts.tsv`, `journal.tsv`, `plan.tsv`, `budget_alloc.tsv`, `cycle.tsv` は多くの経路で base-aware。
- しかし `config.tsv` だけは `src/core/config.bqn` import 時に `config.tsv` 固定で読み、base-aware ではない。
- `--base` 対応は entrypoint ごとにばらつきがある。
- `config.tsv` 形式は root が `KEY=value`、`fixtures/historical-cycle/config.tsv` が `KEY<TAB>value` で混在している。
- legacy `Build / BuildDays` は残っており、canonical `BuildCube` と境界を維持して扱う必要がある。

---

## 1. 守ること

- `journal.tsv` / `plan.tsv` / `budget_alloc.tsv` / `accounts.tsv` を変更しない。
- Canonical Daily Cube の shape `Day × Account × Layer` を変えない。
- Layer 契約 `actual / plan / budget / forecast` を設定化しない。
- `BuildCube` の計算意味を変えない。
- Go に残高計算・封筒計算・cycle 計算を持ち込まない。
- `plan finish apply` は実装しない。
- Phase 4 では大改造せず、base/config/Context 境界に限定する。

---

## 2. 現行の config 問題

### 2.1 問題箇所

`src/core/config.bqn` は import 時に固定パスを読む。

```bqn
raw ← lib.LoadLines "config.tsv"
parts ← ('=') lib.SplitKeepEmpty ¨ raw
```

このため、例えば `bqn src/reports/main.bqn --base fixtures/basic` を実行しても、budget prefix 等は root の `config.tsv` から来る。

一方、`BuildCube` は source TSV を base 配下から読む。

```bqn
base2 ← (0 < ≠ base) ◶ ⟨ { 𝕊 ⋄ "." }, { 𝕊 ⋄ base } ⟩ @
Path ← { base2 ∾ "/" ∾ 𝕩 }
accs ← pacc.Init ⟨ (Path "accounts.tsv"), conf.BudgetSpent @, conf.BudgetPrefix @ ⟩

j_events ← LoadEvents (Path "journal.tsv")
p_events ← LoadEvents (Path "plan.tsv")
b_events ← LoadEvents (Path "budget_alloc.tsv")
```

つまり現在は次のねじれがある。

```text
accounts.tsv         -> base-aware
journal.tsv          -> base-aware
plan.tsv             -> base-aware
budget_alloc.tsv     -> base-aware
cycle.tsv            -> base-aware in report_engine path
config.tsv           -> current directory fixed
```

### 2.2 影響する主な呼び出し

`conf.BudgetPrefix @` / `conf.BudgetSpent @` / `conf.BudgetOpening @` / `conf.BudgetUnassigned @` を使っている箇所:

```text
src/core/build_cube.bqn
src/views/envelope_view.bqn
src/reports/exporters/export-envelope-flow.bqn
src/reports/exporters/export-next-cycle.bqn
src/input/txn.bqn
src/input/add.bqn
src/input/gen-budget.bqn
checks/lint_cli.bqn
checks/lint_accounts.bqn
checks/lint_journal.bqn
checks/lint_merged.bqn
checks/check-tx-updates.bqn  # import はあるが現状未使用に見える
src/views/plan_view.bqn          # import はあるが現状未使用に見える
```

更新: 2026-06-21 時点で `checks/lint_merged.bqn` は未参照の旧結合版として削除済み。現状のcleanup状況は `docs/LEGACY_COMPAT_CLEANUP_AUDIT.md` を参照する。

調査コマンド:

```sh
rg -n "config\.bqn|conf\.|BudgetPrefix|BudgetSpent|BudgetOpening|BudgetUnassigned" src tools --glob '!*.go'
```

---

## 3. config.tsv の形式混在

root `config.tsv` は `KEY=value` 形式。

```text
BUDGET_PREFIX=budget:
BUDGET_ID_OPENING=budget:opening
BUDGET_ID_UNASSIGNED=none
BUDGET_ID_SPENT=budget:spent
```

一方、現存 fixture では `fixtures/historical-cycle/config.tsv` のみが存在し、これは `KEY<TAB>value` 形式。

```text
BUDGET_PREFIX<TAB>budget:
BUDGET_ID_OPENING<TAB>budget:opening
BUDGET_ID_UNASSIGNED<TAB>budget:unassigned
BUDGET_ID_SPENT<TAB>budget:spent
```

`docs/GO_SOURCE_TSV_EDITOR_DESIGN.md` では `cycle.tsv` / `config.tsv` は `key<TAB>value` または `key=value` の現行形式を壊さない、としている。

したがって Phase 4 の `LoadConfig` は、少なくとも当面は **両形式を読む**のが安全。

推奨 parser 方針:

1. comment / empty line は `lib.LoadLines` に任せる。
2. 行に TAB があれば TAB split の 1,2 列目を key/value とする。
3. TAB がなければ `=` split の 1,2 要素を key/value とする。
4. value が空なら missing と扱う。
5. 余分な列または `=` を含む value を許すかは別判断。最小実装では現行ファイルに合わせて simple split でよい。

---

## 4. `--base` 対応状況

### 4.1 入口として整っているもの

#### Human report

`main.bqn` と `src/reports/main.bqn` は `src/reports/main_impl.bqn` を使う。

対応済み:

- legacy: `bqn main.bqn fixtures/basic`
- explicit: `bqn main.bqn --base fixtures/basic`
- `--as-of YYYY-MM-DD`
- `--section ...`

#### Canonical summary 系 exporters

`src/reports/exporters/args.bqn` の `ParseArgs` を使う exporter は `--base` と `--as-of` に対応している。

確認済み:

```text
export-report-numbers.bqn
export-envelope-summary.bqn
export-liquid-assets-summary.bqn
export-cycle-summary.bqn
export-plan-summary.bqn
```

### 4.2 legacy positional base のみのもの

更新: 2026-06-21 時点で、以下の `GetBase ← { a ← 𝕩 ⋄ (0 < ≠ a) ? (⊑ a) ; "." }` 型 entrypoint は `src/reports/exporters/args.bqn` の `ParseArgs` へ移行済み。

```text
src/reports/exporters/export-balances.bqn
src/reports/exporters/export-canonical-snapshot.bqn
src/reports/exporters/export-planned.bqn
src/reports/exporters/export-tx-updates.bqn
src/reports/exporters/export-day-balances.bqn
src/reports/exporters/export-envelope-flow.bqn
src/reports/exporters/summary.bqn
checks/invariants.bqn
checks/check-tx-updates.bqn
```

これらは従来の第1引数 base 指定を維持しつつ、`--base <dir>` も受け付ける。残る `GetBase ← ...` は、引数なし既定値が `fixtures/multi-time-card` の `src/reports/exporters/export-cashflow-due.bqn` のみで、別判断にする。

### 4.3 個別注意

- `src/reports/exporters/export-next-cycle.bqn`
  - 第1引数を `as_of` として扱い、base は常に `.`。
  - `reng.BuildAt "."`, `rmeta.Build "."`, `cyc.Resolve` を使う。
  - consultation export 寄りなので、canonical path ほど先に直さなくてもよいが、Phase 4 の未対応一覧には載せる。

- `checks/lint_cli.bqn`
  - legacy positional base のみ。
  - `pacc.Init` に root config 由来の `conf.BudgetSpent @`, `conf.BudgetPrefix @` を渡すため、base-aware config 化の主要対象。

- `src/input/add.bqn`
  - `FindRoot •path` で root を探し、source TSV に書き込みうる。
  - Phase 4 の read-only Context 整理と混ぜない方が安全。
  - Go editor 移行前に扱うとしても別 commit/別タスクにする。

- `src/input/txn.bqn`
  - read-only helper。
  - positional base はあるが `--base` は未対応。
  - `pacc.Init` に root config 由来の値を渡す。

調査コマンド:

```sh
for f in src/reports/exporters/*.bqn checks/*.bqn src/views/plan_view.bqn src/input/txn.bqn; do
  if rg -q "•args|ParseArgs|GetBase|BuildAt|Build " "$f"; then
    echo "--- $f"
    rg -n "•args|ParseArgs|GetBase|BuildAt|Build |BuildDays|BuildCube|--base|as_of|base ←|meta ←" "$f"
  fi
done
```

---

## 5. 現行 base-aware 読み込み経路

### 5.1 report_engine

`src/reports/report_engine.bqn` は base を受け取り、以下を base 配下から読む。

- `rmeta.Build base` -> `accounts.tsv`
- `rtx.BuildCube ⟨ base, meta ⟩` -> `accounts.tsv`, `journal.tsv`, `plan.tsv`, `budget_alloc.tsv`
- `rcycle.Build ⟨ P "cycle.tsv", ... ⟩` -> `cycle.tsv`

問題は、`BuildCube` 内の `pacc.Init` が `config.bqn` 0-arg accessor を使うこと。

### 5.2 account_space

`src/core/account_space.bqn` は base-aware。

```bqn
base2 ← (0 < ≠ base) ⊑ ⟨ ".", base ⟩
P ← { base2 ∾ "/" ∾ 𝕩 }
raw_acc ← lib.LoadLines (P "accounts.tsv")
```

ただし fallback の `budget:` prefix は現在ハードコードされている。

```bqn
("budget:" HasPrefix nm) -> "budget"
```

Phase 4 最小ではすぐ直さなくてもよいが、config-driven budget prefix と role fallback の整合 TODO として残す。

### 5.3 cycle

`src/core/cycle.bqn` 自体は path を受け取る `ResolveFrom` があり、report 経路では base 配下の `cycle.tsv` を渡している。

`Resolve ← { "cycle.tsv" ResolveFrom 𝕩 }` は current directory 固定の互換入口なので、今後は使用箇所を限定する。

---

## 6. legacy `Build / BuildDays` 境界

`src/core/build_cube.bqn` には canonical path と legacy compatibility path が同居している。

```text
BuildCube -> Day × 256 × 4  # canonical
Build     -> tx updates 256 × 2  # legacy compatibility
BuildDays -> Day × 256 × 2       # legacy compatibility
```

確認済みの `BuildDays` 呼び出し元:

```text
src/reports/exporters/export-envelope-flow.bqn
checks/check-tx-updates.bqn
```

更新: 2026-06-21 時点で `export-day-balances.bqn` と `check-trend-liquid.bqn` は `BuildCube` 由来へ移行済み。

注意:

- `BuildDays` は `as_of` を受け取らない。
- `export-envelope-flow.bqn` は transaction source 分解を使うため、BuildCube 化には provenance 設計が必要。
- `check-tx-updates.bqn` は legacy と canonical の整合検査として価値がある。

Phase 4 では legacy path を削除しない。まず docs に「compatibility export/check 専用」と明記し、canonical report/export は `BuildCube` 由来とする。

---

## 7. 推奨実装ステップ

### Step 1: `config.bqn` を副作用なし loader に寄せる

現行の import-time global 読み込みをやめる。

候補 API:

```text
src/core/config.bqn
  LoadConfig(base_or_path)
  Get(config, key)
  Required(config, key)
  BudgetPrefix(config)
  BudgetOpening(config)
  BudgetUnassigned(config)
  BudgetSpent(config)
```

移行中の互換のために 0-arg accessor を残す場合は、明確に deprecated とし、root default 用に限定する。

推奨: Phase 4 の新規コードでは 0-arg accessor を使わない。

### Step 2: `context.bqn` の最小 record を作る

候補ファイル:

```text
src/core/context.bqn
```

最小 record:

```text
{
  base ⇐ base,
  path ⇐ Path,
  config ⇐ cfg,
  budget_prefix ⇐ conf.BudgetPrefix cfg,
  budget_opening ⇐ conf.BudgetOpening cfg,
  budget_unassigned ⇐ conf.BudgetUnassigned cfg,
  budget_spent ⇐ conf.BudgetSpent cfg
}
```

最初から account predicates や cycle resolver を全部入れない。巨大 Context にしない。

### Step 3: `BuildCube` と lint を Context 経由にする

最初の主要対象:

```text
src/core/build_cube.bqn
checks/lint_cli.bqn
checks/lint_accounts.bqn
checks/lint_journal.bqn
src/views/envelope_view.bqn
src/reports/exporters/export-envelope-flow.bqn
```

ただし一気に全部触らず、最初は canonical report + lint + one fixture を通す範囲でよい。

### Step 4: base-aware config fixture を追加する

新 fixture 候補:

```text
fixtures/base-aware-config-minimal
```

目的:

- root `config.tsv` ではなく fixture `config.tsv` を読むことを証明する。
- `BUDGET_PREFIX` を root と異なる値（例: `env:`）にする。
- `accounts.tsv` も `env:` budget accounts を使う。
- `journal.tsv`, `plan.tsv`, `budget_alloc.tsv`, `cycle.tsv` は最小データにする。

注意:

- fixture は実データ TSV ではないため追加可能。
- expected/golden を置くなら出力値の意味を説明する。
- 既存 root 生活設定を暗黙参照して通る fixture にしない。

### Step 5: CLI parser の統一は別段階で進める

Phase 4 最小では `main` / canonical exporters / lint / checks から順に対応する。

優先順:

1. `main.bqn`, `src/reports/main.bqn` 既存維持。
2. `lint_cli.bqn` に `--base` を入れる。
3. canonical exporters を `args.bqn` に寄せる。
4. legacy exporters/checks を必要に応じて対応。
5. `add.bqn` のような書き込み系は Go editor 設計と合わせて別作業。

---

## 8. acceptance criteria

Phase 4 最小完了条件:

- `LoadConfig(base)` または `LoadContext(base)` が存在する。
- `config.tsv` が base 配下から読まれる。
- `config.tsv` は `KEY=value` と `KEY<TAB>value` の現行2形式を読める。
- `accounts.tsv` / `cycle.tsv` / `config.tsv` の base が揃う。
- root config を暗黙参照しない fixture がある。
- `bqn src/reports/main.bqn --base fixtures/base-aware-config-minimal --as-of <date> --section envelopes` 相当が通る。
- `bqn checks/lint_cli.bqn --base fixtures/base-aware-config-minimal` 相当が通る。
- `./tools/check.sh` が通る。
- legacy `Build / BuildDays` は削除せず、canonical との境界が docs に残る。

---

## 9. 実装時の落とし穴

- BQN は branch が eager 評価になりやすい箇所があるため、既存コード同様に function branch を使う。
- `lib.Split` は空フィールドを落とす。journal-like TSV には `SplitKeepEmpty` を使う。
- `config.tsv` は空 value を missing と扱うなら `SplitKeepEmpty` が必要。
- `fixtures/historical-cycle/config.tsv` は TAB 形式なので、`=` 専用 parser にすると壊れる。
- `account_space.bqn` の `budget:` fallback はまだ固定文字列。budget prefix 完全設定化とは別に扱う。
- `BuildDays` は `as_of` を知らない。as_of 対応の有無を混同しない。
- source TSV 書き込み系 (`add.bqn`) と read-only report/check の Context 整理を混ぜない。

---

## 10. 次の pit への作業指示テンプレ

```text
bqn-ledger の Phase 4 Base-aware Context を進める。

読むもの:
- TODO.md
- docs/GENERALIZATION_TODO.md
- docs/PHASE4_BASE_AWARE_CONTEXT_HANDOFF.md
- docs/PHASE4_BASE_AWARE_CONTEXT_INVESTIGATION.md
- docs/ARCHITECTURE.md
- docs/CANONICAL_DAILY_CUBE.md

今回の目的:
- config.bqn の import-time current directory 固定読み込みをやめる。
- base 配下 config.tsv を読む LoadConfig/LoadContext を最小導入する。
- canonical report と lint が同じ base の accounts/cycle/config を使うようにする。

守ること:
- 実データ TSV は変更しない。
- BuildCube の計算意味を変えない。
- Cube shape / Layer 契約を変えない。
- Go editor apply は実装しない。
- legacy BuildDays 削除はしない。

完了条件:
- base-aware config fixture を追加する。
- lint と main report が fixture で通る。
- 可能なら ./tools/check.sh を通す。
- 変更した公開report fieldやsectionがあれば docs/REPORT_FIELD_MAP.md / docs/MAIN_SECTIONS.md を更新する。
```

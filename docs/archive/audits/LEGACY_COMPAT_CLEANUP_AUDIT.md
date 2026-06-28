# Legacy compatibility cleanup audit


> **Note (2026-06-26):** Old engine has been deleted. References in this doc are historical. Current engine is src_next/.
作成日: 2026-06-21
最終更新: 2026-06-21

目的: Phase 4 Base-aware Context 安定後に、残っているレガシー互換コードを安全に削除・移行するための棚卸し。

この文書は実データ TSV を変更しない。`BuildCube` の意味も変更しない。

---

## 結論

- `src/core/config.bqn` には、現在 `DefaultConfig` も module-level の `conf.BudgetPrefix @` 形式アクセサ export も残っていない。
- 生きている通常経路は `conf.LoadConfig(base)` または `context.LoadContext(base)` 経由で config record を読む形に寄っている。
- module-level `conf.BudgetPrefix @` / `conf.BudgetSpent @` の残存は `checks/lint_merged.bqn` だけだったが、現行コードから未参照であることを確認し削除済み。
- `Build / BuildDays` の legacy compatibility path は `src/core/build_cube.bqn` から削除済み。
- `export-tx-updates.bqn`、`export-day-balances.bqn`、`export-envelope-flow.bqn`、`check-trend-liquid.bqn` は `BuildCube` / `cube_projections` / `cube_balances` 由来へ移行済み。
- `checks/check-tx-updates.bqn` は旧更新行列と canonical cube の bridge check としての役割を終え、削除済み。

---

## 1. config.bqn cleanup 状況

### 現状

`src/core/config.bqn` の public export は以下のみ。

```bqn
{ LoadConfig ⇐ LoadConfig }
```

`LoadConfig(base_or_path)` が返す config record に次の accessor がある。

```text
cfg.BudgetPrefix @
cfg.BudgetOpening @
cfg.BudgetUnassigned @
cfg.BudgetSpent @
```

これは module-level 0引数 accessor ではなく、読み込んだ config record 上の accessor である。

### 削除済み module-level 呼び出し

削除前の残存は以下のみだった。

```text
checks/lint_merged.bqn:96:  spent_name ← conf.BudgetSpent @
checks/lint_merged.bqn:99:  bp ← conf.BudgetPrefix @
checks/lint_merged.bqn:305:    ((conf.BudgetPrefix @) ∾ "* accounts are only allowed in budget_alloc.tsv (manual allocation SoT).") FmtLine 𝕩
```

`rg "lint_merged" src tools tests --glob '!*.go'` で未参照であることを確認し、`checks/lint_merged.bqn` を削除した。

### 判断

- `config.bqn` 本体から削除する `DefaultConfig` / legacy accessor は現時点でない。
- config cleanup は完了扱いでよい。
- 今後は `conf.LoadConfig(base)` または `context.LoadContext(base)` 経由を維持する。

---

## 2. Build / BuildDays cleanup 状況

### 現状

`src/core/build_cube.bqn` の public export は以下のみ。

```bqn
{ LoadEvents ⇐ LoadEvents, BuildCube ⇐ BuildCube }
```

現在の canonical path は `BuildCube` のみである。旧 `Build` / `BuildDays` は削除済みで、通常 exporter / check は以下の形に移行した。

```text
src/reports/exporters/export-tx-updates.bqn
  BuildCube.cube_projections 由来。
  transaction-level sparse update export。
  source/row/date/memo/from/to provenance は `cube_projections` から取る。

src/reports/exporters/export-day-balances.bqn
  BuildCube.cube_balances / cube_updates 由来。
  actual 表示の sign 補正は維持し、role metadata predicate を使う。

src/reports/exporters/export-envelope-flow.bqn
  BuildCube.cube_projections / cube_updates / cube_balances 由来。
  allocated/spent/transferred/day balance を canonical projection から再構成する。

checks/check-trend-liquid.bqn
  BuildCube cube_balances 由来。
```

### 削除済み

```text
checks/check-tx-updates.bqn
```

旧 `BuildDays` と canonical cube の数学的対応を見る bridge check だったが、legacy path 削除後は役割終了として削除済み。

### 判断

- `Build / BuildDays` cleanup は完了扱いでよい。
- 新しい exporter や report section は `BuildCube` または `report_engine.BuildAt` の上に作る。
- transaction / day-level provenance が必要な場合は `cube_projections` を使う。

---

## 3. `--base` 共通 CLI 契約とのズレ

2026-06-21 cleanup で、以下は legacy positional-only `GetBase` から `src/reports/exporters/args.bqn` の `ParseArgs` へ移行済み。

```text
src/reports/exporters/export-tx-updates.bqn
src/reports/exporters/export-day-balances.bqn
src/reports/exporters/export-envelope-flow.bqn
checks/check-trend-liquid.bqn
src/reports/exporters/export-balances.bqn
src/reports/exporters/export-canonical-snapshot.bqn
src/reports/exporters/export-planned.bqn
src/reports/exporters/summary.bqn
checks/invariants.bqn
```

これらは従来の第1引数 base 指定を維持しつつ、`--base <dir>` も受け付ける。

残る `GetBase ← ...` は以下のみ。

```text
src/reports/exporters/export-cashflow-due.bqn
```

これは引数なし既定値が `fixtures/multi-time-card` の実験的 due projection exporter で、通常の `.` default と異なるため別判断にする。

### 判断

- `GetBase ← ... ; "."` 型 entrypoint の `ParseArgs` 移行は完了。
- `export-cashflow-due.bqn` の既定baseを変えるかどうかは、cashflow due projection の位置づけ整理時に判断する。
- legacy exporter の中身を `BuildCube` へ移す作業とは分ける。

---

## 推奨 next actions

1. `docs/ARCHITECTURE.md` の legacy compatibility section が古い場合は、`Build / BuildDays` 削除済みの状態へ同期する。
2. `docs/AI_CODEMAP.md` の Go editor 承認済み範囲を、`journal add` / `budget add` / `plan finish --apply` へ同期する。
3. 各ステップ後に `./checks/check.sh` を通す。出力値が変わる場合は fixture/golden 差分の理由を説明して確認を取る。

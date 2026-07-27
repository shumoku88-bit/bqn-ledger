# Report Latency Characterization Report

Date: 2026-07-27  
Repository: `shumoku88-bit/bqn-ledger`  
Base SHA: `a826a833799a0e75328ae7aeb794fe44c9018cf2` (`main`)  
PR Branch: `docs/report-latency-characterization-instructions`  

---

## 1. Baseline SHA and Environment

- **Target Base SHA**: `a826a833799a0e75328ae7aeb794fe44c9018cf2`
- **Current Branch**: `docs/report-latency-characterization-instructions` (PR #429)
- **Environment**: macOS (Apple Silicon), CBQN v0.1.0, Bash 3.2 / Zsh
- **Measurement Tooling**: `tools/report-latency-benchmark.sh` (5 runs per benchmark following 1 untimed warmup run) and `src_next/report_latency_probe.bqn` (`•MonoTime` microsecond precision).

---

## 2. Confirmed Call Graph

### 2.1 Interactive Section Selector Route (`tools/bl` / `tools/main-ui.sh select`)

```text
tools/bl
  -> tools/main-ui.sh --base <base> select
       ├── 1. bqn src_edit/actual_journal_file_cmd.bqn <base> (~76 ms)
       ├── 2. stat scan of source mtimes (accounts, journal, plan, budget_alloc, cycle, issues, config, src_next/*.bqn, report_labels) (~10 ms)
       ├── 3. Cache validity check (.cache-timestamp >= max_src_mtime)
       │    └── IF STALE OR MISSING:
       │         tools/report <base> --write-section-cache <dir> --no-color
       │           -> bqn src_next/report.bqn <base> --write-section-cache <dir> --no-color
       │                -> ctx_mod.BuildContext <base>
       │                -> BuildSectionEntries (builds all 15 human section texts)
       │                -> write all 15 section text files + all.txt
       ├── 4. select_section <cache_dir>
       │    -> tools/report-section-metadata (bqn src_next/report_section_metadata.bqn) (~95 ms)
       │    -> fzf with preview (`cat <cache_dir>/{1}.txt`)
       └── 5. Output selected cached section or launch direct command
```

### 2.2 Direct Section Output Route (`tools/main-ui.sh --base <base> <key>`)

```text
tools/main-ui.sh --base <base> <key>
  -> tools/report <base> --section <key> --no-color
  -> bqn src_next/report.bqn <base> --section <key> --no-color
       ├── IF key == "balances" (human):
       │    balances.BuildSelected ⟨base, currency_val⟩ -> FormatSelectedHuman -> exit 0
       ├── IF format == "json":
       │    BuildContext <base> -> FormatJson for section -> exit 0
       └── ELSE (all other direct human sections):
            -> BuildContext <base> (loads all posting rows, parses Journal, builds TBDS & Cube)
            -> BuildSectionEntries (constructs ALL 15 human section texts)
            -> FindSectionIndex & output only requested section text
```

---

## 3. Measurements Across Datasets

Measurements present **Min / Median / Max** elapsed wall-clock time in milliseconds across 5 timed runs.

| Dataset / Environment | Posting Rows | Transactions | Accounts |
| :--- | :--- | :--- | :--- |
| **`fixtures/src-next-golden`** | 10 | 2 | 5 |
| **`data` (sandbox)** | 24 | 9 | 10 |
| **`LEDGER_DATA_DIR` (daily use)** | 536 | 247 | 36 |

### 3.1 Baselines & Process Startup

| Benchmark | `fixtures/src-next-golden` | `data` (sandbox) | Daily-Use Data |
| :--- | :--- | :--- | :--- |
| `tools/bl --help` | 89 / 98 / 109 ms | 77 / 80 / 85 ms | 80 / 84 / 87 ms |
| BQN engine startup (`bqn -e 1+1`) | 70 / 75 / 76 ms | 65 / 68 / 69 ms | 67 / 69 / 71 ms |
| BQN `report.bqn` import baseline | 123 / 127 / 135 ms | 118 / 120 / 123 ms | 121 / 126 / 127 ms |
| Journal path resolution (`actual_journal`) | 77 / 85 / 89 ms | 73 / 79 / 82 ms | 74 / 76 / 84 ms |
| `report-section-metadata` export | 89 / 97 / 105 ms | 89 / 94 / 95 ms | 91 / 95 / 100 ms |

### 3.2 Cold vs Warm Cache Generation

| Benchmark | `fixtures/src-next-golden` | `data` (sandbox) | Daily-Use Data |
| :--- | :--- | :--- | :--- |
| **Cold section cache generation** | 445 / 448 / 473 ms | 639 / 642 / 654 ms | **1268 / 1340 / 1391 ms** |
| **Warm selector section-metadata** | 97 / 99 / 111 ms | 88 / 90 / 100 ms | **93 / 98 / 101 ms** |

### 3.3 Representative Direct Section Execution

| Direct Section Key | `fixtures/src-next-golden` | `data` (sandbox) | Daily-Use Data |
| :--- | :--- | :--- | :--- |
| `--section snapshot` | 448 / 463 / 481 ms | 647 / 687 / 1374 ms | **1279 / 1300 / 1381 ms** |
| `--section cycle` | 463 / 776 / 1095 ms | 668 / 687 / 702 ms | **1269 / 1311 / 1351 ms** |
| `--section outlook` | 454 / 483 / 538 ms | 680 / 685 / 706 ms | **1262 / 1300 / 1334 ms** |
| `--section daily-trend` | 509 / 520 / 537 ms | 697 / 754 / 1484 ms | **1332 / 1369 / 1421 ms** |
| `--section balances` (human) | 151 / 175 / 177 ms | 388 / 408 / 437 ms | **927 / 957 / 977 ms** |

### 3.4 Full Report Execution

| Benchmark | `fixtures/src-next-golden` | `data` (sandbox) | Daily-Use Data |
| :--- | :--- | :--- | :--- |
| `tools/report` (full report) | 440 / 449 / 458 ms | 787 / 792 / 808 ms | **1323 / 1369 / 1397 ms** |

---

## 4. Internal Timing Decomposition (`•MonoTime` Probe)

The breakdown below measures exact internal execution phases inside BQN via `src_next/report_latency_probe.bqn` (times in milliseconds).

| Execution Phase | `fixtures/src-next-golden` | `data` (sandbox) | Daily-Use Data (536 rows) |
| :--- | :--- | :--- | :--- |
| Top-level `•Import` evaluation | 57.5 ms | 60.8 ms | 60.4 ms |
| **`BuildContext`** | **54.4 ms** | **213.3 ms** | **818.7 ms** (62%) |
| Precompute `expense_breakdown` | 0.04 ms | 0.05 ms | 0.18 ms |
| Precompute `trial_balance` | 0.02 ms | 0.02 ms | 0.02 ms |
| Precompute `envelope_computation` | 34.4 ms | 44.2 ms | 65.7 ms |
| **All 15 Section Builders Total** | **206.4 ms** | **320.6 ms** | **367.7 ms** (28%) |
| Section cache disk writes (`•FChars`) | 3.2 ms | 2.5 ms | 3.3 ms |
| **Total BQN Internal Elapsed** | **360.3 ms** | **646.4 ms** | **1320.2 ms** |

### 4.1 Per-Section Builder Breakdown (Daily-Use Data)

| Section Builder Key | Time (ms) | Share of Builder Phase |
| :--- | :--- | :--- |
| `outlook` | **119.54 ms** | 32.5% |
| `cycle` | **71.70 ms** | 19.5% |
| `daily-trend` | **61.27 ms** | 16.7% |
| `planned` | **55.44 ms** | 15.1% |
| `daily-flow` | **38.32 ms** | 10.4% |
| `check` | **17.58 ms** | 4.8% |
| `ytd` | 1.64 ms | 0.4% |
| `actual-comparison` | 1.00 ms | 0.3% |
| `recent` | 0.45 ms | 0.1% |
| `balances` | 0.26 ms | 0.1% |
| `snapshot` | 0.20 ms | 0.1% |
| `trial-balance` | 0.13 ms | < 0.1% |
| `issues` | 0.01 ms | < 0.1% |
| `envelopes` | 0.001 ms | < 0.1% |
| `debug` | 0.00 ms | 0.0% |

---

## 5. Cache Invalidation Mechanics

- **Inputs Scanned**: `accounts.tsv`, resolved native journal, `plan.tsv`, `budget_alloc.tsv`, `cycle.tsv`, `issues.tsv`, `config.tsv`, `report_labels.tsv`, and root `src_next/*.bqn`.
- **Observation**: `tools/main-ui.sh` uses `find "$ROOT_DIR/src_next" -maxdepth 1 -name "*.bqn"`. Nested BQN files (e.g. `src_next/queries/*.bqn`) are currently omitted from the mtime scan.
- **Cache Check Overhead**: Scanning mtimes in bash takes ~10 ms; BQN journal path resolution takes ~76 ms. Total cache validity check is ~86 ms.

---

## 6. Key Findings

### 6.1 Directly Observed

1. **Direct section dispatch constructs all 15 sections**: Requesting a single section like `tools/report --section snapshot` takes ~1300 ms on daily-use data. Formatting `snapshot` itself takes only **0.20 ms**, but `src_next/report.bqn` executes `BuildSectionEntries` for all 15 sections (including `outlook` 120ms, `cycle` 72ms, `daily-trend` 61ms, `planned` 55ms) before filtering to the requested key.
2. **`BuildContext` scales with transaction volume**: `BuildContext` time grows from 54 ms (10 rows) to 213 ms (24 rows) to **818.7 ms** (536 rows). It constitutes 62% of cold execution time on daily-use data.
3. **Builder time is heavily concentrated**: 6 out of 15 section builders account for >99% of total section builder time (361 ms out of 368 ms). The remaining 9 builders (including `snapshot`, `balances`, `issues`, `recent`) take < 0.5 ms each.
4. **Stale cache regeneration blocks selector entrance**: On cold/stale cache, opening `tools/bl section` blocks for 1.34+ seconds while generating all section previews via `tools/report --write-section-cache`. On warm cache, selector entrance takes ~98 ms.
5. **Human balances has a specialized dispatch**: `--section balances` dispatches before `BuildContext` using `balances.BuildSelected`, taking 957 ms on 536 rows.

### 6.2 Inferred

1. Single-section requests pay a ~368 ms penalty for constructing 14 unused report sections.
2. `BuildContext` performs full ledger loading, posting IR adaptation, TBDS construction, and Daily Cube materialization for all historical postings, which is required for period balance continuity but represents the majority of execution time as transaction history grows.

### 6.3 Not Yet Determined

1. Whether `BuildContext` can be lazily or partially evaluated for sections that only require posting rows or TBDS without full Daily Cube materialization.
2. Whether section selector UI can display existing warm previews immediately while refreshing stale cache in the background or on demand.

---

## 7. Ranked Candidate Implementation Slices

### Slice 1 (Recommended): Selected-section-only construction for `--section <key>`
- **Description**: Modify `src_next/report.bqn` so that when `--section <key>` is specified, only the requested section builder is executed instead of building all 15 sections.
- **Expected Impact**: Reduces direct single-section latency for light sections (`snapshot`, `balances`, `issues`, `recent`, `trial-balance`, `ytd`, `actual-comparison`) by ~368 ms (from ~1300 ms to ~930 ms on daily-use data).
- **Scope & Safety**: Very small BQN change in `report.bqn`. Zero changes to report text, contracts, accounting core, or CLI flags.

### Slice 2: Selector-first preview display for interactive navigation
- **Description**: Open `fzf`/`gum` selector in `tools/main-ui.sh` using available warm previews or section metadata immediately without blocking on cold cache generation.
- **Expected Impact**: Eliminates the 1.34s cold-start block when entering `tools/bl section`.

### Slice 3: Cache invalidation glob fix for nested modules
- **Description**: Update `tools/main-ui.sh` find command to include nested BQN modules (`src_next/**/*.bqn`).
- **Expected Impact**: Correctness fix preventing stale cache when files under `src_next/queries/` or future subdirectories change.

### Slice 4: Decompose `BuildContext` for lightweight consumers
- **Description**: Allow sections that do not need Daily Cube (e.g. `recent`, `issues`, `check`) to consume posting rows directly without full Cube materialization.
- **Expected Impact**: Reduces `BuildContext` time for lightweight section queries.

---

## 8. Recommendation & Next Steps

**Recommendation**: Proceed next with **Slice 1 (Selected-section-only construction for `--section <key>`)**.

### Invariants for Slice 1 Implementation:
- Preserve exact output text for all section keys (`--section <key>`).
- Preserve full report (`tools/report`) output and section ordering.
- Preserve `--write-section-cache` behavior (writing all section files).
- Preserve `--list-sections` output and section metadata.
- Preserve JSON export behavior (`--format json`).

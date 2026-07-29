# Report Latency Characterization Report

Date: 2026-07-27  
Repository: `shumoku88-bit/bqn-ledger`  
Base SHA: `a826a833799a0e75328ae7aeb794fe44c9018cf2` (`main`)  
PR Branch: `docs/report-latency-characterization-instructions`  

Follow-up status: the measurements and call graphs below are a point-in-time baseline, not the current route. Selected-section-only construction, selector-first Slice 2, and recursive invalidation Slice 3 are now implemented. A TTY opens before cold/stale report computation, shows an explicit non-stale updating status, and refreshes a staged cache in the background; non-interactive callers remain synchronous. BQN now generates the complete canonical cache in one route, including selected-domain balances when `DEFAULT_CURRENCY` is declared; preview files publish by atomic rename, and the validity timestamp publishes last.

---

## 1. Baseline SHA and Environment

- **Target Base SHA**: `a826a833799a0e75328ae7aeb794fe44c9018cf2`
- **Current Branch**: `docs/report-latency-characterization-instructions` (PR #429)
- **Environment**: macOS (Apple Silicon), CBQN v0.1.0, Bash 3.2 / Zsh
- **Measurement Tooling**:
  - `tools/characterization/report-latency-benchmark.sh` (Perl `Time::HiRes` process wall-clock timing harness with one Perl timing process per measured run, failing closed on non-zero status).
  - `tools/characterization/report_latency_probe.bqn` (`•MonoTime` BQN harness timing probe).

---

## 2. Standalone Harness Notice

The BQN probe (`tools/characterization/report_latency_probe.bqn`) lives outside the production `src_next/` source tree. It is a **standalone characterization harness** that reproduces the current section construction sequence of `BuildSectionEntries`, not an internal production hook inside `src_next/report.bqn`. All test outputs generated during probe execution are written to a dedicated temporary directory (`probe_tmp`) inside the benchmark script's root temporary directory (`tmp_bench_dir`), and are guaranteed to be cleaned up on exit by the script's `EXIT` trap even if execution or a command fails mid-run.

---

## 3. Baseline Call Graph & Problem Separation

At the recorded base SHA, static inspection and execution tracing confirmed two distinct performance issues. Both have since been addressed; this section is retained as measurement history:

- **Problem A (Direct Section Latency)**: Invoking `tools/report --section <key>` synchronously and sequentially evaluates all 15 section builders inside `BuildSectionEntries` before discarding 14 outputs and returning the single requested section text.
- **Problem B (Interactive Selector Cold-Start Block)**: Entering `tools/bl section` / `tools/main-ui.sh select` when the cache is missing or stale synchronously blocks opening the selector until `tools/report --write-section-cache` finishes generating all 15 section text files.

### 3.1 Interactive Section Selector Route (`tools/bl` / `tools/main-ui.sh select`)

```text
tools/bl
  -> tools/main-ui.sh --base <base> select
       ├── 1. bqn src_edit/actual_journal_file_cmd.bqn <base> (~19 ms)
       ├── 2. stat scan of source mtimes (accounts, journal, plan, budget_alloc, cycle, issues, config, src_next/*.bqn, report_labels) (~10 ms)
       ├── 3. Cache validity check (.cache-timestamp >= max_src_mtime)
       │    └── IF STALE OR MISSING (Problem B):
       │         tools/report <base> --write-section-cache <dir> --no-color
       │           -> bqn src_next/report.bqn <base> --write-section-cache <dir> --no-color
       │                -> ctx_mod.BuildContext <base>
       │                -> BuildSectionEntries (synchronously evaluates all 15 section builders & formats)
       │                -> write all 15 section text files + all.txt
       ├── 4. select_section <cache_dir>
       │    -> tools/report-section-metadata (bqn src_next/report_section_metadata.bqn) (~34 ms command time)
       │    -> fzf / gum TTY menu rendering with preview (`cat <cache_dir>/{1}.txt`)
       └── 5. Output selected cached section text or launch sub-action
```

### 3.2 Direct Section Output Route (`tools/main-ui.sh --base <base> <key>`)

```text
tools/main-ui.sh --base <base> <key>
  -> tools/report <base> --section <key> --no-color
  -> bqn src_next/report.bqn <base> --section <key> --no-color
       ├── IF key == "balances" (human):
       │    balances.BuildSelected ⟨base, currency_val⟩ -> FormatSelectedHuman -> exit 0
       ├── IF format == "json":
       │    BuildContext <base> -> FormatJson for section -> exit 0
       └── ELSE (all other direct human sections) (Problem A):
            -> BuildContext <base> (loads all posting rows, parses Journal, builds TBDS & Cube)
            -> BuildSectionEntries (synchronously and sequentially evaluates ALL 15 section builders & formats)
            -> FindSectionIndex & output only requested section text
```

---

## 4. Measurements Across Dataset Scales

Measurements below present **Min / Median / Max** process wall-clock elapsed time in milliseconds across 5 timed runs (using single-process Perl `Time::HiRes` timer).

| Dataset Sample | Posting Rows | Transactions | Accounts |
| :--- | :--- | :--- | :--- |
| **`fixtures/editor-golden`** | 8-10 | 2 | 5-6 |
| **`data` (sandbox)** | 24 | 9 | 10 |
| **`LEDGER_DATA_DIR` (daily use)** | 536 | 247 | 36 |

### 4.1 Subprocess Baselines & Metadata Command Execution

| Benchmark | `fixtures/editor-golden` | `data` (sandbox) | Daily-Use Data |
| :--- | :--- | :--- | :--- |
| Command Hub `--help` CLI route (`bl help`) | 26.1 / 28.1 / 31.6 ms | 25.5 / 30.9 / 37.6 ms | 26.6 / 29.9 / 32.9 ms |
| BQN engine startup (`bqn -e 1+1`) | 12.9 / 13.6 / 14.8 ms | 12.3 / 13.4 / 13.6 ms | 12.4 / 13.0 / 14.2 ms |
| BQN `report.bqn` import baseline | 60.7 / 65.4 / 70.2 ms | 59.5 / 65.5 / 73.8 ms | 56.5 / 62.0 / 66.7 ms |
| Journal path resolution (`actual_journal`) | 20.4 / 20.8 / 24.2 ms | 18.1 / 18.9 / 21.9 ms | 18.5 / 19.3 / 21.3 ms |
| `report-section-metadata` command execution | 33.4 / 38.5 / 42.5 ms | 31.8 / 33.7 / 35.6 ms | 32.2 / 34.4 / 40.1 ms |

*Note: The non-interactive `--help` CLI route (`tools/bl help`) measures CLI parsing and help display. Interactive TTY menu rendering (`tools/bl` without args) opens `fzf`/`gum` upon terminal TTY input.*

### 4.2 Cold Section Cache Generation vs Warm Metadata Command Execution

| Benchmark | `fixtures/editor-golden` | `data` (sandbox) | Daily-Use Data |
| :--- | :--- | :--- | :--- |
| **Cold section cache generation** | 384.1 / 387.9 / 408.0 ms | 574.9 / 581.4 / 585.0 ms | **1268.4 / 1298.5 / 1334.6 ms** |
| **Warm selector metadata command** | 33.4 / 37.7 / 42.1 ms | 32.8 / 34.7 / 35.1 ms | **33.8 / 37.1 / 40.4 ms** |

*Note: Warm selector measurement captures `tools/report-section-metadata` process execution, not full TTY `fzf`/`gum` rendering or end-to-end user interaction availability.*

### 4.3 Representative Direct Section Execution

| Direct Section Key | `fixtures/editor-golden` | `data` (sandbox) | Daily-Use Data |
| :--- | :--- | :--- | :--- |
| `--section snapshot` | 382.6 / 385.1 / 401.8 ms | 577.0 / 579.8 / 586.0 ms | **1291.6 / 1311.2 / 1345.9 ms** |
| `--section cycle` | 383.4 / 416.1 / 424.7 ms | 577.4 / 587.0 / 614.7 ms | **1282.7 / 1307.8 / 1340.6 ms** |
| `--section outlook` | 351.0 / 358.7 / 382.8 ms | 577.5 / 586.2 / 617.7 ms | **1283.4 / 1305.2 / 1351.9 ms** |
| `--section daily-trend` | 356.1 / 781.4 / 804.4 ms | 620.3 / 627.3 / 677.5 ms | **1342.1 / 1368.5 / 1402.1 ms** |
| `--section balances` (selected human) | 74.0 / 77.2 / 82.5 ms | 313.5 / 313.7 / 324.5 ms | **868.5 / 902.6 / 937.1 ms** |

### 4.4 Full Report Execution

| Benchmark | `fixtures/editor-golden` | `data` (sandbox) | Daily-Use Data |
| :--- | :--- | :--- | :--- |
| `tools/report` (full report) | 357.4 / 359.8 / 363.5 ms | 634.3 / 637.6 / 683.2 ms | **1328.7 / 1356.4 / 1408.2 ms** |

---

## 5. Internal Harness Timing Decomposition (`•MonoTime` Probe)

The breakdown below measures execution phases inside the characterization harness (`tools/characterization/report_latency_probe.bqn`) (times in milliseconds).

| Execution Phase | `fixtures/editor-golden` | `data` (sandbox) | Daily-Use Data (536 rows) |
| :--- | :--- | :--- | :--- |
| Top-level `•Import` evaluation | 42.9 ms | 60.1 ms | 54.2 ms |
| **`BuildContext`** | **53.7 ms** | **209.3 ms** | **816.2 ms** |
| Precompute `expense_breakdown` | 0.05 ms | 0.04 ms | 0.19 ms |
| Precompute `trial_balance` | 0.02 ms | 0.01 ms | 0.02 ms |
| Precompute `envelope_computation` | 32.9 ms | 47.8 ms | 66.1 ms |
| **All Section Builders & Formatting Total** | **191.8 ms** | **286.6 ms** | **363.9 ms** |
| Section cache disk writes (`•FChars`) | 2.4 ms | 2.3 ms | 3.2 ms |
| **Total Harness Execution Time** | **328.1 ms** | **611.0 ms** | **1308.3 ms** |

### 5.1 Section Builder & Format Evaluation Time Breakdown (Daily-Use Data)

*Note: Timings below measure evaluating both the section builder model logic and its human text formatting (`FormatHuman`) call for each section.*

| Section Key | Builder & Format Eval Time (ms) | Share of Section Eval Phase |
| :--- | :--- | :--- |
| `outlook` | **118.29 ms** | 32.5% |
| `cycle` | **71.22 ms** | 19.6% |
| `daily-trend` | **60.85 ms** | 16.7% |
| `planned` | **54.90 ms** | 15.1% |
| `daily-flow` | **37.89 ms** | 10.4% |
| `check` | **17.48 ms** | 4.8% |
| `ytd` | 1.63 ms | 0.4% |
| `actual-comparison` | 0.99 ms | 0.3% |
| `recent` | 0.44 ms | 0.1% |
| `balances` | 0.26 ms | 0.1% |
| `snapshot` | 0.20 ms | 0.1% |
| `trial-balance` | 0.13 ms | < 0.1% |
| `issues` | 0.01 ms | < 0.1% |
| `envelopes` | 0.001 ms | < 0.1% |
| `debug` | 0.00 ms | 0.0% |

*Observation*: The top 6 section builders (`outlook`, `cycle`, `daily-trend`, `planned`, `daily-flow`, `check`) account for **approximately 99%** (361.05 ms out of 363.90 ms = 99.2%) of total section evaluation time.

---

## 6. Cache Invalidation Scan Observations

- **Inputs Scanned**: `accounts.tsv`, resolved native journal, `plan.tsv`, `budget_alloc.tsv`, `cycle.tsv`, `issues.tsv`, `config.tsv`, `report_labels.tsv`, and root `src_next/*.bqn`.
- **Cache Check Duration**: File mtime scan in bash takes ~10 ms; BQN journal path resolution takes ~19 ms.
- **Nested Module Omission**: `tools/main-ui.sh` currently uses `find "$ROOT_DIR/src_next" -maxdepth 1 -name "*.bqn"`. BQN files located in subdirectories (such as `src_next/queries/*.bqn`) are omitted from the cache mtime scan. This is categorized separately as a **Correctness Characterization Candidate** rather than a performance optimization.

---

## 7. Findings & Categorization

### 7.1 Directly Observed

1. **Direct section execution synchronously evaluates all 15 sections**: Requesting a single section like `tools/report --section snapshot` takes ~1311 ms on daily-use data. Evaluating `snapshot` itself takes only **0.20 ms**, but `src_next/report.bqn` executes `BuildSectionEntries` for all 15 human sections (including `outlook` 118ms, `cycle` 71ms, `daily-trend` 61ms, `planned` 55ms) before filtering to the requested key.
2. **`BuildContext` execution time across sample datasets**: Across the three sample datasets measured (8-10 rows, 24 rows, 536 rows), `BuildContext` execution time was observed at 53.7 ms, 209.3 ms, and **816.2 ms** respectively.
3. **Section evaluation time is concentrated**: 6 out of 15 section evaluation calls account for approximately 99% (99.2%) of section evaluation time (361 ms out of 364 ms).
4. **Cold/stale cache blocks selector entrance**: When cache is missing or stale, `tools/bl section` blocks for **1.30+ seconds** while generating all section text files via `tools/report --write-section-cache`.
5. **Human balances has a specialized dispatch**: `--section balances` dispatches before `BuildContext` using `balances.BuildSelected`, taking 902.6 ms on 536 rows.

### 7.2 Inferred

1. Single-section requests pay a ~364 ms overhead for evaluating 14 unused report sections.
2. Cold cache generation spends >60% of execution time in `BuildContext` and ~28% in section evaluation.

### 7.3 Remaining question

1. Whether `BuildContext` can be lazily or partially evaluated for sections that only require posting rows or TBDS without full Daily Cube materialization.

The former selector question is resolved by the current selector-first background refresh path. It does not display stale financial content silently: while refresh is active, preview rows show an explicit updating status.

The later full-report context follow-up is recorded in `docs/REPORT_CONTEXT_DUPLICATION_CHARACTERIZATION-2026-07-27.md`. Its baseline found repeated cycle/Actual evidence resolution rather than raw source reads alone. Follow-up slices now reuse complete admitted transactions across selected cycle/composition and one complete-or-historical-fallback evidence carrier across compatibility default/explicit cycle resolution. Compatibility and selected checked rows remain distinct contracts rather than a proven sharing boundary.

---

## 8. Ranked Candidate Implementation Slices at the Baseline

### Slice 1: Selected-Section-Only Construction for Direct `--section <key>` (Outcome B)
- **Problem Targeted**: Problem A (Direct Section Latency).
- **Scope Limitation**: Slice 1 targets direct section latency (`tools/report --section <key>`). It does **NOT** directly resolve Problem B (cold/stale cache block when opening interactive selector).
- **Description**: Modify `src_next/report.bqn` so that when `--section <key>` is specified, only the requested section builder is evaluated instead of evaluating all 15 sections.
- **Expected Impact**: Reduces direct single-section latency for light sections (`snapshot`, `balances`, `issues`, `recent`, `trial-balance`, `ytd`, `actual-comparison`) by ~364 ms (from ~1311 ms to ~947 ms on daily-use data).

### Slice 2: Selector-First Preview Display for Interactive Navigation (Outcome A) — implemented
- **Problem Targeted**: Problem B (Interactive Selector Cold-Start Block).
- **Current behavior**: TTY selectors open before cold/stale generation, show explicit updating status, and start one exclusive staged background refresh. Non-interactive selection remains synchronous.
- **Observed outcome**: selector entrance no longer waits for complete report generation; file-only navigation resumes when the background generation publishes.

### Slice 3: Nested Module Cache Invalidation Scan Fix — implemented
- **Problem Targeted**: Correctness / cache freshness for nested BQN modules.
- **Current behavior**: `tools/main-ui.sh` recursively includes `src_next/**/*.bqn` in the source mtime set.
- **Outcome**: root and nested module changes both invalidate the preview cache.

---

## 9. Slice 1 Prerequisites & Implementation Checklist

If Slice 1 is selected for implementation in a future PR, the following prerequisites and edge cases must be preserved:

1. **Shared Precomputations**: Dependent sections (`cycle` requires `exp.entries`, `trial-balance` requires `tb`, `envelopes` requires `vm`) must still evaluate their required shared precomputations.
2. **Unknown Section Key Handling**: Invalid keys must preserve `ERROR: unknown section key: <key>` output and exit status 1.
3. **`--outlook-as-of` Option**: `--outlook-as-of` date override must remain functional when `--section outlook` is selected.
4. **`envelopes` Disabled Policy Guard**: The `vm.status ≢ "disabled"` check and title header formatting for `envelopes` must remain identical.
5. **Section Ordering & `--list-sections`**: Full report order and `--list-sections` descriptor order must remain unchanged.
6. **Human `balances` Specialized Pre-Dispatch**: Human `--section balances` must maintain its specialized `balances.BuildSelected` pre-dispatch route.

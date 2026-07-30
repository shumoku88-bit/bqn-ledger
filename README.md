# bqn-ledger

A plain-text household event ledger and retained report engine written in BQN.

## Requirements

- CBQN with FFI/Singeli support
- `fzf` or `gum` for optional interactive UI

## Data and report configuration

Set the data directory and the separately admitted report-manifest config:

```sh
export LEDGER_DATA_DIR=../ledger-data/data
export REPORT_MANIFEST_CONFIG=../ledger-data/data/report_manifests.tsv
```

The manifest config names distinct human and compact request manifests. Every engine request row carries explicit source basenames, domain, observation, and report-specific coordinates; report routing does not infer them from ledger config. The daily Command Hub treats the human manifest as a source/policy template and resolves one clock-free `current` profile from the latest admitted Actual date, so a normal later-dated Journal append does not require manual date maintenance. Direct `tools/report` requests remain explicit and reproducible for historical use.

Validate strict sources:

```sh
tools/ledger-check "$LEDGER_DATA_DIR" \
  actual.journal plan.tsv budget_alloc.tsv cycle.tsv issues.tsv daily_target_scope.tsv
```

## Reports

```sh
# Interactive retained-report selector
tools/main-ui.sh

# Full current human report through the daily profile
tools/main-ui.sh report

# Full explicit/historical engine report
tools/report "$LEDGER_DATA_DIR" all human report_all_human.tsv

# One retained report through the same manifest row
tools/report "$LEDGER_DATA_DIR" balances human --manifest report_all_human.tsv

# Compact output and exact query
tools/report-summary "$LEDGER_DATA_DIR" "$LEDGER_DATA_DIR/report_all_compact.tsv"
tools/query "$LEDGER_DATA_DIR" "$LEDGER_DATA_DIR/report_all_compact.tsv" ledger_daily_target_amount

# Source-independent catalog metadata
tools/report-section-metadata
tools/report-section-metadata --format json
```

The retained keys are `envelopes`, `balances`, `balance-sheet`, `profit-and-loss`, `recent`, `planned`, `cycle-accounts`, `cycle-comparison`, `monthly-accounts`, `daily-flow`, `daily-target`, and `issues`.

### Local terminal UI preferences

UI preferences belong in the ignored `.env`, not household `data/config.tsv`:

```sh
BL_SELECTOR=auto                 # auto | fzf | gum | plain
BL_FZF_PREVIEW_WINDOW=right:75%  # right|left|up|down and 1–100%
```

`auto` prefers fzf, then gum. Only fzf has a report preview pane; gum is a filter-only fallback. Invalid explicit values fail with a configuration error instead of silently changing behavior. See [`.env.example`](.env.example).

Operational diagnostics are separate from reports:

```sh
tools/ledger-check --help
tools/ledger-inspect --help
```

## Editing

```sh
tools/add-ui.sh
tools/edit-bqn --help
```

Writes use preview, stale checks, backups, atomic replacement, and narrow post-write validation. Canonical household data remains in the separate private data repository.

## Development

```sh
tools/check.sh
tools/doctor
```

Start with [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), [`docs/AI_CODEMAP.md`](docs/AI_CODEMAP.md), and [`TODO.md`](TODO.md).

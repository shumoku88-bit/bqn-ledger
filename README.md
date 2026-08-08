# bqn-ledger

A plain-text household event ledger and retained report engine written in BQN.

## Requirements

- CBQN with FFI/Singeli support
- `fzf` or `gum` (Optional for rich TUI; minimal mode works out of the box with CBQN + Bash alone)

## Canonical Household root

Point `LEDGER_DATA_DIR` at the Household root shared with `h-kernel`:

```sh
export LEDGER_DATA_DIR=/path/to/canonical-household
```

The retained read side uses these eight physical sources:

- `accounts.journal`
- `actual.journal`
- `plan.journal`
- `budget.journal`
- `budget.toml`
- `household.toml`
- `report.toml`
- `issues.tsv`

`report.toml` owns current report query defaults and presentation policy. It does not name physical source files. Report requests carry semantic coordinates such as domain and dates; canonical source identity is resolved internally from the Household root.

For a single-domain Household, the Command Hub can infer the report domain from admitted canonical facts. With multiple domains, select one explicitly:

```sh
export REPORT_DOMAIN=JPY
```

Direct historical requests remain explicit and reproducible without exposing source basenames.

## Reports

```sh
# Interactive retained-report selector
tools/main-ui.sh

# Full current human report from report.toml
tools/main-ui.sh report

# Explicit domain when the Household contains multiple domains
tools/main-ui.sh --domain JPY report

# One explicit/historical report
tools/report "$LEDGER_DATA_DIR" balances human JPY 2026-01-31
tools/report "$LEDGER_DATA_DIR" profit-and-loss human JPY 2026-01-01 2026-02-01

# Full current report for one domain
tools/report-all "$LEDGER_DATA_DIR" JPY human

# Compact output and exact query
tools/report-summary "$LEDGER_DATA_DIR" JPY
tools/query "$LEDGER_DATA_DIR" JPY ledger_daily_target_amount

# Source-independent catalog metadata
tools/report-section-metadata
tools/report-section-metadata --format json
```

`LATEST` may be supplied to current-report tools for deterministic tests or snapshots. Normal operation resolves `latest` from the local day at the application boundary; the pure report-policy resolver itself has no clock.

The retained keys are `envelopes`, `balances`, `balance-sheet`, `profit-and-loss`, `recent`, `planned`, `cycle-accounts`, `cycle-comparison`, `monthly-accounts`, `daily-flow`, `daily-target`, and `issues`.

### Local terminal UI preferences

UI preferences belong in the ignored `.env`, not Household policy files:

```sh
BL_UI_MODE=rich                  # rich | minimal (minimal mode has zero TUI dependencies)
BL_THEME=nord                    # nord | catppuccin | tokyo-night | dracula | savepoint | plain
BL_SELECTOR=auto                 # auto | fzf | gum | plain
BL_FZF_PREVIEW_WINDOW=right:75%  # right|left|up|down and 1–100%
```

`auto` prefers fzf, then gum. When `fzf` and `gum` are not installed (or when `BL_UI_MODE=minimal`), the UI automatically falls back to the zero-dependency **Minimal Mode** (pure Bash numbered prompts + interactive arrow-key preview browser). See [`.env.example`](.env.example).

Operational diagnostics are separate from reports and accept the canonical Household root, never individual source basenames:

```sh
tools/ledger-check "$LEDGER_DATA_DIR"
tools/ledger-inspect "$LEDGER_DATA_DIR"
```

## Editing

```sh
tools/add-ui.sh
tools/edit-bqn --help
```

Writer qualification is separate from the canonical read-side recovery. Existing writer authority is not changed by report configuration. Writes continue to use preview, stale checks, backups, atomic replacement, and narrow post-write validation. Canonical household data remains in the separate private data repository.

## Development

```sh
tools/check.sh
tools/doctor
```

Start with [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), [`docs/AI_CODEMAP.md`](docs/AI_CODEMAP.md), and [`TODO.md`](TODO.md).

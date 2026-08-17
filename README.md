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
- `entitlement.journal`
- `envelope.toml`
- `household.toml`
- `report.toml`
- `issues.tsv`

`entitlement.journal` has exactly two source fact forms:

```text
YYYY-MM-DD origin COMMODITY [memo]
YYYY-MM-DD transfer FROM -> TO QUANTITY COMMODITY [memo]
```

Transfer endpoints are `unallocated` or a stable `EnvelopeId`. `unallocated` is a boundary, not an Account or stored balance. Current Envelope presentation/membership and Backing policy live in `envelope.toml`; stable Envelope identities and historical Expense/Fulfillment routing live in `household.toml`.

`report.toml` owns current report query defaults and presentation policy. It does not name physical source files. Report requests carry semantic coordinates such as domain and dates; canonical source identity is resolved internally from the Household root.

For a single-domain Household, the Command Hub can infer the report domain from admitted canonical facts. With multiple domains, select one explicitly:

```sh
export REPORT_DOMAIN=JPY
```

Direct historical requests remain explicit and reproducible without exposing source basenames.

## Daily Command Hub

```sh
# One interactive entrance for recording, browsing, reports, and operations
tools/bl

# Discoverable direct routes also work without an interactive selector
tools/bl --base "$LEDGER_DATA_DIR" journal list
tools/bl --base "$LEDGER_DATA_DIR" plans overdue
tools/bl --base "$LEDGER_DATA_DIR" accounts list
tools/bl --base "$LEDGER_DATA_DIR" issues list

# Full current human report from report.toml
tools/bl report

# Explicit domain when the Household contains multiple domains
tools/bl --domain JPY report

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

The Hub is grouped into Record, Plans, Budget, Accounts, Issues, Reports, and Inspect / Operations. Its Reports menu is generated from the static twelve-report catalog. It routes only: report meaning remains in BQN owners and all mutation routes continue through the qualified editor writers.

Operational diagnostics are separate from reports and accept the canonical Household root, never individual source basenames:

```sh
tools/bl check       # canonical Household readiness, not repository tests
tools/bl inspect
tools/bl doctor
tools/bl export      # canonical Journal projection for hledger

# Equivalent low-level operations
tools/ledger-check "$LEDGER_DATA_DIR"
tools/ledger-inspect "$LEDGER_DATA_DIR"
```

See [`docs/CANONICAL_CAPABILITY_MATRIX.md`](docs/CANONICAL_CAPABILITY_MATRIX.md) for the historical/current capability inventory, owners, recovery classification, and intentional non-capabilities.

## Editing and export

The Command Hub routes ordinary two-Posting and multi-Posting entries, Plan add/edit/finish/replenishment, native Entitlement transfers, and Account creation to the qualified canonical writers. Low-level commands remain available for automation:

```sh
tools/add-ui.sh
tools/edit-bqn --help

# Native Entitlement endpoint transfer
tools/edit --base "$LEDGER_DATA_DIR" entitlement transfer \
  --date 2026-01-31 --from unallocated --to food --amount 1000 --memo allocation --dry-run

# Copy the canonical Journal surface for hledger (no legacy TSV input)
tools/to-hledger "$LEDGER_DATA_DIR"
```

Every interactive mutation displays a candidate preview and confirmation before publication. Plan Finish retains its `plan-id` provenance and can replenish the next Plan while inheriting recurrence metadata. Completed Plans are observed as Envelope Fulfillment through historical PlanId routing; completion does not write a Budget execution companion.

Writer qualification is separate from the canonical read-side recovery. Existing writer authority is not changed by report configuration. Writes continue to use preview, stale checks, backups, atomic replacement, and narrow post-write validation. Canonical household data remains in the separate private data repository.

## Development

```sh
tools/check.sh
tools/doctor
```

Start with [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), [`docs/AI_CODEMAP.md`](docs/AI_CODEMAP.md), and [`TODO.md`](TODO.md).

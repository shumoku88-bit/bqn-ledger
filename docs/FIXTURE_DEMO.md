# Fixture Demo Walkthrough

Status: current operational guide
Owner: docs
Canonical: no; canonical path: `docs/DATA_DIR_SETUP.md`
Exit: revise when the public demo fixture or command path changes

This document is a small public demo path for BQN Ledger. It uses synthetic fixture data only. Do not use real household data, real account names, private file paths, or screenshots with private balances.

## What this demo shows

1. Eight human-readable canonical Household sources.
2. BQN report generation as a derived view.
3. Safe editor preview/write paths.
4. Native Envelope Entitlement without Budget Accounts.

## 1. Read fixture reports

```bash
tools/report fixtures/ledger-facts-phase1-proof balances human JPY 2026-01-12
tools/report fixtures/ledger-facts-phase1-proof envelopes human JPY \
  2026-01-01 2026-02-01 2026-01-12
```

The report is derived from the fixture Household root, not private data or hidden application state.

## 2. Read the machine summary

```bash
tools/report-summary fixtures/ledger-facts-phase1-proof JPY 2026-01-12
tools/query fixtures/ledger-facts-phase1-proof JPY ledger_envelope_backing_surplus 2026-01-12
```

Compact output is useful for regression checks and bounded external inspection.

## 3. Inspect the canonical sources

```bash
ls fixtures/ledger-facts-phase1-proof
cat fixtures/ledger-facts-phase1-proof/accounts.journal
cat fixtures/ledger-facts-phase1-proof/actual.journal
cat fixtures/ledger-facts-phase1-proof/plan.journal
cat fixtures/ledger-facts-phase1-proof/entitlement.journal
cat fixtures/ledger-facts-phase1-proof/envelope.toml
cat fixtures/ledger-facts-phase1-proof/household.toml
```

The canonical topology is:

```text
accounts.journal
actual.journal
plan.journal
entitlement.journal
envelope.toml
household.toml
report.toml
issues.tsv
```

`entitlement.journal` contains only:

```text
YYYY-MM-DD origin COMMODITY [memo]
YYYY-MM-DD transfer FROM -> TO QUANTITY COMMODITY [memo]
```

## 4. Try the editor in a scratch directory

```bash
sandbox=$(mktemp -d)
cp -R fixtures/ledger-facts-phase1-proof/. "$sandbox"/

tools/edit --base "$sandbox" entitlement transfer \
  --date 2026-01-13 --from unallocated --to food \
  --amount 5 --memo demo --dry-run

tools/edit --base "$sandbox" journal add \
  --date 2026-01-13 --from assets:cash --to expenses:food \
  --amount 1 --memo demo --dry-run

rm -rf "$sandbox"
```

Dry-run shows the exact candidate without modifying source bytes or creating a backup. A real append uses confirmation, stale-source fencing, complete candidate admission, backup, post-publication validation, and guarded rollback.

## 5. Run public qualification

```bash
tools/check.sh
tools/coverage
```

These commands operate on repository code and synthetic fixtures. They do not require private household data.

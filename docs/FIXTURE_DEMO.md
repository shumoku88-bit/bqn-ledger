# Fixture Demo Walkthrough

This document is a small public demo path for BQN Ledger.

It uses fixture data only. Do not use real household data, real account names, private file paths, or screenshots with private balances when preparing public demos or application material.

## What this demo shows

BQN Ledger keeps source data as human-readable TSV, derives reports with BQN, and routes daily writes through a small Go editor.

The demo shows three layers:

1. TSV source data as the visible ground.
2. BQN report generation as the derived view.
3. Go editor preview/write path as the protected input route.

## 1. Read a fixture report

```bash
tools/report fixtures/src-next-golden
```

Expected meaning:

- `fixtures/src-next-golden` is the demo base directory.
- `tools/report` is the daily production report wrapper.
- The report is derived from fixture TSV files, not from private data.

## 2. Read the machine summary

```bash
tools/report-next-summary fixtures/src-next-golden
```

Expected meaning:

- This is the compact machine-readable summary path.
- It is useful for regression checks, AI review, and external inspection.

## 3. Inspect source TSV files

```bash
ls fixtures/src-next-golden
cat fixtures/src-next-golden/journal.tsv
cat fixtures/src-next-golden/plan.tsv
cat fixtures/src-next-golden/budget_alloc.tsv
cat fixtures/src-next-golden/accounts.tsv
cat fixtures/src-next-golden/cycle.tsv
```

Expected meaning:

- The source of truth is still plain TSV.
- Reports are derived from these files rather than hidden application state.

## 4. Try the Go editor in a scratch directory

```bash
mkdir -p sandbox
cp fixtures/plan-completion/*.tsv sandbox/
./tools/edit --base sandbox plan list
./tools/edit --base sandbox plan finish --index 1 --actual-date 2026-01-12
```

Expected meaning:

- The preview command shows the write that would happen.
- Without `--apply`, it does not write the finished entry.
- This demonstrates the review-before-write path.

## 5. Run the check suite

```bash
tools/check.sh
```

Expected meaning:

- Unit tests, golden fixtures, section checks, repo hygiene checks, and editor tests are grouped behind one maintainer command.
- This is the main safety net before merging report or editor changes.

## Public demo rule

For public demos, applications, screenshots, and issue reports:

- Use `fixtures/` or the public `data/` sandbox.
- Do not show real balances, real household data, real account names, private paths, tokens, or local machine identifiers.
- Prefer command output that can be recreated from committed fixture files.

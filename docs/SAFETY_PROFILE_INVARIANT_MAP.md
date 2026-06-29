# Safety Profile Invariant Map

Status: **current re-audit / src_next guard map**
Created: 2026-06-22
Updated: 2026-06-27
Source: `docs/SAFETY_PROFILE.md`
Current task truth: `TODO.md`

This document maps Safety Profile invariant candidates to the **current `src_next` repository state**.

Important: old-engine files such as `src/reports/report_engine.bqn`, `checks/lint_cli.bqn`, `checks/lint_journal.bqn`, `checks/check-cube-shape.bqn`, `checks/check-forecast-zero.bqn`, and `checks/check-section-status.sh` no longer exist in this repository. Historical docs may still mention them, but they are not current guards.

This document does not change implementation behavior and does not approve new source TSV writes.

## Reading rule

Use this file to answer:

```text
Which Safety Profile invariant is guarded by current src_next checks?
Which one is only documented?
Which one is partially guarded?
Which one still needs a check / lint / fixture / report status policy?
```

Current guard inventory:

```text
tools/check.sh
checks/check-src-next-*.sh
checks/check-src-next-budget-actual-zero.sh
checks/check-src-next-clock-boundary.sh
checks/check-repo-index.sh
checks/check-disabled-features.sh
tests/test_src_next_*.bqn
editor/*_test.go
```

## Status labels

| status | meaning |
|---|---|
| `GUARDED` | Current check, unit test, fixture, or contract directly guards the invariant. |
| `PARTIAL` | Some protection exists, but scope or failure behavior is incomplete. |
| `DOC_ONLY` | The rule is documented, but no current automated guard was confirmed. |
| `GAP` | A missing guard is known and should become a TODO. |
| `POLICY` | This is a working boundary or human/agent policy, not only a code invariant. |

## Summary

| area | status | current guard summary |
|---|---|---|
| Source TSV shape / required fields | `PARTIAL` | `src_next/loader.bqn` and `projection.bqn` produce skipped/invalid projection diagnostics; golden fixtures cover malformed / missing data classes. No standalone current lint map exists after old-engine removal. |
| Empty column preservation | `GUARDED` | `src_next` uses `SplitTsvKeepEmpty`; `fixtures/src-next-broken-empty-columns` and `fixtures/empty-fields` are connected to current checks. |
| Unknown account rejection / diagnosis | `GUARDED` | `fixtures/src-next-unknown-account`, readiness/minimal-summary checks, and cube row acceptance keep unknown accounts out of cube indices. |
| Integer amount | `PARTIAL` | Projection/readiness paths diagnose invalid posting data; explicit current standalone amount lint inventory is not yet mapped here. |
| Future / out-of-period actuals | `PARTIAL` | `fixtures/src-next-out-of-cycle-journal` and readiness/minimal-summary checks cover skipped out-of-period rows. Hard error policy for all future actual cases needs a refreshed current contract. |
| Budget account row boundary | `PARTIAL` | Current envelope and budget fixtures cover some behavior, but old standalone lint references are gone. |
| Missing budget mapping for variable expense | `GUARDED` | `fixtures/src-next-missing-budget-mapping` and current golden/minimal checks are connected through `tools/check.sh`. |
| Canonical Daily Cube shape | `GUARDED` | `src_next/cube.bqn` materializes `Day × AccountKey × Layer`; `tests/test_src_next_cube.bqn` and `check-src-next-golden.sh` cover shape output, skipped row boundaries, layer totals, and dynamic account count. |
| Dynamic account axis | `GUARDED` | Account count is `ak_count` from `accounts.tsv` resolution, not a fixed 256 slot space. `src_next/cube.bqn` accepts `ak_count`; golden output includes the runtime shape. |
| Layer source meaning | `PARTIAL` | Layer constants are fixed in `src_next/cube.bqn`; projection and summary checks cover actual/plan totals. Full source-to-layer provenance assertions remain incomplete. |
| `budget:*` Actual layer zero | `GUARDED` | `checks/check-src-next-budget-actual-zero.sh` verifies that budget:* accounts carry zero Actual layer totals in `src_next/main.bqn` output. Connected to `tools/check.sh`. |
| Forecast layer safety | `PARTIAL` | Layer 3 exists as `forecast`, but old `check-forecast-zero` is gone. Current golden output includes forecast layer totals; dedicated forecast-zero policy should be refreshed if forecast-derived views are added. |
| `as_of` entry boundary | `GUARDED` | `checks/check-src-next-clock-boundary.sh` verifies that only `src_next/date.bqn` reads the system clock. `src_next/date.bqn` exports `Today` as the single approved entry point. Connected to `tools/check.sh`. |
| Cycle half-open / historical availability | `PARTIAL` | `src_next/cycle.bqn`, TBDS tests, cycle summary checks, and opening-before-cycle tests cover important cases. Full overlap/reversal lint inventory is not mapped here. |
| Section status policy | `PARTIAL` | Policy exists, and current compact output exposes status-like fields for some sections (`actual-comparison`, envelope/status fields), but old `section_status_*` exporter is gone. |
| BQN editor write boundary | `GUARDED/POLICY` | `docs/archive/active-plans/GO_EDITOR_NEXT_PLAN.md`, `docs/GO_EDITOR_USAGE.md`, `editor/*_test.go`, and now-gating Go tests cover approved editor behavior. |
| Multi-file write / idempotency safety | `GAP` | Explicitly not widened; failure-injection and idempotency tests remain TODO before any broader write scope. |

## Source invariants

### S1. Source TSV first five columns are preserved

Status: `PARTIAL`

Current guards:

- Source TSV contract is documented in `docs/ARCHITECTURE.md`, `docs/CONVENTIONS.md`, and `docs/JOURNAL_META.md`.
- `src_next/loader.bqn` exposes `SplitTsvKeepEmpty` for journal-like rows.
- `fixtures/src-next-broken-empty-columns` is connected to `check-src-next-golden.sh` through `tools/check.sh`.
- BQN editor tests cover safe append/edit behavior for approved writer commands.

Known gap:

- No single current invariant check inventories every parser and every writer against the first-five-column contract.

### S2. Empty fields are preserved where required

Status: `GUARDED`

Current guards:

- `src_next/loader.bqn` uses keep-empty TSV splitting.
- `fixtures/src-next-broken-empty-columns` and `fixtures/empty-fields` are included in current check paths.
- `tests/test_src_next_cube.bqn` verifies invalid/sentinel projection rows are skipped rather than indexed.

### S3. Undefined accounts are not used as cube indices

Status: `GUARDED`

Current guards:

- `fixtures/src-next-unknown-account` is included in golden and minimal summary checks.
- `src_next/cube.bqn` validates `account_key_index` against runtime `ak_count` before materialization.
- `tests/test_src_next_cube.bqn` asserts unknown-account sentinel rows are skipped and do not become cube indices.

Known gap:

- Future metadata account-like fields should be added to validation only after their contract is explicit.

### S4. Amounts are integer yen

Status: `PARTIAL`

Current guards:

- Projection/readiness checks expose invalid posting counts and skipped invalid rows.
- `fixtures/src-next-invalid-posting` is included in current golden/minimal checks.

Known gap:

- This re-audit did not map a standalone current integer-amount lint equivalent after old-engine cleanup.

### S5. AI / assistant does not edit real source TSV without explicit instruction

Status: `POLICY`

Current guards:

- `AGENTS.md`, `README.md`, `docs/QUALITY_BAR.md`, and `docs/SAFETY_PROFILE.md` state source TSV protection.
- This audit and fix plan explicitly avoid source TSV edits.

Known gap:

- This is a human/agent boundary. It is not fully enforceable by BQN checks.

## Cube invariants

### C1. Canonical Daily Cube shape is fixed

Safety Profile candidate:

```text
Day × AccountKey × Layer
```

Status: `GUARDED`

Current guards:

- `docs/CANONICAL_DAILY_CUBE.md` defines the axes and forbids adding store, memo, category, or arbitrary tags as cube axes.
- `src_next/cube.bqn` materializes `day_count × ak_count × layer_count` with `layer_count = 4`.
- `tests/test_src_next_cube.bqn` verifies row acceptance, skipped rows, layer totals, and validation summary.
- `checks/check-src-next-golden.sh` compares compact shape / layer / validation output against fixtures.

Known gap:

- A small dedicated shape-only check could still be useful, but current golden/unit coverage guards the core shape.

### C2. Layer sources remain separate

Status: `PARTIAL`

Current guards:

- `src_next/cube.bqn` fixes layer indices: `actual=0`, `plan=1`, `budget=2`, `forecast=3`.
- `src_next/projection.bqn` maps source rows into layer-indexed projection rows.
- Minimal summary checks assert actual/plan total consistency and per-account actual totals.

Known gap:

- Full source-to-layer provenance assertions for every projection kind are not yet mapped.

Next action:

- Add provenance-oriented checks before changing projection logic.

### C3. `budget:*` account Actual layer is zero

Status: `GUARDED`

Current guards:

- The invariant is documented in `docs/CANONICAL_DAILY_CUBE.md`.
- `checks/check-src-next-budget-actual-zero.sh` directly asserts that `budget:*` accounts carry zero Actual layer totals in `src_next/main.bqn` output.
- The check is connected through `tools/check.sh`.

Known gap:

- No known current gap for this direct invariant. Future budget projection changes should keep this check in the main suite.

### C4. Forecast layer is safe when unimplemented

Status: `PARTIAL`

Current guards:

- `src_next/cube.bqn` reserves layer index 3 as `forecast`.
- Golden summary output includes forecast layer totals.

Known gap:

- Old `check-forecast-zero` is gone. A dedicated forecast-zero / unavailable contract should be added before forecast-derived report sections are introduced.

### C5. Event/projection level zero-sum

Status: `PARTIAL`

Current guards:

- `src_next/cube.bqn` validation summary checks actual/plan totals and per-account actual totals.
- `checks/check-src-next-minimal-summary.sh` asserts projection/cube balance fields from compact output.

Known gap:

- A current standalone per-`source_id` / per-`tx_id` zero-sum check is not mapped here.

## Time invariants

### T1. `as_of` is fixed at the entry boundary

Status: `GUARDED`

Current guards:

- `docs/TIME_AS_AXIS.md` defines `system_today` / `as_of` separation.
- Current `src_next` report wrappers pass a base directory and do not require UI/editor helpers for canonical report calculation.
- `checks/check-src-next-clock-boundary.sh` verifies that no `src_next/*.bqn` module except `src_next/date.bqn` reads the system clock directly.
- `tools/check.sh` runs `check-src-next-clock-boundary.sh` as part of the engine-independent checks.

Known gap:

- No known current gap for direct clock-reference guarding. Export-specific `system_now` / `generated_at` semantics still require a separate contract before introduction.

### T2. Future / out-of-period journal rows are not silently included

Status: `PARTIAL`

Current guards:

- `fixtures/src-next-out-of-cycle-journal` is included in golden and minimal summary checks.
- `src_next/cube.bqn` skipped summary distinguishes `day_before_start` / `day_after_end` from valid cube rows.

Known gap:

- Hard error vs skipped/report-diagnostic policy for all future actual cases needs a current section contract.

### T3. Cycle is a half-open interval and invalid cycle config fails safely

Status: `PARTIAL`

Current guards:

- `docs/TIME_AS_AXIS.md` defines `cycle = [start, end_exclusive)`.
- `src_next/cycle.bqn`, `src_next/tbds.bqn`, and related tests/checks cover key period behavior.
- `tests/test_src_next_tbds_opening_before_cycle.bqn` guards opening-before-period behavior.

Known gap:

- This map does not confirm every overlap/reversal case in cycle configuration.

## Report status implementation

Status: `PARTIAL`

Current guards:

- `docs/REPORT_SECTION_STATUS_POLICY.md` defines `OK / WARN / ERROR / SKIPPED / UNAVAILABLE` vocabulary.
- Current `src_next` compact output includes status-like fields for some sections, e.g. `src_next_actual_comparison_status` and `src_next_envelope_status`.
- `checks/check-src-next-actual-comparison.sh` checks actual-comparison status output.

Known gap:

- The old machine-readable `section_status_*` exporter has been removed with the old engine.
- Most sections do not expose a uniform machine-readable status yet.
- `SKIPPED` remains mostly policy-level.

Next action:

- Reintroduce uniform section status only one section at a time, with current `src_next` fixtures and checks.

## Editor invariants

### E1. Approved writes go through preview / confirm / backup / stale check / post-check

Status: `GUARDED/POLICY`

Current guards:

- `docs/archive/active-plans/GO_EDITOR_NEXT_PLAN.md` defines the current BQN editor boundary and safe write scope.
- Current approved commands include `journal add`, `journal reverse`, `budget add`, `plan add`, `plan finish --apply`, and narrow open-plan `date` / `amount` edit.
- `editor/*_test.go` covers the approved BQN editor behavior, and `tools/check.sh` now gates on `go test ./...` in `editor/` (if `go` is not installed, it emits a warning and skips).

Known gap:

- Any broader write scope still needs new tests and explicit approval.

### E2. Deletion and large edits remain manual / not approved for helper UI

Status: `POLICY`

Current guards:

- `docs/archive/active-plans/GO_EDITOR_NEXT_PLAN.md` keeps deletion, broad row editing, and multi-file transactions outside current scope.
- `AGENTS.md` and `README.md` state that AI must not edit real source TSV without explicit instruction.

### E3. Multi-file transactions are not widened before idempotency / failure-injection design

Status: `GAP`

Current guards:

- `docs/archive/active-plans/GO_EDITOR_NEXT_PLAN.md` marks multi-file transactions and additional writes as planning-only.
- `TODO.md` keeps idempotency, recurrence, metadata, concurrency, recovery contracts as active work.

Known gap:

- No failure-injection / idempotency test suite is mapped here.

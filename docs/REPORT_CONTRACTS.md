# Report Contracts

Status: current index / boundary note
Date: 2026-06-29

This file exists so current safety and report-policy docs have a live landing page.

It is **not** a revival of the archived old-engine report contract. The historical contract remains at:

- `docs/archive/completed-plans/REPORT_CONTRACTS.md`

## Current sources of truth

For current `src_next` behavior, use these in order:

1. `tools/report --list-sections` — canonical list of currently runnable human report sections.
2. `src_next/report.bqn` — section dispatcher and human report rendering entrypoint.
3. `tools/report-section-metadata` — structured section metadata export for UI tools (TSV default / JSON), without reading source TSV.
4. `src_next/summary.bqn` — current machine-readable compact summary fields.
5. `docs/REPORT_SECTION_CONTRACT_CHECKLIST.md` — checklist for section identity, data ownership, empty-state/status behavior, labels, machine output, and fixture coverage.
6. `docs/archive/active-plans/REPORT_SECTION_STATUS_POLICY.md` — `OK / WARN / ERROR / SKIPPED / UNAVAILABLE` status vocabulary and partial implementation policy.
7. Fixture checks under `checks/check-src-next-*.sh` and BQN unit tests under `tests/test_src_next_*.bqn` — executable contracts.

## Current section list

As of this note, `tools/report --list-sections` reports these section keys:

```text
snapshot
issues
ytd
balances
cycle
trial-balance
envelopes
planned
recent
check
outlook
daily-trend
actual-comparison
debug
```

Do not edit this list by hand as a contract change. If section behavior changes, update the implementation/checks first, then refresh this note if it is useful.

## Envelope safety note

The `envelopes` section must not show only per-envelope balances while hiding an over-allocated budget pool. Current `src_next/envelope_computation.bqn` derives the unassigned pool from `accounts.tsv` entries with `role=budget kind=unassigned` and exposes these compact summary keys.

Important: this is **ledger unassigned**, not cash-backed surplus. It is the unallocated amount inside the Budget layer / `budget_alloc.tsv` movements. It must not be presented as "safe to spend" until a Budget Backing invariant defines 可用資金 (`type=liquid`) and cash backing for envelope balances.

- `src_next_envelope_unassigned_remaining`
- `src_next_envelope_unassigned_status`
- `src_next_envelope_unassigned_account_count`

If the unassigned pool is negative, status is `OVER_ALLOCATED` and the human report shows a visible warning.

The section also exposes a readonly backing diagnostic. This is intentionally not a write-path or allocation rule yet: `src_next_envelope_funding_base` is currently a provisional `type=liquid` actual closing balance, while `src_next_envelope_allocated_total` is the sum of active envelope remaining balances. `src_next_envelope_cash_backed_unassigned` and `src_next_envelope_backing_status` show whether the envelope balances are cash-backed under that provisional base.

Backing status vocabulary:

- `OK`: cash-backed unassigned equals ledger unassigned.
- `MISMATCH`: cash-backed unassigned differs from ledger unassigned; readonly diagnostic only, no automatic correction.
- `OVER_ALLOCATED`: active envelope remaining total exceeds the provisional funding base.
- `unavailable...` / `error...`: backing diagnostic cannot be trusted because the unassigned budget account is missing, ambiguous, or otherwise unavailable.

- `src_next_envelope_funding_base`
- `src_next_envelope_allocated_total`
- `src_next_envelope_cash_backed_unassigned`
- `src_next_envelope_ledger_cash_delta`
- `src_next_envelope_backing_status`
- `src_next_envelope_funding_base_source` (repeated when funding source accounts exist)
- `src_next_envelope_active_remaining_source` (repeated)
- `src_next_envelope_ledger_unassigned_source` (repeated when unassigned account exists)
- `src_next_envelope_active_movement` (repeated budget-layer movement provenance)
- `src_next_envelope_ledger_unassigned_movement` (repeated budget-layer movement provenance)

Movement provenance values are TSV-like payloads: `date<TAB>source_row<TAB>account<TAB>side<TAB>delta<TAB>source_id`.

## What belongs here later

Only add stable contracts here when they are true for the current `src_next` engine and have a check/fixture or clear implementation reference.

Good candidates:

- per-section checklist applications after they have matching checks,
- section-level status contract once the output is uniform enough to document,
- machine-readable summary key groups that are intentionally stable,
- fail-closed behavior for known invalid input classes.

Do not put old-engine guarantees here unless they have been revalidated against current `src_next`.

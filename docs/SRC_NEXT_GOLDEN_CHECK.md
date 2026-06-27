# src_next golden check

Phase 8 adds a tiny fixture for the `src_next` path:

```text
fixtures/src-next-golden/
  accounts.tsv
  cycle.tsv
  journal.tsv
  plan.tsv
  expected/src_next_summary.txt
```

Run the prototype against the fixture:

```sh
bqn src_next/main.bqn fixtures/src-next-golden
```

Run the compact golden check:

```sh
bash checks/check-src-next-golden.sh fixtures/src-next-golden
```

The expected summary pins the stable values that should not drift accidentally:

- cycle mode, start, end, and day count
- AccountKey count
- ledger-like projection row samples (`source_id`, `side`, account key index, signed delta)
- projection balance status by `source_id`
- cube shape
- valid and skipped projection row counts
- skipped out-of-cycle plan row reason
- actual, plan, budget, and forecast layer totals
- nonzero actual account totals
- numeric verification status
- minimal report summary fields: `src_next_cycle_range`, `src_next_valid_projection_rows`, `src_next_skipped_projection_rows`, signed `src_next_actual_total` / `src_next_plan_total`, debit-side expense totals, and nonzero actual/plan per-account totals

This is intentionally smaller than a full stdout golden file. `src_next/main.bqn` still mixes inspection rendering with calculation, so these checks pin projection semantics and core numbers without freezing every display line.

Current projection semantics are ledger-like: one source journal/plan row normally expands into a debit-side projection row and a credit-side projection row. Derived rows keep the same `source_id`; `side` makes the two rows visible. Deltas use the convention `debit` = positive and `credit` = negative, so ordinary balanced source rows should sum to `0` per `source_id`. `src_next` remains experimental and read-only.

For manual observation against selected production-engine numbers, see `docs/SRC_NEXT_CURRENT_ENGINE_COMPARISON.md` and `checks/check-src-next-vs-current.sh`. That comparison is deliberately not a production replacement check.

For account and expense classification notes before food / daily remaining work, see `docs/SRC_NEXT_EXPENSE_ACCOUNT_MAPPING.md`. For the intended configurable household report policy contract, see `docs/SRC_NEXT_HOUSEHOLD_REPORT_POLICY_CONTRACT.md`.

Before considering src_next as a production replacement, see `docs/SRC_NEXT_REPLACEMENT_READINESS.md`.

`src_next/cube.bqn` owns the next boundary: projection rows are partitioned into valid rows and skipped rows, only valid rows are materialized into the cube, and skipped rows expose both detailed reasons and a compact skipped-summary namespace. Sentinel account-key indices and out-of-cycle day indices are kept as skipped evidence and are not used as cube indices.

### Phase 8.6: household metadata diagnostics (added 2026-06-24)

`src_next/household_metadata.bqn` provides computation-free account metadata diagnostics visible in both `tools/report-next` (full) and `tools/report-next-summary` (compact). The golden grep pattern includes `src_next_household_metadata_` fields.

`checks/check-src-next-household-metadata.sh` validates the format and consistency of the metadata diagnostic output across the configured `src_next` fixtures.

### Phase 8.2: missing optional plan.tsv

`fixtures/src-next-missing-plan` is a copy of the golden fixture without `plan.tsv`. It confirms that `src_next` survives the optional file being absent and still produces the correct compact summary.

## Verification status

Status: Phase 8.1 is integrated. Minimal Report Summary is now a machine-checkable
Stage 4 trial surface (2026-06-24).

The command below was run locally after the Phase 8 fixture and expected summary were added:

```sh
bash checks/check-src-next-golden.sh fixtures/src-next-golden
```

It returned with no output, which means the compact summary extracted from `src_next/main.bqn` matched `fixtures/src-next-golden/expected/src_next_summary.txt`.

The standalone check is now wired into the full repository check in `checks/check.sh` near the existing fixture golden checks:

```sh
bash checks/check-src-next-golden.sh fixtures/src-next-golden >/dev/null
```

This keeps `src_next` under the normal regression-check route while still avoiding a full stdout golden file.

### Phase 8.3: Minimal Report Summary semantic check

`checks/check-src-next-minimal-summary.sh` verifies the Minimal Report Summary
section across all `src_next` fixtures without baking in specific household amounts.
It checks:

- Section presence (`--- SrcNext Minimal Report Summary ---`)
- Field format validity (cycle range, projection counts, signed totals, expense totals)
- Internal consistency (projection balance, cube numeric verification)
- Account total line format
- No production readiness claims

This semantic check complements the exact golden diff and is wired into
`tools/check.sh` on all 9 `src_next` fixtures.

### Phase 8.4: compact Cycle Summary fixture comparison

`checks/check-src-next-cycle-summary.sh` verifies the compact
`--- SrcNext Cycle Summary ---` section from `tools/report-next-summary` on
fixtures, without baking in production data amounts.

It checks required field presence and integer formats, then compares these
fields against `src/reports/exporters/export-cycle-summary.bqn`:

- `cycle_start`
- `cycle_end_exclusive`
- `cycle_income_actual`
- `cycle_expense_actual`
- `cycle_net_actual`

`src_next_cycle_plan_expense` is checked for presence and integer format, but
`export-cycle-summary.bqn` does not expose the comparable plan-expense value.
The default fixture list excludes fixtures where the current exporter fails
closed (`src-next-unknown-account`, `src-next-out-of-cycle-journal`) and documents
that reason in the script.

### Phase 8.5: compact daily observation section checks

The expanded `tools/report-next-summary` Stage 4 surface is covered by fixture
checks without baking in private production amounts:

- `check-src-next-expense-breakdown.sh` — validates breakdown format and that the internal total equals `src_next_cycle_expense_actual`.
- `check-src-next-ytd-summary.sh` — validates compact YTD fields and compares income/expense/net with `src/reports/exporters/summary.bqn` on supported fixtures.
- `check-src-next-recent-journal.sh` — validates recent journal format.
- `check-src-next-planned-payments.sh` — validates planned payment format and `planned` / `paid` / `ambiguous` status vocabulary; includes `fixtures/plan-completion`.
- `check-src-next-balances.sh` — validates nonzero actual account total format.
- `check-src-next-readiness.sh` — validates readiness counters and count consistency with Minimal Report Summary.
- `check-src-next-plan-journal-overlap.sh` — validates plan/journal overlap diagnostics (counts integer, consistency, strong_overlap_key presence when strong_overlap_count > 0) across all src_next fixtures.
- `check-src-next-actual-comparison.sh` — validates that Actual Comparison is an explicit `not_implemented` placeholder and does not claim parity.

These checks are wired into `tools/check.sh`. They protect compact Stage 4
observation surfaces only; they are not production replacement gates.

### Phase 8.8: fixture-only envelope computation prototype

`fixtures/src-next-envelope-computation` adds an opt-in Stage 4a envelope computation fixture. It is checked by `checks/check-src-next-envelope-computation.sh` and wired into `tools/check.sh`.

The compact golden surface pins only the envelope computation fields:

- `src_next_envelope_target_id: fixture_food_like`
- `src_next_envelope_label: 食費`
- `src_next_envelope_selector: budget=食費`
- `src_next_envelope_allocated: 1000`
- `src_next_envelope_actual_spent: 350`
- `src_next_envelope_remaining: 650`
- `src_next_envelope_status: computed`

This is not a production-equivalent Section 5 check. It verifies only the fixture contract:

```text
remaining = allocated - actual_spent
```

Planned spending is present in the fixture but is not subtracted. `safe_remaining` and `daily_amount` remain unimplemented.

## Next candidates

Phase 8.2 should expand coverage with additional tiny fixtures before changing the `src_next` design itself. Good candidates:

- missing optional `plan.tsv` (covered by `fixtures/src-next-missing-plan`)
- empty journal / empty projection result (covered by `fixtures/src-next-empty-projection`)
- unknown account row with explicit skipped reason (covered by `fixtures/src-next-unknown-account`)
- out-of-cycle journal row, not only out-of-cycle plan row (covered by `fixtures/src-next-out-of-cycle-journal`)
- AccountKey separation by currency metadata (covered by `fixtures/src-next-currency-accountkey`)

The initial Phase 8.2 fixture set is now complete.

Keep each fixture small and give it its own expected summary. Avoid large cleanup or abstraction work until these regression bells are in place.

## Related documents

- [SRC_NEXT_STAGE4A_OBSERVATION_INVENTORY.md](SRC_NEXT_STAGE4A_OBSERVATION_INVENTORY.md) — Stage 4a 観測面棚卸し
- [SRC_NEXT_REPLACEMENT_READINESS.md](SRC_NEXT_REPLACEMENT_READINESS.md) — 置き換え準備チェックリスト


# Retained Cycle Comparison report

Status: Portfolio P6 destination proof

Owners:

- `src/accounting/cycle_comparison.bqn` — exact comparison of two explicit accounted windows;
- `src/sections/cycle_comparison.bqn` — retained human-only Matrix.

Inputs are two `cycle_account_period` results and one explicit policy. The capability does not search Facts for a previous or similar period.

```text
aligned_elapsed = both observed windows have equal day counts
complete_cycles = both windows reach their resolved cycle end
```

Both windows must use the same domain and identical admitted Account axes. Their scales normalize exactly before arithmetic.

```text
rows       = every Account in admitted order
columns    = current_movement | baseline_movement | difference
difference = current_movement - baseline_movement
```

Current and baseline contributors remain separate. The difference cell carries their source-qualified union, while `difference_evidence` retains both coefficients and both contributor arrays independently. This prevents a difference from erasing which window supplied evidence.

Totals for all three columns are exact zero-sum checks. Valid empty Actual remains a normal all-zero Matrix. An unavailable current/baseline window remains unavailable with a qualified reason. Invalid policy, unequal elapsed days, incomplete cycles under `complete_cycles`, domain/axis mismatch, normalization failure, or overflow returns no numeric Matrix.

Portfolio P1 is human-only. Counts, ratios, increase/decrease labels, and old Actual Comparison status lanes are intentionally absent.

Public proof covers:

- aligned ten-day current and baseline windows;
- complete 31-day versus 28-day cycles;
- source-qualified current/baseline/difference evidence;
- exact mixed-scale normalization;
- USD valid empty Actual;
- unavailable baseline;
- invalid policy, misaligned elapsed days, incomplete windows, and domain mismatch;
- deterministic human golden.

Because Matrix semantics are independent of rendering, future narrow-terminal presentation may transpose, split columns, or page the same result without changing accounting arithmetic or provenance.

Production routing remains unchanged until atomic cutover.

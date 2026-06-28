# Ledger Engine Idea Catalog

Status: **design ideas / not yet implementation plan**

This document collects ideas for making `bqn-ledger` an interesting, extensible ledger/report engine while preserving the current source-data safety model.

The ideas here are intentionally exploratory. They are not commitments, not current behavior, and not implementation claims.

## Context

`bqn-ledger` can use `bqn-kakeibo` as the ordinary household-report numeric oracle. The goal is not to protect the old `src/` structure as production truth. The goal is to build a more interesting engine that can reproduce the ordinary report numbers and then expose richer views, accounting-like derived data, provenance, and scenario analysis.

Working distinction:

| Area | Role |
|---|---|
| `bqn-kakeibo` | ordinary household report / numeric oracle |
| `bqn-ledger/src` | fork-derived implementation material, not sacred production truth |
| `bqn-ledger/src_next` | main candidate for new ledger engine development |
| `data/*.tsv` | source data, protected ground |

## Guardrails

These ideas must stay inside the existing safety model.

- Do not rewrite source TSV as part of exploratory engine work.
- Do not make AI edit `data/journal.tsv`, `data/plan.tsv`, `data/budget_alloc.tsv`, or `data/accounts.tsv` without explicit instruction.
- Preserve the first five TSV columns as the stable journal-like contract.
- Keep the BQN-only report/export path possible.
- Do not mix consultation advice into canonical numeric output.
- Prefer explicit `OK / WARN / ERROR / SKIPPED / UNAVAILABLE / EXPERIMENTAL` status over silent correction.
- Use `bqn-kakeibo` parity for ordinary report numbers where applicable.

A useful motto:

```text
source data is the temple
engine work is the laboratory
reports can multiply
numeric roots must remain visible
```

## Candidate architecture shape

Long-term conceptual flow:

```text
TSV source data
  ↓
Event / source row
  ↓
Posting IR
  ↓
Canonical Cube
  ↓
TBDS
  ↓
Report Lenses
  ↓
Human / Machine / Export
```

This does not require all layers to be implemented at once. It provides a vocabulary for deciding where each new idea belongs.

## Idea 1: Report Lens structure

Treat each report section as a lens over a stable context rather than as a fixed block of formatting code.

Candidate shape:

```text
Lens.Build(ctx)        -> ViewModel
Lens.Format(vm)        -> machine text
Lens.FormatHuman(vm)   -> human text
Lens.Export(vm)        -> optional TSV / machine export
```

Possible lenses:

- `cycle_summary`
- `balances`
- `expense_breakdown`
- `planned_payments`
- `food_pressure`
- `daily_cash_pressure`
- `envelope_velocity`
- `tax_materials`
- `posting_trial_balance`
- `scenario_outlook`
- `shape_map`

Why this is interesting:

- New reports become small composable modules.
- Household reports, accounting-like reports, and machine exports can share the same intermediate context.
- `main.bqn` becomes an orchestrator rather than the place where report meaning accumulates.

Risks:

- Too many lenses can create navigation noise.
- Each lens needs a clear owner: cube view, TBDS query, policy layer, or formatter.

First small experiment:

- Choose one existing `src_next` section and document it as a lens without changing behavior.
- Add a tiny lens registry / section list only after the shape is clear.

## Idea 2: Numeric provenance

Every important report value should eventually be explainable as:

```text
value
source rows or source view
formula
status
```

Example concept:

```text
food_remaining: 12340
formula: allocated - actual_spent
sources:
  - budget_alloc.tsv rows used for allocation
  - journal.tsv rows used for actual spending
status: OK
```

Why this is interesting:

- AI and humans can ask where a number came from.
- Debugging becomes less mystical.
- Reports can distinguish an accurate number from a number that is missing data, skipped, or experimental.

Possible outputs:

- `tools/explain-value <field>`
- `tools/explain-section <section>`
- `src_next` machine export with provenance fields
- provenance TSV for selected summary values

Risks:

- Full row-level provenance may be costly or noisy.
- Start with major values only, not every scalar.

First small experiment:

- Add provenance for one value such as food remaining, current cycle spending, or net liquid balance.

## Idea 3: TBDS as the accounting waterway

Treat TBDS as a central accounting-like derived dataset.

Candidate fields:

```text
period
account
layer
opening
debit
credit
movement
closing
status
```

Possible reports derived from TBDS:

- cycle trial balance
- monthly trial balance
- account movement table
- actual vs plan movement
- budget layer movement
- asset/liability snapshot
- expense breakdown via TBDS query
- prior-cycle comparison

Why this is interesting:

- Household reports and bookkeeping-like reports can share one derived dataset.
- It gives `bqn-ledger` a real ledger flavor without replacing TSV with ledger block syntax.
- It supports report expansion without repeatedly scanning source TSV in unrelated ways.

Risks:

- TBDS must not become a second source of truth.
- It should remain derived from source TSV / cube / Posting IR.

First small experiment:

- Add one human-readable TBDS report for a cycle, marked experimental if needed.

## Idea 4: Scenario Overlay

Allow temporary hypothetical events without editing source TSV.

Concept:

```text
base source data + scenario overlay -> report
```

Possible questions:

- What if food spending is 800 yen/day for the rest of the cycle?
- What if one extra book purchase is added?
- What if a planned payment is delayed?
- What if an expected income date shifts?
- What if tobacco spending changes for this cycle only?

Possible forms:

- in-memory overlay rows
- fixture-like scenario TSV
- CLI option: `--scenario scenarios/foo.tsv`
- machine export comparing base vs scenario

Why this is interesting:

- Future planning becomes testable without polluting source data.
- It separates facts from hypotheses.
- AI can reason from scenario outputs rather than inventing arithmetic.

Risks:

- Scenario rows must be visually and mechanically distinct from source data.
- Canonical report output should not accidentally include scenario data without labeling.

First small experiment:

- Design a docs-only scenario TSV format and one fixture scenario.

## Idea 5: Status as first-class report data

Each report or value should carry a status such as:

```text
OK
WARN
ERROR
SKIPPED
UNAVAILABLE
EXPERIMENTAL
```

Why this is interesting:

- Experimental reports can exist without pretending to be production truth.
- Missing or invalid inputs become visible.
- It supports fail-closed behavior: do not print a beautiful wrong number.

Example:

```text
Food Pressure: WARN
reason: food budget exists, but one expense account lacks household policy metadata
```

Risks:

- Too many warnings can make daily use noisy.
- Need clear status policy for section-level vs value-level status.

First small experiment:

- Add `EXPERIMENTAL` status to one new report lens rather than blocking the report entirely.

## Idea 6: Life pressure reports

Build reports that measure household pressure without giving advice.

Possible lenses:

- `food_pressure`
- `daily_cash_pressure`
- `plan_collision`
- `cycle_end_risk`
- `fixed_cost_shadow`
- `envelope_burn_rate`

Example output idea:

```text
food_daily_possible: 734
recent_7day_food_average: 982
difference_per_day: -248
status: WARN
```

Important boundary:

- The engine reports observations.
- Human or AI outside the engine interprets them.
- The engine should not say what the user must do.

Why this is interesting:

- It turns the ledger into a living household instrument.
- It preserves the difference between arithmetic and advice.

Risks:

- Policy assumptions can sneak into BQN code.
- Inputs like food account mapping must be explicit metadata or policy docs.

First small experiment:

- Create `food_pressure` from existing food/daily policy contracts, with explicit `EXPERIMENTAL` status.

## Idea 7: `txn_id` bundle view for light multi-posting

Keep journal-like one-row TSV, but allow multiple rows to be grouped by metadata such as:

```text
txn_id=2026-06-25-book-001
```

Possible bundle views:

- transaction bundle summary
- bundle balance check
- bundle posting table
- bundle memo rollup
- same-event multi-line audit

Why this is interesting:

- It gives some multi-posting power without switching to ledger block syntax.
- It keeps TSV rows readable and diffable.
- It creates a bridge from household rows to accounting-like transactions.

Risks:

- `txn_id` conventions can become messy if not linted.
- Need clear handling of rows without `txn_id`.

First small experiment:

- Docs-only `txn_id` bundle contract plus lint design.

## Idea 8: Shape Contract visibility

Expose the shapes of important BQN arrays and derived datasets.

Example:

```text
accounts: 256
days: 64
layers: 4
cube: 64 × 256 × 4
posting_ir_rows: 412
tbds_rows: 138
```

Possible tools:

- `tools/shape-map`
- `tools/explain-section <section>`
- `tools/explain-value <field>`
- `src_next` shape dump for AI debugging

Why this is interesting:

- BQN development becomes easier for humans and AI helpers.
- Shape drift is caught earlier.
- It turns array structure into visible documentation rather than hidden machinery.

Risks:

- Shape output can become stale if manually documented.
- Prefer generated shape output where possible.

First small experiment:

- Add a small shape dump exporter for `src_next` context.

## Prioritization sketch

Recommended first wave:

1. Report Lens vocabulary for existing `src_next` sections.
2. Numeric provenance for one important value.
3. Scenario Overlay docs-only design.
4. `EXPERIMENTAL` status pattern for new reports.
5. Shape Contract visibility for AI/human debugging.

Recommended second wave:

1. TBDS human report.
2. Food / daily pressure report.
3. `txn_id` bundle contract and lint.
4. Scenario comparison export.

## Decision questions before implementation

Before implementing any idea, answer:

1. Is this a report, a derived dataset, a source-data rule, or a tool?
2. Does it require new source TSV columns or only derived calculation?
3. Does it affect ordinary `bqn-kakeibo` parity?
4. Should it be `OK` production output or `EXPERIMENTAL` output?
5. Which layer owns the meaning: TSV metadata, Posting IR, Cube, TBDS, Lens, formatter, or external AI?
6. What fixture proves it works?
7. What check fails if it regresses?

## Non-goals

- Do not turn `bqn-ledger` into a full tax filing program.
- Do not replace source TSV with ledger-style multi-line blocks as a prerequisite.
- Do not let scenario data masquerade as source data.
- Do not make the engine produce lifestyle advice as canonical output.
- Do not protect old `src/` structure for its own sake.

## Summary

`bqn-ledger` can be more than a replica of the ordinary household report. The interesting shape is:

```text
same trusted numbers as bqn-kakeibo
+ clearer numeric roots
+ accounting-like derived waterways
+ experimental report lenses
+ hypothetical scenario overlays
+ visible BQN shapes
```

That gives the project room to move fast while keeping source data and numeric trust intact.

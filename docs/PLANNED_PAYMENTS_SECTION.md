# Destination Planned Payments section

Status: Phase 3I destination section proof

Owner: `src/sections/planned_payments.bqn`

## Composition

The section receives only:

```text
Plan Facts
Actual Facts
successful resolved cycle
explicit as-of
```

It composes:

```text
half-open Plan/Actual Transaction selection
  → durable Plan completion Join
  → section-local temporal state and total
  → one List result
  → human / compact / JSON renderers
```

There is no source path, I/O, clock, report context, Cube/TBDS, raw TSV row, or `src_next` import.

## Selection and observation

Plan and Actual Transactions are independently selected inside `[cycle.start, cycle.end_exclusive)`. Plan rows are sorted by date before the Join. Equal-date source order remains deterministic.

The explicit section observation must equal:

- the latest selected Actual Transaction date; or
- cycle start when selected Actual is empty.

A caller cannot substitute hidden today or a report-wide fallback date. Invalid/mismatched observation fails closed with no rows or total.

## Relationship policy

Only Join rows in `open` or `completed` state are renderable.

- `duplicate` completion evidence is rejected as `completion_duplicate`;
- conflicting evidence is rejected as `completion_ambiguous`;
- completed currency mismatch is rejected;
- completed Account-direction mismatch is rejected;
- multiple selected Plan currency domains are rejected before computing one naked total.

The section never sums multiple Actual completion transactions. It preserves source-qualified Plan/Actual Transaction references and Posting contributors in the result.

## Temporal state

Open Plan rows are classified against explicit as-of:

```text
plan date < as-of  → overdue
plan date = as-of  → due
plan date > as-of  → future
```

A valid single completion is `completed`. These are section display states, not generic accounting states.

## Exact amounts and totals

Every row retains its own admitted coefficient and scale. Open Plan amounts normalize to the highest selected open scale and use checked exact summation. Different currency domains are never normalized or added together.

Human/compact/JSON rendering occurs from the same section result. JSON numbers are emitted from exact decimal text, not binary-float conversion.

## Category label

Account role determines which Plan direction supplies the category:

- income-source Plan uses the `from` Account;
- other Plans use the `to` Account.

Existing `income:`, `expenses:`, and `liabilities:` prefixes are shortened only after explicit role selection. Prefixes do not infer accounting role.

## Output contracts

Human and JSON preserve current strict-fixture semantics and schema. Compact performs the approved atomic generation-name cleanup in its destination golden:

```text
--- Ledger Planned Payments ---
ledger_planned_payment: ...
```

No `src_next_planned_payment` alias is emitted by the destination renderer. Production compact routing is unchanged until final cutover.

Goldens:

- `fixtures/ledger-facts-phase1-proof/planned_payments.destination.human.txt`
- `fixtures/ledger-facts-phase1-proof/planned_payments.destination.compact.txt`
- `fixtures/ledger-facts-phase1-proof/planned_payments.destination.json`

## Proof

`tests/test_section_planned_payments.bqn` proves:

- strict public completed row with planned `25` and Actual `20`;
- exact source-qualified Transaction and Posting provenance;
- deterministic human/compact/JSON output;
- empty Plan output;
- overdue/due/future state and exact open total;
- observation mismatch fail-closed;
- duplicate completion refusal with no partial rows.

`checks/check-ledger-facts-phase1-proof-fixture.sh` compares destination human and JSON bytes/schema with current production output for the same public evidence. No private household data is used.

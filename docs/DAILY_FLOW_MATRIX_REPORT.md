# Daily Flow Matrix report proof

Status: Phase 3F second destination Matrix section proof
Owner: `src/sections/daily_flow.bqn`
Accounting owner: `src/accounting/date_category_flow.bqn`
Matrix owners: `src/accounting/sparse_pivot.bqn`, `src/accounting/matrix_result.bqn`

## Vertical slice

```text
canonical Facts + explicit period
→ date/category accounting evidence
→ genuine sparse expense Pivot
→ section-local income/expense/net dense MatrixResult
→ human rendering
```

The section accepts one successful date/category result, matching strict period text, and one explicit as-of date. It performs no source I/O, source admission, clock read, context construction, Cube/TBDS access, or other-section build.

## Explicit empty and layer evidence

Canonical admissions now always expose `declared_layers`:

```text
Actual → actual
Plan   → plan
Budget → budget
```

Facts use that explicit side-table evidence rather than inferring Layer solely from existing transactions. Therefore an empty Actual source can answer an `actual` layer query with zero transactions/postings without fabricating evidence or accepting an arbitrary missing layer. This contract is shared by all source families and is owned by admission/Facts, not patched inside Daily Flow.

## Observation policy

Observation is section-local and explicit:

- for nonempty selected transaction dates, `as_of` must equal the latest date;
- for empty evidence, `as_of` must equal period start;
- `as_of` must occur inside the half-open period;
- if the observation date has no transaction row, the section adds one explicit zero row.

No hidden today/clock fallback exists. A later source/use-case boundary supplies the explicit observation coordinate.

## Matrix composition

Rows are sorted date ordinals. Columns are:

```text
income
<dynamic admitted expense categories>
other
net
```

Expense evidence genuinely uses sparse Group/Pivot. The section then combines dense expense cells with accounting-provided income/net measures through the canonical MatrixResult constructor.

Contributor cells preserve:

- income Posting indices;
- per-category expense Posting indices;
- derived net contributors as the sorted union of income and expense evidence.

Category classification remains in the accounting capability; Pivot and Matrix do not know `food`, `other`, or display signs.

## Output proof

The approved contract requires Daily Flow human output only. This section intentionally adds no compact or JSON formatter.

The strict public fixture proves:

- dates `2026-01-02`, `2026-01-10`, `2026-01-12`;
- dynamic columns `food`, `other`;
- income `1000`;
- expenses `20`, `10`, `5`;
- net `1000`, `-20`, `-15`;
- contributor Posting indices for income, expenses, and net;
- deterministic human bytes;
- valid empty Actual as one period-start zero row;
- mismatched observation rejection with an empty MatrixResult.

Destination human output uses approved ASCII minus signs. The parity check normalizes the current engine's BQN high-minus before comparing bodies.

Golden:

- `fixtures/ledger-facts-phase1-proof/daily_flow.destination.human.txt`

## Routing boundary

Production remains on `src_next`. This proof introduces no alternate CLI or fallback. Daily Flow cutover waits for explicit observation/source composition and supported-source readiness, then switches all applicable surfaces and deletes the old section owner atomically.

# Trial Balance Matrix report proof

Status: Phase 4A first destination section proof
Owner: `src/sections/trial_balance.bqn`
Accounting owner: `src/accounting/account_period.bqn`
Matrix owner: `src/accounting/matrix_result.bqn`

## Vertical slice

The first destination section is composed as:

```text
canonical Actual Facts
+ explicit admitted fixed period
→ Account-period accounting state
→ section-local dense measure arrays
→ canonical MatrixResult constructor
→ human or compact rendering
```

The section accepts only one successful Account-period result and matching strict period date text. It performs no source I/O, source admission, clock read, context construction, Cube/TBDS access, or other-section build.

Accounting formulas are not copied into the section. Opening, debit/credit movement, closing, totals, exact scale, balance status, and Posting contributors come from `account_period.bqn`. The section only chooses the four Trial Balance measure columns and passes their already-dense values/contributors directly to `matrix_result.bqn`.

Trial Balance does not route dense Account state through sparse Group/Pivot. Sparse Pivot is reserved for genuinely sparse/dynamic axes such as date/category and month/category; both paths converge only at the canonical MatrixResult constructor.

## Section result

Rows follow canonical Account order, including zero-activity Accounts. Row coordinates are canonical Account indices; section-local row labels are `account_key/domain`.

Columns are stable semantic coordinates:

```text
opening
debit_movement
credit_movement
closing
```

Every dense cell retains contributors. Closing contributors are the union of opening and period Posting contributors; absent zero cells remain empty evidence. Totals and balanced status remain separate accounting-result fields rather than a fabricated Account row.

A period date string that does not match the Account-period ordinal fails closed with an empty MatrixResult.

## Output proof

`FormatHuman` and `FormatCompact` consume the same section result. They do not parse each other's text or rebuild accounting state.

The strict public fixture fixes:

- all eight Account rows and canonical order;
- opening/debit/credit/closing cells;
- debit `1035`, credit `-1035`, closing `0`;
- zero-sum status;
- exact human body matching the current report after wrapper trailing-newline normalization;
- destination compact keys using the approved `ledger_` prefix;
- repeated formatter calls producing identical bytes.

Goldens:

- `fixtures/ledger-facts-phase1-proof/trial_balance.destination.human.txt`
- `fixtures/ledger-facts-phase1-proof/trial_balance.destination.compact.txt`

The approved output contract does not support Trial Balance JSON, so this slice intentionally adds no JSON formatter.

## Routing boundary

Current daily production remains `tools/report → src_next/report.bqn`. This proof does not add a second CLI, generation-name wrapper, broad report context, cache route, or fallback. Production section routing will switch only when strict supported-source readiness and the section cutover checks are satisfied; the old section owner is then deleted in the same cutover rather than retained as a dual implementation.

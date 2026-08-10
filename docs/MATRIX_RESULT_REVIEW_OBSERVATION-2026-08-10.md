# MatrixResult review observation — 2026-08-10

## Baseline

The review resumes from `src/accounting/matrix_result.bqn` after Fact reference closeout PR #608 merged to `main` `2756e49749dbfb498eadf9cc873c2eb442557219`.

This document records observation only. No MatrixResult production code, public shape, diagnostics, section result, renderer, source authority, exact arithmetic, or provenance semantics change in this slice.

## Retained responsibility

`src/accounting/matrix_result.bqn` is the canonical presentation-neutral dense MatrixResult constructor.

Its input is:

```text
row coordinates
column coordinates
exact value scale
dense nested value rows
dense nested contributor rows
```

Its successful matrix publishes:

```text
row_count, column_count, cell_count
row_index, column_index
row_coordinates, column_coordinates
scale
values[row][column]
contributors[row][column]
```

The owner deliberately does not know Account, date, month, category, label, sign, formatting, report, source path, Facts, or observation policy.

Its validation boundary currently protects:

1. unique opaque row coordinates;
2. unique opaque column coordinates;
3. nonnegative integer exact scale;
4. value/contributor row counts aligned with the row axis;
5. every value row aligned with the column axis;
6. every contributor row aligned with the column axis;
7. error publication as the canonical empty MatrixResult plus structured diagnostics.

The focused `tests/test_accounting_matrix_result.bqn` directly protects the successful, empty, duplicate-axis, invalid-scale, row-misalignment, value-column-misalignment, and contributor-column-misalignment cases.

## Historical reason for the owner

The owner was deliberately separated from `sparse_pivot.bqn` in commit `e67885e2bffe7074fd8ee91a52fde1186459173c`.

That move removed an artificial dense → sparse → dense route for already-dense consumers and made one MatrixResult constructor the convergence point for both:

```text
dense semantic arrays --------------------┐
                                          ├→ matrix_result.Build
sparse groups → sparse_pivot materialize -┘
```

That reason still exists. `sparse_pivot.bqn` owns sparse-coordinate validation and absent-cell materialization, while MatrixResult owns the dense result contract.

Initial ownership classification: **KEEP** under the current accounting-result dependency direction. No evidence presently justifies moving the owner upward into Sections or folding it back into Pivot.

## Direct production consumer graph

Repository search finds seven direct production importers:

Accounting:

- `src/accounting/month_account_movement.bqn`
- `src/accounting/sparse_pivot.bqn`

Sections:

- `src/sections/account_balances.bqn`
- `src/sections/cycle_accounts.bqn`
- `src/sections/cycle_comparison.bqn`
- `src/sections/daily_flow.bqn`
- `src/sections/trial_balance.bqn`

`month_account_movement.bqn` reaches MatrixResult through both its local empty-result construction and its normal `sparse_group → sparse_pivot → matrix_result` path.

The Section consumers either compose already-dense semantic evidence directly into MatrixResult or use it to project/filter a previously built matrix.

This confirms MatrixResult is not a report-format helper and not a Pivot-private implementation detail.

## Existing Each / Cells / Rank evidence

`experiments/bqn/matrix_result_cells_rank.md` already tested whether the current per-row column-alignment checks should replace Each with Cells or Rank.

The result was **KEEP Each for the current admission representation**:

- candidate rows are a rank-1 sequence of nested arrays;
- ragged rows must remain representable long enough to produce structured `matrix_*_columns_misaligned` diagnostics;
- Cells/Rank become direct only after publication has already crossed into a true rectangular array representation;
- merging before admission could turn a domain diagnostic into a primitive shape error.

Therefore an Each → Cells/Rank spelling change is not a current subtraction candidate.

A different future question remains possible: whether successfully admitted MatrixResult values should publish a true rectangular array rather than nested rows. That is a representation/public-contract decision and is not selected by this observation.

## Shape-authority duplication

The strongest current architecture finding is not inside `Build`; it is around the canonical empty MatrixResult shape.

`matrix_result.bqn` owns the empty shape, but exact hand-written copies of the same record currently appear in:

- `src/sections/cycle_accounts.bqn`
- `src/sections/cycle_comparison.bqn`
- `src/sections/trial_balance.bqn`
- `src/sections/monthly_accounts.bqn`

Other consumers avoid that duplication by asking `matrix_result.Build ⟨⟨⟩,⟨⟩,0,⟨⟩,⟨⟩⟩` for the canonical empty matrix.

The four literal copies mean a future MatrixResult shape change has more than one authority site. This is a concrete change-locality and ownership-duplication finding.

Classification: **SUBTRACT / centralize candidate**, but the API form is not chosen yet.

Do not automatically add a generic helper merely to remove text. The next step must compare at least these end states:

1. expose a named canonical empty MatrixResult from the existing owner;
2. reuse existing upstream MatrixResult values where an error result already carries one;
3. continue constructing the empty value through `Build` where that preserves one authority without adding another public concept.

The coherent choice should remove duplicate shape authority rather than merely replace four literals with a new convenience abstraction.

## Public-field observations

### `row_index` / `column_index`

These are derivable from counts, but they have live production consumers. Section renderers use them as explicit deterministic traversal axes.

Classification: **KEEP for now**. Derivability alone is not enough reason to churn the result contract and every renderer.

### `row_coordinates` / `column_coordinates`

These are the semantic opaque axes that distinguish MatrixResult from a bare nested value table. Tests and documented contract depend on them even when a renderer also carries section-local labels.

Classification: **KEEP**.

### `cell_count`

`cell_count` is exactly `row_count × column_count` and current repository search found no production consumer that reads it. Search hits outside its definitions are documentation and tests.

However, `docs/SPARSE_PIVOT_MATRIX.md` explicitly documents it as part of the successful MatrixResult contract, so it is not silently dead implementation state.

Classification: **SUBTRACT candidate requiring a public-contract decision**.

A focused follow-up should prove repository reachability and decide whether the documented field carries useful semantic meaning beyond its derivation. If removed, production owner, all literal empty copies, tests, and active MatrixResult documentation must change coherently.

## Validation/control-flow observations

The mutable `diagnostics` accumulation and conditional publication are visually heavier than the final matrix relation, but each guard currently protects a named admission diagnostic.

In particular, row-count alignment gates the per-row column checks. Changing that structure could change which diagnostics are published for multiply-invalid candidates even when successful behavior is unchanged.

Therefore there is no justified control-flow subtraction yet. A law would be required before simplifying diagnostic staging.

Classification: **OBSERVE, no production change selected**.

## Current classification

- MatrixResult owner: **KEEP**;
- dense nested candidate rows + Each admission check: **KEEP** under current representation;
- unique-axis / scale / alignment diagnostics: **KEEP**;
- four hand-written empty MatrixResult copies: **SUBTRACT / centralize candidate**;
- `row_index` / `column_index`: **KEEP for now**;
- `row_coordinates` / `column_coordinates`: **KEEP**;
- `cell_count`: **SUBTRACT candidate**, but documented public surface means it needs an explicit contract decision;
- successful true rank-2 representation: **future representation question, not selected automatically**.

## Continuation

Keep the review cursor on `src/accounting/matrix_result.bqn`.

Before production changes, inspect the empty-shape consumers and `cell_count` contract as two separate questions. Prefer the smaller proven subtraction first only if it has a complete coherent end state.

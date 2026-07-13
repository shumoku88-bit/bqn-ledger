# Currency Mixed-Ledger M1 Post-implementation Verification — 2026-07-13

Status: audit snapshot
Owner: currency
Canonical: no; current plan remains `docs/archive/active-plans/CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md`
Exit: retain as point-in-time evidence; use the active plan and `TODO.md` for current authorization

## 1. Reviewed lineage

```text
PR #194  feat: add M1 selected-currency projection seam
head     a21580b9acfd09e480fe59ff7d12e7891f64ee73
merge    568e06103cfea2a04754377e79a45745523714a3
```

GitHub Actions evidence:

```text
workflow: check
run:      #701
status:   completed
result:   success
```

Overall result:

```text
M1 selected claims -> verified
material unresolved plan/runtime mismatch -> none
M1 -> complete
next finite slice -> M1.5 explicit default carrier and migration tooling
```

## 2. Actual implementation diff

PR #194 changed exactly five paths:

```text
src_next/currency_selection.bqn
tests/test_src_next_currency_selection.bqn
fixtures/src-next-currency-mixed-selected/accounts.tsv
fixtures/src-next-currency-mixed-selected/cycle.tsv
fixtures/src-next-currency-mixed-selected/journal.tsv
```

The runtime addition is isolated to the pure `src_next/currency_selection.bqn` boundary. No public report CLI, editor, source migration, human formatting, FX, conversion, valuation, Currency axis, or mixed aggregation was introduced.

## 3. Claim-to-evidence review

| # | M1 claim | Current evidence | Classification |
|---|---|---|---|
| 1 | One shared mixed snapshot is interpreted once | `currency_selection.Build` calls `BuildRowEvidenceFromSnapshot` once and performs all later checks and filtering over that evidence array. | **verified** |
| 2 | A mixed snapshot without a selector remains closed | The focused test calls the pre-existing checked projection boundary on the mixed fixture and asserts `mixed_currency_domains`, no posting rows. | **verified** |
| 3 | Explicit JPY selection succeeds | The focused test selects JPY, obtains a proven JPY proof, exact scale 0 postings, and a zero posting sum. | **verified** |
| 4 | Explicit ILS selection succeeds | The focused test selects ILS, obtains a proven ILS proof with `amount_scale=2`, exact coefficients `4250` and `5`, and a zero posting sum. | **verified** |
| 5 | Row/account currency mismatch fails closed | The selector checks From and To account metadata against row currency before arithmetic and emits `account_currency_mismatch` with no posting rows. | **verified** |
| 6 | Selector domain is explicit and closed | JPY and ILS are admitted; an unsupported USD selector returns `unsupported_selected_currency`. | **verified** |
| 7 | Existing exact single-currency arithmetic is reused | Selected evidence is passed to `currency_arithmetic.Build` and then to the existing pure prepared checked-projection seam. | **verified** |
| 8 | Scope did not widen beyond M1 | Base-to-head diff is five paths and contains no editor, report, config, migration, production data, FX, or mixed-total change. | **verified** |

## 4. Exact fixture evidence

The mixed fixture contains:

```text
JPY 1200
ILS 42.50
ILS 0.05
```

Asserted selected outputs:

```text
JPY amount_scale = 0
JPY debit = 1200
JPY posting sum = 0

ILS amount_scale = 2
ILS debits = 4250, 5
ILS posting sum = 0
```

No calculation adds JPY and ILS or converts one into the other.

## 5. CI and correction evidence

The first workflow run exposed a BQN case-insensitive identifier collision in the test helper (`Snapshot` and `snapshot`). The helper was renamed to `MakeSnapshot`. The final clean workflow run #701 then passed both:

```text
tools/check.sh
tools/coverage
```

The temporary diagnostic workflow edit used while recovering the first failure was reverted and is absent from the final five-path implementation diff.

## 6. Routing decision

M1 is complete and verified. The concrete July travel requirement authorizes the next finite slice defined by the active plan:

```text
M1.5: Explicit default carrier and production migration tooling
```

M1.5 may:

- select one ledger-level owner and key for the explicit default currency;
- keep default selection separate from source currency authority;
- expose effective selected currency and selection provenance;
- add read-only missing / duplicate / unknown currency audit;
- add idempotent dry-run migration tooling for `accounts.tsv`, `journal.tsv`, `plan.tsv`, and `budget_alloc.tsv`;
- add fake fixtures and checks proving `currency=JPY` migration without first-five-column, account-name, row-order, empty-field, comment, or unrelated-metadata drift.

M1.5 must not:

- modify production source data;
- enable strict missing-currency rejection;
- change the editor or public report CLI;
- implement human balance formatting;
- introduce FX, conversion, valuation, Currency axis, or mixed aggregation;
- automatically authorize M2 or later slices.

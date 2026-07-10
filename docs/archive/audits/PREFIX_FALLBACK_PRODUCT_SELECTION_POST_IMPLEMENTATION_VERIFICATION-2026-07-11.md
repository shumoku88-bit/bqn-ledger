# Prefix Fallback Product-Selection Post-Implementation Verification

Status: audit snapshot
Owner: envelope
Canonical: no; semantic decision: `PREFIX_FALLBACK_CURRENT_MAIN_RECONCILIATION-2026-07-11.md`
Exit: retain as evidence for PR #151; reopen only on concrete contrary evidence

Date: 2026-07-11
Implementation PR: #151
Implementation head: `9d5a3a29cbead94c7f4d60991180faa7da0c0331`
Merge commit: `1a992628ba6bdd6a8bc86fc9a382f4d973e55071`
Plan: `../completed-plans/PREFIX_FALLBACK_PRODUCT_SELECTION_REMOVAL_PLAN-2026-07-11.md`

## Verification result

```text
verified
```

No material unresolved plan/runtime mismatch was found for the selected finite slice.

Selected meaning now evidenced on merged `main`:

```text
explicit role metadata = classification owner
prefix-shaped missing role = diagnostic signal only
prefix fallback != product/accounting/envelope selection authority
```

## Scope reviewed

- PR #151 changed-file set and full patch;
- merged `main` runtime owners;
- focused negative fixture and unit evidence;
- GitHub Actions evidence for the implementation head;
- plan exclusions, especially Currency Stage 2 B2 non-interference.

## Claim-to-evidence table

### 1. Envelope expense eligibility is explicit-role-only

Claim: `ExpenseAccountMask` must admit only `role=expense`.

Evidence on merged `main`:

```text
ExpenseAccountMask <- role == "expense"
```

`SelectedExpenseIndices` consumes that mask before applying the target budget selector.

Status: `verified`.

### 2. Envelope budget eligibility is explicit-role-only

Claim: `BudgetAccountMask` must admit only `role=budget`.

Evidence on merged `main`:

```text
BudgetAccountMask <- role == "budget"
```

The mask is consumed by:

- `TargetBudgetAccountIndices`;
- `UnassignedBudgetAccountIndices`;
- `BuildEnvelopes` budget index selection.

Status: `verified`.

### 3. Missing-role prefix shape does not enter product selection

Claim: prefix-shaped missing-role expense/budget accounts must not be silently admitted.

Focused fixture:

`fixtures/src-next-envelope-computation-prefix-negative/`

It includes:

- `expenses:prefix-only` with no `role=` but selectable-looking budget/group/spend metadata;
- `budget:食費` with no `role=` but envelope-like metadata;
- `budget:unassigned` with no `role=` but `kind=unassigned`.

Focused assertions require:

- zero selected expense indices;
- zero target budget-account indices;
- zero unassigned budget-account indices;
- zero built envelopes;
- zero selected expense-account count;
- zero target budget-account count;
- zero unassigned account count.

Status: `verified`.

### 4. Diagnostic visibility remains

Claim: prefix-shaped missing-role accounts may remain observable diagnostically.

Evidence:

The same negative fixture requires:

- `prefix_fallback_expense_count = 1`;
- `prefix_fallback_budget_count = 2`;
- readiness missing-role account count = 3.

`household_metadata.bqn` keeps familiar-prefix masks as diagnostic counters while `expense_mask` remains explicit `role=expense` only.

Status: `verified`.

### 5. Household-policy classified expense counts are explicit-role-owned

Claim: fallback must not inflate fields that claim classified expense accounts.

Evidence on merged `main`:

```text
expense_accounts <- role_expense
prefix_fallback <- separate diagnostic mask
```

Focused negative assertions require:

- diagnostic fallback expense count = 1;
- classified expense count = 0;
- expense-with-budget count = 0;
- all budget-group classified counts = 0;
- all spend-class classified counts = 0.

Status: `verified`.

### 6. Stale fallback commentary was corrected

Claim: tests/docs must not claim current explicit-role fixtures exercise fallback admission.

Evidence in PR #151:

- `fixtures/src-next-expense-role-metadata/accounts.tsv` purpose comment now states explicit-role classification;
- `fixtures/src-next-household-mapping-policy/README.md` no longer claims prefix fallback coverage;
- `tests/test_src_next_household_metadata.bqn` comments now match fixture data carrying explicit roles.

Status: `verified`.

### 7. Unrelated prefix-based display/label behavior was not swept away

Claim: the slice must not blanket-delete string-prefix operations.

Evidence:

`BudgetLabel` remains present and still trims the `budget:` display/label prefix. The implementation patch removes only role-eligibility fallback from the two product-selection masks.

Status: `verified`.

### 8. Currency Stage 2 B2 was untouched

Claim: this safety slice must not alter B2 semantics or currency proof/projection work.

Evidence:

PR #151 changed only:

- one narrow negative fixture;
- two fixture/docs comments;
- `src_next/envelope_computation.bqn`;
- `src_next/household_metadata.bqn` comment;
- `src_next/household_policy.bqn`;
- three focused unit tests.

No `context.bqn`, `exact_decimal.bqn`, currency plan, proof carrier, projection authorization, Posting IR, Cube, or TBDS file changed.

Status: `verified`.

### 9. Verification suite is green

Implementation PR report recorded passing focused tests and `rtk bash ./tools/check.sh`.

GitHub Actions run #577 for implementation head `9d5a3a29...` completed successfully.

Status: `verified`.

## Plan acceptance criteria assessment

| Criterion | Result |
|---|---|
| explicit role owns touched expense/budget eligibility | verified |
| missing-role prefix candidates not silently admitted | verified |
| diagnostic visibility preserved | verified |
| missing role remains fail-visible | verified |
| explicit-role green path preserved | verified by focused tests + full CI |
| expense negative evidence | verified |
| budget negative evidence | verified |
| no B2 behavior change | verified by diff scope |
| no broad envelope refactor | verified |
| no unrelated prefix-helper deletion | verified |

## Implementation learning

The narrow separation worked:

```text
prefix shape can remain observable
without becoming classification authority
```

The key improvement was not deleting all prefix knowledge. It was removing prefix shape from product eligibility while retaining explicit diagnostic evidence.

The negative fixture is particularly valuable because it gives missing-role accounts metadata that looks selectable. The test therefore proves the role gate rather than merely proving an empty or irrelevant account is ignored.

## Closure and routing

This finite audit-promoted safety slice is complete and verified.

Routing returns to the already authorized current finite currency work:

```text
Currency Stage 2 Slice B2: Snapshot Arithmetic Evidence
```

The external audit remains a periodic reassessment source, not an implementation queue.

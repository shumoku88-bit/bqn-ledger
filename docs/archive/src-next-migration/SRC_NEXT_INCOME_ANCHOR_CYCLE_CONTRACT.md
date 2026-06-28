# src_next incomeAnchor cycle contract

Status: **implemented (PR #20)** — contract, public fixture, and minimal
implementation have landed. `src_next` is still not the production default.

This document was the design gate for the `incomeAnchor` cycle mode in
`src_next`. The minimal feature boundary was agreed here, then delivered
across PRs #18 (contract docs), #19 (public fixture), and #20 (minimal
implementation in `src_next/cycle.bqn`).

## 1. Background

### 1.1 Current state

- `src_next/cycle.bqn` supports only `mode fixed`. It reads `start` and
  `end_exclusive` from `cycle.tsv` and computes `day_count`.
- All 8 `fixtures/src-next-*` fixtures use `mode fixed`. All comparable
  fields (`cycle_range`, `actual_expense_total`, `plan_expense_total`) match
  the current engine exactly on these fixtures.
- Production `data/cycle.tsv` uses `mode incomeAnchor`. `src_next` fails on it
  because `cycle.bqn` looks up `start` / `end_exclusive` (absent in
  `incomeAnchor` mode), gets empty strings, and `DayCount` falls through with
  an out-of-bounds error.

### 1.2 Why this contract was needed

This contract was created before implementation to prevent:
- accidentally breaking fixed-mode fixture behavior
- leaking private production values into public tests/docs
- baking policy labels (food/daily/reserve) into cycle resolution
- rushing into code before the boundary is clear

With PR #20 merged, `src_next` can now resolve `incomeAnchor` cycles from
public fixtures. Production data comparison is retryable but not yet recorded.

## 2. Mode definitions

### 2.1 fixed mode (supported, must not regress)

`mode fixed` takes explicit `start` and `end_exclusive` from `cycle.tsv`.
This is the **comparison baseline** for all fixture-based golden checks.
It must continue to work exactly as it does today.

```tsv
mode    fixed
start   2026-05-01
end_exclusive   2026-06-01
```

### 2.2 incomeAnchor mode (implemented in PR #20)

`mode incomeAnchor` resolves cycle boundaries from the nearest income date
in the journal and the next income date in the plan. This is the production
cycle mode.

```tsv
mode    incomeAnchor
income_account  income:年金
```

Semantics (inherited from current engine `src/core/cycle.bqn`):

- `income_account` specifies which income account determines cycle boundaries.
- Cycle start: the most recent `income_account` entry in `journal.tsv` whose
  date ≤ `as_of` (or ≤ journal max date for src_next).
- Cycle end (exclusive): the next `income_account` entry in `plan.tsv` whose
  date is after the journal max date.
- The interval is half-open: `[start, end_exclusive)`.
- If the income account has no journal entry or no future plan entry, the
  cycle is unavailable (not silently defaulted).

### 2.3 incomeAnchor in src_next differs from current engine

| aspect | current engine | src_next (planned) |
|---|---|---|
| observation point | Uses `as_of` date for cycle window, row filtering, and plan visibility. Cycle start resolves against journal rows ≤ `as_of`. | No `as_of` concept yet. Cycle resolves against all journal rows in the data directory. All valid rows in the resolved cycle are materialized. |
| unavailable cycle | Reports "unavailable" section. | Returns an explicit unavailable/error indicator. Must not silently produce a misresolved range. |
| offset | Supports optional `offset` in `cycle.tsv` for shifting the anchor index. | Not planned for initial implementation. Default offset=0 only. |

## 3. Minimal feature boundary for src_next

The first implementation of `incomeAnchor` in `src_next/cycle.bqn` must do
these things and **only** these things:

### 3.1 Required behavior

1. **Parse `mode` and `income_account`** from `cycle.tsv`.
2. **When `mode=fixed`**: behave exactly as today (no change).
3. **When `mode=incomeAnchor`**:
   - Read `journal.tsv` and find the most recent row where column C (account
     name) matches `income_account`.
   - Read `plan.tsv` and find the first row dated after the journal max date
     where column C matches `income_account`.
   - Set `start` to the latest matching journal date.
   - Set `end_exclusive` to the matching plan date (or an unavailable sentinel
     if no match).
   - Compute `day_count` from resolved dates.
4. **`income_account` value is read from cycle.tsv**, not hard-coded.
5. **If `income_account` is absent** in `incomeAnchor` mode: unavailable.

### 3.2 Must not regress

- `mode fixed` must produce identical `start`, `end_exclusive`, `day_count`
  for all existing fixtures.
- All existing golden expected outputs must pass unchanged.
- `checks/check-src-next-vs-current.sh` must continue to pass on all
  fixed-mode fixtures.

### 3.3 Explicitly out of scope for the initial implementation

- `mode calendarMonth` (not needed for production data comparison; later
  Phase).
- `offset` support (default offset=0 is sufficient; current engine supports
  offset but src_next initial version does not need it).
- `as_of` / observation-point filtering (src_next has no `as_of` concept yet;
  this is a known design difference from the current engine, documented in
  `docs/SRC_NEXT_CURRENT_ENGINE_COMPARISON.md`).

## 4. Privacy boundary

### 4.1 Production cycle.tsv values are private

Production `data/cycle.tsv` contains `income_account` values that are
specific to this household. These values must not appear in:

- Public docs (this file included).
- Public fixture files.
- Public golden expected outputs.
- Commit messages that are pushed to the public repository.

### 4.2 Fixture policy

Fixtures for `incomeAnchor` mode must use **fabricated** values:

- Example `income_account`: use a generic, non-identifying name such as
  `income:example` or `income:test`.
- Example dates: use clearly fictional dates that do not correspond to any
  real financial schedule.
- The fixture `accounts.tsv` must define the fabricated account.

This policy applies to all fixture directories added in the implementation
PRs: `fixtures/src-next-income-anchor-*` or similar.

## 5. Non-goals (not in any cycle-related PR)

These topics are explicitly excluded from `incomeAnchor` cycle work.
They belong to separate, later contract docs and implementation PRs.

### 5.1 food / daily / safe / allocated remaining

- Food reporting, daily remaining, safe remaining, and allocated remaining
  are out of scope for cycle mode implementation.
- Cycle resolution does not need to know what "food" is.
- See `docs/SRC_NEXT_HOUSEHOLD_REPORT_POLICY_CONTRACT.md` for the intended
  policy boundary of those features.

### 5.2 daily / flex / reserve as engine concepts

- `daily`, `flex`, `reserve` are **policy/config values**, not engine
  concepts.
- They must not be hard-coded into `src_next/cycle.bqn` or any cycle
  resolution logic.
- If a future report contract uses these labels for grouping, they will be
  driven by configurable policy data (see
  `docs/SRC_NEXT_HOUSEHOLD_REPORT_POLICY_CONTRACT.md`).

### 5.3 calendarMonth mode

- `calendarMonth` is a later Phase. It is not required for production data
  comparison and is not part of the initial `incomeAnchor` implementation.

## 6. Fixture and golden strategy (completed)

### 6.1 Implementation was delivered in 3 PRs

```
PR #18: docs: define src_next incomeAnchor cycle contract
PR #19: src_next: add incomeAnchor cycle fixture
PR #20: src_next: support incomeAnchor cycle mode
```

All three PRs are merged. The fixture directory
`fixtures/src-next-income-anchor-golden/` is present with fabricated income
account `income:example`. The golden check is wired into `tools/check.sh` via
`check-src-next-golden.sh`. All existing fixed-mode fixtures still pass.

## 7. Acceptance criteria for this PR

This PR was docs-only. It was accepted when:

- [x] `docs/SRC_NEXT_INCOME_ANCHOR_CYCLE_CONTRACT.md` exists.
- [x] At least one existing docs file references this new contract doc.
- [x] No `src_next/*.bqn` changes.
- [x] No fixture changes.
- [x] No golden expected output changes.
- [x] `tools/check.sh` passes.
- [x] `git diff` is clean except for docs changes.

## 8. Related documents

- `docs/CYCLE.md` — current engine cycle.tsv format and mode documentation.
- `docs/SRC_NEXT_CURRENT_ENGINE_COMPARISON.md` — read-only comparison notes,
  including the `incomeAnchor` missing-feature classification.
- `docs/SRC_NEXT_REPLACEMENT_READINESS.md` — replacement readiness checklist
  and stage gates.
- `docs/SRC_NEXT_HOUSEHOLD_REPORT_POLICY_CONTRACT.md` — intended configurable
  household report policy contract (out of scope for cycle mode work).
- `docs/SRC_NEXT_GOLDEN_CHECK.md` — compact golden check surface for src_next.
- `src/core/cycle.bqn` — current engine cycle resolver (reference
  implementation for incomeAnchor semantics).
- `src_next/cycle.bqn` — src_next cycle reader (target for PR 3).

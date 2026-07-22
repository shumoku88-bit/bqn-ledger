# Journal split-purchase report aggregation and source-information boundary — test-only plan

Status: selected finite implementation contract
Owner: journal source migration
Canonical: no; canonical routing remains `TODO.md`
Exit: focused characterization implementation, review, completion record, and explicit return to no selected finite Journal slice
Date: 2026-07-22

## Purpose

The completed split-purchase characterization proved that three public synthetic Journal purchase transactions retain transaction-local balance, posting order, distinct fallback event identities, and exact account totals through Stage 1, the read-only source carrier, Stage 2A, and Cube materialization.

The earlier Journal report rehearsals proved that one simpler three-posting Journal transaction can reach the existing Trial Balance and Balances builders.

This finite slice connects those two completed evidence paths without changing either production routing or report code. It characterizes the boundary between:

- account-level information intentionally retained by Cube, TBDS, Trial Balance, and Balances; and
- transaction-level information intentionally retained by the read-only source carrier and Transaction IR, but not represented in account-aggregated reports.

The goal is not to make an aggregate report reconstruct a source transaction. The goal is to prove, with one focused test, that numeric aggregation remains exact while the location of non-aggregate source meaning is explicit and separately observable.

## Finite question

> Can the existing public synthetic split-purchase Journal fixture flow through the read-only source carrier, `context.BuildPeriodView`, `trial_balance.Build`, and `balances.Build` to produce exact account-level report aggregates, while separately demonstrating that transaction identities, descriptions, and posting order remain observable in carrier/Transaction IR evidence and are intentionally not reconstructible from the aggregated report outputs?

## Selected public synthetic evidence

Reuse the existing fixture without modification:

```text
fixtures/journal-split-purchase-characterization/profile.journal
fixtures/journal-split-purchase-characterization/accounts.tsv
```

The fixture contains three actual purchase transactions:

1. Convenience store
   - `expenses:tobacco/JPY` 600
   - `expenses:coffee/JPY` 150
   - `assets:cash/JPY` -750
2. Supermarket food split
   - `expenses:food:daily/JPY` 1400
   - `expenses:food:stock/JPY` 900
   - `assets:bank/JPY` -2300
3. Supermarket mixed purchase
   - `expenses:food:daily/JPY` 1400
   - `expenses:food:stock/JPY` 900
   - `expenses:household/JPY` 500
   - `assets:bank/JPY` -2800

All amounts remain tax-inclusive category subtotals. This slice does not introduce tax postings or tax metadata.

## Selected read path

```text
profile.journal
  -> journal_read_only_source_carrier.Build
  -> Transaction IR + current 16-field Posting IR rows
  -> context.BuildPeriodView
  -> Cube + TBDS
  -> trial_balance.Build
  -> balances.Build
  -> balances.Format / balances.FormatHuman
```

The focused implementation must use the existing public fixture and existing modules directly. It must not connect Journal input to `BuildContext`, `LoadPostingSourceSnapshot`, the production report command, or the production source loader.

## Responsibility boundary

### Read-only carrier and Transaction IR retain

- three transaction blocks;
- descriptions in source order;
- distinct nonempty `source_event_id` values;
- `physical_fallback` identity kind for the current fixture;
- posting counts `⟨3, 3, 4⟩`;
- posting order within each transaction;
- transaction-local zero-sum balance.

### Posting IR retains

- ten successful rows;
- account coordinates;
- signed deltas;
- layer and date coordinates;
- transaction and posting identities available before aggregation.

### Cube, TBDS, Trial Balance, and Balances retain

- account-level numeric movements and closings;
- exact debit and credit totals;
- zero-sum accounting result;
- resolved account order required by existing report builders.

### Aggregate report outputs do not claim to retain

- transaction description;
- shop or payee as a report dimension;
- original transaction grouping;
- posting order;
- `source_event_id` or `posting_id`;
- a reversible representation of the source Journal text.

Absence of those fields from aggregate reports is an intentional boundary in this characterization, not a failure. The test must not add transaction metadata axes to Cube or TBDS merely to make the report reversible.

## Required assertions

### 1. Source-side evidence remains separately observable

Before report aggregation, assert at least:

- carrier state is `ok` and diagnostics are empty;
- transaction count is 3;
- descriptions are exactly:
  - `Convenience store`
  - `Supermarket food split`
  - `Supermarket mixed purchase`
- posting counts are `⟨3, 3, 4⟩`;
- three `source_event_id` values are nonempty and pairwise distinct;
- posting account order and signed deltas match the existing fixture;
- every transaction-local delta sum is zero;
- Posting IR row count is 10 and every row status is `ok`.

### 2. Period-view aggregation is exact

Build an explicit August 2026 cycle view and assert:

- Cube valid count is 10;
- Cube skipped count is 0;
- actual account totals, in resolved account order, are:

```text
assets:cash/JPY             -750
assets:bank/JPY            -5100
expenses:tobacco/JPY         600
expenses:coffee/JPY          150
expenses:food:daily/JPY     2800
expenses:food:stock/JPY     1800
expenses:household/JPY       500
```

- actual expense total is 5850;
- all-account closing sum is zero.

### 3. Trial Balance is exact

For the actual layer, assert:

```text
accounts:
  assets:cash/JPY
  assets:bank/JPY
  expenses:tobacco/JPY
  expenses:coffee/JPY
  expenses:food:daily/JPY
  expenses:food:stock/JPY
  expenses:household/JPY

openings:
  0, 0, 0, 0, 0, 0, 0

debits:
  0, 0, 600, 150, 2800, 1800, 500

credits:
  -750, -5100, 0, 0, 0, 0, 0

closings:
  -750, -5100, 600, 150, 2800, 1800, 500
```

Also assert:

- debit total is 5850;
- credit total is -5850;
- closing total is 0.

### 4. Balances report is exact and renderable

Use `balances.Build` over the Journal-derived period view and assert that its account entries carry the same seven account-level closing values in resolved account order.

Also assert:

- `balances.Format` succeeds and returns nonempty output;
- `balances.FormatHuman` succeeds and returns nonempty output;
- no formatter or report implementation change is needed for this characterization.

### 5. Information-loss boundary is explicit

The focused test or its adjacent comments must make the following non-equivalence visible:

```text
source-side evidence:
  3 transactions / 10 ordered postings / 3 descriptions / 3 event identities

aggregate report evidence:
  7 account-level entries with exact movements and closings
```

The test must not assert that transaction descriptions, event identities, transaction grouping, or posting order can be recovered from Trial Balance or Balances output. Those properties are asserted against the carrier/Transaction IR before aggregation.

## Expected implementation scope

Expected new implementation file:

```text
tests/test_journal_split_purchase_report_information_boundary.bqn
```

Reused unchanged files:

```text
fixtures/journal-split-purchase-characterization/profile.journal
fixtures/journal-split-purchase-characterization/accounts.tsv
src_next/journal_read_only_source_carrier.bqn
src_next/context.bqn
src_next/trial_balance.bqn
src_next/balances.bqn
```

If the existing modules satisfy the contract, no `src_next/**`, fixture, tool, or production source file is changed.

If the focused test exposes a genuine existing contract failure, implementation must stop and report the mismatch rather than broadening the slice or silently changing report semantics.

## Success criteria

- the three split-purchase events remain observable as three events before reduction;
- ten ordered postings reduce to seven exact account-level report entries;
- Trial Balance and Balances values match hand-calculated expectations;
- debit and credit totals remain equal and opposite;
- report aggregation does not contaminate Cube or TBDS with transaction metadata axes;
- the source-information boundary is documented as intentional and non-reversible;
- existing production routing and source truth remain unchanged;
- only public synthetic evidence is used.

## Non-goals

- production Journal loader or routing;
- `BuildContext` or `LoadPostingSourceSnapshot` integration;
- production report command activation from Journal;
- report formatter redesign;
- new report section or JSON schema;
- transaction-detail report;
- payee or shop reporting dimension;
- adding description, memo, event identity, posting identity, or posting order axes to Cube or TBDS;
- reconstructing Journal text from Trial Balance or Balances;
- legacy TSV parity fixture for these three purchases;
- writer, editor, or interactive UI implementation;
- receipt OCR or automatic classification;
- tax postings, tax-rate allocation, or tax metadata;
- source-row consumer migration;
- private-data comparison;
- shadow read, conversion, source-of-truth switch, or cutover;
- broader report campaign or broader red-path campaign;
- automatic selection of the writer-contract slice or any later Journal stage.

## Validation gate for the future implementation

```bash
bqn tests/test_journal_split_purchase_report_information_boundary.bqn
bqn tests/test_journal_split_purchase_transaction_characterization.bqn
bqn tests/test_journal_read_path_trial_balance_rehearsal.bqn
bqn tests/test_journal_read_only_source_carrier.bqn

bash checks/check-docs-lifecycle.sh
bash checks/check-absolute-links.sh
bash checks/check-repo-index.sh
git diff --check
bash tools/check.sh
```

## Completion routing

After focused implementation and all checks pass:

- move this plan to:
  `docs/archive/completed-plans/JOURNAL_SPLIT_PURCHASE_REPORT_INFORMATION_BOUNDARY_PLAN-2026-07-22.md`;
- record exact carrier counts, report entry counts, Trial Balance vectors, Balances values, and validation evidence;
- update `TODO.md`, `NEXT_SESSION.md`, and `docs/README.md`;
- return Journal routing to `no finite slice selected`;
- do not automatically select production routing, writer work, UI work, conversion, shadow read, cutover, tax work, or another report slice.

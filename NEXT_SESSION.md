# Next session

Status: finite slice selected
Owner: journal source migration
Canonical: no; canonical routing remains `TODO.md`
Exit: complete the focused characterization and return routing to no selected finite Journal slice

## Selected Slice

Journal split-purchase report aggregation and source-information boundary — test-only

## Canonical Finite Contract

[docs/JOURNAL_SPLIT_PURCHASE_REPORT_INFORMATION_BOUNDARY_PLAN.md](docs/JOURNAL_SPLIT_PURCHASE_REPORT_INFORMATION_BOUNDARY_PLAN.md)

## Finite Question

> Can the existing public synthetic split-purchase Journal fixture flow through the read-only source carrier, `context.BuildPeriodView`, `trial_balance.Build`, and `balances.Build` to produce exact account-level report aggregates, while separately demonstrating that transaction identities, descriptions, and posting order remain observable in carrier/Transaction IR evidence and are intentionally not reconstructible from the aggregated report outputs?

## Selected Evidence Path

```text
fixtures/journal-split-purchase-characterization/profile.journal
  -> journal_read_only_source_carrier.Build
  -> Transaction IR + 10 Posting IR rows
  -> context.BuildPeriodView
  -> Cube + TBDS
  -> trial_balance.Build
  -> balances.Build / Format / FormatHuman
```

## Expected Boundary

- Source side: 3 transactions, posting counts `⟨3, 3, 4⟩`, 10 ordered postings, 3 descriptions, and 3 distinct fallback event identities.
- Report side: 7 exact account-level entries, debit total 5850, credit total -5850, and closing total 0.
- Transaction identity, descriptions, grouping, and posting order remain source-side evidence; aggregate reports do not claim reversibility.

## Expected Implementation File

```text
tests/test_journal_split_purchase_report_information_boundary.bqn
```

## Guard Rails

- Reuse the existing public fixture unchanged.
- No `src_next/**` change is expected.
- No production Journal routing, writer, editor, UI, report redesign, conversion, shadow read, private data, or cutover.
- Do not add transaction metadata axes to Cube or TBDS.
- If existing report contracts do not satisfy the selected assertions, stop and report the mismatch instead of widening the slice.

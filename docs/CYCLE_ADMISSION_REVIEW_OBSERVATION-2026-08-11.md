# Cycle admission review observation — 2026-08-11

## Baseline

- repository: `shumoku88-bit/bqn-ledger`
- review main: `d6f7c93845680d09dd3452724b88ea9560d0fb81`
- reviewed owner: `src/ledger/cycle_admission.bqn`

## What this owner is

`cycle_admission.bqn` is the strict admission owner for the older `cycle.tsv` contract. It parses key/value rows, admits `fixed`, `incomeAnchor`, and `calendarMonth` definitions, validates mode-specific fields and Account relations, and publishes the old `{state, table, definition, diagnostics}` shape.

Its implementation still contains visible mutable row/diagnostic staging and a line classifier whose empty-line guard surrounds a shape-sensitive first-character expression. Those are real code-shape observations, but they are not sufficient reason to refactor this owner.

## Reachability first

Current repository reachability no longer supports treating `cycle_admission.bqn` as the canonical runtime Cycle source owner.

Exact searches for imports/calls of this owner reach retained tests and qualification fixtures, including Cycle accounting/Section tests and the old aggregate config/cycle admission proof. No current `src/application` owner imports `cycle_admission.bqn` as its source boundary.

The current application Cycle resolver instead accepts an already-admitted Household Cycle definition and dispatches to the retained accounting resolvers.

## Canonical Cycle ownership

Canonical Cycle policy moved to `household.toml` during the Household source recovery.

The live path is now:

```text
canonical household.toml
  -> application/household_source_adapter.bqn
  -> ledger/household_policy_admission.bqn
  -> evidence.household.cycle
  -> application/cycle_resolution.bqn
  -> accounting Cycle resolver
```

`household_policy_admission.bqn` explicitly owns Household-only Cycle policy. Current Report destination code resolves Planned/Cycle reports from `evidence.household.cycle` rather than reading `cycle.tsv`.

The canonical Household source-name owner lists eight physical sources and contains no `cycle.tsv` basename.

## Executable cutover evidence

`checks/check-canonical-household-read-cutover.sh` constructs a temporary Household root containing exactly the eight canonical files and explicitly proves that legacy files, including `cycle.tsv`, are absent.

That root still executes retained Cycle-dependent workflows such as:

- Cycle Accounts;
- Planned Payments;
- Envelope/Backing;
- Daily Flow;
- Daily Target.

This is stronger evidence than naming convention alone: current retained reads do not require the old physical Cycle source.

Historical PR #559 completed the corresponding read-side ownership cutover. Its merged description explicitly assigns Cycle policy to canonical `household.toml`, routes Cycle/Planned/Cycle Accounts/Cycle Comparison through canonical Household evidence, removes legacy Cycle-line read authority, and qualifies the same no-`cycle.tsv` exit gate.

## Classification

Treat `src/ledger/cycle_admission.bqn` as a **legacy/qualification `cycle.tsv` seam**, not as the current Cycle policy architecture.

Therefore do not spend this BQN-native review converting its row loop, diagnostics append staging, helpers, or line classifier into a new array kernel. That would improve a source contract whose runtime authority has already moved elsewhere.

This is the same subtraction principle used for other retired aggregate/TSV seams: remove obsolete ownership coherently rather than beautifying it in place.

## Retirement boundary

Eventual deletion should be coordinated with the evidence that still constructs old Cycle admissions, especially:

- `tests/test_ledger_config_cycle_admission.bqn`;
- Cycle accounting/Section tests that use the old admission only as synthetic setup;
- old `cycle.tsv` fixtures and documentation;
- the remaining canonical Household recovery/repository-reachability closeout.

The retained accounting Cycle resolvers themselves are current owners and are not retirement targets merely because some tests still feed them through this old admission seam.

## Review decision

No production code change is selected for `cycle_admission.bqn`.

The correct BQN-native action here is architectural subtraction: record the lost source authority, preserve qualification evidence until its coherent retirement, and continue the live-owner review sequence at `src/ledger/date_ordinal.bqn`.

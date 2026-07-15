# Actual Comparison Numeric-Owner Compatibility Decision

Status: completed decision record / docs-only
Owner: report
Canonical: no; current paths: `docs/archive/active-plans/REPORT_PROJECTION_ALIGNMENT_PLAN-2026-07-15.md`, `docs/REPORT_CONTRACTS.md`, and future runtime checks
Exit: retain as the approved preimplementation compatibility decision; a runtime migration may implement it only when independently selected

## Decision scope

This record decides the compatibility contract required before Actual Comparison can move numeric ownership away from its current raw `journal.tsv` parser. It follows the pre-migration evidence in `ACTUAL_COMPARISON_PROJECTION_CHARACTERIZATION-2026-07-15.md`.

This slice changes no runtime, BQN module, fixture expectation, source/config schema, report option, or private data. The migration itself remains unselected.

## 1. Rejected actual source rows fail the section closed

If a `journal.tsv` source row rejected by checked Posting IR is observable by the section and affects the current or baseline comparison window, Actual Comparison is `ERROR`-like and its numeric table is empty. Upstream authorization failures that prevent context construction have the precedence defined below.

- Do not show a normal-looking partial aggregate.
- Do not coerce an observable rejected row to zero.
- Do not silently exclude it and continue.
- Do not preserve a value produced by the current raw parser.
- Unknown-account, invalid-date, and equivalent consumer-observable invalid actual evidence are not trustworthy comparison evidence. Invalid amount/currency evidence may instead stop at the upstream authorization boundary before the section is built.

### Section-local applicability

Actual Comparison owns only the windows it observes, not ledger-wide strict readiness. These rules apply to rejected journal rows retained in a successful checked projection/result and therefore observable by the consumer.

- A rejected journal row with a valid event coordinate `D` is section-local when `D` is in either the current or baseline half-open window.
- A rejected journal row with a valid `D` outside both windows does not by itself fail Actual Comparison. Ledger-wide readiness may still report it independently.
- An observable invalid-date journal row has no trustworthy coordinate and therefore cannot be proved outside the observed windows. It is applicability-unknown and fails Actual Comparison closed as `ERROR`; this is the narrow conservative exception to the valid-coordinate window rule.
- Rejected non-journal layers are not actual-row failures under this decision. Any plan/cycle evidence failure remains governed by the explicit anchor and cycle rules below.

Checked projection emits debit and credit posting rows for one rejected source row. Future rejected-row diagnostics and failure counting must group by stable source identity, at minimum `source_file + source_row` (and may retain `source_id` / `tx_id` as evidence), so one rejected source row does not produce duplicate section diagnostics. This diagnostic identity is separate from the numeric event-count identity in section 4.

### Upstream snapshot authorization takes precedence

The current context path performs snapshot-wide amount/currency arithmetic authorization before `BuildAuthorizedRowsFromSnapshot` can return a context. Therefore:

- unknown-account and invalid-date failures retained as checked posting rows/evidence are observable by the consumer, so Actual Comparison applies the current/baseline window rule above;
- invalid amount/currency evidence that makes snapshot arithmetic authorization unsupported currently produces an upstream fatal/error before `actual_comparison.BuildAt ⟨ctx, O⟩` can be reached;
- this decision does not require converting that upstream failure into a section-local `error`;
- continuing to render independent sections while carrying invalid amount/currency evidence would require a separately designed nonfatal checked-result carrier through context/report;
- that carrier change must not be folded automatically into the Actual Comparison numeric-owner runtime migration;
- the upstream fatal/error is stronger fail-closed behavior than a section-local error and does not weaken the safety decision.

## 2. Actual Comparison owns an explicit observation `O`

The future section boundary is:

```text
actual_comparison.BuildAt ⟨ctx, O⟩
```

The production report entry is intended to pass its already captured report date:

```text
report_today
  -> actual_comparison.BuildAt(ctx, report_today)
```

`O` is a hard cutoff.

- A journal event with `D > O` does not contribute to current amount or event count.
- `O` is not derived from the maximum journal date.
- `ctx.as_of` is not an implicit Actual Comparison observation owner.
- Record frontier `L`, maximum journal date, cycle end, and generation time are not substitutes for `O`.
- This decision does not introduce a report-wide common `as_of` or a CLI option.
- Outlook may receive the same date value, but Outlook `O` and Actual Comparison `O` remain separate consumer contracts.

The current period is the intersection:

```text
[cycle.start, min(O + 1 day, cycle.end_exclusive))
```

Consequences:

- journal rows after `O` are excluded;
- journal rows at or after `cycle.end_exclusive` are excluded even if `O` is later;
- if the intersection is empty, including `O < cycle.start`, the section is `UNAVAILABLE` with an empty table;
- an invalid cycle is `ERROR` with an empty table;
- the baseline starts at the resolved previous comparable anchor and uses the same elapsed length as the current window.

## 3. Remove `insufficient_history` from the migrated contract

The characterization proved that current `insufficient_history` is unreachable from valid source and that event absence does not establish source-history completeness. The migrated section vocabulary is therefore:

```text
ok
unavailable
error
```

- No constructible previous comparable cycle/anchor is `unavailable`.
- An invalid cycle or applicable invalid actual source is `error`.
- Zero baseline events are still `ok` when the comparison window itself is valid.
- A row with baseline amount zero retains `new` / `n/a` behavior.
- `insufficient_history` may be reconsidered only in an independent future slice after explicit source-history coverage evidence exists.

Removing `insufficient_history` from machine and human output is an intentional future runtime contract change. This docs-only slice does not change current output.

## 4. Numeric and evidence ownership

A future migration must use these owners:

| Meaning | Owner |
|---|---|
| current/baseline amount | period-local actual-layer TBDS movement derived from checked ledger-wide Posting IR |
| current/baseline event count | admitted actual posting evidence from the same checked Posting IR, counted per lane/unit key with debit/credit pair duplication removed |
| lane/account classification | `ctx.resolved` account identity, `role`, and `spend_class` |
| income anchor / previous-cycle identity | checked posting/source identity or explicit valid plan/cycle evidence |
| source memo, ID, and anchor provenance | evidence path, not a second amount parser |
| rejected-row diagnostics | checked projection and source evidence, grouped by source identity |

The section must not parse the same amount again from `journal.tsv`.

### Numeric event-count identity

The migration preserves the current account-level amount/count semantics. Event counting is per output key, not a report-wide source-row deduplication.

- Remove duplication caused by the debit/credit posting pair for the same semantic contribution.
- Count identity is at least `source_file + source_row + lane + unit/account identity`.
- One source row may contribute one event to each distinct output key that it semantically matches.
- For example, when the source `from` side is an income account and the `to` side is an expense account, that row may contribute one event to the income unit and one event to the expense unit.
- Do not globally deduplicate the whole report by source row and thereby discard one of those account-level observations.

Rejected-row diagnostic deduplication remains source-identity based because it answers “how many invalid source rows?”, not “how many admitted events contributed to each numeric key?”. Diagnostic identity and numeric event-count identity must not be shared accidentally.

### Cube boundary

- Canonical Cube shape remains `Day × Account × Layer`.
- This decision does not require every Actual Comparison amount to come from the existing cycle Cube.
- A non-cycle baseline may use a local TBDS view or rematerialized local Cube derived from the same checked ledger-wide Posting IR.
- Implementation details are intentionally not fixed beyond checked Posting IR / TBDS-family semantic ownership.
- Event count, anchor identity, and diagnostics are evidence concerns and do not become Cube axes.

## 5. Intentional compatibility changes

When the runtime migration is independently selected, the PR #261 normal fixture has at least these intentional differences:

1. The in-window `unknown:ghost -> expenses:food 7` source row makes the section `error` with an empty numeric table. Current `food=88` is not preserved.
2. With explicit `O=2026-03-05`, the `2026-03-07` journal row is outside the hard cutoff and is not aggregated.
3. `vm.as_of` is owned by the explicit `O`, not the maximum journal date.
4. `insufficient_history` is removed from the section status vocabulary.

The PR #261 characterization fixture and expectations remain unchanged as pre-migration evidence in this docs-only slice. A runtime PR must either add separate target-contract fixtures or change existing expectations with an explicit compatibility review that cites both characterization and this decision.

## Future runtime boundary: selectable, not selected

The next selectable finite slice is the Actual Comparison numeric-owner runtime migration around:

```text
actual_comparison.BuildAt ⟨ctx, O⟩
```

That slice may implement only the approved section-local rejection, explicit observation, status, numeric-owner, and evidence-owner contracts with focused fixtures/checks. It must not infer a report-wide `--as-of`, generic temporal kernel, generic period-query abstraction, Projection Workbench, Cube shape change, or migration of Outlook / `actual_snapshot`.

## Non-goals

- no `src_next/*.bqn` changes;
- no test, fixture, or check expectation changes;
- no Actual Comparison runtime migration or `BuildAt` implementation;
- no report CLI option or report-wide `--as-of`;
- no generic temporal kernel or period-query abstraction;
- no Projection Workbench or Cube shape change;
- no source TSV, config, or metadata change;
- no Outlook, `actual_snapshot`, or Daily Capacity follow-up;
- no private production-data access.

# Cycle Remaining-Plan Numeric-Owner Runtime Migration

Status: completed runtime record
Owner: report
Canonical: no; current runtime contract: `docs/REPORT_CONTRACTS.md`, `src_next/cycle_summary.bqn`, and executable checks
Exit: retain as the implementation record; future changes require an independently selected finite slice

## Completed scope

Cycle Summary `plan_expense_remaining` now follows the approved compatibility decision without expanding the Cube, TBDS API, temporal kernel, or source schema.

The runtime now:

- preserves `O <= D < C.end_exclusive`;
- derives O from the latest valid actual date inside C and falls back to `C.start` when C has no actual row;
- excludes completed plans using existing cycle-local `plan_id` / five-field fallback identity evidence;
- joins each applicable plan source row to admitted `plan.tsv` Posting IR by stable `source_row`;
- derives remaining expense money only from the admitted expense-side debit delta;
- returns `state`, `reason`, and one source diagnostic per invalid source row;
- fails the whole Cycle Summary closed on applicable invalid, rejected, missing, or structurally unjoinable plan evidence;
- suppresses all normal Cycle Summary numeric and breakdown output on error;
- displays the source file, source row, date, status, and message explaining why the section stopped;
- preserves valid empty-plan, no-actual, outside-actual, duplicate-identity, exact-decimal, and narrow no-base compatibility behavior.

## Ownership after migration

| Meaning | Owner |
|---|---|
| actual income, expense, net, and total plan expense | TBDS over checked Posting IR |
| remaining expense-plan money | admitted `plan.tsv` debit Posting IR |
| source correspondence | `source_file=plan.tsv` plus `source_row` |
| completion identity | cycle-local source evidence using `plan_rows.PlanId` |
| section state and diagnostics | `src_next/cycle_summary.bqn` |
| human/machine fail-closed rendering | `cycle_summary.FormatHuman` / `cycle_summary.Format` |

The Canonical Cube remains `Day × Account × Layer`. No plan ID, completion, memo, or diagnostic axis was added. No generic TBDS plan API or Projection Workbench was introduced.

## Intentional compatibility changes

The selected runtime intentionally changes the characterized raw-parser behavior:

1. Completed plans no longer contribute to the remaining amount.
2. Supported exact-decimal amounts use the normalized admitted Posting IR coefficient instead of becoming local zero.
3. Applicable unknown-account evidence stops Cycle Summary instead of being silently excluded.
4. Invalid plan dates return controlled source-row diagnostics instead of an indexing crash.
5. Missing half of a debit/credit plan pair returns `structural_join` error instead of preserving a raw-parser total.
6. Error machine output contains state/reason/diagnostics but no normal Cycle numeric keys.
7. Error human output states why the section stopped and renders no normal totals or breakdowns.

## Executable evidence

- `fixtures/cycle-remaining-plan-characterization/`
- `tests/test_src_next_cycle_remaining_plan_characterization.bqn`
- `checks/probes/cycle-summary-invalid-date.bqn`
- `checks/check-src-next-cycle-remaining-plan-characterization.sh`
- existing src_next golden, section, compact-summary, workflow-drift, docs-lifecycle, and coverage checks

Focused cases cover:

- normal and reverse-journal order;
- completed-plan exclusion;
- applicable unknown account;
- structurally missing credit posting;
- two independent invalid-date source rows;
- empty plan;
- no actual in C and actual only outside C;
- exact-decimal USD amount ownership;
- duplicate plan identity order independence;
- no-base direct-call compatibility.

## Validation

GitHub Actions `check` run #998 passed on the runtime branch, including:

- `bash tools/check.sh`;
- the complete existing unit/golden/section/check suite;
- Cycle Summary controlled invalid-date subprocess coverage;
- Coverage.

No private production data was accessed. The implementation and tests use repository fixtures only.

## Non-goals retained

- no source TSV, config schema, metadata, or currency-policy change;
- no Cube shape or metadata-axis change;
- no generic TBDS plan API, Projection Workbench, or query framework;
- no shared temporal kernel or report-wide observation option;
- no envelope allocation or execution-plan coverage change;
- no Daily Capacity connection;
- no editor, automatic advice, adjustment, or write path;
- no private production-data access.

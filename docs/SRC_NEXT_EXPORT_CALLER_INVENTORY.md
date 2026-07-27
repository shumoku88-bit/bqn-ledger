# `src_next` export and caller inventory

Status: Phase 0C current evidence
Owner: ledger-facts report migration
Scope: source-level qualified callers at `d7188bd` plus current uncommitted audit tooling

## Reproducible inventory

```bash
python3 tools/characterization/src_next_export_callers.py --summary
python3 tools/characterization/src_next_export_callers.py
```

The detailed TSV command emits every recognized final-record export with runtime, editor, test, check, and tool reference counts plus caller files.

The inventory tool follows the repository convention that an importable BQN module ends in one export namespace record. It resolves qualified references from BQN imports and embedded BQN imports in checks/tools. Dynamic name lookup or undocumented external consumers cannot be proved by static search; no such public package contract is currently documented.

## Summary

| disposition | exports |
|---|---:|
| repository runtime/editor/tool caller | 205 |
| test/check-only caller | 63 |
| explicit `ForTest` seam | 14 |
| zero repository caller | 53 |
| **total** | **335** |

Recognized modules with exports: 70 of 75 `src_next` modules.

## Disposition meaning

### Repository runtime caller

These exports are current migration inputs, not automatic destination APIs. Each moves only if it expresses canonical ledger/accounting behavior; section/context/compatibility APIs are replaced and deleted according to `docs/RUNTIME_COMPATIBILITY_INVENTORY.md`.

### Test/check-only caller

A test is evidence for behavior, not sufficient reason to preserve an API. During migration each export must become one of:

- a truthful canonical pure capability with a real destination consumer;
- an internal helper tested through its owner;
- archived experiment evidence;
- deleted compatibility surface.

### Explicit `ForTest` seam

All 14 are mandatory deletion candidates. Tests must call real canonical APIs; destination production modules expose no `ForTest` names.

```text
src_next/context.bqn.BuildAuthorizedRowsFromPreparedForTest
src_next/context.bqn.BuildCheckedPostingProjectionFromPreparedForTest
src_next/cycle_summary.bqn.BuildFromPreparedForTest
src_next/cycle_summary.bqn.BuildRemainingEvidenceFromLinesForTest
src_next/cycle_summary.bqn.BuildRemainingFromEvidenceForTest
src_next/daily_trend_plan.bqn.BuildEvidenceFromLinesForTest
src_next/daily_trend_plan.bqn.BuildFromEvidenceForTest
src_next/outlook_remaining_plan.bqn.BuildEvidenceFromLinesForTest
src_next/outlook_remaining_plan.bqn.BuildFromEvidenceForTest
src_next/planned_payments.bqn.BuildCompactViewModelFromPreparedForTest
src_next/planned_payments.bqn.BuildViewModelFromPreparedForTest
src_next/planned_payments.bqn.FormatCompactViewModelForTest
src_next/planned_payments.bqn.FormatHumanViewModelForTest
src_next/planned_payments.bqn.FormatJsonViewModelForTest
```

One seam is already a runtime smell: `selected_domain_context.bqn` calls `context.BuildCheckedPostingProjectionFromPreparedForTest`. The destination must replace that name/ownership rather than carry it forward.

### Zero repository caller

These 53 exports have no recognized repository caller. They are not all dead definitions: some are private helpers used within their own module. The export fields themselves have no current repository justification and must not be copied into the destination API.

```text
src_next/account_key.bqn.KindFromMeta
src_next/account_key.bqn.MetaValue
src_next/context.bqn.BuildProjectionRowsForEvidence
src_next/context.bqn.BuildRowsForFileOptional
src_next/cube.bqn.BuildSkippedSummary
src_next/cube.bqn.IsValidRow
src_next/cube.bqn.MakeValidationSummary
src_next/cube.bqn.RowSkipCategory
src_next/currency_setup.bqn.AuditLine
src_next/cycle.bqn.DayCount
src_next/daily_flow.bqn.Format
src_next/date.bqn.IsLeap
src_next/format.bqn.Blue
src_next/format.bqn.Bold
src_next/format.bqn.Cyan
src_next/format.bqn.Dim
src_next/format.bqn.Green
src_next/format.bqn.Magenta
src_next/format.bqn.Red
src_next/format.bqn.Yellow
src_next/format.bqn.c_blue
src_next/format.bqn.c_bold
src_next/format.bqn.c_cyan
src_next/format.bqn.c_dim
src_next/format.bqn.c_green
src_next/format.bqn.c_magenta
src_next/format.bqn.c_red
src_next/format.bqn.c_reset
src_next/format.bqn.c_yellow
src_next/friend_travel_source_event.bqn.Render
src_next/household_metadata.bqn.Sum0
src_next/household_policy.bqn.HasPolicyMetadata
src_next/household_policy.bqn.Sum0
src_next/journal_profile_stage1.bqn.LegacyMetadataValueValid
src_next/journal_shadow_context.bqn.Build
src_next/loader.bqn.SplitTsv
src_next/plan_journal_overlap.bqn.InCycle
src_next/plan_journal_overlap.bqn.Key
src_next/plan_rows.bqn.InCycle
src_next/planned_payments.bqn.BuildViewModel
src_next/planned_payments.bqn.PlanId
src_next/planned_payments.bqn.StatusFor
src_next/projection.bqn.ArithmeticCurrencyAuthorizationMessage
src_next/selected_domain_context.bqn.ValidateNonActualEvidence
src_next/snapshot.bqn.DaysElapsed
src_next/snapshot.bqn.RemainingDaysText
src_next/tbds.bqn.ExpenseRows
src_next/tbds.bqn.IncomeRows
src_next/tbds.bqn.MovementByLayer
src_next/tbds.bqn.MovementByLayerSide
src_next/travel_exchange_event.bqn.Render
src_next/unavailable.bqn.noData
src_next/unavailable.bqn.noPolicy
```

## Module-level pressure

The largest export shelves with zero-caller fields are:

| module | exports | zero-caller exports | observation |
|---|---:|---:|---|
| `format.bqn` | 35 | 17 | color constants/wrappers exceed current callers |
| `context.bqn` | 14 | 5 | broad construction shelf plus test seam |
| `cube.bqn` | 17 | 4 | validation internals and Layer compatibility surface |
| `tbds.bqn` | 12 | 4 | unused broad query helpers |
| `planned_payments.bqn` | 11 | 3 | compatibility/test-oriented surface |
| `account_key.bqn` | 10 | 2 | metadata helper exports exceed runtime needs |

This confirms that destination APIs should be designed from concrete consumers rather than copied from current export records.

## Migration rules from this evidence

1. Do not copy any current export record wholesale.
2. A zero-caller export is deleted or kept private when its module migrates.
3. A test-only export requires a named destination consumer before becoming public.
4. Every `ForTest` export is removed with its owning section/capability migration.
5. Runtime callers are migrated to canonical capabilities, not redirected through old-path wrappers.
6. Final Phase 7 reruns the tool before deleting `src_next`; expected destination result is no `src_next` tree, not a smaller compatibility inventory.

## Caveats and follow-up

- Shell scripts that mention module filenames without importing qualified exports are captured by the compatibility/path inventory, not this symbol table.
- Unqualified function calls inside the defining module are intentionally not export callers.
- Human docs may describe external intent but do not count as executable callers.
- Phase 0C still needs output contract parity decisions and strict-source decision approval before new runtime code begins.

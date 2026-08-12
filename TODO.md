# BQN review queue

## Purpose

Turn bqn-ledger into a place where household accounting is expressed through compact, explicit, and instructive BQN architecture and algorithms.

The canonical Household source/configuration migration is the foundation. The main review line now subtracts incidental machinery while preserving admitted meaning, exact arithmetic, diagnostics, identity, provenance, evidence alignment, safe effects, and public behavior.

The intended path is:

```text
strict source and request admission
  -> bounded whole-array accounting kernel
  -> semantic result and provenance
  -> selector-independent command/UI boundary
```

Terminal selectors are adapters rather than architecture owners. Accounting meaning, source mutation, report keys, and policy must not drift into selector-specific shell code.

## Repository-resident continuation contract

The repository defines the current review state. Chat history, remembered SHAs, and handoff prompts are conveniences only.

A fresh session should:

1. verify current remote `main`, relevant open PRs/branches, and CI;
2. read this queue and the closeout/observation documents referenced by completed phases;
3. check whether parallel work changed the active owner, direct consumers, or protected invariants;
4. resume from the current cursor unless a concrete correctness, performance, or architectural defect justifies a cursor exception;
5. record durable decisions and the resulting cursor in the repository before ending the session.

A checked item means the owner has been reviewed under the dense-array policy and its final decision is reconstructible from current repository evidence and Git history.

## Review rules

Review one coherent reason-to-change at a time. A coherent end-state may cross files or layers; do not manufacture tiny PRs, temporary adapters, duplicate paths, or compatibility shims merely to keep a change small.

For each owner, ask whether semantic axes, classification, Group/Pivot/Rank/Cells, structural transformation, composition, and exact reductions are visible enough. Distinguish removable machinery from protected complexity.

Keep local guards when they protect a real law or evaluation boundary, including:

- exact-operation failure;
- identity/provenance selection;
- diagnostic ordering and fail-closed publication;
- source/writer authority;
- optional publication whose eager evaluation changes validity or behavior.

Validation density or file size is not itself a defect. Compactness is useful only when meaning becomes clearer.

## Cross-cutting audit inventory

- [ ] terminal selector/input duplication and UI change locality across active shell surfaces;
- [ ] editor/writer ownership from BQN semantic decision through machine operation to safe-write publication;
- [ ] report/application CLI reachability and repeated effect/protocol boundaries beyond the resolved multi-report lifetime;
- [ ] repository-wide dead-surface and reachability audit, including retained wrappers, `experiments/`, and `tui/`;
- [ ] validation/kernel/publication separation across retained accounting and adjacent semantic owners;
- [ ] remaining migration/compatibility residue classified without duplicating the canonical Household recovery closeout;
- [ ] checks and tests classified as law guards, characterization evidence, or obsolete topology assumptions.

## Phase order

1. `src/accounting/` pure accounting kernels
2. `src/ledger/` admission, Facts, exact values, identity, and provenance
3. `src/sections/` semantic result owners
4. `src/report/` catalog, request, composition, and rendering
5. `src/application/` adapters, profiles, and effect boundaries
6. `src/editor/` and `src_edit/` rewrite and command owners
7. remaining production BQN under `src/text/` and `tools/`, followed by selector/UI adapter consolidation

The production inventory covers every `.bqn` file under `src/`, `src_edit/`, and `tools/` exactly once below. `experiments/` stays outside this production inventory and belongs to the repository-wide reachability audit.

## Phase 1: `src/accounting/` — complete

Closeout: `docs/ACCOUNTING_PHASE_ONE_REVIEW_CLOSEOUT-2026-08-11.md`.

- [x] `src/accounting/account_balance.bqn`
- [x] `src/accounting/account_period.bqn`
- [x] `src/accounting/balance_sheet.bqn`
- [x] `src/accounting/cycle_account_period.bqn`
- [x] `src/accounting/cycle_calendar_month_resolution.bqn`
- [x] `src/accounting/cycle_comparison.bqn`
- [x] `src/accounting/cycle_fixed_resolution.bqn`
- [x] `src/accounting/cycle_income_anchor_resolution.bqn`
- [x] `src/accounting/cycle_result.bqn`
- [x] `src/accounting/daily_target.bqn`
- [x] `src/accounting/date_category_flow.bqn`
- [x] `src/accounting/envelope_backing.bqn`
- [x] `src/accounting/matrix_result.bqn`
- [x] `src/accounting/month_account_movement.bqn`
- [x] `src/accounting/month_category_flow.bqn`
- [x] `src/accounting/plan_completion_join.bqn`
- [x] `src/accounting/plan_temporal_status.bqn`
- [x] `src/accounting/profit_and_loss.bqn`
- [x] `src/accounting/recent_transactions.bqn`
- [x] `src/accounting/sparse_group.bqn`
- [x] `src/accounting/sparse_pivot.bqn`

## Phase 2: `src/ledger/` — complete

Closeout: `docs/LEDGER_PHASE_TWO_REVIEW_CLOSEOUT-2026-08-12.md`.

- [x] `src/ledger/account_admission.bqn`
- [x] `src/ledger/account_journal_admission.bqn`
- [x] `src/ledger/amount_text.bqn`
- [x] `src/ledger/budget_journal_admission.bqn`
- [x] `src/ledger/budget_policy_admission.bqn`
- [x] `src/ledger/canonical_journal_root_admission.bqn`
- [x] `src/ledger/companion_admission.bqn`
- [x] `src/ledger/config_admission.bqn`
- [x] `src/ledger/currency_registry.bqn`
- [x] `src/ledger/cycle_admission.bqn`
- [x] `src/ledger/date_ordinal.bqn`
- [x] `src/ledger/exact_decimal.bqn`
- [x] `src/ledger/exact_scale.bqn`
- [x] `src/ledger/fact_reference.bqn`
- [x] `src/ledger/facts.bqn`
- [x] `src/ledger/household_policy_admission.bqn`
- [x] `src/ledger/issue_admission.bqn`
- [x] `src/ledger/journal_complete_admission.bqn`
- [x] `src/ledger/journal_posting_text.bqn`
- [x] `src/ledger/journal_single_domain_admission.bqn`
- [x] `src/ledger/journal_transaction_structure.bqn`
- [x] `src/ledger/plan_journal_admission.bqn`
- [x] `src/ledger/plan_snapshot.bqn`
- [x] `src/ledger/report_policy_admission.bqn`
- [x] `src/ledger/snapshot.bqn`
- [x] `src/ledger/transaction_rows.bqn`

## Phase 3: `src/sections/` — complete

Closeout: `docs/SECTIONS_PHASE_THREE_REVIEW_CLOSEOUT-2026-08-12.md`.

- [x] `src/sections/account_balances.bqn` — #684
- [x] `src/sections/balance_sheet.bqn` — #685
- [x] `src/sections/cycle_accounts.bqn` — #686
- [x] `src/sections/cycle_comparison.bqn` — #686
- [x] `src/sections/daily_flow.bqn` — #687
- [x] `src/sections/daily_target.bqn` — #689
- [x] `src/sections/envelope_backing.bqn` — #689
- [x] `src/sections/issues.bqn` — #687
- [x] `src/sections/monthly_accounts.bqn` — #687
- [x] `src/sections/planned_payments.bqn` — #690
- [x] `src/sections/profit_and_loss.bqn` — #687
- [x] `src/sections/recent_journal.bqn` — #688
- [x] `src/sections/trial_balance.bqn` — #688

## Phase 4: `src/report/`

- [ ] `src/report/catalog.bqn`
- [ ] `src/report/catalog_text.bqn`
- [ ] `src/report/compose.bqn`
- [ ] `src/report/json_text.bqn`
- [ ] `src/report/render.bqn`
- [ ] `src/report/request.bqn`
- [ ] `src/report/section_metadata.bqn`
- [ ] `src/report/text.bqn`

## Phase 5: `src/application/`

- [ ] `src/application/account_source_adapter.bqn`
- [ ] `src/application/actual_journal_config.bqn`
- [ ] `src/application/actual_source_adapter.bqn`
- [ ] `src/application/budget_source_adapter.bqn`
- [ ] `src/application/canonical_household_sources.bqn`
- [ ] `src/application/config_rows.bqn`
- [ ] `src/application/current_report_batch_cli.bqn`
- [ ] `src/application/current_report_profile_cli.bqn`
- [ ] `src/application/current_report_requests.bqn`
- [ ] `src/application/cycle_resolution.bqn`
- [ ] `src/application/daily_scope_adapter.bqn`
- [ ] `src/application/daily_scope_admission.bqn`
- [ ] `src/application/date_today.bqn`
- [ ] `src/application/editor_accounts.bqn`
- [ ] `src/application/editor_actual.bqn`
- [ ] `src/application/editor_config_path.bqn`
- [ ] `src/application/editor_currency.bqn`
- [ ] `src/application/editor_plan_rows.bqn`
- [ ] `src/application/funding_scope.bqn`
- [ ] `src/application/household_daily_scope.bqn`
- [ ] `src/application/household_source_adapter.bqn`
- [ ] `src/application/ledger_check_cli.bqn`
- [ ] `src/application/ledger_inspect_cli.bqn`
- [ ] `src/application/plan_source_adapter.bqn`
- [ ] `src/application/report_destination.bqn`
- [ ] `src/application/report_destination_cli.bqn`
- [ ] `src/application/report_domain_cli.bqn`
- [ ] `src/application/report_domain_selection.bqn`
- [ ] `src/application/report_metadata_cli.bqn`
- [ ] `src/application/report_policy_resolution.bqn`
- [ ] `src/application/report_policy_source_adapter.bqn`
- [ ] `src/application/report_presentation_cli.bqn`
- [ ] `src/application/report_request_cli.bqn`
- [ ] `src/application/report_route.bqn`
- [ ] `src/application/report_route_plan.bqn`
- [ ] `src/application/report_route_plan_cli.bqn`
- [ ] `src/application/report_selection_cli.bqn`
- [ ] `src/application/report_source_adapter.bqn`
- [ ] `src/application/source_io.bqn`
- [ ] `src/application/system_defaults.bqn`

## Phase 6: `src/editor/` and `src_edit/`

### `src/editor/`

- [ ] `src/editor/friend_travel_source_event.bqn`
- [ ] `src/editor/journal_profile.bqn`
- [ ] `src/editor/travel_exchange_event.bqn`

### `src_edit/`

- [ ] `src_edit/account_add_cmd.bqn`
- [ ] `src_edit/account_list_cmd.bqn`
- [ ] `src_edit/account_validate_cmd.bqn`
- [ ] `src_edit/actual_journal_file_cmd.bqn`
- [ ] `src_edit/budget_add_cmd.bqn`
- [ ] `src_edit/budget_movement_candidate.bqn`
- [ ] `src_edit/budget_validate_cmd.bqn`
- [ ] `src_edit/issue_add_cmd.bqn`
- [ ] `src_edit/issue_close_cmd.bqn`
- [ ] `src_edit/issue_list_cmd.bqn`
- [ ] `src_edit/issue_validate_cmd.bqn`
- [ ] `src_edit/journal_block_add_cmd.bqn`
- [ ] `src_edit/journal_canonical_surface_apply_cmd.bqn`
- [ ] `src_edit/journal_canonical_surface_plan.bqn`
- [ ] `src_edit/journal_canonical_surface_plan_cmd.bqn`
- [ ] `src_edit/journal_canonical_surface_preview_cmd.bqn`
- [ ] `src_edit/journal_canonical_surface_rewrite.bqn`
- [ ] `src_edit/journal_cleanup_apply_cmd.bqn`
- [ ] `src_edit/journal_cleanup_plan.bqn`
- [ ] `src_edit/journal_cleanup_plan_cmd.bqn`
- [ ] `src_edit/journal_cleanup_rewrite.bqn`
- [ ] `src_edit/journal_cleanup_verify_cmd.bqn`
- [ ] `src_edit/journal_identity_inventory.bqn`
- [ ] `src_edit/journal_identity_inventory_cmd.bqn`
- [ ] `src_edit/journal_list_cmd.bqn`
- [ ] `src_edit/journal_native_reverse_cmd.bqn`
- [ ] `src_edit/journal_native_source_check.bqn`
- [ ] `src_edit/journal_reconstructible_identity_cleanup.bqn`
- [ ] `src_edit/journal_reconstructible_identity_cleanup_cmd.bqn`
- [ ] `src_edit/journal_validate_cmd.bqn`
- [ ] `src_edit/plan_add_cmd.bqn`
- [ ] `src_edit/plan_budget_sync_cmd.bqn`
- [ ] `src_edit/plan_edit_cmd.bqn`
- [ ] `src_edit/plan_finish_cmd.bqn`
- [ ] `src_edit/plan_finish_validate_cmd.bqn`
- [ ] `src_edit/plan_id.bqn`
- [ ] `src_edit/plan_list_cmd.bqn`
- [ ] `src_edit/plan_related_cmd.bqn`
- [ ] `src_edit/plan_validate_cmd.bqn`
- [ ] `src_edit/render.bqn`
- [ ] `src_edit/travel_exchange_add_cmd.bqn`
- [ ] `src_edit/travel_friend_add_cmd.bqn`
- [ ] `src_edit/validate.bqn`

## Phase 7: remaining production BQN and selector/UI adapters

### `src/text/`

- [ ] `src/text/parse.bqn`

### `tools/` BQN

- [ ] `tools/bqn-dump.bqn`

After the production BQN inventory is reviewed, selector/UI adapter consolidation and shell/tool families remain governed by the cross-cutting audit inventory rather than pretending every shell wrapper is a BQN semantic owner.

## Current cursor

`src/report/catalog.bqn`

Resume the normal Phase 4 report review sequence at Report Catalog.

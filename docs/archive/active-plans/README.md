# active-plans inventory

Status: directory inventory / docs hygiene
Date: 2026-07-06

This directory is an archive staging area, not a guarantee that every file is currently active.
Some files are active plans or backlogs; others are completed decisions, historical handoffs, or superseded sketches kept here until references are cleaned up.

When choosing work, prefer `TODO.md` first. Use this inventory to avoid treating stale notes as current specs.

## Reading rule

| Class | Meaning | How to use |
|---|---------|------|
| `active` | Current plan/backlog/intake that may feed future TODO slices | Read when the corresponding TODO asks for it |
| `parked` | Idea/sketch/planning note with no approved implementation | Do not implement directly; first promote a small docs-only slice to `TODO.md` |
| `historical` | Implemented, superseded, or stale handoff/decision | Read only for background; do not use as current instruction |

## Inventory

| File | Class | Current reading path / note |
|---|---|---|
| `../completed-plans/ACTUAL_COMPARISON_REPORT_PLAN.md` | historical | Moved to completed plans. Implemented decision record for `actual-comparison`; current report entry is `docs/REPORT_CONTRACTS.md` plus `src_next/` checks. |
| `AI_AGENT_EFFICIENCY_PLAN.md` | parked | AI efficiency ideas; use only when doing dev-experience work with `AI_WORKING_FEEDBACK_LOG.md`. |
| `AI_BUDGET_CALCULATOR_DESIGN.md` | active | P1-P4 implemented, P5-P7 pending; current CLI is `tools/envelope-calc`. |
| `AI_REVIEW_BQN_EVAL_TASK.md` | parked | Review request for devtool work; not a standing TODO by itself. |
| `AI_WORKING_FEEDBACK_LOG.md` | active | Intake log for pit workflow/tooling observations. |
| `PLAN_TEMPORAL_STATUS_PROJECTION_PLAN-2026-07-05.md` | historical | First extraction slice implemented by PR #64. Keep for rationale; current follow-up is `PLAN_TEMPORAL_EXECUTION_COVERAGE_JOIN-2026-07-06.md`. |
| `PLAN_TEMPORAL_EXECUTION_COVERAGE_JOIN-2026-07-06.md` | active | Selected from current TODO. Adopts one aggregate-only temporal execution coverage snapshot, rejects per-plan funded claims without stronger linking semantics, and identifies duplicated open-plan ownership as the first seam to reduce. |
| `SUBPROCESS_DEBUG_VISIBILITY_PLAN-2026-07-05.md` | historical | Implemented by PR #61 and closed as `resolved` for the selected slice. Review / Learning record: `../completed-plans/SUBPROCESS_DEBUG_VISIBILITY_REVIEW-2026-07-05.md`. Do not treat the old plan as authorization for broad subprocess migration. |
| `CONFIG_RESOLUTION_SEMANTICS_PLAN-2026-07-05.md` | historical | A4 parent plan. Superseded as active instruction by the completion decision; retain for background. |
| `CONFIG_KEY_CLASSIFICATION_DECISION-2026-07-05.md` | historical | A4 Phase 0 decision. Key classes and quarantines remain useful background, but A4 is closed. |
| `CONFIG_TYPED_POLICY_CHECKPOINT-2026-07-05.md` | historical | A4 checkpoint after two typed policy keys; no longer a current next-step instruction. |
| `POLICY_INCOME_CADENCE_OWNERSHIP_INVESTIGATION-2026-07-05.md` | historical | A4 ownership investigation retained as evidence. |
| `POLICY_INCOME_CADENCE_OWNERSHIP_DECISION-2026-07-05.md` | historical | A4 evidence decision; `POLICY_INCOME_CADENCE` remains dormant with runtime work frozen. |
| `CONFIG_EFFECTIVE_RESOLUTION_ENTRY_CHECKPOINT-2026-07-05.md` | historical | A4 phase-alignment checkpoint retained for background. |
| `CONFIG_MINIMAL_EFFECTIVE_DEFAULTABLE_SLICE_PROPOSAL-2026-07-05.md` | historical | Proposal implemented by the first two-key effective sparse-override runtime slice. |
| `CONFIG_EFFECTIVE_RESOLUTION_RUNTIME_CHECKPOINT-2026-07-05.md` | historical | Post-PR #55 checkpoint that paused automatic expansion and prepared A4 closure. |
| `CONFIG_RESOLUTION_A4_COMPLETION_DECISION-2026-07-05.md` | historical | Final A4 decision: complete enough for now; remaining config concerns must re-enter as independent concrete work. |
| `GOLDEN_ASSERTION_OWNERSHIP_PLAN-2026-07-04.md` | historical | Completed first AI feedback process trial for A5. Result `resolved`; PR #40 removed duplicate exact machine-summary assertions while preserving negative/human checks. |
| `AUDIT_IMPROVEMENT_BACKLOG-2026-06-30.md` | active | Historical-dated copy of audit backlog; top-level current pointer is `docs/AUDIT_IMPROVEMENT_BACKLOG.md`. |
| `BASH_SAFETY_ANALYSIS.md` | historical | First pass implemented; remaining shell safety work should be promoted through TODO/check-specific docs. |
| `../completed-plans/COMMAND_HUB_DESIGN.md` | historical | Moved to completed plans. Implemented as `tools/bl`; current UI entry docs are `docs/README.md`, `docs/ADD_UI_USAGE.md`, and tool help. |
| `DEBUG_PROVENANCE_DESIGN.md` | parked | Proposed design; old-engine references are historical. |
| `DECISION_TERMINAL_COLOR_CONFIG.md` | active | Current decision note for terminal color/styling boundary. |
| `EDIT_BQN_HANDOFF.md` | historical | Stale handoff from Go-to-BQN editor migration; current editor docs are `docs/PRODUCTION_EDITOR_DIRECTION.md` and `docs/BQN_EDITOR_USAGE.md`. |
| `ENVELOPE_TARGET_POLICY_SKETCH.md` | parked | Sketch only; not implemented. |
| `FINTECH_ENGINEERING_REVIEW_BACKLOG-2026-07-01.md` | active | Pointer/triage companion for `docs/FINTECH_ENGINEERING_REVIEW_BACKLOG.md`. |
| `GO_BQN_GAP_ALIGNMENT_PLAN.md` | historical | Superseded historical draft. Current write path is BQN+shell editor. |
| `GO_EDITOR_NEXT_PLAN.md` | historical | Superseded by `docs/PRODUCTION_EDITOR_DIRECTION.md` and `docs/BQN_EDITOR_USAGE.md`. |
| `GUM_FZF_COLOR_LAYER_PLAN.md` | active | Phase 1 implemented as `tools/bl`; Phase 2 remains possible. |
| `HOUSEHOLD_POLICY_LAYER_PLAN.md` | active | Active policy-layer boundary design. |
| `../completed-plans/ISSUE_TRACKER_PLAN.md` | historical | Moved to completed plans. Current implementation is `issues.tsv`, `src_next/issues.bqn`, and editor/report docs. |
| `LEDGER_ENGINE_IDEA_CATALOG.md` | parked | Idea catalog, not an implementation plan. |
| `LEGACY_FINISH_GO_RETIREMENT_PLAN.md` | historical | Old-engine/legacy retirement note; current editor direction supersedes it. |
| `QUERY_CONTEXT_TRACK.md` | parked | Planning note only; no implementation approved. |
| `REPORT_DESIGN.md` | historical | Superseded by `docs/SRC_NEXT_CURRENT.md` and `docs/ARCHITECTURE.md`. |
| `REPORT_POLICY_EXTERNALIZATION_PLAN.md` | parked | Design track; old-engine references are historical, current externalization work must be sliced through TODO. |
| `REPORT_SECTION_STATUS_POLICY.md` | active | Current policy / partial `src_next` implementation. |
| `SEAM_REDUCTION_PLAN.md` | active | Partially implemented seam-reduction principle; current invariants are also in `AGENTS.md`. |
| `SHELL_MEANING_INVENTORY-2026-07-01.md` | active | Active/done inventory for shell meaning reduction; use with structured UI export work. |
| `STRUCTURED_UI_EXPORT_CONTRACT-2026-07-01.md` | active | Active plan companion for `docs/STRUCTURED_UI_EXPORT_CONTRACT.md`. |
| `WIDE_REPORT_PAGER_PLAN.md` | parked | Planned/docs-only UI display idea. |

## Cleanup candidates

Do not delete or move these blindly; first update inbound references and keep a short stub if needed.

1. Move remaining clearly completed/historical files to `docs/archive/completed-plans/` in small batches:
   - `BASH_SAFETY_ANALYSIS.md`
2. Replace stale handoffs with stubs or completed-plan records:
   - `EDIT_BQN_HANDOFF.md`
   - `GO_BQN_GAP_ALIGNMENT_PLAN.md`
   - `GO_EDITOR_NEXT_PLAN.md`
   - `LEGACY_FINISH_GO_RETIREMENT_PLAN.md`
   - `REPORT_DESIGN.md`
3. Keep parked idea catalogs in place until a TODO slice explicitly adopts or rejects them.

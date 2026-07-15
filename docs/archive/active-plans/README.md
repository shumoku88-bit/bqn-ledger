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
| `parked` | Idea/sketch with no current authorization | Do not implement directly; first promote a small docs-only slice to `TODO.md` |
| `historical` | Implemented, superseded, or stale handoff/decision | Read only for background; do not use as current instruction |

## Inventory

| File | Class | Current reading path / note |
|---|---|---|
| `../completed-plans/ACTUAL_COMPARISON_REPORT_PLAN.md` | historical | Moved to completed plans. Implemented decision record for `actual-comparison`; current report entry is `docs/REPORT_CONTRACTS.md` plus `src_next/` checks. |
| `AI_AGENT_EFFICIENCY_PLAN.md` | parked | AI efficiency ideas; use only when doing dev-experience work with `AI_WORKING_FEEDBACK_LOG.md`. |
| `AI_BUDGET_CALCULATOR_DESIGN.md` | active | P1-P4 implemented, P5-P7 pending; current CLI is `tools/envelope-calc`. |
| `../completed-plans/AI_DIFF_SELF_REVIEW_PILOT_PLAN-2026-07-10.md` | historical | Completed after 3 comparable slices. Review / Learning retains the small `AGENTS.md` actual-diff rule without lint, telemetry, a tracker, a parser, a permanent form, or statistical/token-efficiency claims. |
| `AI_REVIEW_BQN_EVAL_TASK.md` | parked | Review request for devtool work; not a standing TODO by itself. |
| `AI_WORKING_FEEDBACK_LOG.md` | active | Intake log for pit workflow/tooling observations. Feedback remains evidence and never auto-authorizes TODO work. |
| `CONFIGURABLE_AI_ASSISTED_LEDGER_FOUNDATION-2026-07-13.md` | active routing map | Selected highest-priority development direction and completed docs-only synthesis map. PR #219 currency-policy integration and the config ownership inventory are complete; the privacy-safe AI context-bundle contract is the next routed candidate but remains unselected; PR #211 Observatory stays last. Only finite work explicitly selected in `TODO.md` is authorized. |
| `../completed-plans/CONFIG_POLICY_CONTINUATION_HANDOFF-2026-07-14.md` | historical | Completed temporary handoff. Its `POLICY_RISK_STYLE` discussion is resolved by `../completed-plans/POLICY_RISK_STYLE_DAILY_CAPACITY_DECISION-2026-07-15.md`; it authorizes no runtime or migration work. |
| `../completed-plans/POLICY_RISK_STYLE_DAILY_CAPACITY_DECISION-2026-07-15.md` | historical | Completed docs-only decision: replace the durable risk-style concept with owner-selected asset scope, obligation scope, and horizon; current `simple`, `conservative`, and fallback behavior remain compatibility-only until separate audit and migration slices are selected. |
| `../audits/DAILY_CAPACITY_CURRENT_CONSUMER_INPUT_EVIDENCE_AUDIT-2026-07-15.md` | historical audit | Completed current-main audit: Outlook is the one direct behavioral consumer found, the current switch controls secondary `liq_safe_daily`, and owner asset admission, obligation admission, and per-obligation reservation provenance remain unresolved. The minimal input/result contract is only an unselected next candidate. |
| `../completed-plans/CONFIG_OWNERSHIP_INVENTORY-2026-07-14.md` | historical | Completed docs-only ownership map separating source meaning, ledger policy, engine admission, view preference, runtime bootstrap, export policy, fixed contracts, and quarantined ownership. It adds no key or runtime and leaves the privacy-safe context-bundle contract unselected. |
| `../completed-plans/PERSONAL_HARDCODE_INVENTORY-2026-07-14.md` | historical | Completed docs-only classification of user/profile literals, fixed contracts, quarantined compatibility behavior, and fixture-only values. It recommends the remaining Outlook presentation-literal extraction as the smallest next candidate but selects no runtime work. |
| `../completed-plans/POLICY_BUDGET_STYLE_EXPLICIT_CHOICE_DECISION-2026-07-14.md` | historical | Completed policy decision: envelope budgeting is optional and reversible, new ledgers must explicitly choose `envelope` or `none`, and the current missing-key `envelope` fallback is only a temporary compatibility bridge. The later fail-closed runtime migration remains unselected. |
| `../completed-plans/AI_WORKING_IMPROVEMENT_PLAN-2026-07-09.md` | historical | Completed Review / Learning as `mitigated` after PR #135. `docs/CONVENTIONS.md` remains the single BQN pitfalls owner; broader tutorial, lint, and devtool work are not authorized. |
| `PLAN_TEMPORAL_STATUS_PROJECTION_PLAN-2026-07-05.md` | historical | First extraction slice implemented by PR #64. Keep for rationale; current follow-up is `PLAN_TEMPORAL_EXECUTION_COVERAGE_JOIN-2026-07-06.md`. |
| `PLAN_TEMPORAL_EXECUTION_COVERAGE_JOIN-2026-07-06.md` | active | Aggregate-only follow-up remains active. Slice A seam reduction was implemented by PR #70. Before Slice B, use `../audits/TEMPORAL_SEMANTICS_OBSERVATION-2026-07-06.md` and `../audits/TEMPORAL_SEMANTICS_CLASSIFICATION-2026-07-06.md`; next finite step is characterization of envelope source-order and outlook historical-cycle clock behavior. |
| `PLAN_COMPLETION_WORKFLOW_DESIGN_INTAKE-2026-07-08.md` | active | The concrete execution-envelope linkage evidence is resolved by `../completed-plans/ENVELOPE_EVENT_LINKAGE_AUTOMATION_PLAN-2026-07-14.md`; other workflow questions remain on observation hold. |
| `../completed-plans/ENVELOPE_EVENT_LINKAGE_AUTOMATION_PLAN-2026-07-14.md` | historical | Completed confirmation-gated `plan_id` linkage, idempotent retry, and pending recovery path. |
| `../completed-plans/INCOME_BUDGET_LINKAGE_COMPLETION-2026-07-14.md` | historical | Completed explicit ordinary-income intent, stable `txn_id`, unassigned companion, exclusion, and retry path. |
| `CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md` | active backlog | M1 through M3 are implemented and separately verified. Strict-source Step 1 is completed separately; M4 remains an independent candidate and is not automatically authorized. |
| `STRICT_PRODUCTION_SOURCE_CURRENCY_ENFORCEMENT_DECISION-2026-07-13.md` | active plan | Step 1 policy-carrier/pure-admission core is completed by PR #207. Steps 2–5 remain unselected; writer closure, compatibility preparation, production activation, and M4 do not auto-start. |
| `FRIEND_TRAVEL_SOURCE_EVENT_JPY_FINALIZATION_PLAN-2026-07-13.md` | active | Canonical consumer semantics. Its pure one-row JPY preview is implemented and verified; pending storage, safe append, status/index mutation, and journal writer remain unselected. The atomic writer is parked as Israel travel candidate 6. |
| `FRIEND_TRAVEL_ATOMIC_FINALIZATION_WRITE_DESIGN-2026-07-13.md` | parked | Future candidate 6 recovery proposal preserving the possible event store, derived index, manifest, backup, stale-check, rollback, and retry design from PR #213. It selects no synthetic or production runtime implementation. |
| `../completed-plans/ISRAEL_TRAVEL_DAILY_CAPTURE_PLAN-2026-07-13.md` | historical | Completed by PR #215 as the docs-only decision record for the four Israel operational rails. Read it for semantic background; implementation completion is recorded in `../completed-plans/ISRAEL_PREDEPARTURE_EDITOR_CAPTURE_COMPLETION-2026-07-13.md`. |
| `../completed-plans/ISRAEL_PREDEPARTURE_EDITOR_CAPTURE_COMPLETION-2026-07-13.md` | historical | Completed four-path editor capture, mixed-safe journal lint recovery, and integrated synthetic rehearsal record. Candidate 6, router, cash view, finalization, strict-source Steps 2–5, and M4 remain unselected. |
| `LEDGER_OBSERVATORY_LONG_TERM_PLAN-2026-07-13.md` | active long-term plan | Connects evidence trace, ephemeral scenarios, Cube Theatre, fixture-based BQN kata, later projection-helper extraction, and AI-work observation. It selects no runtime work; the next eligible finite design candidate is a pure synthetic source-row-to-Cube trace contract. |
| `FRIEND_FOREIGN_LIABILITY_JPY_SETTLEMENT_PLAN-2026-07-13.md` | historical | Rejected alternative: FCY liability plus two-row clearing settlement. Follow the source-event finalization plan instead; it authorizes no work. |
| `TRAVEL_MULTI_CURRENCY_SETTLEMENT_DESIGN_INTAKE-2026-07-12.md` | parked | Broad 1–2 month travel-living intake. The completed Israel operating choice routes to `../completed-plans/ISRAEL_TRAVEL_DAILY_CAPTURE_PLAN-2026-07-13.md`, while friend finalization details route to `FRIEND_TRAVEL_SOURCE_EVENT_JPY_FINALIZATION_PLAN-2026-07-13.md`; other travel rails remain parked. |
| `../completed-plans/CURRENCY_STAGE2_B2_ARITHMETIC_OWNERSHIP_RECHECK-2026-07-11.md` | historical | Completed docs-only decision selected Outcome B: `src_next/currency_arithmetic.bqn` owns pure B2 snapshot arithmetic while `context.bqn` remains the orchestrator. Current runtime route is in `TODO.md` and the canonical split decision. |
| `../completed-plans/PREFIX_FALLBACK_PRODUCT_SELECTION_REMOVAL_PLAN-2026-07-11.md` | historical | Completed by PR #151 and verified by `../audits/PREFIX_FALLBACK_PRODUCT_SELECTION_POST_IMPLEMENTATION_VERIFICATION-2026-07-11.md`; current finite routing returns to Currency Stage 2 B2. |
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
| `REPORT_PROJECTION_ALIGNMENT_PLAN-2026-07-15.md` | active plan | Selected, gated report numeric-owner alignment sequence. It preserves `Day × Account × Layer` and source-evidence boundaries; only a separately selected finite slice may change runtime behavior. |
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

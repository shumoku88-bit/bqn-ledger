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
| `../completed-plans/AI_DIFF_SELF_REVIEW_PILOT_PLAN-2026-07-10.md` | historical | Completed after 3 comparable slices. Review / Learning retains the small `AGENTS.md` actual-diff rule without lint, telemetry, a tracker, a parser, a permanent form, or statistical/token-efficiency claims. |
| `AI_REVIEW_BQN_EVAL_TASK.md` | parked | Review request for devtool work; not a standing TODO by itself. |
| `AI_WORKING_FEEDBACK_LOG.md` | active | Intake log for pit workflow/tooling observations. Feedback remains evidence and never auto-authorizes TODO work. |
| `CONFIGURABLE_AI_ASSISTED_LEDGER_FOUNDATION-2026-07-13.md` | active routing map | Selected highest-priority development direction and completed docs-only synthesis map. PR #219 currency-policy integration and the config ownership inventory are complete; the privacy-safe AI context-bundle contract is the next routed candidate but remains unselected; PR #211 Observatory stays last. Only finite work explicitly selected in `TODO.md` is authorized. |
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

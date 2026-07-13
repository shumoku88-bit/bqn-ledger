# Unreferenced Docs Routing Audit

Status: audit snapshot
Owner: docs
Canonical: no; canonical routing remains `docs/README.md`
Exit: keep as point-in-time evidence; consume findings through separate finite routing or archive PRs

Date: 2026-07-14

## Purpose

This audit replaces the unverified TODO list proposed in PR #230.

A Markdown file that is absent from `docs/README.md` is not automatically dead or ready to archive. It may be:

- already routed from the top-level `README.md`;
- a current canonical document whose route is missing;
- a current auxiliary implementation note;
- an implemented decision record waiting for synchronization and retirement;
- a pre-runtime decision that still carries unresolved meaning;
- a local workspace index that does not need top-level routing;
- an experiment or historical note whose lifecycle status is unclear.

This document records current evidence before any bulk move. It does not authorize runtime work, semantic changes, or automatic archive operations.

## Classification rules

| Classification | Meaning | Normal next action |
|---|---|---|
| `route-current` | Explicit current/canonical meaning exists, but the docs router does not expose it | Add one narrow route in `docs/README.md` |
| `route-auxiliary` | Useful current implementation detail under an existing canonical owner | Link from the relevant topic without making it a second canonical owner |
| `already-routed` | Reachable from another intentional current entry point | Do not classify as orphaned merely because `docs/README.md` lacks a direct link |
| `review-cluster` | Several decisions share one product/temporal question | Review ownership and exit conditions together before moving files |
| `lifecycle-needed` | Content may still be useful, but current/historical/experimental ownership is unclear | Add or revise lifecycle metadata before routing or archive |
| `local-index` | README for a subdirectory workspace or catalog | Route only when the workspace is an active current path |

## Verified findings

### Editor and dependency documents

| Document | Evidence | Classification | Proposed next action |
|---|---|---|---|
| `docs/PRODUCTION_EDITOR_DIRECTION.md` | Declares `Status: current policy / architecture direction`, `Owner: editor`, and `Canonical: yes`; records the current `tools/edit` → `tools/edit-bqn` → `src_edit` ownership | `route-current` | Add to the editor/current-write-path route in `docs/README.md` |
| `docs/THIRD_PARTY_DEPENDENCIES.md` | Declares a current canonical dependency inventory; it is already linked from the top-level README design section | `already-routed` plus possible `route-current` | Keep the root route; add a maintenance/dependency route in `docs/README.md` only if that improves discovery |
| `docs/EDIT_BQN_DISPATCHER.md` | Declares a current implementation note and describes the thin dispatcher boundary behind the canonical editor path | `route-auxiliary` | Link beneath `PRODUCTION_EDITOR_DIRECTION.md` or `BQN_EDITOR_USAGE.md`; do not promote it to a competing canonical editor owner |

These three documents should be handled in one small routing PR. No file move is needed.

### Daily Trend decision cluster

| Document | Current evidence | Classification |
|---|---|---|
| `docs/DAILY_TREND_OBSERVATION_CONSISTENCY_DECISION.md` | Current pre-runtime temporal property; non-canonical; exit depends on a future explicit temporal contract/runtime consumer | `review-cluster` |
| `docs/DAILY_TREND_KNOWLEDGE_BOUNDARY_DECISION.md` | Current pre-runtime meaning correction; still points at the temporal semantics chain | `review-cluster` |
| `docs/DAILY_TREND_ROW_MEMBERSHIP_PRODUCER_DECISION.md` | Current implemented product decision; auxiliary to the selected product and dependency map | `review-cluster` |
| `docs/DAILY_TREND_HEADER_TIME_OWNER_DECISION.md` | Current implemented product decision; exit text still anticipates implementation/review | `review-cluster` |
| `docs/DAILY_TREND_EXPLICIT_EMPTY_PLAN_IDENTITY_MEANING_DECISION.md` | Implemented repo-wide decision; its own exit says to archive after docs synchronization | `review-cluster`, likely first retirement candidate |

Do not bulk archive this cluster. First compare each exit condition with the current routed Daily Trend path in `docs/README.md`, then choose one of:

1. route as a small auxiliary chain;
2. replace with one compact current map and archive completed leaves;
3. revise stale exit/status text where runtime already consumed the decision.

The explicit-empty-plan-identity decision is the strongest initial archive candidate, but only after confirming no current contract relies on it as the sole explanation.

### Outlook decision cluster

| Document | Current evidence | Classification |
|---|---|---|
| `docs/OUTLOOK_PRODUCTION_OBSERVATION_SOURCE_DECISION.md` | Current pre-wiring source contract | `review-cluster` |
| `docs/OUTLOOK_RECORD_FRONTIER_RELATION_DECISION.md` | Current pre-runtime freshness relation | `review-cluster` |
| `docs/OUTLOOK_OBSERVATION_TRANSPORT_BOUNDARY.md` | Current pre-runtime transport boundary | `review-cluster` |
| `docs/OUTLOOK_HOUSEHOLD_QUESTION_DECISION.md` | Current pre-runtime consumer question | `review-cluster` |

These documents form one semantic chain: household question → observation transport → record frontier relation → production observation source. They should not be exposed as four unrelated top-level routes. A follow-up audit should determine whether one current Outlook index/contract can own the chain and whether any leaves have already been consumed by runtime.

### Experiments, demos, and public presentation material

| Document | Current evidence | Classification | Proposed next action |
|---|---|---|---|
| `docs/ASCII_GARDEN_REPORT.md` | Explicitly experimental, but lacks full lifecycle owner/canonical/exit metadata | `lifecycle-needed` | Decide parked experiment versus active read-only projection work before routing |
| `docs/FIXTURE_DEMO.md` | Public demo walkthrough with no lifecycle header; uses `fixtures/src-next-golden` while the top-level quick start now uses `fixtures/demo` | `lifecycle-needed` | Compare with current quick start; revise as current auxiliary or archive as an older demo path |
| `docs/REPORT_MOCK_SANITIZATION.md` | Contract-like privacy rules for public report mocks, but no lifecycle header | `lifecycle-needed` | Verify whether `mocks/reports/` remains active, then mark current policy or historical |
| `docs/CBQN_REPRODUCIBILITY.md` | Current-policy content and a direct relationship with `THIRD_PARTY_DEPENDENCIES.md`, but no lifecycle header | `route-auxiliary` plus `lifecycle-needed` | Add lifecycle metadata and link from the dependency inventory rather than making a separate broad route |
| `docs/WHY_SHARE.md` | Already linked from the top-level README | `already-routed` | No orphan cleanup needed; improve lifecycle metadata only when substantively editing it |

### Subdirectory indexes

| Document | Current evidence | Classification | Proposed next action |
|---|---|---|---|
| `docs/report-mocks/README.md` | Local mock review workspace with an adopt/revise/reject workflow | `local-index` | Route from `docs/README.md` only if report-mock review is an active current workflow |
| `docs/variable-catalog/README.md` | Auxiliary catalog for reading short BQN names; points to a small existing catalog entry and asks future additions | `local-index` plus `lifecycle-needed` | Check whether the referenced source area remains current; otherwise mark historical rather than creating a permanent top-level route |

## Findings about PR #230

PR #230 should not be merged as written because:

1. it treats absence from `docs/README.md` as equivalent to being unreferenced;
2. it includes documents already routed from the top-level README;
3. it assigns current/archive destinations before reading lifecycle headers and exit conditions;
4. it places a large unresolved inventory directly into `TODO.md`, increasing the active reading burden;
5. it groups current contracts, implemented decisions, pre-runtime decisions, experiments, and local indexes under one action.

The PR was closed without merge and replaced by this evidence-first audit.

## Recommended finite sequence

1. **Editor and dependency routing**
   - route `PRODUCTION_EDITOR_DIRECTION.md` as the current editor architecture/policy;
   - route `EDIT_BQN_DISPATCHER.md` as auxiliary implementation detail;
   - ensure `THIRD_PARTY_DEPENDENCIES.md` and `CBQN_REPRODUCIBILITY.md` have one clear dependency ownership chain.

2. **Daily Trend and Outlook ownership audit**
   - compare lifecycle exits with current runtime and routed contracts;
   - create one compact route per semantic chain;
   - archive only decisions whose meaning is fully consumed elsewhere.

3. **Experiment and workspace classification**
   - classify ASCII garden, fixture demo, report mock material, report-mocks workspace, and variable catalog as current auxiliary, parked, or historical;
   - avoid routing inactive workspaces merely to make link counts look complete.

4. **`AGENTS.md` refresh**
   - perform only after the current routes above are settled;
   - replace stale task routes with the smallest current paths;
   - do not add every decision record to the AI's mandatory reading list.

## Non-goals

- no runtime, source TSV, schema, fixture, editor, report, or configuration changes;
- no broad docs rewrite;
- no automatic deletion;
- no bulk archive move;
- no new permanent checker based solely on incoming-link counts;
- no change to current feature priorities in `TODO.md`.

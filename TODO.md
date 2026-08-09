# BQN review queue

## Purpose

Turn bqn-ledger into a place where household accounting is expressed through beautiful, compact, and instructive BQN architecture and algorithms.

The Haskell project provides an independent implementation path and reduces the need to preserve incidental report machinery here. This repository should still preserve admitted meaning, exact arithmetic, diagnostics, identity, provenance, and safe effects, but its pure kernels should actively teach array-language thinking.

The canonical Household source and configuration migration is now the foundation rather than the next architecture campaign. Its remaining retirement and closeout work is tracked separately; it must not displace this queue or reintroduce legacy source shapes into reviewed kernels.

## Long-term outcome

The main development line is now simplification of the retained BQN system:

```text
strict source and request admission
  -> bounded whole-array accounting kernel
  -> semantic result and provenance
  -> selector-independent command/UI boundary
```

The desired result is less production machinery, fewer repeated scans and incidental row representations, shallower successful paths, and more direct use of BQN classification, grouping, rank, cells, structural transformation, and composition. Compactness is accepted only when exactness, diagnostics, canonical ordering, evidence alignment, safe effects, and public behavior remain explicit.

Terminal UI implementation is replaceable. `fzf`, `gum`, and the current plain selector are adapters, not architecture owners; a later UI may replace any of them. Refactoring before the UI phase must therefore preserve structured command/result boundaries and must not move accounting meaning, source mutation, report keys, or policy into selector-specific shell code. UI implementation may move with the architectural concern that requires it; phase order does not force an incomplete intermediate design.

## Repository-resident continuation contract

The repository is the authority for review state. Chat history, handoff prompts, local recollection, and remembered SHAs are conveniences only; none of them define the current continuation point.

A fresh review session must be able to recover the current state from the repository alone. Start by:

1. verifying remote `main`, open PRs/branches relevant to the active owners, and current CI instead of assuming a remembered state;
2. reading this queue, especially the current cursor, unchecked inventory, and any recorded cross-cutting work;
3. reading the active architecture observation and decision records that explain unresolved evidence and accepted constraints;
4. checking whether parallel work changed the active owner, its direct consumers, or protected invariants;
5. resuming from the first unresolved review item unless a recorded cursor exception applies;
6. before ending a review session, recording durable observations, accepted decisions, merged outcomes, and the resulting cursor in the repository rather than relying on a future handoff prompt.

PR descriptions may explain one coherent change, but they are not the sole continuity store. Historical handoff documents are not required for ordinary continuation; Git history is the archive. A checked queue item must still mean that its final decision is present on current `main` and can be reconstructed from current repository evidence.

### Subtraction audit dimensions

Each owner or coherent owner family is reviewed against the dimensions that actually apply. The purpose is not to manufacture refactors, but to distinguish protected complexity from removable machinery.

- ownership duplication: the same semantic decision or transformation owned in more than one place;
- structural plumbing: adapters, rows, stages, or forwarding surfaces that add no retained meaning;
- repeated effect lifetime: canonical evidence, admission, processes, or other effects repeated where one capability lifetime would suffice;
- obsolete migration residue: compatibility or migration surfaces whose live contract has ended;
- change locality: one behavioral change requiring edits across unrelated owners;
- array visibility: semantic axes, masks, classification, Group/Pivot/Rank/Cells, and exact reductions remaining visible as BQN transformations;
- validation/kernel/publication separation: capability admission or diagnostic control flow obscuring an otherwise bounded whole-array kernel;
- dead surface and reachability: production, documented public, qualification, or evidence consumers no longer reaching a retained surface;
- generic abstraction debt: abstractions whose maintenance burden exceeds the domain meaning they preserve;
- guard quality: checks protecting semantic, lifetime, authority, or safety laws rather than incidental implementation topology.

Validation density or file size is not, by itself, a defect. Exact-operation failure checks stay at the operation that can fail; public diagnostic ownership and successful-path visibility are reviewed separately.

### Cross-cutting audit inventory

These items complement the file-by-file phase inventory. They are checked only after their consumer graph, protected laws, and final repository decision have been reviewed on current `main`.

- [ ] terminal selector/input duplication and UI change locality across active shell surfaces;
- [ ] editor/writer ownership from BQN semantic decision through machine operation to safe-write publication;
- [ ] report/application CLI reachability and repeated effect/protocol boundaries beyond the resolved multi-report lifetime;
- [ ] repository-wide dead-surface and reachability audit, including retained wrappers, `experiments/`, and `tui/`;
- [ ] validation/kernel/publication separation across retained accounting and adjacent semantic owners;
- [ ] remaining migration/compatibility residue classified without duplicating the canonical Household recovery closeout tracked separately;
- [ ] checks and tests classified as law guards, characterization evidence, or obsolete topology assumptions.

## Review method

Use the top-to-bottom owner order as the normal place to resume review. The cursor identifies where to look next; it does not constrain one PR to one file, one owner, or one layer.

Starting from the current owner:

1. read the whole owner, its direct imports, focused tests, and direct consumers;
2. state input/output shapes, semantic axes, order, fill/empty behavior, exactness, and evidence alignment;
3. ask whether loops, repeated masks, row namespaces, mutable append, single-use names, staged plumbing, repeated admissions, and unnecessary process/effect boundaries can become a clearer classification, Group, Rank, Cells, Table, structural transform, composition, or shared admitted observation;
4. apply the subtraction audit dimensions above and distinguish protected complexity from removable responsibility;
5. preserve names where they carry accounting meaning or protect admission, diagnostics, exact arithmetic, identity, provenance, publication, effects, or write authority;
6. identify the complete architectural end-state implied by the reason-to-change and move every necessary owner, caller, consumer, test, adapter, and document together when that produces the clearer design;
7. avoid temporary adapters, duplicate paths, compatibility shims, or intermediate abstractions whose only justification is keeping a PR small;
8. either merge the coherent completed change or record why the current architecture is already the clearer form;
9. check reviewed queue items only after the relevant decision is merged to current `main` and the final owners are reread there.

Change boundaries are defined by **one reason-to-change and one coherent end-state**, not by file count, owner count, layer count, line count, or a preferred PR size. Unrelated changes remain separate, but related changes must not be artificially fragmented merely to produce small slices.

The negotiated rationale is recorded in `docs/POST_MIGRATION_ARCHITECTURE_DECISIONS-2026-08-09.md`.

### Cursor policy

The cursor is a default navigation sequence, not an absolute prohibition or PR-size policy. A concrete user-facing defect, measured performance problem, correctness risk, or clearly demonstrated cross-owner architectural defect may move work outside the current owner. Such a change must have one explicit reason-to-change and completion condition, preserve protected invariants and writer authority, and record why the normal sequence was bypassed. It may be as broad across owners and layers as the coherent end-state requires, while excluding unrelated work.

After the change closes, review resumes from the remembered cursor unless the architecture itself changed enough to require updating the queue.

Checkbox meaning:

- `[ ]` not yet finally reviewed under the dense-array-kernel policy;
- `[x]` reviewed on current `main`, with the final decision recorded beside the path.

## Phase order

The phases are an inventory and review-navigation order, not mandatory PR boundaries. A coherent architectural change may cross them when its reason-to-change genuinely does.

1. `src/accounting/` pure accounting kernels
2. `src/ledger/` admission, Facts, exact values, identity, and provenance
3. `src/sections/` semantic result owners
4. `src/report/` catalog, request, composition, and rendering
5. `src/application/` adapters, profiles, and effect boundaries
6. `src/editor/` and `src_edit/` rewrite and command owners
7. remaining production BQN under `src/text/` and `tools/`, followed by selector/UI adapter consolidation

Before a phase becomes the active inventory focus, its complete file inventory must be added here and covered by the queue check. A phase is considered reviewed only when every listed box is checked and the inventory check still passes. This bookkeeping does not require implementation changes to be split at phase boundaries.

## Phase 1: `src/accounting/`

- [x] `src/accounting/account_balance.bqn` — PR #517 grouped the selected Posting axis onto the canonical Account axis; reread on main `a318b4c49fe4b37cd49e61850a17f8d196184a0f`.
- [x] `src/accounting/account_period.bqn` — PR #519 exposed the selected Posting axis as an Account × period-lane Group kernel; reread on main `5619cb24bcaa57202135bc8a40d49b0827c98648`.
- [x] `src/accounting/balance_sheet.bqn` — PR #521 classified canonical Account rows once into Balance Sheet statement lanes, grouping signed balances and durable Posting evidence in parallel; reread on main `f10ab4db29e9b89bae014d89310497db58162855`.
- [x] `src/accounting/cycle_account_period.bqn` — PR #523 mapped Account × contributor-lane Posting-index cells to durable Posting references and joined opening plus observed-period evidence by aligned Account cells; reread on main `0ef1ed2492de051896e08890e65bb4361deb1b15`.
- [x] `src/accounting/cycle_calendar_month_resolution.bqn` — PR #525 derived start and end-exclusive as one adjacent calendar boundary axis; reread on main `29c161e3853ca9bc5b69dbb5f77501f03c060ca3`.
- [x] `src/accounting/cycle_comparison.bqn` — PR #529 simplified comparison window mapping; reread on main `2b587913d24428c9465a2790660b9a449002d8e0`.
- [x] `src/accounting/cycle_fixed_resolution.bqn` — PR #531 replaced 3-level nested repeat blocks with flat early guard pattern; reread on main `9c386937f959727c223534642e7792d2ccb3aee9`.
- [x] `src/accounting/cycle_income_anchor_resolution.bqn` — PR #533 simplified Deduplicate and IndexOf helpers; reread on main `6a0e12d785cb1ef397173993322af298b22091c1`.
- [x] `src/accounting/cycle_result.bqn` — PR #548 simplified ordinal resolution with dyadic Each; reread on main `ae9049d`.
- [x] `src/accounting/daily_target.bqn` — PR #549 simplified helper functions and duplicate validation; reread on main `7aed0a6`.
- [ ] `src/accounting/date_category_flow.bqn`
- [ ] `src/accounting/envelope_backing.bqn`
- [ ] `src/accounting/fact_reference.bqn`
- [ ] `src/accounting/matrix_result.bqn`
- [ ] `src/accounting/month_account_movement.bqn`
- [ ] `src/accounting/month_category_flow.bqn`
- [ ] `src/accounting/plan_completion_join.bqn`
- [ ] `src/accounting/plan_temporal_status.bqn`
- [ ] `src/accounting/profit_and_loss.bqn`
- [ ] `src/accounting/recent_transactions.bqn`
- [ ] `src/accounting/sparse_group.bqn`
- [ ] `src/accounting/sparse_pivot.bqn`

## Current cursor

`src/accounting/date_category_flow.bqn`

This remains the normal place to resume review. It does not limit the scope of a coherent architectural change discovered from that review.

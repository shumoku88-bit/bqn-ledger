# BQN review queue

## Purpose

Turn bqn-ledger into a place where household accounting is expressed through beautiful, compact, and instructive BQN architecture and algorithms.

The Haskell project provides an independent implementation path and reduces the need to preserve incidental report machinery here. This repository should still preserve admitted meaning, exact arithmetic, diagnostics, identity, provenance, and safe effects, but its pure kernels should actively teach array-language thinking.

## Review method

Work strictly from top to bottom, one owner at a time.

For each file:

1. read the whole owner, its direct imports, focused tests, and direct consumers;
2. state input/output shapes, semantic axes, order, fill/empty behavior, exactness, and evidence alignment;
3. ask whether loops, repeated masks, row namespaces, mutable append, single-use names, and staged plumbing can become classification, Group, Rank, Cells, Table, structural transforms, trains, or modifier composition;
4. preserve names only where they carry accounting meaning or protect admission, diagnostics, exact arithmetic, identity, provenance, publication, effects, or write authority;
5. either merge a coherent simplification slice or record why the current expression is already the clearest BQN form;
6. check the item only after the decision is merged to current `main` and the final file is reread there.

A file may require moving all of its consumers in the same coherent PR. The queue nevertheless advances by the owning file, not by arbitrary batches. Do not skip forward because a later file looks easier.

Checkbox meaning:

- `[ ]` not yet finally reviewed under the dense-array-kernel policy;
- `[x]` reviewed on current `main`, with the final decision recorded beside the path.

## Phase order

1. `src/accounting/` pure accounting kernels
2. `src/ledger/` admission, Facts, exact values, identity, and provenance
3. `src/sections/` semantic result owners
4. `src/report/` catalog, request, composition, and rendering
5. `src/application/` adapters, profiles, and effect boundaries
6. `src/editor/` and `src_edit/` rewrite and command owners
7. remaining production BQN under `src/text/` and `tools/`

Before a phase begins, its complete file inventory must be added here and covered by the queue check. A phase is complete only when every listed box is checked and the inventory check still passes.

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

Do not begin the next file until this cursor has a merged final decision and its checkbox is updated on current `main`.

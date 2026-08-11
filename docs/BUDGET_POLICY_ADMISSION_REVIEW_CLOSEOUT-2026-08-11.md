# Canonical Budget policy admission review closeout — 2026-08-11

## Final main

- reviewed owner: `src/ledger/budget_policy_admission.bqn`
- review PR: #650 `refactor(ledger): align Budget policy source relations`
- squash-merged main: `e196924ec3d500c72899891bbf2e5946803b5a8d`
- final PR-head CI #2619: SUCCESS
- merged-main CI #2620: SUCCESS, including full repository check and coverage

## Main reread

The merged owner was reread on `e196924ec3d500c72899891bbf2e5946803b5a8d`.

The intended architecture is present on main:

```text
physical source
  -> explicit quote/escape + multiline logical-row state
  -> logical rows
  -> header classification
  -> Scan table coordinate
  -> Group ordered source segments
  -> local table semantics
  -> classify-once backing-pool / Account relations
  -> source-ordered diagnostics
  -> fail-closed policy publication
```

In particular:

- the previous logical-row `active / Finalize` table state machine is absent;
- canonical headers are classified once, with `+\`` Scan-derived segment IDs and Grouped source coordinates;
- Envelope backing-pool references resolve once onto the pool ID axis;
- ragged Expense/Asset Account keys are flattened with aligned owner lines;
- Account coordinates use dyadic Index Of and vector Select, `⊐ -> ⊏`, before known/role masks and diagnostic cells;
- lexical quote/escape and multiline pending state remain explicit because they represent real sequential source state;
- the characterized global `blockClean` semantic diagnostic frontier remains unchanged;
- no generic TOML/parser abstraction, writer ownership, fallback path, or Household policy responsibility was added.

No temporary debug path remains.

## Failed probes retained as evidence

CI #2616 and #2617 remain useful review evidence rather than hidden noise. They exposed scalar notation surviving after the relation had become an array: first a role-axis shape mismatch, then the precise Pick-versus-Select mistake. The final coordinate-array projection passed #2618, the documented head passed #2619, and merged main passed #2620.

## Closeout decision

`src/ledger/budget_policy_admission.bqn` is finally reviewed under the BQN-native architecture/algorithm policy.

Advance the normal Phase 2 cursor to:

`src/ledger/canonical_journal_root_admission.bqn`

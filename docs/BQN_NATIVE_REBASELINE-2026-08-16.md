# BQN-native review re-baseline — 2026-08-16

## Purpose

Restart the BQN-native review from the repository that exists now, without pretending that the earlier closeouts are either immutable truth or wasted work.

The review is not a rewrite campaign and not a glyph-counting exercise. It asks whether the current household meaning is expressed through clear BQN relations, arrays, structural transformations, exact reductions, and explicit effect boundaries, while preserving diagnostics, identity, provenance, writer authority, and fail-closed admission.

## Restart coordinates

- Phase 5 closeout reference: PR #729 merge `379d1b8d443bb35217906c5f1bf08eb9642be90b`
- restart `main`: `21c1626087e1886db23ea9ed094c911d22fbcbfc`
- distance from Phase 5 closeout to restart: 49 commits
- current normal Phase 6 cursor: `src_edit/journal_block_add_cmd.bqn`
- explicit pre-cursor hotspot: `src/accounting/envelope_entitlement.bqn`

The 49-commit interval is intentionally broad. It includes ordinary Phase 6 work, the Envelope clean-epoch migration, Issue relation work, Home/Calendar work, and the Household frontend changes. Those changes are real current architecture and must not be treated as temporary noise merely because they happened after a closeout.

## Why re-baseline

The earlier phase closeouts remain useful evidence, but their checked state does not mean the files stopped evolving. Comparing the Phase 5 closeout reference with the restart main shows 49 production BQN path deltas across `src/`, `src_edit/`, and adjacent owners, including:

- Accounting: Envelope Entitlement / Consumption / Fulfillment / Commitment / Backing, Plan observation, and category-flow changes;
- Ledger: clean Household/Envelope admission, Budget admission, Plan retirement/admission, Issue admission/relation, Journal structure, Date, and Report policy changes;
- Sections / Report: Envelope, Home, Issue, Plan, catalog, composition, and metadata changes;
- Application: source adapters, Home navigation, Household surface, report destination/source wiring, and batch lifetime changes;
- Editor / `src_edit`: the already-started Phase 6 Account/Budget/Issue work plus the still-pending Journal/Plan family.

This is not evidence that all 49 paths need a second full review. It is evidence that `checked once` and `current review confidence` are different coordinates.

## Delta classification

Every post-closeout production delta encountered during the restart is classified into exactly one of these states.

### KEEP

The current shape remains appropriate. A post-closeout feature or migration may already contain stronger BQN-native structure and law coverage than the earlier owner. Do not churn it for stylistic uniformity.

### SPOT-REVIEW

An already-reviewed owner changed materially after its closeout. Inspect the changed semantic axes, array shape, evaluation/failure order, and direct consumers. Re-open the whole owner only if a concrete defect appears.

### ACTIVE

There is unresolved BQN-native pressure with a concrete reason to change: duplicated semantic parsing, procedural staging that obscures a regular array relation, duplicated dispatch authority, or a confused effect/publication boundary.

### RESIDUE

The item is not a semantic kernel problem but stale topology, experiment, shell/UI duplication, dead wrapper, outdated documentation, or retired compatibility evidence. Keep it out of the active BQN owner rewrite lane and remove/update it in the cross-cutting closeout.

## Restart plan

### A. Re-baseline infrastructure

1. Treat current `main` as the new observation baseline.
2. Keep the existing phase closeouts as historical evidence, not immutable certification.
3. Correct the review-queue CI cursor to the actual active Phase 6 scope, `src_edit/`.
4. Do not change accounting, source, writer, report, or UI behavior in this step.

Exit condition: repository CI describes the same active review cursor as `TODO.md` and this document.

### B. Post-closeout delta audit

Audit the 49-commit interval by owner family rather than chronologically.

1. Accounting / Envelope cluster.
2. Ledger / Household admission cluster.
3. Sections + Report composition cluster.
4. Application source/effect/wiring cluster.
5. Already-reviewed Phase 6 Account/Budget/Issue editor deltas.
6. Home/Household UI application projections as application relations, not as terminal presentation code.

For each cluster, record KEEP / SPOT-REVIEW / ACTIVE / RESIDUE. Do not create a PR merely to touch every changed file.

Exit condition: every materially changed owner has a classification and every ACTIVE item has a concrete reason-to-change.

### C. Active BQN-native review

#### C1. Envelope Entitlement hotspot

Close `src/accounting/envelope_entitlement.bqn` first because it is the one Phase 1 owner still explicitly unchecked and it was introduced during the later clean Envelope work.

Questions:

- Are endpoint classification and effect construction visible as relations/arrays rather than repeated procedural cases?
- Are Group / ordering / exact-scale normalization used where they clarify the domain rather than merely shorten code?
- Which mutations protect diagnostic ordering or fail-closed evaluation and should remain?
- Is historical nonnegative validation separated clearly enough from publication-range filtering?
- Is provenance alignment structural and exact?
- Can the implementation become smaller without hiding the Entitlement law?

Do not genericize Envelope processing merely to share helpers with Consumption/Fulfillment/Commitment.

#### C2. Resume normal Phase 6 cursor

Return to `src_edit/journal_block_add_cmd.bqn`, then continue the existing `TODO.md` sequence.

The Editor review should especially distinguish:

- semantic admission from physical source-shape preservation;
- regular whole-array validation from failure-order-sensitive guards;
- candidate construction from safe publication protocol;
- canonical parsing/admission owners from command-local re-parsing;
- stable domain relations from CLI argument choreography.

Do not manufacture a generic editor framework. Let repeated pressure across several concrete writers justify any shared owner.

### D. Cross-cutting closeout

Only after the production BQN inventory is closed:

- consolidate terminal selector/input duplication;
- classify shell wrappers as real effect adapters or dead topology;
- audit `experiments/` reachability and retire/promote completed probes deliberately;
- update stale UI/TUI documentation to the current multi-frontend boundary;
- remove obsolete compatibility checks/topology assumptions;
- keep gum, terminal, future BQN TUI, and future GUI concerns outside accounting ownership.

Known residue candidates at restart include the old `tui/README.md` status and the completed `experiments/bqn/add_ui_action_catalog.*` probe/workflow. They are observations, not reasons to interrupt C1/C2.

## Review laws

The restart keeps these rules from the earlier review and makes them explicit again:

1. Preserve exact arithmetic, identity, provenance, diagnostics, writer authority, and fail-closed admission.
2. Prefer dense/whole-array expression when it exposes semantic axes or structural transformation.
3. Mutation is not automatically a defect. Keep it when it makes evaluation order, source-shape construction, or fail-closed publication safer and clearer.
4. File size is not a defect by itself.
5. Do not replace concrete domain vocabulary with generic frameworks merely to reduce line count.
6. One coherent reason-to-change may cross several files; do not manufacture tiny PRs.
7. Existing tests are evidence, not unquestionable topology. Classify them as law guards, characterization evidence, or stale assumptions.
8. UI selectors and frontends consume semantic relations; they do not become accounting or writer authorities.

## Immediate next cursor

After this re-baseline lands:

```text
src/accounting/envelope_entitlement.bqn
  -> targeted closeout
  -> src_edit/journal_block_add_cmd.bqn
  -> continue Phase 6 sequence
```

The restart is complete only when the repository can answer both questions without chat history:

- what owner is being reviewed now?
- why is that owner next?

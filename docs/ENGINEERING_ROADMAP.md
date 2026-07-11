# ENGINEERING_ROADMAP: historical implementation summary

Status: historical / superseded roadmap
Owner: docs
Canonical: no; current routing: `TODO.md` and the current feature contracts linked from `docs/README.md`
Exit: retain as a compact historical summary; do not implement directly from this file

Original date: 2026-06-26
Reclassified: 2026-07-11

## Purpose

This file records a June 2026 engineering roadmap and the work it helped initiate. It is no longer an active implementation queue.

```text
historical roadmap
  != current TODO
  != implementation authorization
```

For current work, read:

1. `TODO.md` for the sole selected finite slice and standing maintenance lanes;
2. `docs/AI_CODEMAP.md` for current data flow and ownership;
3. `docs/QUALITY_BAR.md` and `docs/SAFETY_PROFILE.md` for quality and failure boundaries;
4. the focused current contract or decision record for the feature being changed.

## Completed foundations recorded by the roadmap

### Dynamic Account Space

The current engine uses the resolved account count rather than a fixed 256-slot account space. Cube and downstream structures use dynamic account dimensions.

### Journal reversal in the BQN editor

The current BQN editor and shell safe-write path support reversal as an appended transaction. The retired Go editor is not a current daily dependency.

### Contributor documentation

`CONTRIBUTING.md`, `docs/README.md`, and `docs/AI_CODEMAP.md` provide the current contributor and pit entry routes.

### Failure fixtures and safety checks

The repository contains positive and negative fixtures for source-shape, unknown-account, empty-projection, missing-plan, stale-plan, anchor, budget mapping, and related fail-visible behavior.

### Command Hub

`tools/bl` provides the current navigation hub while calculation and source meaning remain owned by BQN and the source contracts.

### Household configuration foundations

Report labels and household policy inputs were externalized in finite phases. The current boundary is recorded in:

- `docs/archive/completed-plans/GENERALIZATION_TODO.md`;
- `docs/archive/completed-plans/GENERALIZATION_COMPLETED_PHASES.md`.

Configuration externalization is `complete enough for now`. New settings require an evidence-driven ownership decision; there is no automatic migration campaign.

## Correction: Prefix fallback terminology

The old roadmap said Prefix fallback had been completely removed. That wording combined three different concerns.

Current classification:

```text
semantic account classification
  -> explicit role metadata owns meaning

missing role + familiar prefix
  -> diagnostic observation only

prefix removal for a displayed label
  -> presentation behavior only
```

The primary inspected current classification and selection paths use explicit roles. Diagnostic counts for missing-role accounts may remain intentionally. Presentation-only trimming does not infer accounting meaning.

Do not perform blanket deletion of prefix-related code from this historical roadmap statement.

## Correction: Multi-currency routing

The broad Phase A/B/C plan formerly listed here is superseded by the staged Currency Stage 2 contracts and `TODO.md`.

Current authority includes:

- `docs/CURRENCY_STAGE2_SLICE_B_SPLIT_DECISION.md`;
- the dated B3 post-implementation verification;
- `TODO.md` finite routing.

Current Slice C is limited to checked ILS posting admission while preserving:

- exact JPY behavior;
- the normalized integer and snapshot-wide amount-scale model;
- mixed JPY/ILS failure.

It does not authorize:

- FX or conversion;
- valuation or base currency;
- display precision or rounding policy;
- mixed-currency aggregation;
- a currency axis;
- broad report or JSON changes.

## Current option catalogs

Exploratory future architecture options are described in `CURRENT_ENGINE_DESIGN_IDEAS.md`.

That file is an option catalog, not an active plan. A proposal becomes work only after one finite slice is selected in `TODO.md` with explicit acceptance criteria and non-goals.

## External audit routing

The current post-B3 reassessment is:

- `docs/archive/audits/EXTERNAL_STATIC_AUDIT_REASSESSMENT_SOURCE-2026-07-11.md`.

Audit findings are evidence, not a shadow roadmap. Re-check them against current `main` and promote at most one finite candidate at a time.

## Work that remains deliberately unstarted

Do not auto-start the following without a concrete consumer or observed defect:

- broad module decomposition based on file size alone;
- OpenTelemetry or structured operation-log infrastructure;
- broad i18n architecture;
- release packaging, attestation, or CI matrices;
- database migration;
- multi-user product work;
- a rewrite in another implementation language.

## Historical order

The roadmap's original order was useful at the time:

```text
1. dynamic account space
2. failure fixtures
3. reversal UI
4. contributor documentation
5. staged currency investigation
6. household policy/configuration work
7. command hub
```

Most of these became completed foundations or were replaced by narrower current contracts. Use git history and the completed-plan archive for the original detailed proposal; use current contracts for present truth.
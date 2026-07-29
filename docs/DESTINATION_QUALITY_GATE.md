# Destination quality gate

Status: active completion gate
Owner: destination report engine

This gate applies to every module and retained portfolio slice under `src/ledger`, `src/accounting`, `src/sections`, and `src/report`. A slice is not complete merely because tests pass. Its row may move to **complete** only when every required quality dimension is green.

## Required dimensions

| Dimension | Green evidence | Failure examples |
|---|---|---|
| Dependency direction | imports follow `sections → accounting → ledger`; presentation helpers remain pure; no destination runtime import of `src_next`, context, I/O, clock, CLI, Cube/TBDS | reverse import, filesystem read in capability, universal context |
| I/O separation | core accepts already-read/admitted evidence and explicit coordinates | path fallback, environment/default resolution, hidden today |
| Exact arithmetic | coefficient/scale retained; every normalization and sum checked; mixed domains rejected | float conversion, unchecked `.coefficient`, silent rounding/overflow |
| Evidence separation | distinct accounting claims remain distinct and source-qualified | Budget=funding conflation, current/baseline provenance flattened, Plan reserve double deduction |
| Fail-closed | error/unavailable publishes no numeric partial result; valid empty remains distinguishable | zero fabricated for unavailable, partial Matrix/List/Statement |
| Local algorithm auditability | named purpose-specific stages expose validation, selection, arithmetic, reconciliation, publication; each formula can be reviewed without decoding unrelated rendering/orchestration | one deeply nested Build mixing all stages, anonymous giant record construction |
| Code readability | bounded functions/records, reviewable line structure, meaningful names, no forwarding wrappers/dual APIs; exceptional long lines are reformatted before completion | multi-hundred-character semantic blocks, compressed constructors, compatibility alias |
| Scenario proof | public synthetic tests cover happy, empty, unavailable, invalid/conflict, exact-scale, overflow where arithmetic is new, provenance, and each meaningful status; supported renderers have deterministic goldens | happy path only, private data as proof, status branch untested |
| Documentation | portfolio contract, owner/codemap, behavior/status/proof docs, TODO/NEXT state agree; completed plans are shortened or removed | stale “complete”, stale key/surface, another redundant process plan |
| Verification | focused tests, fixture checks, import-boundary search, `git diff --check`, JSON validation where applicable, and full `tools/check.sh` pass | only one focused test run |

## Review record

Use `green / improve / incomplete / not-applicable`. Record concrete evidence, not a score. Any `improve` or `incomplete` blocks completion and production cutover for that slice.

| Slice | Dependencies / I/O | Exact / evidence / fail-closed | Auditability / readability | Scenario proof | Surfaces/docs | State |
|---|---|---|---|---|---|---|
| Planned Payments | green | green | green | green | green | complete |
| Account Balances | green | green | green | green | green | complete |
| Recent Journal | green | green | green | green | green | complete |
| Current-cycle Accounts | green | green | green | green | green | complete |
| Monthly Accounts | green | green | green | green | green | complete |
| Cycle Comparison | green | green | green | green | green | complete |
| Envelope & Backing | green | green | green: named purpose-specific stages, bounded publication, reviewable lines | green | green | complete |
| Daily Target | green | green | green: named validation/normalization/calculation stages | green | green | complete |
| Issues | green | green | green: strict admission then bounded source-order selection | green | green | complete |
| P10 composition | green | green: core pure; I/O/cache/operations isolated in application boundary | green: catalog metadata; nine composers; all/cache/compact reuse individual routes | green: direct/all/cache/metadata/summary/exact-query/operations proofs | **incomplete**: editor/private gates | in progress |
| P11 editor extraction | green: zero old imports; owners moved physically | green: pure editor semantics + canonical facts/date; no wrappers | green: narrow post-write validation; no report context | green: parser/rewrite/travel/date/editor/full checks | green: `src_edit` and `src/editor` clean | complete |
| P12 deletion classification | green: exhaustive tracked scan | green: retained canonical test/fixture separated | green: exact migrate/delete actions; no unknown runtime ref | green: inventory assertion + full checks | green: 26 compatibility tests and 34 fixtures are explicit deletion set | complete |

## P7 exit gate

Before Envelope & Backing can be marked complete:

1. [x] Refactor the accounting owner into named source/coordinate validation, ownership resolution, prepared evidence, per-envelope terms, aggregate backing, and publication stages.
2. [x] Keep the bounded Statement schema, but format constructors and publication so fields are locally reviewable.
3. [x] Add public proofs for open and completed Plan, refund, overspent, under-backed, empty Plan, duplicate completion, invalid ownership/domain/range, normalization overflow, and source-qualified contributors.
4. [x] Build one section-local Statement result and only the contracted human/compact/JSON renderers.
5. [x] Validate all three goldens from the same result, then run the full verification set.
6. [x] Change the P7 review row to green only in the same commit that satisfies the evidence.

This document is a completion gate, not a demand for generic frameworks, arbitrary module counts, or cosmetic line limits. Refactoring remains purpose-specific and evidence-driven.

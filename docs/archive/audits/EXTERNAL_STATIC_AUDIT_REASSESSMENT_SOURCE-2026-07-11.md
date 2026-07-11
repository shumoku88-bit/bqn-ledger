# External Static Audit Reassessment and Repository Shelf Review

Status: audit snapshot
Owner: docs
Canonical: no; current work routing: `TODO.md`
Exit: retain as the 2026-07-11 post-B3 reassessment snapshot; create a newer dated snapshot only when current-main evidence materially changes the routing

Date: 2026-07-11
Source: external static audit of a user-supplied `bqn-ledger` ZIP, re-checked against current `main` after Currency Stage 2 Slice B3 verification and the AI actual-diff pilot closure.

## Purpose

This document preserves the useful parts of the external audit without turning the audit's recommendation order into an implementation queue.

```text
external audit finding
  != current-main fact
  != TODO authority
  != implementation authorization
```

The review also performs a repository shelf check without defining when a different experiment may begin.

## Reassessment rule

When an audit finding is revisited:

1. Re-check it against current `main`, not only against the old ZIP.
2. Classify it as `confirmed-current`, `policy-choice`, `already-resolved`, `stale`, `hold`, or `unclear-needs-evidence`.
3. Look for concrete daily-use, maintenance, CI, review, ownership, or consumer evidence.
4. Do not preserve the audit's original priority order automatically.
5. Promote at most one small finite candidate into `TODO.md` at a time.
6. Prefer a docs-only decision slice before runtime changes when source meaning, arithmetic, policy, or ownership is involved.
7. Do not start broad refactor, observability, i18n, security, release, or supply-chain campaigns merely because the audit proposed them.

## Executive routing decision

At this reassessment:

- Currency Stage 2 Slice C remains the sole finite Active work in `TODO.md`.
- No additional audit finding is promoted into Active work.
- configuration externalization remains `complete enough for now`; future additions are evidence-driven ownership decisions, not a key-by-key migration campaign.
- Prefix fallback is split into three different concerns rather than treated as one switch:
  - semantic account classification;
  - missing-role diagnostics;
  - presentation-only prefix trimming.
- broad `context.bqn` or `envelope_computation.bqn` decomposition is not authorized.
- `tools/coverage` truthfulness and the legacy `ResolveDay` export remain small evidence-gathering candidates, not current work.
- the old engineering roadmap and the compressed generalization remainder are historical decision records, not parallel TODO authorities.

## Finding inventory after current-main review

| ID | Finding | Current classification | Routing |
|---|---|---|---|
| F1 | Prefix fallback documentation/runtime drift | `confirmed-current` docs/terminology drift; primary inspected semantic selectors already use explicit roles | clarify ownership; no blanket code deletion |
| F2 | CBQN `master` tracking | `policy-choice` | keep current documented policy; revisit on upstream break or release need |
| F3 | `context.bqn` centralization | `unclear-needs-evidence` | observe; no broad decomposition |
| F4 | `envelope_computation.bqn` centralization | `unclear-needs-evidence` | observe change friction; do not reopen closed temporal semantics |
| F5 | `tools/coverage` truthfulness | `confirmed-current` small review candidate | do not promote while Slice C is active |
| F6 | structured operation logs / OpenTelemetry | `hold` | require a concrete troubleshooting consumer and privacy boundary |
| F7 | privacy, redaction, backup handling | `policy-choice` with narrow future value | current baseline remains; revisit on concrete sharing friction |
| F8 | i18n / locale / UTF-8 architecture | `hold` | require a real multilingual consumer or distribution goal |
| F9 | CI matrix, artifacts, OIDC, attestation, packaging | `hold` | require a release or support goal |
| F10 | currency / exact-decimal transition | `confirmed-current`, already governed | `TODO.md` and staged currency contracts remain authoritative |
| F11 | documentation volume and lifecycle drift | `confirmed-current` standing risk | use small lifecycle corrections, not a broad rewrite |

## F1. Prefix fallback is three separate things

The phrase `Prefix fallback` had been used for different behaviors. They must not be removed or preserved as one bundle.

### A. Semantic account classification

Primary inspected current paths classify accounting meaning from explicit metadata:

- `src_next/projection.bqn` infers income and expense from resolved `role=` values.
- `src_next/household_policy.bqn` selects expense accounts with explicit `role=expense`.
- `src_next/household_metadata.bqn` uses explicit roles for the actual expense-account set.
- `src_next/envelope_computation.bqn` uses explicit expense and budget roles for selection.

Current decision:

```text
accounting or product selection
  -> explicit role metadata owns meaning
  -> account-name prefix does not silently supply the role
```

### B. Missing-role diagnostics

`household_policy.bqn` and `household_metadata.bqn` still observe familiar prefixes when `role=` is missing. Those counts are diagnostic evidence for migration/readiness; they are not semantic classification.

Current decision:

```text
missing explicit role + familiar prefix
  -> diagnostic observation
  -> not an inferred accounting role
```

Do not delete these observations merely because semantic fallback was removed. Rename or document them more precisely when a touched-path change requires it.

### C. Presentation-only prefix trimming

Helpers that shorten labels such as `expenses:food` to `food` are display behavior. They do not decide accounting meaning.

Current decision:

```text
presentation label cleanup
  != role inference
  != compatibility fallback
```

### Documentation correction

The old roadmap statement that Prefix fallback was "completely removed" was too broad. The correct claim is:

- semantic role inference from account prefixes is removed from the primary inspected selection paths;
- explicit-role migration diagnostics remain intentionally observable;
- presentation-only prefix trimming is a separate concern.

No runtime change is authorized by this wording correction alone.

## F2. CBQN reproducibility

Current CI intentionally tracks CBQN `master`, records the resolved commit, and documents failure handling in `docs/CBQN_REPRODUCIBILITY.md`.

Classification: `policy-choice`.

Revisit only when:

- an upstream change breaks the repository;
- reproducible release artifacts become a goal;
- repeatability requirements materially change.

Do not auto-pin from the audit.

## F3. `context.bqn` ownership

B2/B3 introduced a dedicated pure arithmetic module while `context.bqn` retained snapshot loading, evidence orchestration, proof integration, and posting construction coordination.

This addresses the immediate concern that every new arithmetic rule would automatically accumulate in `context.bqn`, but it does not prove that the file should never be decomposed.

Classification: `unclear-needs-evidence`.

Evidence required before a split:

- repeated multi-site edits for one concept;
- test-isolation problems;
- an ownership conflict that cannot be expressed by a small pure module;
- concrete maintenance friction, not file size alone.

## F4. `envelope_computation.bqn` ownership

The module remains broad, but the recent temporal campaign is closed. A structural split must not casually reopen policy or time semantics.

Classification: `unclear-needs-evidence`.

Observe:

- repeated edits spanning unrelated responsibilities;
- inability to test a responsibility independently;
- recurring ownership confusion during real work.

## F5. `tools/coverage` truthfulness

`tools/coverage` is a hand-maintained module inventory and direct editor-check map. Its `covered` and `untested` words can be mistaken for a full runtime coverage claim.

Classification: `confirmed-current` small review candidate.

Possible finite review, only after current Active work is resolved:

- compare the map with current tests/checks;
- rename output if it overstates what is measured;
- do not build a broad coverage framework.

## F6-F9. Broad infrastructure proposals

Structured telemetry, broad privacy programs, i18n architecture, CI matrices, attestation, and release packaging remain unapproved without a concrete consumer.

The repository is a personal local ledger/workbench. Infrastructure must earn its upkeep and must not create a new private-data surface.

Classification: `hold` or documented `policy-choice`.

## F10. Currency work

The audit correctly observed that integer-JPY behavior and exact-decimal/currency preparation coexist. Current authority is not the old broad roadmap; it is:

- `docs/CURRENCY_STAGE2_SLICE_B_SPLIT_DECISION.md`;
- the B3 post-implementation verification;
- `TODO.md` finite routing.

Slice C is limited to checked ILS posting admission while preserving JPY behavior and mixed-domain failure. It does not authorize FX, conversion, valuation, base currency, display precision, rounding policy, mixed-currency aggregation, report, JSON, or axis expansion.

Classification: `confirmed-current`, already governed.

## F11. Documentation authority and lifecycle

Two authority problems were confirmed:

1. `docs/ENGINEERING_ROADMAP.md` still looked like an active implementation queue even though several sections were superseded by narrower current contracts.
2. `docs/archive/completed-plans/GENERALIZATION_TODO.md` was located under completed plans while describing itself as an active remainder.

Current decision:

- the roadmap is a historical summary and router, not an implementation authority;
- the generalization record is a completed boundary decision, not an active migration queue;
- current work comes from `TODO.md` and current canonical contracts;
- option catalogs remain exploratory until one small slice is explicitly selected.

## Additional shelf findings

### Legacy `ResolveDay`

`src_next/projection.bqn` still exports a compatibility `ResolveDay` with a hard-coded `2026-01-01` base, while current context construction uses `ResolveDayFromCycle` with an explicit cycle start.

Classification: `unclear-needs-evidence`.

Before any change:

1. identify current callers;
2. confirm whether the export is test-only, compatibility-only, or unused;
3. remove or migrate it only as a separate finite slice.

It is not promoted while Slice C is active.

### Configuration externalization

A4 configuration resolution remains `complete enough for now`.

Future candidates must answer:

- which semantic owner is correct: config, metadata, cycle, source schema, or code contract;
- how unknown, missing, duplicate, and empty values behave;
- which lint, fixture, and check prove the boundary;
- whether a real user-facing rule needs to vary.

Do not externalize canonical Daily Cube shape, layer meaning, or arbitrary accounting computation. Configuration must not become a household-accounting DSL.

### Option catalogs

`CURRENT_ENGINE_DESIGN_IDEAS.md` remains exploratory. Temporal, scenario, proof, registry, and policy options are not authorized merely because they are ranked there. The completed temporal campaign and current TODO routing take precedence.

## No maturity gate

This audit does not define criteria for when `bqn-ledger` is finished, mature, in maintenance mode, or `枯れた`.

The user's sense that a tool has become `枯れた` is deliberately not converted into a checklist, milestone, completion condition, or repository state.

A separate 6D event-sourcing experiment may begin whenever the user chooses. Keeping it in a separate repository is an architectural boundary, not a timing gate, and it is not conditional on Slice C completion, an empty Active section, or a maintenance-mode declaration.

## Final routing

```text
Active
  -> Currency Stage 2 Slice C only

Continuous maintenance
  -> docs lifecycle
  -> configuration ownership discipline
  -> CI/workflow drift
  -> source TSV safety
  -> audit reassessment on concrete triggers

Observe / evidence needed
  -> context ownership
  -> envelope computation ownership
  -> diagnostic prefix terminology
  -> legacy ResolveDay callers
  -> tools/coverage semantics

Hold
  -> telemetry / OpenTelemetry
  -> broad privacy program
  -> i18n architecture
  -> release packaging / attestation / CI matrix
  -> broad refactors without concrete friction
```

No additional finite candidate is promoted by this shelf review.
# Journal External Plan Reference Profile Prerequisite Plan

Status: completed
Owner: journal source migration / test-only Journal profile
Canonical: no; current route: `TODO.md` and `docs/JOURNAL_CANONICAL_TSV_NATIVE_PREFIX_CONVERTER_PLAN.md`
Date: 2026-07-22
Exit: archived; explicit owner review is required before converter work may be selected again

## Finite prerequisite question

> Can the non-production Minimal BQN Journal profile expose an explicit historical-actual cross-link policy that retains an actual transaction’s `plan-id` when its plan source is external to the parsed Journal, while preserving the current strict default parser behavior, all existing internal plan-completion validation, every other cross-link invariant, the current Transaction IR shape, the 16-field Posting IR schema, production routing, private-data boundaries, and converter topology?

In other words, can an explicitly selected profile retain `plan-id` as an unresolved external reference for a historical actual transaction whose plan source is outside the parsed Journal, without weakening the default parser or changing internal completion semantics?

This document selects only that finite prerequisite. It does not implement the profile or converter.

## Observed parser/profile conflict

### Legacy cross-source lifecycle

The current legacy lifecycle links separate sources:

```text
plan.tsv
  plan_id付き予定

journal.tsv
  同じplan_idを引き継いだactual transaction
```

A plan is treated as completed when `journal.tsv` contains the same `plan_id`. The actual source therefore retains the link even though the corresponding plan row remains in another physical source. When only historical `journal.tsv` actual rows are converted into a native Journal prefix, an actual transaction with `plan_id` can legitimately have no corresponding plan transaction inside that prefix.

### Current strict parser

`src_next/journal_profile_stage1.bqn` currently applies these rules in `CrossLinkDiagnostics`, called by `Parse`:

```text
actual has plan-id, zero matching in-document plans
  -> plan_completion_target_invalid

actual has plan-id, exactly one matching in-document plan
  -> require matching execution-envelope
  -> mismatch is execution_envelope_mismatch

multiple in-document plans with one plan-id
  -> plan_id_duplicate and/or invalid completion target
```

A public synthetic actual-only Journal with `plan-id` was observed to fail with `plan_completion_target_invalid`.

### Converter conflict

The canonical converter accepts legacy `journal.tsv` actual rows, not `plan.tsv`. The converter contract also requires admitted `plan_id` metadata to be retained. Therefore none of these are valid workarounds:

- dropping or renaming `plan-id`;
- synthesizing a plan transaction;
- implicitly adding `plan.tsv` as converter input;
- weakening strict parsing globally.

The converter remains blocked until this prerequisite is implemented and reviewed.

## Explicit profile boundary

The non-production Minimal BQN Journal profile must distinguish at least:

```text
strict self-contained profile
historical actual with external plan source profile
```

The implementation may finalize names and API shape after inspection, but profile selection must be explicit at the call site. A compatible shape may be one of:

```text
Parse raw
ParseWithProfile ⟨raw, profileName⟩
```

or:

```text
Parse raw
ParseHistoricalActual raw
```

The existing `Parse` entry point must retain its strict self-contained behavior. The implementation must not infer a profile from transaction content, automatically relax when zero plans match, use mutable global state, or silently fall back for an unknown profile value.

This explicit policy is test-only/non-production. It is not production parser routing.

## Historical external-plan contract

The relaxation applies only to an actual transaction with a nonempty `plan-id`, and only when the caller explicitly selects the historical external-plan profile.

### Zero internal matches

When no in-document plan transaction has the actual transaction's `plan-id`:

- parsing succeeds;
- `plan_id` is retained exactly in the existing Transaction IR field;
- the existing `plan-id` metadata item remains present;
- `source_event_id`, transaction order, posting order, amounts, accounts, layer, and status remain unchanged;
- no plan transaction is synthesized;
- no diagnostic or summary publishes the `plan-id` value.

This state means “external unresolved historical plan reference,” not “the plan did not exist.” It does not prove or infer anything about an external plan source beyond preserving the source link.

### Exactly one internal match

When exactly one in-document plan transaction matches, both profiles retain the current internal completion semantics:

- the plan and actual `plan_id` match;
- `execution-envelope` must match;
- mismatch remains `execution_envelope_mismatch`.

The historical profile must not bypass internal validation merely because it permits external references.

### Multiple internal matches

Multiple in-document plan transactions with the same `plan-id` remain invalid. `plan_id_duplicate`, `plan_completion_target_invalid`, and other stable diagnostics must not be changed without demonstrated need.

### Unchanged cross-links and validation

The historical profile must not relax:

- plan event `event-id` and `plan-id` requirements;
- budget `allocation-id` / `actual-event-id` linkage rules;
- actual-event layer restrictions;
- duplicate durable event identity checks;
- account and commodity declarations;
- posting balance and posting order;
- metadata key, value, and duplicate validation;
- any cross-link invariant unrelated to the zero-match actual `plan-id` case.

## Semantic classification and schema decision

The profile distinguishes:

```text
internal resolved plan completion link
external unresolved historical plan reference
```

The existing combination of `layer_name`, `plan_id`, ordered metadata, `source_event_id`, and explicit parser profile is sufficient to retain the required source meaning for this finite prerequisite. This docs slice does not add a classification field to Transaction IR or Posting IR.

The profile describes admission context; it does not persist a new transaction attribute. Downstream converter validation knows which profile it explicitly selected and can compare the retained `plan_id` and metadata without changing the current schemas.

If implementation demonstrates that this distinction cannot remain explicit and schema-preserving, it must stop. A new Transaction IR field, a Posting IR change, or implicit context inference is not authorized by this plan.

## Required public-synthetic implementation evidence

A later implementation Draft PR must use wholly invented values and prove all of the following.

### Strict default preservation

1. An actual-only Journal contains `plan-id`.
2. Existing default `Parse` is used.
3. Parsing fails with `plan_completion_target_invalid`.

### Explicit historical profile

1. The same actual-only Journal is parsed with the explicit historical profile.
2. Parsing succeeds.
3. Transaction IR retains the exact `plan_id` and metadata item.
4. Stage 2A and Stage 2B succeed.
5. Posting IR remains exactly 16 fields in the established order.
6. Source identity and posting order remain unchanged.

### Existing internal match

A Journal with exactly one matching plan transaction, matching `plan-id`, and matching `execution-envelope` succeeds under both profiles.

### Internal mismatch and duplicate target

- An `execution-envelope` mismatch remains `execution_envelope_mismatch` under the historical profile.
- Multiple plan transactions sharing one `plan-id` remain fail-closed, including existing `plan_id_duplicate` evidence.

### Absence, other links, and profile selection

- An actual transaction without `plan-id` behaves identically under both profiles.
- Existing budget companion, actual-event, allocation, and duplicate-event-ID rejection evidence remains unchanged.
- Unknown profile names and malformed policy values fail closed; there is no strict or historical silent fallback.

### Unicode and privacy-safe evidence

A synthetic Unicode description and metadata value coexist with an external `plan-id` and round-trip without alteration. Tests, diagnostics, docs, IDs, paths, accounts, descriptions, and amounts must be newly invented and public-safe.

## Expected implementation surface

The later implementation should remain narrow. Likely surfaces are:

```text
src_next/journal_profile_stage1.bqn
tests/test_src_next_journal_profile_stage1.bqn
tests/test_journal_legacy_metadata_profile_extension.bqn
focused new public-synthetic test only if needed
tools/check.sh only if a new test is added
completion routing docs
```

The implementation must preserve `Parse` as strict and avoid production routing. It must not implement the converter in the prerequisite PR.

## Explicit non-goals and stop conditions

Stop rather than simplify if implementation requires:

- global weakening of default `Parse`;
- automatic profile detection or zero-match fallback;
- plan transaction synthesis;
- adding `plan.tsv` to converter input;
- deleting or renaming `plan-id`;
- changing the Transaction IR schema;
- changing the 16-field Posting IR schema;
- production parser, report, or writer routing changes;
- changing legacy plan lifecycle semantics;
- private data access;
- converter implementation or production cutover.

## Completion record

The test-only parser now exports `ParseWithProfile` with the explicit supported names `strict_self_contained` and `historical_external_plan`. Default `Parse` delegates to the strict profile. The historical profile admits only an actual transaction's nonempty `plan-id` with zero matching in-document plan transactions; one match still enforces execution-envelope agreement, duplicates and unrelated cross-links remain fail closed, and unsupported profiles return `parser_profile_unsupported`.

Public synthetic focused evidence fixes exact metadata and Unicode retention, strict equivalence, zero/one/duplicate target behavior, Stage 2A's unchanged 16-field Posting IR, and Stage 2B provenance alignment. Transaction IR, production source/report routing, writers, converter code, private data, and cutover were not changed.

## Routing after completion

```text
external plan reference profile prerequisite:
  complete and archived

canonical TSV-to-native Journal prefix converter:
  remains selected but blocked pending explicit owner review

converter implementation:
  not resumed

production source truth:
  TSV

production report routing:
  TSV

production cutover:
  blocked
```

Completion does not restart converter work automatically. Explicit owner review is required before the stopped converter branch may resume or a replacement implementation branch may be selected.

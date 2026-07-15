# Daily Capacity evidence assembler characterization contract

Status: current test-only contract
Owner: report / ledger policy / envelope
Canonical: yes; companion to `DAILY_CAPACITY_MINIMAL_INPUT_RESULT_CONTRACT.md` for the selected synthetic assembler seam
Exit: replace or retire when a separately reviewed source-backed adapter contract supersedes this test-only input shape

## Purpose

Define a pure, test-only characterization boundary between already-resolved candidate facts and explicit owner decisions:

```text
AssembleDailyCapacityInputFromResolvedEvidence request
  -> {state, input, diagnostics}
```

It assembles the five-part input expected by `BuildDailyCapacityFromEvidence`. It does not call that function and does not calculate Daily Capacity.

## Request shape

```text
observation_with_source
resolved_horizon_evidence
arithmetic_domain_proof

asset_candidates
asset_basis_decision
per_asset_decisions
asset_policy_ref

obligation_candidates
settlement_evidence
per_obligation_decisions
obligation_policy_ref

reservation_evidence
```

All values are public, already-resolved, in-memory synthetic evidence.

### Facts and decisions remain separate

Asset candidates contain only:

```text
asset_id, source_kind, source_ref, currency, amount
```

Asset decisions contain only:

```text
asset_id, decision, decision_basis
```

Obligation candidates contain only:

```text
obligation_id, source_ref, due_on, currency, amount
```

Settlement evidence contains only:

```text
obligation_id, settlement_state, evidence_ref
```

Obligation decisions contain only:

```text
obligation_id, decision, decision_basis
```

Reservation evidence contains only:

```text
obligation_id, reservation_state,
excluded_from_asset_basis, reservation_ref, evidence_ref
```

The assembler does not generate an include/exclude decision, settlement state, reservation state, account selection, obligation selection, or policy reference from names, metadata, aggregates, or omitted rows.

## Normalization

- `observation_with_source` becomes `observation` unchanged.
- `resolved_horizon_evidence` becomes `horizon` unchanged.
- proven `arithmetic_domain_proof.domain` becomes contract `arithmetic_domain.currency`.
- each candidate joins only with its same-ID decision/evidence records.
- output `asset_scope.rows` and `obligation_scope.rows` follow candidate input order. Decision/evidence input order never changes that order.
- a selected asset basis supplies `asset_scope.scope_id` and `basis_kind`; explicit policy refs supply both scope `policy_ref` values.

The first test-only shape requires settlement and reservation evidence for every obligation candidate. It does not infer `open` or reservation `none` from an absent record.

## State and diagnostics

Diagnostics use:

```text
{severity, stage, code, message, evidence_refs}
```

Stages and evaluation order:

```text
1. structure: candidate and identity validity
2. temporal: observation and horizon carrier availability
3. currency: arithmetic proof
4. asset_scope: basis and asset-decision joins
5. obligation_scope: settlement and obligation-decision joins
6. reservation: reservation joins and linkage uniqueness
```

Precedence is:

```text
error > unavailable > resolved
```

- `error`: malformed/contradictory supplied evidence, duplicate identity, or a decision/link to an unknown candidate.
- `unavailable`: a required owner decision or required evidence record is absent, or reservation evidence is explicitly ambiguous.
- `resolved`: all required joins are present and valid.

On `error` or `unavailable`:

```text
input = empty
```

The assembler never returns a partial plausible five-part input.

## Responsibility split with the calculator

`resolved` means the assembler has established only assembly-level facts:

- stable candidate and join identity validity;
- exact same-ID joins between candidates and their decision/evidence carriers;
- presence of every required owner decision and evidence record;
- rejection of duplicate or unknown decision/evidence/linkage identities;
- the explicitly supplied evidence states, including rejection of an invalid state vocabulary;
- deterministic output row order equal to candidate input order.

It does **not** mean that the five-part carrier has passed the Daily Capacity calculator's semantic validation. `BuildDailyCapacityFromEvidence` remains the sole owner of:

- observation date validity;
- horizon date and ordering semantics;
- asset and obligation row value semantics;
- currency agreement with the arithmetic domain;
- decision enum validation and decision/settlement calculator-level compatibility;
- reservation amount/ref arithmetic invariants.

The assembler continues not to call the calculator and must not duplicate those calculator validations.

## Required diagnostic codes

```text
observation_source_missing
horizon_evidence_unavailable
horizon_evidence_error
arithmetic_domain_unproven

duplicate_asset_candidate_id
unknown_asset_decision_id
duplicate_asset_decision_id
asset_basis_unselected
asset_basis_error
asset_decision_missing
asset_policy_ref_missing

duplicate_obligation_candidate_id
unknown_settlement_obligation_id
duplicate_settlement_evidence
settlement_evidence_missing
settlement_evidence_invalid
unknown_obligation_decision_id
duplicate_obligation_decision_id
obligation_decision_missing
obligation_policy_ref_missing

unknown_reservation_obligation_id
duplicate_reservation_evidence
reservation_evidence_missing
reservation_evidence_invalid
reservation_evidence_ambiguous
duplicate_reservation_linkage
```

## Explicit non-goals

- no source/config/environment/system-time access;
- no source-backed account balance or pool projection;
- no settlement normalization;
- no `BuildDailyCapacityFromEvidence` call;
- no runtime module, report, JSON, CLI, UI, config, metadata, or TSV change;
- no inference from account names, prefixes, role/type, envelope labels, or aggregate equality.

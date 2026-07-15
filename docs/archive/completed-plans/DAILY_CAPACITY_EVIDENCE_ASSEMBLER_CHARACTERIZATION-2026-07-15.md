# Daily Capacity evidence assembler characterization — 2026-07-15

Status: completed test-only characterization
Owner: report / ledger policy / envelope
Canonical: no; current contract: `../../DAILY_CAPACITY_EVIDENCE_ASSEMBLER_CHARACTERIZATION_CONTRACT.md`
Exit: retain as completion evidence until a separately selected adapter implementation supersedes this synthetic seam

## Delivered boundary

The test-only reference evaluator in:

```text
tests/daily_capacity_evidence_assembler_reference.bqn
```

exports:

```text
AssembleDailyCapacityInputFromResolvedEvidence request
  -> {state, input, diagnostics}
```

It joins public in-memory candidate facts to explicit owner decisions by stable asset or obligation identity. It produces the five-part input carrier for `BuildDailyCapacityFromEvidence`, but deliberately never calls that calculator.

## Selected characterization rules

- facts and owner decisions are separate request carriers;
- candidate order controls assembled row order; decision, settlement, and reservation order do not;
- a missing required decision/evidence is `unavailable`;
- unknown or duplicate identity/linkage is `error`;
- explicit ambiguous reservation evidence is `unavailable`;
- precedence is `error > unavailable > resolved`;
- non-resolved results have `input = empty`.

The retained public synthetic tests cover resolved assembly, missing asset/obligation decisions, unknown and duplicate decisions, missing basis, unproven domain, ambiguous/unknown/duplicate reservation evidence, deterministic ordering, and error precedence.

## Boundary retained

This slice does not add a runtime adapter or read source/config/environment/system time. It does not project O-bounded balances, normalize settlement evidence, infer asset or obligation policy, infer reservations from envelopes, connect Outlook/output paths, or change current compatibility behavior.

## Next candidate

No implementation is selected. A future candidate must separately decide whether the test-only assembler contract should become a production pure module, and must not combine that question with source-backed evidence loading, Candidate B account-balance projection, or Candidate C pool/reservation linkage.

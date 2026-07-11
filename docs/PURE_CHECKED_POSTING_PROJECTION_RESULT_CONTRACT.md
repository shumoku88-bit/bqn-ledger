# Pure Checked Posting Projection Result Contract

Status: selected design contract; runtime not yet implemented
Owner: other
Canonical: yes; canonical for Headless Kernel Evolution Phase B
Exit: retain as the current boundary contract after implementation; supersede only through an explicit replacement decision

## 1. Purpose

This contract selects the smallest data-only boundary that can remove inner `•Out` / `•Exit` from the current posting projection path without changing the behavior of existing commands, reports, Cube materialization, TBDS construction, source TSV, or accounting semantics.

The selected boundary is accounting-specific. It is not a universal event model.

```text
posting source snapshot
+ resolved account metadata
+ explicit cycle start coordinate
  -> pure checked posting projection result
  -> existing compatibility wrapper
  -> existing stdout / process exit behavior
```

The contract is the Phase B answer to one question:

> What data result can represent the current checked Posting IR construction before CLI rendering and process termination?

It does not authorize runtime implementation by itself. Runtime extraction remains a separate Phase C decision.

## 2. Current runtime seam

Current `main` performs the following inside `BuildAuthorizedRowsFromSnapshot`:

```text
snapshot
  -> BuildRowEvidenceFromSnapshot
  -> currency_arithmetic.Build
  -> ResolveArithmeticCurrencyProof
  -> RequireArithmeticCurrencyProof
  -> normalized coefficient length check
  -> BuildProjectionRowsForEvidence
  -> { rows, arithmetic_currency_proof }
```

Two failure paths currently terminate the process inside this inner path:

1. arithmetic-currency proof authorization failure;
2. row-evidence / normalized-coefficient length mismatch.

The selected extraction replaces those inner process effects with a returned result. Existing outer callers remain responsible for reproducing the current terminal behavior.

## 3. Selected pure builder

The selected public calculation boundary for Phase C is:

```text
BuildCheckedPostingProjectionFromSnapshot
  ⟨snapshot, resolved, cycleStart⟩
```

The name is selected for this workstream. Phase C may adjust local helper names, but it must not silently widen the public meaning.

### 3.1 Inputs

#### `snapshot`

The exact in-memory posting source snapshot already produced by `LoadPostingSourceSnapshot`.

Required meaning:

- contains the journal-like posting sources used by the current path;
- is reused for row evidence, arithmetic evidence, proof, and Posting IR construction;
- is not reloaded or replaced during the calculation;
- preserves the one-snapshot invariant.

The pure builder must not read source files.

#### `resolved`

The current result of `account_key.Resolve`.

It remains an explicit input because Posting IR construction needs:

- account identities;
- account roles;
- canonical account keys;
- account-key indices.

The pure builder must not read `accounts.tsv` or perform account-file loading. Account resolution remains an upstream adapter responsibility.

#### `cycleStart`

An explicit date coordinate used by the current Posting IR path to derive `day_index`.

Required meaning:

- supplied by the caller;
- not read from system time;
- not resolved from environment state;
- not a period filter;
- preserves ledger-wide row construction.

The pure builder does not own cycle-file loading or report-period selection.

### 3.2 Inputs not selected

The pure builder does not accept:

- a base directory;
- source filenames to load;
- `as_of` as an implicit clock value;
- a report section;
- Cube dimensions;
- TBDS period state;
- household policy;
- a separately supplied arithmetic proof.

A proof supplied independently from the snapshot would weaken the current same-snapshot authorization invariant and is therefore not selected.

## 4. Selected result carrier

The builder returns one namespace with these fields:

```text
{
  state
  row_evidence
  arithmetic_evidence
  arithmetic_currency_proof
  posting_rows
  diagnostics
}
```

### 4.1 `state`

Allowed values:

```text
"ok"
"error"
```

`state = "ok"` means:

- row evidence and arithmetic evidence were derived from the same snapshot;
- the arithmetic-currency proof was authorized;
- the row-evidence count equals the normalized-coefficient count;
- Posting IR rows were constructed.

It does **not** mean that every Posting IR row has `status = "ok"`.

Current row-level accounting validation remains separate. For example, `unknown_account` and `invalid_date` remain Posting IR row statuses rather than being promoted automatically to aggregate builder failure.

`state = "error"` means the checked posting projection was not admitted. In that state, `posting_rows` must be empty.

### 4.2 `row_evidence`

The complete result of `BuildRowEvidenceFromSnapshot snapshot`.

It remains available on both success and error so a headless caller can inspect source-local evidence without scraping terminal text.

### 4.3 `arithmetic_evidence`

The complete result of `currency_arithmetic.Build row_evidence`.

It remains available on both success and error. This includes the normalized-coefficient carrier owned by the current currency arithmetic path.

### 4.4 `arithmetic_currency_proof`

The complete result of:

```text
ResolveArithmeticCurrencyProof
  ⟨row_evidence, arithmetic_evidence⟩
```

This field retains the current five-field proof meaning:

```text
state
domain
basis
amount_scale
message
```

It is an arithmetic-currency proof only. It is not renamed to a generic projection proof.

### 4.5 `posting_rows`

On success, the complete ledger-wide Posting IR rows generated from the admitted evidence and normalized coefficients.

On error:

```text
posting_rows = ⟨⟩
```

The pure builder must never return partial posting rows together with `state = "error"`.

### 4.6 `diagnostics`

An ordered list of structured diagnostic namespaces.

For the selected Phase C slice, each diagnostic has exactly these fields:

```text
{
  severity
  stage
  code
  message
}
```

Allowed values in the selected slice:

```text
severity = "error"

stage = "authorization"
      | "structure"

code = "arithmetic_currency_proof_rejected"
     | "normalized_coefficient_length_mismatch"
```

The diagnostic `message` does not include the terminal prefix `ERROR: `.

Success requires:

```text
diagnostics = ⟨⟩
```

The current slice returns at most one diagnostic because the existing runtime exits at the first fatal boundary. A future multi-diagnostic design requires a separate contract change.

## 5. Evaluation and failure order

The builder must preserve the current fail-closed order:

```text
1. build row evidence
2. build arithmetic evidence
3. resolve arithmetic-currency proof
4. authorize proof
5. if rejected, return authorization error
6. compare evidence and normalized-coefficient lengths
7. if mismatched, return structure error
8. build posting rows
9. return success
```

This order matters. A proof rejection must not be hidden by a later structural diagnostic.

### 5.1 Proof rejection

When:

```text
projection.AuthorizeArithmeticCurrencyProof proof = 0
```

the result is:

```text
state = "error"
posting_rows = ⟨⟩
diagnostics = ⟨
  {
    severity = "error"
    stage = "authorization"
    code = "arithmetic_currency_proof_rejected"
    message = projection.ArithmeticCurrencyAuthorizationMessage proof
  }
⟩
```

### 5.2 Structural mismatch

When the proof is authorized but:

```text
≠row_evidence
  ≢
≠arithmetic_evidence.normalized_coefficients
```

the result is:

```text
state = "error"
posting_rows = ⟨⟩
diagnostics = ⟨
  {
    severity = "error"
    stage = "structure"
    code = "normalized_coefficient_length_mismatch"
    message = "evidence and normalized coefficients length mismatch"
  }
⟩
```

### 5.3 Success

When authorization and structural admission pass:

```text
state = "ok"
diagnostics = ⟨⟩
posting_rows = complete constructed Posting IR
```

Posting rows preserve the existing source order and debit-then-credit order for each evidence row.

## 6. Compatibility wrapper contract

`BuildAuthorizedRowsFromSnapshot` remains the compatibility boundary used by current callers.

After Phase C extraction, its observable contract remains:

```text
BuildAuthorizedRowsFromSnapshot
  ⟨snapshot, resolved, cycleStart⟩
  -> { rows, arithmetic_currency_proof }
```

Its selected behavior is:

```text
result ← BuildCheckedPostingProjectionFromSnapshot
  ⟨snapshot, resolved, cycleStart⟩

result.state = "ok"
  -> return {
       rows = result.posting_rows
       arithmetic_currency_proof = result.arithmetic_currency_proof
     }

result.state = "error"
  -> print "ERROR: " + first diagnostic.message
  -> exit 1
```

The wrapper must preserve the current stdout text and exit code for existing failure cases.

### 6.1 Existing callers preserved

Phase C must preserve the signatures and externally visible behavior of:

- `BuildAuthorizedRowsFromSnapshot`;
- `BuildAllRowsFromSnapshot`;
- `BuildAllRows`;
- `BuildRowsForFile`;
- `BuildRowsForFileOptional`;
- `BuildContext`;
- `tools/report`;
- `tools/report-next-summary`;
- current section JSON entry points.

### 6.2 Existing proof API preserved

The selected extraction does not delete or rename:

- `AuthorizeArithmeticCurrencyProof`;
- `ArithmeticCurrencyAuthorizationMessage`;
- `RequireArithmeticCurrencyProof`.

The pure builder uses the pure authorization predicate and message builder. Existing direct callers and tests of `RequireArithmeticCurrencyProof` remain valid unless a separate later cleanup is selected.

### 6.3 Source-file compatibility guard preserved

`SourceFromSnapshot` remains outside the selected pure builder.

Its unsupported-source and missing-source `•Out` / `•Exit` behavior belongs to the compatibility file-selection wrapper, not to snapshot-wide checked Posting IR construction.

## 7. Purity and ownership rules

`BuildCheckedPostingProjectionFromSnapshot` must be deterministic for the same inputs.

It must not:

- call `loader.ReadLines` or `loader.ReadLinesOptional`;
- call `•Out`;
- call `•Exit`;
- read system time;
- inspect environment variables;
- construct Cube or TBDS;
- render reports or JSON;
- apply household advice or envelope policy;
- mutate source TSV;
- accept a proof detached from the snapshot.

The selected ownership remains:

```text
I/O adapters
  -> load source snapshot, cycle, accounts

pure checked posting builder
  -> evidence, arithmetic, proof, admission, Posting IR, diagnostics

compatibility wrappers
  -> terminal rendering and process exit

projection consumers
  -> Cube, TBDS, reports, policy, exports
```

## 8. Row-level status boundary

The aggregate result must not blur proof admission with Posting IR row acceptance.

Current distinctions remain:

```text
arithmetic-currency proof rejected
  -> aggregate result error, no posting rows

normalized coefficient length mismatch
  -> aggregate result error, no posting rows

unknown account / invalid date in constructed Posting IR
  -> row status under existing Posting IR semantics
  -> not automatically aggregate result error
```

This contract does not change Cube acceptance, skipped-row handling, balance validation, or report policy.

## 9. Required Phase C verification

Phase C is not complete unless all applicable checks below pass.

### 9.1 Direct pure-result tests

Verify at least:

1. legacy-compatible all-JPY success;
2. explicit all-JPY success;
3. proven all-ILS success with `resolved_single_currency`;
4. empty posting sources using current compatibility proof semantics;
5. mixed JPY / ILS rejection;
6. unsupported currency metadata rejection;
7. duplicate currency metadata rejection;
8. malformed amount rejection;
9. structural evidence / coefficient mismatch rejection;
10. unknown-account row parity;
11. invalid-date row parity.

For every error case, verify:

```text
state = "error"
posting_rows = ⟨⟩
exact diagnostic stage
exact diagnostic code
exact diagnostic message
```

For every success case, verify:

```text
state = "ok"
diagnostics = ⟨⟩
proof parity
posting-row parity
```

The structural mismatch branch must have a focused test seam. Phase C may choose a private helper or another narrow test arrangement, but it must not add a generic public projection framework merely to make the branch injectable.

### 9.2 Compatibility-wrapper tests

Verify that current wrapper behavior is unchanged:

- exact success return shape `{rows, arithmetic_currency_proof}`;
- exact stdout for proof rejection;
- exact stdout for length mismatch;
- exit code `1` on both fatal paths;
- no additional stdout on success.

### 9.3 Downstream parity

Verify unchanged results for:

- current JPY fixtures;
- the checked all-ILS fixture;
- mixed-domain fail-closed behavior;
- Cube materialization;
- TBDS construction;
- report golden output;
- machine summary / structured output checks that already cover this path.

### 9.4 Repository validation

Run the repository-prescribed checks, including:

```text
tools/check.sh
```

and confirm GitHub Actions is green.

## 10. Phase C implementation limits

The smallest authorized implementation candidate after a separate Phase C selection is:

```text
add BuildCheckedPostingProjectionFromSnapshot
adapt BuildAuthorizedRowsFromSnapshot as compatibility wrapper
add focused result and parity tests
```

The implementation slice must not also:

- change source TSV or metadata schema;
- change proof domain or basis rules;
- add currency conversion, valuation, rounding, or mixed aggregation;
- alter Posting IR fields or status meanings;
- change Cube or TBDS axes;
- change report output or JSON schemas;
- implement 6D;
- add `CanonicalEvent`;
- introduce `Project(events, spec)`;
- migrate journal, plan, budget, or issues to event sourcing;
- split the entire `context.bqn` module;
- create a new repository or numbered Stage.

## 11. Decisions and non-decisions

Selected now:

- the pure builder accepts `snapshot`, `resolved`, and `cycleStart`;
- the proof is derived internally from the same snapshot;
- the result carrier has six fields;
- fatal result errors produce no Posting IR rows;
- diagnostics are structured data without terminal prefixes;
- existing wrappers retain terminal output and exit behavior;
- row-level Posting IR validation remains distinct from aggregate admission.

Not selected now:

- a universal event carrier;
- a generic projection combinator;
- a new error framework for the whole repository;
- multiple accumulated fatal diagnostics;
- source-level 6D;
- strict event sourcing;
- broad module decomposition.

## 12. Phase transition rule

This document completes the design question owned by Phase B only after it is merged with:

- `HEADLESS_KERNEL_EVOLUTION_MAP.md` updated to show Phase A complete and Phase B active/completed as appropriate;
- `TODO.md` routing exactly one finite Phase B slice;
- docs routing to this contract;
- green repository checks;
- actual-diff confirmation that no runtime path changed.

After Phase B merges, Phase C becomes eligible for explicit selection. It does not start automatically.

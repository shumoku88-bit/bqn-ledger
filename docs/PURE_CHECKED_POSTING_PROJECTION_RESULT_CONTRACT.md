# Pure Checked Posting Projection Result Contract

Status: current contract  
Runtime owner: `src_next/context.bqn`  
Proof predicate/message owner: `src_next/arithmetic_currency_proof.bqn`  
Implementation state: implemented and in use

## Purpose

This document records the current data-only boundary for checked construction of non-Actual Posting IR rows.

The boundary separates deterministic accounting calculation from terminal behavior:

```text
posting source snapshot
+ resolved account metadata
+ explicit cycle-start coordinate
  -> pure checked posting projection result
  -> compatibility wrapper
  -> existing stdout / process exit behavior
```

It is an accounting-specific contract. It is not a universal event carrier, query language, report model, Cube replacement, or TBDS replacement.

## Current runtime flow

The implemented flow is:

```text
snapshot
  -> BuildRowEvidenceFromSnapshot
  -> currency_arithmetic.Build
  -> ResolveArithmeticCurrencyProof
  -> BuildCheckedPostingProjectionFromPrepared
       -> arithmetic_currency_proof.AuthorizeArithmeticCurrencyProof
       -> arithmetic proof diagnostic when rejected
       -> normalized coefficient length check
       -> structural diagnostic when mismatched
       -> BuildProjectionRowsForEvidence when admitted
  -> checked result
```

Normal callers use:

```text
BuildCheckedPostingProjectionFromSnapshot
  ⟨snapshot, resolved, cycleStart⟩
```

Compatibility callers use:

```text
BuildAuthorizedRowsFromSnapshot
  ⟨snapshot, resolved, cycleStart⟩
```

`BuildAuthorizedRowsFromSnapshot` delegates calculation to the pure checked boundary and preserves the historical success shape and fatal terminal behavior.

## Inputs

### `snapshot`

The exact in-memory posting source snapshot used for all evidence, arithmetic, proof, and Posting IR construction in one invocation.

The pure builder does not reload files and does not accept a separately supplied proof. This preserves the one-snapshot invariant.

### `resolved`

The current resolved account namespace used by Posting IR construction, including:

- account identities;
- account roles;
- canonical AccountKeys;
- AccountKey indices.

Account-file loading and account resolution remain upstream responsibilities.

### `cycleStart`

An explicit date coordinate used to derive `day_index`.

It is not a clock read and not a period filter. Posting rows remain ledger-wide; report-period selection belongs to later consumers.

## Pure result carrier

The builder returns one namespace with exactly these fields:

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

### `state`

Allowed values:

```text
"ok"
"error"
```

`state = "ok"` means:

- row evidence and arithmetic evidence came from the supplied snapshot;
- the arithmetic-currency proof was authorized;
- row-evidence and normalized-coefficient lengths agree;
- complete Posting IR rows were constructed.

It does not mean every row has `status = "ok"`. Row-level statuses such as `unknown_account`, `invalid_amount`, and `invalid_date` remain Posting IR meanings.

`state = "error"` means aggregate admission failed. In that state:

```text
posting_rows = ⟨⟩
```

Partial posting rows must not escape with an error result.

### `row_evidence`

The complete result of `BuildRowEvidenceFromSnapshot snapshot`.

It remains present on success and error so callers can inspect source-local evidence without reading terminal output.

### `arithmetic_evidence`

The complete result of `currency_arithmetic.Build row_evidence`, including normalized coefficients and arithmetic-domain evidence.

It remains present on success and error.

### `arithmetic_currency_proof`

The complete five-field proof constructed by `ResolveArithmeticCurrencyProof`:

```text
state
domain
basis
amount_scale
message
```

This is specifically an arithmetic-currency proof. It does not replace account, date, layer, balance, or row-status validation.

### `posting_rows`

On success, the complete Posting IR rows generated in source order, with debit then credit rows for each admitted non-Actual source row.

On error, it is empty.

### `diagnostics`

An ordered list of structured diagnostics with these fields:

```text
{
  severity
  stage
  code
  message
}
```

The current fatal diagnostics are:

```text
severity = "error"

stage = "authorization"
code  = "arithmetic_currency_proof_rejected"

stage = "structure"
code  = "normalized_coefficient_length_mismatch"
```

Diagnostic messages do not contain the terminal prefix `ERROR: `.

Success requires:

```text
diagnostics = ⟨⟩
```

The current boundary returns at most one fatal diagnostic because it preserves first-failure behavior.

## Evaluation and failure order

The pure builder preserves this fail-closed order:

```text
1. build row evidence
2. build arithmetic evidence
3. resolve arithmetic-currency proof
4. authorize proof
5. if rejected, return authorization error with no posting rows
6. compare evidence and normalized-coefficient lengths
7. if mismatched, return structure error with no posting rows
8. build posting rows
9. return success
```

A proof rejection must not be hidden by a later structural mismatch.

### Proof rejection

When:

```text
arithmetic_currency_proof.AuthorizeArithmeticCurrencyProof proof = 0
```

the result contains:

```text
state = "error"
posting_rows = ⟨⟩
diagnostics = ⟨
  {
    severity = "error"
    stage = "authorization"
    code = "arithmetic_currency_proof_rejected"
    message = arithmetic_currency_proof.ArithmeticCurrencyAuthorizationMessage proof
  }
⟩
```

### Structural mismatch

When authorization succeeds but evidence length differs from normalized-coefficient length, the result contains:

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

## Compatibility wrapper

`BuildAuthorizedRowsFromSnapshot` preserves the externally visible compatibility contract:

```text
success
  -> {
       rows = result.posting_rows
       arithmetic_currency_proof = result.arithmetic_currency_proof
     }

error
  -> print "ERROR: " + first diagnostic.message
  -> exit 1
```

Terminal ownership is local to `src_next/context.bqn` through `AuthorizedRowsFromCheckedResult`.

The wrapper preserves:

- the success return shape;
- exact fatal message content after the `ERROR: ` prefix;
- exit code `1` for checked-result failure;
- no additional stdout on success.

`SourceFromSnapshot` remains a separate compatibility guard for unsupported or missing selected source files. Its terminal effects are not part of the pure checked projection.

## Arithmetic-proof ownership

The live proof API is owned by `src_next/arithmetic_currency_proof.bqn`:

```text
AuthorizeArithmeticCurrencyProof
ArithmeticCurrencyAuthorizationMessage
```

The first returns the admission decision. The second returns data-only diagnostic text. `src_next/context.bqn` imports this owner directly for checked-result admission.

`src_next/projection.bqn` temporarily preserves the same two public names as compatibility delegates. It does not independently define the accepted basis/domain/scale policy or rejection messages.

The former effectful `RequireArithmeticCurrencyProof` wrapper was removed after repository characterization found no runtime or focused-test caller. It is not part of the current contract. Process output and exit behavior remain preserved by the outer compatibility wrapper in `context.bqn`.

## Purity boundary

`BuildCheckedPostingProjectionFromSnapshot` and its prepared helper must not:

- read source files;
- call `•Out`;
- call `•Exit`;
- read system time or environment state;
- accept a proof detached from the supplied evidence;
- construct Cube or TBDS;
- render reports or JSON;
- apply household or envelope policy;
- mutate Journal or TSV sources.

Current ownership is:

```text
I/O adapters
  -> load source snapshots, cycle data, and accounts

pure checked posting builder
  -> evidence, arithmetic, proof, admission, Posting IR, diagnostics

compatibility wrappers
  -> terminal rendering and process exit

projection consumers
  -> Cube, TBDS, reports, queries, policy, and exports
```

## Row-level boundary

Aggregate checked-result failure and Posting IR row status remain distinct:

```text
arithmetic-currency proof rejected
  -> aggregate error, no posting rows

normalized coefficient length mismatch
  -> aggregate error, no posting rows

unknown account / invalid amount / invalid date
  -> Posting IR row status
  -> not automatically an aggregate error
```

This contract does not change Cube acceptance, skipped-row handling, source-balance validation, report policy, or selected-domain behavior.

## Verification surfaces

Current direct and compatibility evidence includes:

- `tests/test_src_next_checked_posting_projection.bqn`;
- `tests/test_src_next_currency_domain_proof.bqn`;
- `checks/check-src-next-checked-posting-projection.sh`;
- `checks/check-projection-compatibility-exports.sh`;
- the complete repository gate `tools/check.sh`;
- Coverage and GitHub Actions.

The focused checked-result tests cover success, proof rejection, malformed or unsupported evidence, mixed-domain rejection, structural mismatch, and Posting IR row-status parity. The compatibility check preserves stdout and exit behavior at the outer wrapper.

## Non-goals

This boundary does not introduce:

- a generic projection framework;
- a universal event type;
- a Currency axis;
- currency conversion, valuation, or rounding policy;
- a source-format migration;
- changed Posting IR fields or status meanings;
- changed Cube or TBDS axes;
- changed report or JSON schemas;
- broad decomposition of `context.bqn`.

Git history and the archived headless-kernel records retain the earlier design-phase sequence. This file describes the implemented current boundary.

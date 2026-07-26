# Arithmetic-currency proof ownership inventory — P5a — 2026-07-26

Status: completed read-only ownership inventory
Owner: architecture / checked non-Actual Posting IR admission
Canonical: no; current runtime modules and current contracts remain authoritative
Baseline main: `9b69729f74063ee8b87959d9249dc02331266d2f`
Tracking: Issue #407
Exit: retain as the decision record for the bounded P5b ownership move

## Finite question

> Where should the live arithmetic-currency proof authorization predicate and rejection-message builder be owned, and what is the smallest reversible move that makes `context.bqn` depend directly on that owner without changing proof policy, checked-result failure order, diagnostics, terminal behavior, Posting IR, or currency admission?

This inventory changes no runtime code. It does not authorize correctness changes or broader currency redesign.

## Current state

`src_next/projection.bqn` currently owns:

- the accepted proof-basis vocabulary;
- proof field access with missing-field fallbacks;
- non-negative integer scale validation;
- `AuthorizeArithmeticCurrencyProof`;
- `ArithmeticCurrencyAuthorizationMessage`.

Those definitions use `currency_setup.IsSupportedCurrency`. This is the only reason the current proof block needs currency policy.

`src_next/context.bqn` currently owns:

- row evidence construction;
- `ResolveArithmeticCurrencyProof`, which constructs the five-field proof carrier;
- `BuildCheckedPostingProjectionFromPrepared`, which authorizes that proof;
- the authorization diagnostic carrier;
- first-failure order;
- the no-partial-posting-rows result rule;
- the outer compatibility wrapper that preserves fatal stdout and exit behavior.

`src_next/currency_arithmetic.bqn` owns arithmetic evidence construction and exact coefficient normalization. Its header explicitly excludes projection authorization and posting-row construction.

The current contract records this split directly:

```text
Runtime owner: context.bqn
Proof predicate/message owner: projection.bqn
```

## Current caller graph

Repository search and current-main inspection found this executable shape:

```text
currency_setup.bqn
  -> IsSupportedCurrency

projection.bqn
  -> AuthorizeArithmeticCurrencyProof
  -> ArithmeticCurrencyAuthorizationMessage

context.bqn
  -> ResolveArithmeticCurrencyProof
  -> projection.ArithmeticCurrencyAuthorizationMessage
  -> projection.AuthorizeArithmeticCurrencyProof
  -> checked result / structured diagnostic

focused proof test
  -> context proof construction and checked paths
  -> projection proof predicate/message directly
```

No second runtime caller of the predicate or message builder was found. Historical and current documents mention the names, but archived records are observations rather than runtime owners.

Repository search cannot prove that no external clone imports the public `projection.bqn` fields. Therefore P5b should preserve those two exports as compatibility delegates rather than delete them.

## Responsibility boundary

| Responsibility | Current owner | Selected owner after P5b |
|---|---|---|
| source row currency evidence | `context.bqn` | unchanged |
| exact arithmetic normalization | `currency_arithmetic.bqn` | unchanged |
| proof carrier construction | `context.bqn` | unchanged |
| accepted basis/domain/scale authorization policy | `projection.bqn` | `arithmetic_currency_proof.bqn` |
| rejection message construction | `projection.bqn` | `arithmetic_currency_proof.bqn` |
| checked-result admission and failure order | `context.bqn` | unchanged, with direct owner import |
| fatal stdout / exit compatibility | `context.bqn` wrapper | unchanged |
| old public proof fields on `projection.bqn` | independent definitions | temporary delegates only |

## Options considered

### Option A — move the definitions into `context.bqn`

This is semantically close to the checked admission boundary, but it cannot preserve the current `projection.bqn` compatibility exports without one of two defects:

1. `projection.bqn` imports `context.bqn`, while `context.bqn` still imports `projection.bqn` for live non-proof Posting IR helpers, creating an import cycle;
2. the proof rules remain duplicated in both modules, creating two semantic owners and a drift risk.

Removing the compatibility exports in the same slice would avoid the cycle, but would combine ownership movement with a public-surface deletion whose external consumers cannot be fully observed.

Conclusion: reject for P5b.

### Option B — add `arithmetic_currency_proof.bqn` as the pure owner

The module would own exactly:

- accepted proof bases;
- proof field fallback accessors;
- non-negative integer scale validation;
- `AuthorizeArithmeticCurrencyProof`;
- `ArithmeticCurrencyAuthorizationMessage`.

Its only required repository dependency is `currency_setup.bqn`, because supported-domain policy remains authoritative there.

Then:

```text
context.bqn
  -> import arithmetic_currency_proof.bqn directly

projection.bqn
  -> import arithmetic_currency_proof.bqn
  -> retain the two public names as delegates
```

This creates no cycle, preserves one implementation, keeps external compatibility, and removes the proof-policy reason for `projection.bqn` to import `currency_setup.bqn` directly.

Conclusion: select for P5b.

### Option C — move authorization into `currency_arithmetic.bqn`

`currency_arithmetic.bqn` currently transforms row evidence into arithmetic evidence and explicitly excludes authorization. Proof authorization validates a later five-field carrier, including proof state and basis provenance that are not arithmetic-normalization responsibilities.

Conclusion: reject. It would blur evidence construction with admission policy.

## Selected P5b implementation slice

P5b should be one coherent ownership move with these files:

1. add `src_next/arithmetic_currency_proof.bqn`;
2. update `src_next/context.bqn` to import the owner directly and replace only the two qualified proof calls;
3. update `src_next/projection.bqn` to delegate the two existing exports to the owner and remove its independent proof definitions/private proof helpers;
4. update `tests/test_src_next_currency_domain_proof.bqn` so focused predicate/message assertions import the owner directly;
5. preserve a narrow compatibility assertion or static guard for the projection delegates without treating projection as the proof contract;
6. update `docs/PURE_CHECKED_POSTING_PROJECTION_RESULT_CONTRACT.md` to name the new owner and direct runtime flow;
7. update `checks/check-projection-compatibility-exports.sh` to pin the new ownership and reject duplicate definitions or regression to qualified runtime calls.

No other runtime caller migration is required by current repository evidence.

## Required P5b guard shape

The ownership guard should establish at least:

- the new owner imports `currency_setup.bqn` and does not import `projection.bqn` or `context.bqn`;
- the owner defines and exports both live functions;
- `context.bqn` imports the owner and calls it directly;
- `context.bqn` retains its live `projection.bqn` import for non-proof helpers;
- `projection.bqn` imports the owner and delegates both compatibility exports;
- `projection.bqn` no longer independently defines the accepted bases, proof accessors, scale predicate, authorization predicate, or message builder;
- focused proof tests import the owner directly and contain no `proj.AuthorizeArithmeticCurrencyProof` or `proj.ArithmeticCurrencyAuthorizationMessage` calls;
- the removed effectful `RequireArithmeticCurrencyProof` wrapper does not return.

## Semantics and strings that must remain byte-for-byte compatible

P5b is an ownership refactor. It must preserve:

- allowed bases and their order-independent membership meaning;
- JPY compatibility behavior;
- supported non-JPY requirement for `resolved_single_currency`;
- `empty_source_compatibility` requiring `amount_scale = 0`;
- missing-field fallback behavior;
- non-proof input rejection;
- non-negative integer scale validation;
- all current rejection messages;
- proof rejection before normalized-coefficient length mismatch;
- authorization diagnostic stage, code, severity, and message;
- `posting_rows = ⟨⟩` on aggregate error;
- existing `ERROR: ` prefix and exit behavior in the outer compatibility wrapper.

## Explicitly out of scope

P5b must not change:

- `ResolveArithmeticCurrencyProof` construction rules;
- proof carrier fields or values;
- `currency_arithmetic.Build`;
- `currency_setup.bqn`, registry contents, or supported-currency policy;
- source currency parsing or source admission;
- selected-domain stage order;
- native Journal currency admission;
- exact-decimal parsing or normalization;
- Posting IR fields, identity, ordering, debit/credit semantics, or row statuses;
- Layer, Cube, TBDS, reports, diagnostics outside the proof-owner qualification, or amount semantics;
- `projection.bqn` proof compatibility export names;
- any other remaining `projection.bqn` responsibility.

## Rollback boundary

P5b has one rollback point: revert the new owner and restore the current independent proof block in `projection.bqn` plus its two direct callers. No data migration or output-contract migration is involved.

## Validation required for P5b

- focused arithmetic-currency proof tests;
- checked-result structural mismatch and first-failure tests;
- fatal wrapper stdout/exit parity checks already in the repository gate;
- projection ownership static guard;
- full `tools/check.sh`;
- Coverage;
- final PR patch review before Ready and squash merge.

## Next finite slice

> P5b: establish `src_next/arithmetic_currency_proof.bqn` as the single pure owner, give `context.bqn` direct ownership access, preserve `projection.bqn` as a compatibility delegate, migrate focused tests and the current contract, and change no proof policy or checked-result semantics.

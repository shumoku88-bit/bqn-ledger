# Funding Scope review observation — 2026-08-12

## Decision

`src/application/funding_scope.bqn` is retired rather than rewritten.

## Evidence

At the Phase 5 cursor, repository-wide reference search found no production consumer of the module. The remaining references were:

- its dedicated characterization test;
- the aggregate check that invoked that test;
- review queue/documentation text.

The dedicated test itself still constructed Account evidence from the legacy `accounts.tsv` shape through `src/ledger/account_admission.bqn`; no canonical Household application path consumed the result.

Envelope Backing does not depend on this capability. Its retained accounting owner resolves Backing-pool Account keys directly from admitted `budget.toml` / `household.toml` policy against the current Facts Account axis. That ownership contract is already independently qualified.

## Subtraction

The review therefore removes:

- `src/application/funding_scope.bqn`;
- `tests/test_application_funding_scope.bqn`;
- the aggregate check invocation for that characterization test.

Active Envelope Backing documentation is updated to record the retirement.

No accounting arithmetic, Envelope ownership, source admission, Report surface, canonical Household source, or writer authority changes.

## Classification

**RETIRE DEAD APPLICATION SURFACE.**

A future feature that needs an explicit funding-account selection capability should introduce it from an actual consumer and current canonical Account evidence rather than reviving this unreferenced legacy-shaped owner.

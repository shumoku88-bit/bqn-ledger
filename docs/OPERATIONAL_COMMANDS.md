# Destination operational commands

Status: production; readiness and inspection are separate from the report catalog.

## Why these are not reports

Source admission/readiness and Fact inspection are operational questions. They do not belong in the twelve-key accounting report catalog, human `all`, compact summary, JSON dispatch, or section cache.

Neither command imports `src/sections`, the retired report runtime, report composition, a clock, or cache code.

## `tools/ledger-check`

Usage:

```text
tools/ledger-check BASE
```

`BASE` is the canonical Household root. No physical source basename is a command coordinate.

The command requires and strictly admits the canonical eight-file source set:

- `accounts.journal` for Account identity/type/default Commodity;
- `actual.journal` for Actual transactions and relations;
- `plan.journal` for Plan transactions and lifecycle evidence;
- `budget.journal` for ordered Budget movement evidence;
- `budget.toml` for Budget policy;
- `household.toml` for Household classification, Cycle, and Daily Target policy;
- `report.toml` for Report query and presentation policy;
- `issues.tsv` for the Household notebook.

The repository-owned `config/currencies.tsv` remains the currency registry. It is application configuration, not a ninth Household source.

Success prints implementation-neutral operational counts and exits zero. Any invalid canonical source exits nonzero with admission stage/code and prints no `state ok` line. The command does not calculate balances or render a report; individual report requests still validate their temporal/domain joins at execution.

## `tools/ledger-inspect`

Usage:

```text
tools/ledger-inspect BASE
```

This command strictly admits canonical Actual Facts from `accounts.journal` + `actual.journal` and prints source-qualified Transaction and Posting identities, Account keys, exact coefficients, and scales. The output is explicitly non-authoritative diagnostic text, not a compact or JSON schema.

Inspection can expose details from the supplied Household root. Public fixtures are safe for committed proofs. Running it against private household data requires the user's explicit command/direction; its output must not be committed to public fixtures or reports.

## Boundary

- operational commands accept one canonical root, not caller-selected source files;
- report keys/cache/metadata remain separate from `check` and `inspect`;
- development repository checks stay under `tools/check.sh`, distinct from source-facing `tools/ledger-check`.

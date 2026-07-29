# Destination operational commands

Status: production; readiness and inspection are separate from the report catalog.

## Why these are not reports

Source admission/readiness and Fact inspection are operational questions. They do not belong in the nine-key accounting report catalog, human `all`, compact summary, JSON dispatch, or section cache.

Neither command imports `src/sections`, the retired report runtime, report composition, a clock, or cache code.

## `tools/ledger-check`

Usage:

```text
tools/ledger-check BASE JOURNAL PLAN BUDGET CYCLE ISSUES DAILY_SCOPE
```

The wrapper requires explicit safe basenames and readable Config, Accounts, and supplied sources. The BQN owner strictly admits:

- currency registry and `config.tsv`;
- Accounts/Actual canonical Facts;
- all-or-nothing Plan/Budget Facts;
- unresolved Cycle definition;
- destination Issues;
- Daily Target ownership/linkage rows.

Success prints implementation-neutral operational counts and exits zero. Any invalid source exits nonzero with admission stage/code and prints no `state ok` line. It does not resolve a cycle, calculate balances, render a report, or claim that every possible report coordinate is available. Individual report requests still validate temporal/domain/ownership joins at execution.

## `tools/ledger-inspect`

Usage:

```text
tools/ledger-inspect BASE JOURNAL
```

This command strictly admits canonical Actual Facts and prints source-qualified Transaction and Posting identities, Account keys, exact coefficients, and scales. The output is explicitly non-authoritative diagnostic text, not a compact or JSON schema.

Inspection can expose details from the explicitly selected ledger. Public fixtures are safe for committed proofs. Running it against private household data requires the user's explicit command/direction; its output must not be committed to public fixtures or reports.

## Cutover

At atomic cutover:

- remove report keys/cache/metadata/labels `check` and `debug`;
- retain these operational commands under their implementation-neutral names;
- remove old readiness compact keys and inline debug renderer rather than forwarding them;
- keep development repository checks under `tools/check.sh`, distinct from source-facing `tools/ledger-check`.

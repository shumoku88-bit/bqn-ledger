# Extension Boundary

Status: current design boundary / docs-only

This document defines where BQN Ledger may be extended without weakening the canonical ledger/report engine.

The goal is not to introduce a dynamic plugin system. The goal is to keep the core predictable while allowing downstream tools, views, and adapters to grow around it.

## Decision

BQN Ledger does not make the canonical engine pluggable at this stage.

Extensions may consume canonical machine exports and report outputs. Extensions must not become part of source TSV interpretation, Posting IR construction, Canonical Daily Cube construction, TBDS/report semantics, or source TSV mutation.

In short:

```text
base directory TSV / config TSV
  -> BQN canonical engine
  -> canonical report / machine exports
  -> optional read-only adapters and downstream tools
```

The extension point is downstream of canonical output, not inside canonical meaning.

## Non-pluggable core

The following areas are not plugin surfaces:

- source TSV meaning and the first five-column journal-like contract
- `accounts.tsv` role interpretation
- `budget_alloc.tsv` / envelope semantics
- `cycle.tsv` boundary interpretation
- `plan.tsv` completion semantics
- Posting IR construction
- TBDS semantics
- Canonical Daily Cube shape
- Canonical Daily Cube layer meanings
- section status semantics (`OK / WARN / ERROR / SKIPPED / UNAVAILABLE`)
- direct writes to base directory source TSV

These are part of the engine contract. Changing them should be treated as a core design change, not an extension.

## Allowed extension surfaces

Extensions may be built around stable outputs and explicit user actions.

Allowed examples:

- read machine exports from `tools/report-next-summary`, `tools/query`, or other documented exporters
- read human report output from `tools/report` for display-only transformations
- transform canonical exports into Markdown, CSV, JSON, charts, or public summaries
- create anonymized public reports from already-generated output
- create visualization tools for cycle, envelope, trend, or liquid asset summaries
- provide alternate input UI that delegates writes to approved write paths
- create local-only scripts under `tools/`, `moko/`, or separate repositories

These extensions must be replaceable. Removing an extension must not make the canonical report unreliable.

## Disallowed extension surfaces

Do not add extension points that:

- reinterpret source TSV rows before BQN validation
- change account roles or budget mapping from outside the source/config TSV contracts
- inject custom cycle logic into canonical reports
- change Posting IR, TBDS, Cube axes, or layer meanings
- make report correctness depend on a plugin being installed
- let AI or helper scripts directly mutate source data without the approved write path
- silently recover from invalid data in an extension before the core sees it

A downstream tool may fail, warn, or produce its own optional output. It must not make the core produce a pretty wrong report.

## Read-only adapter pattern

Prefer read-only adapters over plugins.

```text
canonical export
  -> adapter
  -> optional view / artifact / external system
```

Example future layout:

```text
tools/adapters/
  make-public-report.sh
  make-youtube-safe-summary.sh
  plot-cycle-trend.go
  export-tax-candidate.sh
```

The exact directory is not yet a required contract. The design principle is that adapters read from exported values and do not own accounting meaning.

## Write path rule

An extension that needs to write source data must not write TSV directly.

Allowed write paths:

- human-reviewed direct TSV editing
- existing approved editor path such as `tools/edit`
- a future editor path that explicitly preserves preview, confirm, backup, stale check, and post-check lint

Large write-scope changes require their own design record before implementation.

## Public sandbox and real data

The public repository may contain sandbox `data/` and fixtures. Real household data is selected through `LEDGER_DATA_DIR` or an explicit base directory and must stay outside the public repository.

Adapters must respect that boundary:

- do not assume public `data/` is real user data
- do not publish values from `LEDGER_DATA_DIR` unless the user explicitly generated a public/anonymized output
- do not cache private source TSV into tracked files

## Future stages

Possible staged growth:

1. No plugin system. Keep current core and exports stable.
2. Add read-only adapters around machine exports.
3. Add documented adapter examples for public summaries, charts, or tax-candidate exports.
4. Consider static report-section registration only after section contracts are stable.
5. Reconsider dynamic plugins only if repeated real adapters prove a narrow, safe interface.

Dynamic plugin APIs are intentionally out of scope for now.

## AI working rule

When an AI agent proposes a plugin, first classify the proposal:

- Does it read canonical output only?
- Does it change source TSV meaning?
- Does it change Posting IR, TBDS, or Cube construction?
- Does it write source data?
- Does it make canonical report correctness depend on optional code?
- Does it expose real `LEDGER_DATA_DIR` data?

If the answer touches source meaning, Posting IR/TBDS/Cube construction, direct writes, or private data exposure, treat it as a core design change or reject it for this repository.

## Relationship to Safety Profile and Quality Bar

This boundary supports the Safety Profile and Quality Bar by preserving deterministic reports, fail-closed behavior, source TSV protection, and the BQN-only canonical report path.

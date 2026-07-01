# Structured UI Export Contract Plan

Status: active plan / docs-only
Date: 2026-07-01

## Intent

Define the Phase 2 export boundary for UI tools before expanding shell / `gum` /
`fzf` presentation flows.

The repo already has the engine shape needed for this boundary:

```text
source TSV
  -> Posting IR
  -> Canonical Daily Cube
  -> TBDS
  -> report/view models
  -> Format / FormatHuman
```

The gap is not terminal styling in BQN. The gap is a stable structured export
surface that lets UI tools display and select BQN-owned meanings without parsing
human report strings or re-deriving household/accounting rules from source TSV.

## Scope of this PR

This PR is intentionally documentation-only.

In scope:

- add `docs/STRUCTURED_UI_EXPORT_CONTRACT.md`
- add this dated active plan
- clarify the BQN / shell / UI boundary for future work
- preserve the daily human report path as canonical for reading

Out of scope:

- implementing JSON export
- retiring `FormatHuman`
- changing `tools/report` behavior
- changing source TSV format
- changing BQN calculation logic
- changing CLI behavior
- changing `gum` / `fzf` flows

## Boundary decision

### Human report remains the reading path

Human report output is still canonical for daily reading. `FormatHuman` remains
valid and should not be removed as part of the structured export work.

### Structured exports are UI input contracts

Future UI tools should consume explicit BQN exports for candidates, statuses, and
metadata.

UI tools must not parse human report text. They also must not re-derive
accounting or household semantics from `accounts.tsv`, `journal.tsv`, `plan.tsv`,
or `budget_alloc.tsv`.

### BQN exports meanings; shell displays them

BQN should export structured candidates/statuses for shell, `gum`, `fzf`, or a
future viewer to display.

Shell/UI may:

- choose rows
- filter rows
- render labels
- add colors or layout
- call existing commands

Shell/UI must not:

- infer accounting semantics from source TSV
- infer household policy from source TSV
- parse report prose or aligned tables as a data API
- depend on terminal styling embedded in BQN output

## First implementation candidates

Future implementation PRs should be small and independent. Suggested first
exports:

1. **Account candidates**
   - Build from BQN-owned account interpretation.
   - Useful for add/edit UI account pickers.

2. **Unfinished plan entries**
   - Export rows suitable for selecting a plan to finish, inspect, or replenish.
   - Include stable IDs/statuses where available.

3. **Envelope / budget candidate rows**
   - Export envelope rows and semantic status without shell-side envelope logic.

4. **Validation / readiness summary**
   - Export severity/status/rule summaries for UI dashboards and command hubs.

5. **Report section list and metadata**
   - Export section keys, labels, categories, and supported output modes.
   - First slice implemented as `tools/report-section-metadata` backed by
     `src_next/report_section_metadata.bqn` with TSV output.

Each candidate should be implemented in its own PR with its own contract/checks.

## Format decision left open

No single output format is selected here.

Use the simplest appropriate format per export:

- TSV for simple rectangular candidate tables
- JSONL for row streams with optional fields
- JSON for nested view models or metadata

Do not implement JSON merely because this plan exists. Choose JSON only when the
export needs nested structure or explicit typed states that TSV would make
fragile.

## Acceptance criteria

For this docs-only PR:

- docs only
- no runtime behavior changes
- no source TSV changes
- no report calculation changes
- no CLI behavior changes
- future implementation PRs can be sliced one export at a time

For later implementation PRs:

- one export surface per PR where practical
- documented command/module entry point
- documented fields and status words
- fixture or check coverage for the new contract
- no UI parsing of human report strings
- no shell reimplementation of accounting or household semantics

## First slice: report section metadata

Implemented surface:

```text
tools/report-section-metadata
```

Backed by:

```text
src_next/report_section_metadata.bqn
```

Output format: TSV.

Fields:

```text
key	label	category	owner	human_output	structured_output
```

This slice intentionally does not make `tools/main-ui.sh` consume the new export
yet. The export contract is established first; UI adoption can be a later small
PR.

## PR text

Title:

```text
docs: define structured UI export contract
```

Summary:

- add docs-only contract for structured UI exports
- clarify BQN/shell boundary before expanding gum UI
- keep human report path intact

Verification:

- Not run. Docs-only.

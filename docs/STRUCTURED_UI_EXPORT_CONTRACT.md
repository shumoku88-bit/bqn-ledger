# Structured UI Export Contract

Status: contract draft / docs-only
Date: 2026-07-01

## Purpose

This document defines the Phase 2 boundary for structured exports used by UI tools.
It is a contract direction, not an implementation plan for this PR.

The current engine already has the important internal boundaries:

```text
source TSV
  -> Posting IR
  -> Canonical Daily Cube
  -> TBDS
  -> section ViewModels
  -> Format / FormatHuman
```

The remaining UI problem is not that BQN needs to learn terminal styling. The
remaining problem is that UI tools do not yet have a stable structured export
surface for the data they should display, filter, or choose from.

## Current stance

Human report output remains canonical for daily reading.

- `tools/report` and the `src_next/report.bqn` human report path remain intact.
- `FormatHuman` remains the human renderer for report sections.
- Plain human output is still the default way to read the ledger.
- This contract does not retire or replace human report output.

UI tools need structured inputs, but they must not scrape human prose or tables.
Human text can change for readability; UI protocols should only change when an
export contract changes.

## Non-goals for this contract

This document does not require, authorize, or imply the following changes:

- no JSON export implementation in this PR
- no retirement of `FormatHuman`
- no changes to `tools/report` behavior
- no source TSV format changes
- no BQN calculation logic changes
- no CLI behavior changes
- no new dependency on `gum`, `fzf`, or any terminal UI tool for report generation

## Boundary rules

### BQN owns meaning

BQN remains the owner of source TSV validation, accounting meaning, household
semantics, calculations, and semantic statuses.

Structured UI exports should be produced from BQN-owned interpretation, not by
re-deriving meaning in shell.

### UI owns presentation

Shell, `gum`, `fzf`, and future UI tools own display, selection, prompting,
layout, colors, preview panes, and navigation.

UI tools may transform a structured row into a menu label, but they must not
interpret source TSV accounting or household semantics.

### Human report strings are not an API

UI tools must not parse human report strings.

In particular, UI tools must not:

- grep report prose to discover semantic status
- split aligned report tables to recover numbers
- infer overdue/due/completed state from Japanese or English labels
- parse colored or styled terminal output
- depend on `FormatHuman` wording or spacing

If a UI needs a value, candidate list, status, or section metadata, BQN should
export that value through an explicit structured surface.

## First export candidates

Future implementation PRs should be sliced one export at a time. The first useful
candidate surfaces are:

1. **Account candidates**
   - account key / display label
   - optional role or category when BQN already owns that meaning
   - disabled or unavailable state if relevant

2. **Unfinished plan entries**
   - stable plan identity where available
   - due date, memo, from, to, amount
   - status words such as `due`, `overdue`, `future`, `completed` when applicable
   - enough fields for a UI to choose a plan without parsing report text

3. **Envelope / budget candidate rows**
   - envelope account key / label
   - current semantic status word
   - budget, spent, remaining, or unavailable fields as exported values
   - no shell-side reimplementation of envelope rules

4. **Validation / readiness summary**
   - machine-readable severity and rule keys
   - summary counts
   - unavailable/skipped/error status where the engine cannot safely compute

5. **Report section list and metadata**
   - section key
   - display label
   - category or grouping if provided by BQN/config
   - whether the section supports human output, structured output, or both

   Current first slice: `tools/report-section-metadata` exports this metadata as
   TSV from `src_next/report_section_metadata.bqn`. It does not read source TSV
   or change `tools/report` behavior.

Existing exports such as editor candidate commands and report section listing are
part of the current direction, but this contract does not change their CLI shape.

## Output format remains open

The export surface should choose the smallest format that preserves the needed
structure and stability. The format is not fixed by this document.

Likely choices:

- **TSV** for simple rectangular candidate tables
- **JSONL** for row streams with optional fields
- **JSON** for nested report view models or section metadata

Format selection should happen per export. Do not choose JSON for every surface
only because some future UI may want it; also do not force TSV where nested data
or explicit null/unavailable states are part of the contract.

Each implementation PR should document the concrete format, fields, status words,
and compatibility expectations for that export.

## Compatibility expectations

Structured exports are UI contracts. Once introduced, they should be more stable
than human report wording.

A structured export should define:

- command or module entry point
- source of truth module
- output format
- required fields
- optional fields
- semantic status words
- ordering guarantees, if any
- unavailable/error representation
- intended UI consumers

Breaking a structured export should be treated as a contract change, not a
presentation tweak.

## Acceptance criteria for this docs-only step

- docs only
- no runtime behavior changes
- no source TSV changes
- no report calculation changes
- no CLI behavior changes
- future implementation PRs can be sliced one export at a time

## Related documents

- `docs/ARCHITECTURE.md` — engine and presentation boundary
- `docs/AI_CODEMAP.md` — current code map and data flow
- `docs/POSTING_IR_CONTRACT.md` — Posting IR boundary
- `docs/TBDS_CONTRACT.md` — TBDS boundary
- `docs/REPORT_SECTION_CONTRACT_CHECKLIST.md` — report section contract checklist
- `src_next/report_section_metadata.bqn` / `tools/report-section-metadata` — first structured report section metadata export
- `checks/check-report-section-metadata.sh` — contract check for the first export slice
- `docs/archive/active-plans/STRUCTURED_UI_EXPORT_CONTRACT-2026-07-01.md` — dated active plan

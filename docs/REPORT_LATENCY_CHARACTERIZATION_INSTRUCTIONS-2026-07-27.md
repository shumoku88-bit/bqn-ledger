# Report latency characterization instructions

Prepared: 2026-07-27  
Repository: `shumoku88-bit/bqn-ledger`  
Fixed starting point: `main` at `a826a833799a0e75328ae7aeb794fe44c9018cf2`

## 1. Purpose

Characterize the delay experienced when opening the Command Hub, choosing the report-section flow, and waiting for report selection or display.

This is a performance-observation task, not authorization to optimize the report engine immediately.

The work must determine where elapsed time is spent before choosing an implementation slice. Do not treat the current cache design, BQN import count, `BuildContext`, or any individual report builder as the cause until measurements support that conclusion.

## 2. User-observed symptom

The user reports that:

- the Command Hub opens;
- after choosing report-section browsing, several seconds may pass;
- the delay now feels disproportionate for an everyday local household-ledger tool;
- the concern is not only speed but software shape: choosing one report should not silently require unrelated work unless that work is justified and visible.

Preserve this as the product-level observation. Do not reduce the question to a microbenchmark without relating results back to perceived interaction latency.

## 3. Current-main code path to verify before measuring

Re-read these files from the current `main`; do not rely only on this document:

- `tools/bl`
- `tools/main-ui.sh`
- `tools/report`
- `tools/report-section-metadata`
- `src_next/report.bqn`
- `src_next/context.bqn`

At the fixed starting point, the observed route is approximately:

```text
tools/bl
  -> section
  -> tools/main-ui.sh --base <base> select
  -> cache validity check
  -> tools/report <base> --write-section-cache <dir> when stale
  -> bqn src_next/report.bqn
  -> BuildContext
  -> BuildSectionEntries
  -> write all section files
  -> open selector
  -> display selected cached section
```

Also verify the direct-section route:

```text
tools/main-ui.sh --base <base> <section-key>
  -> tools/report <base> --section <section-key>
  -> src_next/report.bqn
```

At the fixed starting point, ordinary human section requests appear to build the common context and then construct the complete section-entry collection before selecting one entry. Human balances has an earlier specialized dispatch and must be measured separately rather than assumed equivalent.

These are hypotheses from static inspection. Confirm the live files and actual execution behavior.

## 4. Finite characterization question

> Where is user-visible elapsed time spent between entering report-section browsing and seeing usable report output, under cold-cache and warm-cache conditions, and which currently unrelated computations are performed for a selected report?

Answer this question before proposing an optimization.

## 5. Non-goals

Do not, in the characterization slice:

- change report text, ordering, labels, colors, pagination, or selector behavior;
- change diagnostics, stdout/stderr routing, or exit status;
- change native Journal parsing, source admission, provenance, or persistence;
- change Posting IR fields, identity, row order, debit/credit semantics, status, or messages;
- change exact arithmetic, currency proof, or selected-domain failure order;
- change Layer indices, names, or source routing;
- change Cube, TBDS, sparse-view, envelope, budget, cycle, or report semantics;
- introduce a persistent cache format;
- add background refresh, daemon processes, concurrency, or speculative execution;
- remove previews merely because they are suspected to be expensive;
- optimize BQN imports without evidence that import time is material;
- combine characterization and optimization in one PR;
- commit private household data, absolute personal paths, report contents, account names, amounts, or Journal excerpts.

## 6. Work gate

Before editing anything:

1. Fetch the latest remote `main` SHA.
2. Confirm open PRs and active branches relevant to report UI or performance.
3. Confirm the working tree is clean.
4. Re-read the files listed in section 3.
5. Search current code and tests for:
   - `--write-section-cache`
   - `BuildSectionEntries`
   - `BuildContext`
   - `show_section_direct`
   - `select_section`
   - `report-section-metadata`
6. Record the exact data and code files used by cache invalidation.
7. Do not start from a stale local branch.

If `main` has moved, record the new SHA and reassess the code path before proceeding.

## 7. Privacy and measurement environments

Use two distinct environments where possible.

### 7.1 Reproducible repository fixture

Use an existing public fixture or construct a synthetic fixture containing no private household information. This measurement can be committed or described precisely.

### 7.2 Local daily-use data

The user may run private local measurements to establish whether data volume changes the result. Never commit:

- source records;
- rendered report text;
- account names;
- amounts;
- absolute home-directory paths;
- filenames that disclose private information.

Only report privacy-safe aggregates such as:

- rounded elapsed time;
- transaction count;
- posting count;
- plan-row count;
- section count;
- cold versus warm classification.

If even these aggregates feel sensitive, keep them in the terminal session and report only qualitative differences.

## 8. Measurement rules

Use wall-clock elapsed time as the primary user-facing measure. CPU time and process counts may be supplementary.

For each automated measurement:

- run at least five times after one untimed preparation run;
- report median and range, not only the fastest result;
- use the same base directory and environment within a comparison;
- disable color only when necessary for stable non-interactive capture;
- keep stdout payload out of timing logs where practical;
- distinguish process startup from report computation;
- distinguish cold cache from warm cache explicitly;
- record the exact command;
- record whether the command invoked an interactive selector;
- avoid benchmarking while CI, package installation, or other heavy processes are running.

`hyperfine` may be used if available. `/usr/bin/time -p` is sufficient. Do not add a new repository dependency merely for benchmarking.

## 9. Required observations

### 9.1 Command Hub entrance

Determine whether `tools/bl` itself is slow before report-section selection.

Observe separately:

- shell startup and theme initialization;
- main menu appearance;
- the transition after choosing `section`.

Do not attribute post-selection delay to Command Hub startup if the menu itself is immediate.

### 9.2 Cache invalidation scan

Measure or account for:

- resolving the actual Journal filename through BQN;
- scanning data-source modification times;
- finding `src_next/*.bqn` files;
- reading platform-specific file mtimes;
- calculating the maximum source mtime;
- checking the cache timestamp and sentinel file.

Determine whether this scan is material on its own.

### 9.3 Cold section-cache generation

Using an isolated temporary cache directory, measure:

```text
tools/report <base> --write-section-cache <cache-dir> --no-color
```

Record:

- total elapsed time;
- number of section files written;
- whether `BuildContext` occurs once;
- which report builders run;
- whether full human formatting runs for every section;
- whether any section dominates elapsed time.

Do not delete or disturb the user's ordinary cache for measurement. Prefer a temporary directory.

### 9.4 Warm selector path

With a valid existing cache, characterize the time from entering section browsing to selector availability.

Separate:

- cache validation;
- section metadata generation;
- fzf/gum startup;
- preview file access.

If precise automated TTY timing is awkward, use a small opt-in diagnostic wrapper or manual timestamp observation in the characterization branch. Do not alter normal output by default.

### 9.5 Direct selected sections

Measure representative direct requests independently:

```text
tools/report <base> --section snapshot --no-color
tools/report <base> --section cycle --no-color
tools/report <base> --section outlook --no-color
tools/report <base> --section daily-trend --no-color
tools/report <base> --section balances --no-color
```

Include:

- one simple section;
- one section using cycle or expense-derived information;
- one likely heavier forward-looking section;
- human balances, because its dispatch differs.

Determine whether an ordinary selected section executes builders for unrelated sections before selecting its output.

### 9.6 Full report

Measure the full report separately:

```text
tools/report <base> --no-color
```

The full report is allowed to build all sections. Its timing is a reference, not necessarily a defect.

### 9.7 BQN process startup and imports

Measure a minimal BQN startup/import baseline only to establish scale. Do not infer from the number of imports alone.

The characterization should answer whether import/startup time is:

- dominant;
- noticeable but secondary;
- negligible compared with context and section construction.

### 9.8 Context construction versus section construction

Find a minimally invasive way to separate:

- BQN process startup/import evaluation;
- `BuildContext`;
- shared precomputation inside `BuildSectionEntries`;
- each section builder and formatter;
- cache file writing.

Acceptable approaches include:

- a temporary characterization command;
- opt-in timing emitted only when a dedicated environment variable is set;
- a test/probe file that imports production modules without altering normal execution.

Timing instrumentation must not change normal report output or failure semantics.

## 10. Candidate hypotheses to test, not assume

### H1: stale-cache regeneration dominates perceived delay

The selector waits because all section files are rebuilt before the selector opens.

### H2: ordinary `--section` dispatch constructs unrelated sections

Selecting one section still invokes `BuildSectionEntries` for all sections, so direct section output is close to full-report cost.

### H3: one or two heavy builders dominate full entry construction

Potential candidates include Outlook, Daily Trend, Actual Comparison, envelope computation, expense breakdown, or trial balance. Measure rather than guess.

### H4: `BuildContext` dominates regardless of selected section

If true, selected-builder dispatch alone may not provide enough improvement.

### H5: cache invalidation is occurring more often than intended

Possible causes include source-code mtimes, data updates, timestamp representation, cache sentinel assumptions, or cache directory identity.

### H6: repeated BQN process startup is material

The section route may launch BQN for Journal-path resolution, metadata, and report generation. Measure individual costs.

### H7: preview freshness policy is coupling navigation to full computation

The selector may be blocked until every preview is current, even though the user has not chosen a section.

None of these hypotheses is an implementation decision.

## 11. Required characterization output

Create one Markdown report containing:

1. verified baseline SHA and environment;
2. confirmed call graph;
3. cold-cache timings;
4. warm-cache timings;
5. representative direct-section timings;
6. full-report timing;
7. timing decomposition;
8. process-count observations;
9. cache invalidation inputs and behavior;
10. privacy-safe fixture/data scale;
11. findings clearly separated into:
    - directly observed;
    - inferred;
    - not yet determined;
12. a ranked list of candidate finite implementation slices;
13. an explicit recommendation for only the next slice;
14. risks and invariants for that slice.

Do not present an optimization as proven unless measurements isolate the relevant cost.

## 12. Decision criteria for the next finite slice

Prefer the smallest slice that materially improves the interaction while preserving semantics.

Possible outcomes include:

### Outcome A: selector-first display

Open the selector from static section metadata immediately, use existing cache previews when present, and avoid blocking navigation on full cache regeneration.

This is appropriate only if cold cache generation dominates and stale preview behavior can be made explicit and safe.

### Outcome B: selected-section-only construction

Dispatch the chosen key to one section builder rather than constructing all human sections first.

This is appropriate only if unrelated section builders materially affect direct-section latency.

### Outcome C: context reuse or decomposition

Reduce repeated or unnecessary context construction without changing its contracts.

This is appropriate only if `BuildContext` dominates and a coherent boundary can be established.

### Outcome D: cache validity correction

Fix invalidation behavior if the cache is unexpectedly stale on unchanged inputs.

This must be treated as a characterized behavior/correctness slice, not mixed with broader redesign.

### Outcome E: no change yet

If the delay cannot be reproduced or decomposed, improve instrumentation and stop. Do not optimize from aesthetic suspicion alone.

## 13. Invariants for any later optimization

Any implementation proposal must preserve:

- exact report contents for every section;
- canonical section keys, labels, and order;
- full-report order;
- selector cancellation behavior;
- fzf, gum, and plain-read fallbacks;
- preview semantics, or explicitly characterize and approve a change;
- color filtering and pager behavior;
- stdout, stderr, and exit status;
- cache isolation by ledger base directory;
- source-change and data-change freshness guarantees;
- native Journal source-of-truth behavior;
- Posting IR, Layer, Cube, TBDS, currency, cycle, envelope, budget, and diagnostic semantics.

## 14. Stop conditions

Stop and report without implementing an optimization if:

- the current `main` no longer matches the described route;
- an open PR is already changing report dispatch or cache behavior;
- the slowdown cannot be reproduced;
- private data would need to be committed;
- measurement instrumentation changes normal output or semantics;
- more than one independent performance responsibility would be changed;
- a proposed improvement requires changing report meaning or freshness policy without explicit approval.

## 15. Git and PR workflow for tomorrow

1. Start from freshly fetched `main`.
2. Create a characterization branch distinct from this instruction-only branch.
3. Add only measurement probes, focused tests/guards if appropriate, and the characterization report.
4. Do not optimize runtime in the characterization PR.
5. Open as Draft.
6. Run focused checks and full CI.
7. Review exact patches and measurement evidence.
8. Stop for discussion before Ready, merge, or a separate implementation branch.

## 16. Terminal-AI opening instruction

The following can be supplied as the first instruction tomorrow:

> Read `docs/REPORT_LATENCY_CHARACTERIZATION_INSTRUCTIONS-2026-07-27.md` as the controlling specification. Work through the report-latency characterization from the current remote `main`. Begin with the work gate and static call-graph verification. Do not implement an optimization. Use privacy-safe fixture measurements and, where useful, local private measurements whose data and rendered output are never committed. Create a separate characterization branch and Draft PR containing only measurement support and the characterization report. Stop after CI and patch review, and report the evidence and recommended next finite slice.

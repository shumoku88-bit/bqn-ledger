# Cross-cutting check / test classification audit — 2026-08-17

## Scope

This is the final lane of the 2026-08-17 BQN-native re-baseline and cross-cutting repository audit.

Earlier passes changed production owners, frontend routing, writer publication, report caching, experiments, dead surfaces, and compatibility classification. This pass asks a different question:

```text
What kind of evidence is each remaining check/test surface?
```

A file named `check-*` is not automatically part of the qualification gate, and a runner-external check is not automatically obsolete.

## Classification vocabulary

### 1. Full-suite law guard

Executed directly by `tools/check.sh` on every qualification run.

Use for current correctness, safety, topology, ownership, and integration laws whose regression should block publication immediately.

### 2. Transitive current law guard

Reached through a directly-qualified meta tool/check rather than listed in `tools/check.sh` itself.

Example:

```text
tools/check.sh
  -> check-devtools.sh
  -> tools/devtools-check.sh
  -> checks/check-repo-index.sh
```

`check-repo-index.sh` is therefore current qualification evidence even though its basename is not directly listed by the top-level runner.

### 3. Deliberate standalone characterization

Current evidence that is intentionally larger, slower, more historical, or more diagnostic than the every-run gate.

Example:

```text
checks/check-ledger-facts-phase1-proof-fixture.sh
```

This replays a large Phase-1 golden end-to-end proof fixture. The normal full suite already qualifies current ledger/report laws through smaller current checks, so the proof fixture remains available without being paid on every qualification run.

### 4. Duplicate characterization

A standalone check whose current law is already owned more completely by the full suite.

Such a file should normally retire rather than becoming another independently maintained gate.

### 5. Obsolete migration / topology characterization

A check whose assumptions describe retired source paths, retired architecture, or completed migration scaffolding.

Passing such a check is not useful current evidence and can actively mislead future work.

## Current laws promoted into the full suite

Two useful current checks were discovered outside `tools/check.sh` and promoted rather than deleted.

### Journal Event Identity Inventory CLI/privacy

`checks/check-edit-bqn-journal-event-identity-inventory.sh` verifies behavior not fully captured by the BQN unit test alone:

- summary/TSV command protocols;
- privacy-safe output;
- rejection of unsupported/unredacted formats;
- source-byte stability;
- no backup/candidate side effects;
- private canary non-leakage.

It is now a direct full-suite law guard.

### JSON report clock independence

`checks/check-json-clock-independence.sh` proves that explicit JSON report requests do not invoke the default local clock path.

This is an application/effect-boundary law and is now a direct report qualification check.

## Current transitive guard retained

### Repository index integrity

`checks/check-repo-index.sh` remains runner-transitive rather than being duplicated in the top-level list.

`tools/devtools-check.sh` owns its invocation, and `check-devtools.sh` is directly qualified by `tools/check.sh`.

This preserves a meaningful devtool composition boundary while keeping the current law active.

## Standalone characterization retained

### Phase-1 proof fixture

`checks/check-ledger-facts-phase1-proof-fixture.sh` remains standalone.

It is a broad golden end-to-end historical/current witness, useful when revisiting foundational ledger/report changes. Re-running the entire proof portfolio on every normal qualification would duplicate smaller current checks with disproportionate cost.

The classification guard intentionally keeps it outside `tools/check.sh`.

## Retired duplicate characterization

### `check-bqn-eval.sh`

The standalone BQN-eval check duplicated current devtool qualification:

- positive liveness/probe behavior is exercised by `tools/devtools-check.sh`;
- invalid expression, timeout, and option failure behavior is exercised by `checks/check-devtools-negative.sh`.

Both paths are already part of the full suite. The duplicate file is removed.

## Retired obsolete migration/topology checks

### Explicit Budget-style audit

`checks/audit-budget-style-explicit.sh` depended on retired `config.tsv`, `POLICY_BUDGET_STYLE`, and `src-next` fixture exceptions. It was no longer part of the runner and described a completed migration era.

Removed.

### Israel/ILS vertical slice

`checks/check-israel-ils-usable-vertical-slice.sh` sounded current but built its entire synthetic Household with retired paths such as:

```text
accounts.tsv
config.tsv
plan.tsv
budget_alloc.tsv
source.journal
```

Current multi-currency editor qualification instead uses canonical `accounts.journal` and verifies that legacy TSV is not writer authority.

Removed.

### Report-label check and catalog

`checks/check-report-labels.sh` explicitly searched `src_next` and protected `config/report_labels.tsv`.

The label catalog has no current source/application consumer and contains old Snapshot/Outlook/src_next presentation vocabulary. Current report labels/placement come from reviewed report/application owners and `report-section-metadata`.

Both the check and `config/report_labels.tsv` are removed.

### Old UI smoke characterization

`checks/check-ui-smoke.sh` encoded the pre-cutover report/Hub surface:

- old Snapshot/Outlook/debug section keys and headings;
- old interactive `bl edit` submenu / “Back to main menu” behavior;
- old report list assumptions.

Current Calendar-first, flat palette, report metadata, `add-ui`, and selector laws are guarded by focused full-suite checks. The old broad smoke file would preserve retired topology as if it were current behavior.

Removed.

## Coverage output corrected

Before this audit, `tools/coverage` printed a hand-maintained `src_edit` module-to-check map and reported values such as:

```text
covered 10 / 40
untested: ...
```

The table contained retired/nonexistent owner names and failed to recognize many current owners exercised through public shell/application integration paths.

That was not code coverage, module coverage, or a trustworthy qualification metric.

`tools/coverage` is now explicitly a **qualification evidence inventory**. It reports:

- current production BQN module count;
- all BQN unit tests auto-run by `tools/check.sh`;
- owner-oriented destination tests;
- direct tests/check references to `src_edit` owners;
- `transitive/no-direct-reference` without equating that with “untested”;
- shell checks directly listed in the full suite versus runner-external/transitive surfaces;
- `tools/check.sh` as the qualification authority.

This keeps the diagnostic useful without pretending static filename matching is coverage measurement.

## Guard

`checks/check-check-test-classification.sh` now fixes the current classification boundary:

- obsolete migration/topology checks remain absent;
- unused legacy report-label catalog remains absent;
- duplicate BQN-eval check remains absent while current devtool qualification stays active;
- Identity Inventory privacy/CLI and JSON clock-independence are direct full-suite guards;
- repository-index integrity remains transitively owned by devtools qualification;
- the Phase-1 proof fixture remains deliberate standalone characterization;
- the retired fixed `tools/coverage` map does not return;
- full BQN test auto-discovery and core qualification remain active.

## Final result

The repository now distinguishes tests by **what they prove and how they are reached**, rather than by filename or age.

The complete re-baseline has therefore reached a stable endpoint:

```text
production BQN owners reviewed
frontend authority aligned
writer publication aligned
report CLI/cache aligned
promoted experiments retired
stale TUI/docs retired
reachable/dead runtime classified
compatibility explicitly bounded
qualification evidence classified
```

There is no remaining audit cursor from this re-baseline.

Future material changes should reopen the relevant owner/cross-cutting lane based on the changed responsibility rather than restarting the entire review sequence.

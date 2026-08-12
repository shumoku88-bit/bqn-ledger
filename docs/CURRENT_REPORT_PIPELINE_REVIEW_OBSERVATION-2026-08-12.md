# Current Report pipeline review observation — 2026-08-12

## Owners

- `src/application/current_report_batch_cli.bqn`
- `src/application/current_report_profile_cli.bqn`
- `src/application/current_report_requests.bqn`

## Decision

Retain the effectful Batch and Profile adapters unchanged. Narrow only the pure request-set selection step.

### Batch lifetime

The Batch adapter intentionally admits one current report request set before establishing one shared evidence lifetime:

```text
request rows
  -> route admission and catalog-order validation
  -> one registry
  -> one canonical Actual admission
  -> one companion admission
  -> optional Issue / Human presentation evidence
  -> many compositions/renders
```

The existing `check-current-report-batch.sh` is a strong lifetime law rather than incidental topology characterization. It proves:

- `report-all` bytes equal the independent single-report oracle;
- invalid routes and mismatched surfaces fail before shared source lifetime begins;
- a one-shot `/dev/stdin` Actual source is consumed once and reused for all reports;
- BQN process count does not scale with selected report count;
- framed cache bodies equal independent single-report output.

Flattening this adapter into per-report reads would therefore regress both evidence consistency and effect/process lifetime.

### Profile lifetime

The Profile adapter owns the current observation and policy/cycle resolution sequence over canonical evidence. Its current guards prevent downstream date/cycle evaluation until each required capability is admitted. The existing profile check protects canonical Report policy, current and baseline Cycle coordinates, current/historical report behavior, UI integration, and stale-cache safety after policy failure.

No generic CLI helper abstraction is introduced merely to share `Fail` or diagnostic-printing syntax.

### Request-set selection

`current_report_requests.bqn` already constructs its twelve candidate request rows in retained Report catalog order. After Phase 4, `report.request.Validate ⟨"all",surface⟩` also publishes the admitted `section_indices` in that same catalog coordinate space.

The previous implementation discarded those coordinates and rescanned all candidate keys with string membership. The reviewed implementation selects directly:

```text
selection.section_indices ⊏ candidates
```

The focused test now protects the exact Compact selected-key order (`envelopes`, `balances`, `recent`, `planned`, `daily-target`) in addition to the Human coordinate arguments.

## Protected contracts

- one shared admitted evidence lifetime for current multi-report rendering;
- source-independent request construction;
- Report catalog ordering and supported-surface selection;
- current observation from latest admitted Actual evidence;
- current/baseline Cycle alignment;
- canonical Report policy ownership and stale-cache failure behavior;
- per-report route admission and public report bytes;
- no aggregate JSON schema;
- no report-count-scaled BQN process fan-out.

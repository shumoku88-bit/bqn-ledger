Status: selected finite production-adjacent read-only plan
Owner: journal source migration
Canonical: no; canonical routing remains TODO.md
Exit: focused public-synthetic implementation, review, completion record, and return to no selected finite Journal slice
Date: 2026-07-22

# Journal File-Backed Shadow Context Plan

## Purpose

Define a finite, production-adjacent, read-only plan to construct a file-backed shadow context from an explicitly specified Journal file path.

This plan establishes the design, contracts, assertion criteria, and file boundaries for reading a Journal file directly from disk, routing its content through the existing Stage 1 Transaction IR parser (`src_next/journal_profile_stage1.bqn`), Stage 2A checked Posting IR adapter (`src_next/journal_posting_ir_stage2a.bqn`), read-only source carrier (`src_next/journal_read_only_source_carrier.bqn`), and `context.BuildPeriodView` (`src_next/context.bqn`), into a new standalone shadow builder module (`src_next/journal_shadow_context.bqn`).

It allows verifying that actual-layer Trial Balance and Balances figures derived from a file-backed native Journal shadow context match the figures derived from standard TSV `context.BuildContext`, without altering production TSV source loading, default report routing, or editor write paths.

## Finite question

> TSVを唯一のsource truthおよびwrite pathに保ったまま、明示指定されたJournalファイルをread-onlyで読み、既存のTransaction IR、checked Posting IR、`context.BuildPeriodView`を通してshadow contextを構築し、public synthetic TSV contextとactual-layerのTrial BalanceおよびBalancesが一致することを、production report routingを変更せずに観察できるか。

## Current production boundary

- `src_next/context.bqn` (`BuildContext` / `LoadPostingSourceSnapshot`) loads TSV files (`journal.tsv`, `plan.tsv`, `budget_alloc.tsv`, `accounts.tsv`) as the single active source truth.
- `src_next/report.bqn` and `src_next/main.bqn` dispatch reports exclusively over TSV `BuildContext`.
- `tools/edit` and `tools/edit-bqn` write exclusively to TSV files via `tools/lib/safe-write.sh`.
- TSV remains the sole source truth and sole write path.

## Completed evidence

- `docs/archive/completed-plans/JOURNAL_MIGRATION_ARCHITECTURE_AND_SOURCE_IDENTITY_DECISION-2026-07-18.md`: Established the target dataflow `journal text -> Transaction IR -> checked Posting IR -> Cube / TBDS -> reports` without re-flattening multi-posting transactions back into TSV rows.
- `docs/archive/completed-plans/JOURNAL_READ_PATH_TRIAL_BALANCE_REHEARSAL_PLAN-2026-07-21.md`: Proved that Journal-derived Posting IR rows pass through `context.BuildPeriodView` and `trial_balance.Build` with zero-sum actual-layer movements.
- `docs/archive/completed-plans/JOURNAL_READ_PATH_REPORT_CONTEXT_REHEARSAL_PLAN-2026-07-21.md`: Extended the rehearsal to `balances.Build`, `balances.Format`, and `balances.FormatHuman`, matching legacy TSV balance entries.
- `docs/archive/completed-plans/JOURNAL_READ_ONLY_SOURCE_CARRIER_REHEARSAL_PLAN-2026-07-21.md`: Grouped Transaction IR and Stage 2A Posting IR assembly into `src_next/journal_read_only_source_carrier.bqn`.
- `docs/archive/completed-plans/JOURNAL_BUDGET_COMPANION_PROJECTION_CHARACTERIZATION_PLAN-2026-07-22.md`: Proved multi-posting actual purchases and budget companion events project into distinct actual and budget layers in TBDS while leaving actual-layer figures unchanged.

Previous rehearsals consumed in-memory line arrays in test files. The next finite step is to read an explicit Journal file from disk via file I/O (`loader.ReadLines` or `•FChars`) through a dedicated shadow context builder.

## Selected shadow path

```text
explicit Journal file path
  -> read-only file load
  -> existing journal_read_only_source_carrier
  -> Stage 1 Transaction IR
  -> Stage 2A checked Posting IR
  -> context.BuildPeriodView
  -> file-backed shadow context
  -> actual-layer Trial Balance / Balances comparison against TSV BuildContext
```

This path is production-adjacent (uses existing BQN modules and production contracts), but is **not** the production default.

## Why this boundary was selected

1. **Preserve production default stability**: `context.BuildContext`, `report.bqn`, and `main.bqn` remain untouched.
2. **Strict source isolation**: TSV remains the sole source truth and write path. No mixing of TSV and Journal posting rows, no automatic fallback, no reverse synchronization.
3. **Real file-backed I/O verification**: Reads a physical `.journal` file from disk via `loader.ReadLines` / `•FChars` instead of embedding string arrays in unit tests.
4. **Clean modular owner**: Isolates the read-only shadow context builder into `src_next/journal_shadow_context.bqn`.

## Shadow source contract

- The Journal file path is explicitly provided by the caller (e.g., `base ∾ "/shadow.journal"`).
- No implicit or default Journal file path is introduced in `BuildContext` or `report.bqn`.
- Read-only file load only.
- Do not combine or merge TSV and Journal posting rows.
- No automatic fallback from Journal to TSV on load/parse error.
- No automatic fallback from TSV to Journal.
- No write-back from Journal to TSV.
- No dual writes to Journal and TSV.
- Source truth remains TSV.
- The shadow context is read-only and ephemeral.
- Uses public synthetic fixtures only (`fixtures/journal-file-backed-shadow-context/`).
- Private ledger data and private synchronized journals must not be used.
- Do not modify `tools/to-hledger`.
- `tools/to-hledger` output is not automatically adopted as canonical shadow input; the supported-profile `shadow.journal` format is used explicitly.

## Expected checked-result contract

The future builder module `src_next/journal_shadow_context.bqn` will provide a pure builder function:

`Build ⇐ {𝕊 ⟨base, journalPath, as_of⟩: ...}`

The return value is a structured checked result namespace:

```text
{
  state,
  source_mode,
  source_path,
  transactions,
  posting_rows,
  diagnostics,
  context
}
```

- **Success state**:
  - `state = "ok"`
  - `source_mode = "journal-shadow"`
  - `source_path = journalPath`
  - `transactions = Stage 1 parsed transactions`
  - `posting_rows = Stage 2A checked posting rows`
  - `diagnostics = ⟨⟩` (empty list)
  - `context = assembled read-only shadow context namespace`

- **Failure state**:
  - `state = "error"`
  - `source_mode = "journal-shadow"`
  - `source_path = journalPath`
  - `transactions = parsed transactions or ⟨⟩`
  - `posting_rows = ⟨⟩` (empty list)
  - `diagnostics = structured non-empty list of diagnostic objects`
  - `context = @` (absent or empty)

- **Diagnostic conventions**:
  - Structured diagnostic objects with `severity`, `stage`, `code`, `line`/`message`.
  - Fatal stdout prints (`•Out "ERROR..."`) and script termination (`•Exit 1`) must **not** be used inside the shadow builder module. Failures are returned as structured checked results.

## Expected context contract

When `state = "ok"`, the `context` namespace within the checked result contains the minimal fields required by actual-layer consumers (`trial_balance.Build`, `balances.Build`, etc.):

```text
{
  base,
  as_of,
  cy,
  resolved,
  posting_rows,
  cube,
  tbds,
  issues,
  source_mode,
  source_path,
  transactions,
  diagnostics
}
```

- `base`: base directory path.
- `as_of`: observation date string.
- `cy`: cycle period structure resolved from `cycle.tsv`.
- `resolved`: resolved account registry from `accounts.tsv` (`ak.Resolve`).
- `posting_rows`: Stage 2A Posting IR rows derived from the Journal file.
- `cube`: cycle-bounded Daily Cube materialized from the Journal posting rows.
- `tbds`: TBDS period view generated by `context.BuildPeriodView`.
- `issues`: empty list `⟨⟩` (issue consumer migration is out of scope).
- `source_mode`: `"journal-shadow"`.
- `source_path`: explicit Journal file path.
- `transactions`: Stage 1 parsed transactions.
- `diagnostics`: `⟨⟩`.

This context does not attempt a full, indiscriminate clone of every legacy `BuildContext` field, but cleanly satisfies actual-layer Trial Balance and Balances contracts.

## Required parity assertions

Future implementation must verify the following in `tests/test_journal_file_backed_shadow_context.bqn`:

### File-backed I/O

- Reads an explicit public synthetic Journal file (`fixtures/journal-file-backed-shadow-context/shadow.journal`) via BQN file I/O (`loader.ReadLines` or `•FChars`).
- No embedding of Journal text lines inside test scripts.
- Pure read-only operation.
- `source_path` is retained in the checked result.

### Transaction and Posting IR

- Retains native multi-posting transaction blocks.
- Preserves Transaction IR event count and posting order.
- Preserves durable event identity (`source_event_id`) and physical source line evidence.
- Stage 2A generates checked Posting IR rows (`status = "ok"`).
- Zero-sum transaction deltas balance independently (`+´ delta = 0`).
- No partial posting rows are emitted on error.

### Period view

- Reuses existing `context.BuildPeriodView` without modification.
- Preserves Cube and TBDS shapes.
- Extracts actual layer using `cube.layer_actual`.

### TSV parity

Compares two execution paths over the same public synthetic accounting facts:

- **Path A**: `context.BuildContext` over TSV fixture (`fixtures/journal-file-backed-shadow-context/`)
- **Path B**: `journal_shadow_context.Build` over `fixtures/journal-file-backed-shadow-context/shadow.journal`

Comparison assertions:

- Actual-layer TBDS rows match field by field:
  `account_key`, `layer_name`, `opening`, `debit_movement`, `credit_movement`, `movement`, `closing`.
- Actual-layer Trial Balance (`trial_balance.Build`) matches field by field.
- Balances entries (`balances.Build`) match.
- Balances formatting (`balances.Format` and `balances.FormatHuman`) succeeds without error.

Physical row topology differences between Journal (e.g. 1 multi-posting transaction block) and TSV (flattened 1-to-1 rows) are permitted; equality of semantic account coordinates is canonical. Native multi-posting transactions must **not** be re-flattened into TSV `from / to / amount` rows before comparison.

## Required fail-closed assertions

Future implementation must verify structured error handling (`state = "error"`, `posting_rows = ⟨⟩`, `context = @`, non-empty `diagnostics`) for the following invalid inputs:

1. Journal file missing (non-existent path)
2. Journal file unreadable / unresolvable
3. Stage 1 parse error (e.g. invalid header, syntax error)
4. Unsupported syntax or group
5. Unbalanced transaction event (`+´ delta ≠ 0`)
6. Unsupported layer name
7. Unknown account key against resolved `accounts.tsv` registry
8. Invalid date format
9. Invalid exact-integer amount

Expected behavior under all failure conditions:

- `state = "error"`
- `diagnostics` contains structured error details from the appropriate stage (`journal_profile_stage1` or `journal_posting_ir_stage2a`).
- `posting_rows` is empty `⟨⟩`.
- Shadow context is absent or empty (not returned in success shape).
- No fallback to production TSV context.
- No partial execution of downstream reports.

Exact diagnostic codes will be inspected from existing module ownership during implementation.

## Production boundary

The future implementation will **not** modify:

```text
src_next/context.bqn BuildContext default path
src_next/report.bqn default dispatch
src_next/main.bqn default dispatch
production data files
current editor / tools/edit / tools/edit-bqn
current safe-write path (tools/lib/safe-write.sh)
tools/to-hledger
Cube shape
TBDS shape
Posting IR 16-field shape
```

The shadow builder will be a standalone read-only module and will **not** be hidden inside production `BuildContext`.

## Explicit exclusions

The following items are explicitly excluded from this plan and its future implementation:

- Default source switch
- Default Journal routing in `report.bqn` or `main.bqn`
- User-facing CLI flags
- Writer, editor, or preview UI for Journal files
- Serializer or TSV-to-Journal converters
- Automatic `event-id` or budget companion generation
- Atomic append, file locking, or concurrency controls
- Production conversion from TSV to Journal
- `tools/to-hledger` compatibility or parser expansion
- Private data trials
- Shadow result persistence or caching
- Dual writes, reverse synchronization, automatic fallback, or conflict resolution
- Cutover, rollback execution, or source archiving
- Correction-event policy
- Per-posting layers or Cube/TBDS axis additions
- Report-wide consumer migration
- Automatic selection of the next finite slice

## Expected future changed-file boundary

The future implementation PR will be limited to:

```text
src_next/journal_shadow_context.bqn
tests/test_journal_file_backed_shadow_context.bqn
fixtures/journal-file-backed-shadow-context/accounts.tsv
fixtures/journal-file-backed-shadow-context/cycle.tsv
fixtures/journal-file-backed-shadow-context/journal.tsv
fixtures/journal-file-backed-shadow-context/plan.tsv
fixtures/journal-file-backed-shadow-context/budget_alloc.tsv
fixtures/journal-file-backed-shadow-context/shadow.journal
docs/archive/completed-plans/JOURNAL_FILE_BACKED_SHADOW_CONTEXT_PLAN-2026-07-22.md
TODO.md
NEXT_SESSION.md
docs/README.md
docs/JOURNAL_FILE_BACKED_SHADOW_CONTEXT_PLAN.md  # deleted on completion
```

If necessary, minimal test-only adjustments to `src_next/journal_read_only_source_carrier.bqn` may be permitted.

The following files are strictly prohibited from being modified in the implementation PR:

```text
src_next/context.bqn
src_next/report.bqn
src_next/main.bqn
src_next/cube.bqn
src_next/tbds.bqn
tools/to-hledger
```

## Validation required before completion

Upon completion of this docs-only plan:

```bash
git diff --check
bash checks/check-docs-lifecycle.sh
bash checks/check-absolute-links.sh
bash checks/check-repo-index.sh
bash tools/check.sh

git status --short
git diff --stat origin/main...HEAD
git diff --name-only origin/main...HEAD
```

All checks must pass cleanly.

## Completion routing

`TODO.md` and `NEXT_SESSION.md` record:

```text
Status: selected finite production-adjacent read-only plan
```

Selected shadow path:

```text
explicit Journal path
  -> file-backed read-only load
  -> Journal carrier
  -> Transaction IR
  -> checked Posting IR
  -> BuildPeriodView
  -> shadow context
  -> actual-layer TSV parity
```

`docs/README.md` routes to `docs/JOURNAL_FILE_BACKED_SHADOW_CONTEXT_PLAN.md`.
Production routing, writer, CLI, private data, conversion, cutover, and reverse sync remain explicitly unselected.

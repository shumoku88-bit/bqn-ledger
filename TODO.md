# TODO

Status: active backlog / work router
Owner: workflow
Canonical: yes
Exit: revise when a finite slice is selected, completed, declined, or rerouted

このファイルは次の4種類だけを置く場所です。

1. **Active work** — 現在進行中または次に終わらせる有限作業
2. **Next candidates** — まだ着手を決めていない小さな候補
3. **Continuous maintenance** — 終了させない基礎保守ループ
4. **Hold / later** — 具体的必要が出るまで保留するもの

完了済みの長い履歴は `docs/archive/TODO_HISTORY-*.md` に退避します。

## Current baseline

Last hygiene pass: 2026-07-24

- Native Journal is the only production Actual source selected by `ACTUAL_JOURNAL_FILE`.
- `plan.tsv`, `budget_alloc.tsv`, `accounts.tsv`, `cycle.tsv`, and `issues.tsv` remain companion/configuration source files.
- Actual TSV runtime, fallback, dual-write, editor, and active-fixture routes are retired.
- The selected report-projection alignment sequence is complete; no next finite report slice is selected.
- The selected Journal parser, Posting IR, read-path, cutover, canonical-surface, and reconstructible-identity cleanup sequence is complete; no next finite Journal slice is selected.
- The unused MCP adapter is retired. Its pre-removal implementation remains recoverable from Git tag `checkpoint-pre-mcp-removal`.
- The generic projection and valuation foundation is recorded as an active backlog, not implementation authorization.
- Detailed completion history through this checkpoint is in `docs/archive/TODO_HISTORY-2026-07-24.md`.

---

## Active work

**No finite implementation slice is currently selected.**

The latest AI working feedback remains evidence only. The generic projection and valuation intake merged through PR #352 is a design boundary only. Neither source authorizes runtime work without a separately selected finite slice in this file.

---

## Next candidates

### Generic projection and valuation foundation

Status: unselected docs-only follow-up.

Canonical intake:

- `docs/archive/active-plans/GENERIC_PROJECTION_AND_VALUATION_FOUNDATION_DESIGN_INTAKE-2026-07-24.md`

Eligible finite candidates:

1. **Generic projection ownership inventory** — document the current owners of admission, axes, coordinates, exact grouping, dense materialization, provenance, rejection, Cube totals, and TBDS overlap.
2. **Commodity and valuation ownership inventory** — document the current owners of currency code, source quantity, precision, arithmetic authorization, formatting, mixed-currency rejection, and reporting selection.

Selection rules:

- select at most one inventory first;
- keep the first slice docs-only;
- do not refactor `cube.bqn` during the inventory;
- do not add a universal Cube, Currency axis, FX, valuation, mixed-currency aggregation, source-schema migration, or report output;
- keep the Canonical Daily Cube contract `Day × Account × Layer` unchanged;
- require a separate decision before any test-only primitive or runtime composition work.

### Configurable AI-assisted household ledger and report

Status: selected long-term direction; no next program slice selected.

Current source-truth boundary:

- human-readable native Journal for Actual transactions;
- human-readable TSV for companion/configuration sources;
- BQN-generated checked projections and reports;
- AI may explain and propose, but accepted changes pass through human judgment and approved editor paths.

Routing candidates remain independently unselected:

1. privacy-safe AI context-bundle contract;
2. one read-only AI consultation report;
3. safe proposal-to-editor handoff;
4. Ledger Observatory synthetic evidence-trace connection last.

Do not infer automatic advice, automatic TODO creation, automatic writes, or private production-data access.

### Bookkeeping matrix study extension

Status: unselected research direction. Use public synthetic, hand-checkable evidence only.

- Select one accounting topic at a time, such as depreciation, inventory, adjustments, closing, trial balance, or financial statements.
- Keep journal evidence, expected event-account matrix, manual accounting explanation, and BQN projection together.
- Do not turn this direction into a broad accounting-engine rewrite or production feature campaign automatically.

### Daily Capacity evidence adapter characterization

Status: unselected runtime follow-up.

Current evidence:

- `docs/DAILY_CAPACITY_EVIDENCE_ASSEMBLER_CHARACTERIZATION_CONTRACT.md`
- `docs/archive/audits/DAILY_CAPACITY_EVIDENCE_ADAPTER_PREIMPLEMENTATION_AUDIT-2026-07-15.md`
- `docs/archive/completed-plans/DAILY_CAPACITY_EVIDENCE_ASSEMBLER_CHARACTERIZATION-2026-07-15.md`

A future slice must choose exactly one of pure seam promotion, O-bounded account-balance facts, or pool/reservation facts. Do not combine them or infer policy from account names, prefixes, roles, country, cadence, or envelope names.

### Friend travel atomic finalization writer

Status: unselected / parked candidate.

- Current source-event semantics: `docs/archive/active-plans/FRIEND_TRAVEL_SOURCE_EVENT_JPY_FINALIZATION_PLAN-2026-07-13.md`.
- Reusable atomic-write proposal: `docs/archive/active-plans/FRIEND_TRAVEL_ATOMIC_FINALIZATION_WRITE_DESIGN-2026-07-13.md`.
- Source-event storage, safe append, production use, strict-source Steps 2–5, and M4 remain independently unselected.

### Mixed-ledger daily-use continuation

Status: candidate only.

- Current plan: `docs/archive/active-plans/CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md`.
- M3 and strict-source Step 1 are complete.
- strict-source Steps 2–5 and M4 remain unselected and do not auto-start.

### Ledger Observatory long-term program

Status: active long-term direction; no runtime slice selected.

Canonical plan:

- `docs/archive/active-plans/LEDGER_OBSERVATORY_LONG_TERM_PLAN-2026-07-13.md`

The next eligible candidate remains a docs-only, synthetic-input source-row → Posting IR → Cube-coordinate evidence-trace contract. Scenario overlay, Cube Theatre, BQN Ledger Kata, Projection Workbench, and new AI-observation infrastructure do not auto-start.

Projection Workbench requires at least two independently completed consumers demonstrating the same projection contract.

### M4: expense breakdown grouped by meaning and currency

Status: candidate only.

Do not implement before daily-use observation and current expense/cycle consumer-contract review. Strict-source completion does not automatically select M4.

### `budget_pool=main` metadata

Status: docs-only future direction; current fallback remains valid.

- Cut any implementation plan into a finite slice.
- Decide fixture, check, and fallback compatibility before changing source TSV.

### Fintech engineering review backlog

Routes:

- `docs/FINTECH_ENGINEERING_REVIEW_BACKLOG.md`
- `docs/archive/active-plans/FINTECH_ENGINEERING_REVIEW_BACKLOG-2026-07-01.md`

Select one candidate only and classify it as `adopt-now`, `adopt-later`, `observe`, or `reject`. Even an adopted candidate must first become a finite docs-only design slice.

---

## Continuous maintenance

This section is a recurring review lane, not a permanently unfinished implementation queue.

### AI work quality / efficiency / accuracy

Purpose:

- improve AI work accuracy;
- reduce unnecessary rereading, token use, and debug iteration;
- keep failure evidence visible;
- make repository-specific safety boundaries difficult to misunderstand.

Use `docs/archive/active-plans/AI_WORKING_FEEDBACK_LOG.md` as evidence input. Feedback does not automatically authorize tools, telemetry, lint, refactors, or implementation work.
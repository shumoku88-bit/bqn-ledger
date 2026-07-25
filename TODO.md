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

Last hygiene pass: 2026-07-25

- Native Journal is the only production Actual source selected by `ACTUAL_JOURNAL_FILE`.
- `plan.tsv`, `budget_alloc.tsv`, `accounts.tsv`, `cycle.tsv`, and `issues.tsv` remain companion/configuration source files.
- Actual TSV runtime, fallback, dual-write, editor, and active-fixture routes are retired.
- The selected report-projection alignment sequence is complete; no next finite report slice is selected.
- The selected Journal parser, Posting IR, read-path, cutover, canonical-surface, and reconstructible-identity cleanup sequence is complete; no next finite Journal slice is selected.
- The unused MCP adapter is retired. Its pre-removal implementation remains recoverable from Git tag `checkpoint-pre-mcp-removal`.
- The Israel 2026 travel funding and settlement ownership characterization is complete.
- JPY→ILS exchange safe append and friend-paid pending safe append already exist.
- Native Journal ordinary Actual writing, parsing, and selected balances remain JPY-only; ordinary ILS travel spending is not currently admitted.
- A non-JPY single-currency admission characterization is selected below. ILS is the first concrete witness, not a permanent special case.
- The generic projection and valuation foundation remains an active backlog, not implementation authorization.
- Detailed completion history through the previous checkpoint is in `docs/archive/TODO_HISTORY-2026-07-24.md`.

---

## Active work

### Native Journal non-JPY single-currency admission characterization

Status: selected docs/test-boundary finite slice.

Concrete witness:

- one public-synthetic, balanced ILS Actual transaction between two existing ILS accounts;
- exact decimal source amounts with the existing ILS precision policy;
- no JPY posting in the same transaction or arithmetic domain.

Finite question:

- identify every current JPY-specific owner across commodity declaration, amount parsing, account-currency admission, native rendering, Stage 1 parsing, Stage 2A adaptation, complete-source validation, post-check, and immediate downstream consumers;
- determine which assumptions are genuinely currency-parameterized already and which are hard-coded to JPY;
- distinguish changes required for any supported non-JPY single-currency Journal from changes required only for ILS;
- prove the smallest test-only contract for one non-JPY transaction without selecting production writing;
- state the smallest separately selectable implementation slice supported by the evidence.

Required generality:

- use ILS as the first witness because it is an immediate travel need;
- do not encode Israel, travel, cash, Wise, or account-name meaning into the generic Journal admission boundary;
- a successful contract should be reusable in principle for another configured supported currency with its own precision policy;
- do not claim universal currency support until a second currency witness or equivalent parameterized proof exists.

Boundaries:

- public synthetic repository evidence only;
- docs and focused test-boundary characterization only;
- no production writer, parser widening, source mutation, account creation, report output, balance view, FX, valuation, Currency axis, or mixed-currency arithmetic;
- no `trip-id` / `payment` metadata work;
- no reverse exchange, friend finalization, Wise semantics, strict-source continuation, M4, or generic projection refactor;
- JPY and ILS must never be added or balanced against each other;
- completing this characterization does not automatically select implementation.

The latest AI working feedback remains evidence only and does not authorize additional work.

---

## Next candidates

### Israel 2026 travel funding and settlement continuation

Status: candidate 1 selected above; all later continuation slices independently unselected.

Canonical lifecycle plan:

- `docs/archive/active-plans/ISRAEL_ILS_CASH_LIFECYCLE_PLAN-2026-07-25.md`

Current ownership audit:

- `docs/archive/audits/ISRAEL_TRAVEL_RAIL_OWNERSHIP_CHARACTERIZATION-2026-07-25.md`

Recommended candidate order:

1. **Native Journal non-JPY single-currency admission characterization** — selected above, using ILS as the first concrete witness while separating reusable currency admission from ILS-only evidence.
2. **Native Journal ILS ordinary-add implementation** — only after candidate 1 supports a finite safe contract.
3. **Travel metadata admission** — separately decide and test `trip-id` and `payment`; do not infer support from the old TSV metadata path.
4. **Bidirectional account-explicit exchange** — widen the existing safe JPY→ILS event rail to admit ILS→JPY without inferring physical cash versus Wise from account names.
5. **Friend atomic JPY finalization writer** — durable finalization/status/index ownership plus exactly one Journal expense/liability append and recovery.
6. **Wise card evidence characterization** — distinguish existing-ILS-balance spending from purchase-time automatic conversion using public synthetic or user-supplied redacted statement shapes.
7. **Narrow per-account position and obligation read models** — physical ILS cash, Wise ILS balance, friend JPY liability, and confirmed own-card JPY spending kept separate.
8. **Synthetic whole-trip rehearsal** — prove no duplicated expense and zero-or-explained balances.
9. **Human-controlled production readiness checkpoint**.

Selection rules:

- select at most one candidate;
- do not bundle non-JPY Journal admission with metadata, reverse exchange, friend finalization, Wise semantics, or reports;
- never add JPY and ILS;
- do not use private production data to determine policy;
- do not create accounts automatically;
- do not treat exchange as expense or friend repayment as another expense.

### Generic projection and valuation foundation

Status: paused while the selected non-JPY admission characterization is active.

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

Status: unselected / parked Israel continuation candidate.

- Current source-event semantics: `docs/archive/active-plans/FRIEND_TRAVEL_SOURCE_EVENT_JPY_FINALIZATION_PLAN-2026-07-13.md`.
- Reusable atomic-write proposal: `docs/archive/active-plans/FRIEND_TRAVEL_ATOMIC_FINALIZATION_WRITE_DESIGN-2026-07-13.md`.
- Pending source-event storage and safe append are already implemented.
- Finalization status/index persistence, atomic Journal append, production use, strict-source Steps 2–5, and M4 remain independently unselected.

### Mixed-ledger daily-use continuation

Status: non-JPY single-currency admission characterization selected separately; residual candidates remain unselected.

- Current broad plan: `docs/archive/active-plans/CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md`.
- Israel lifecycle plan: `docs/archive/active-plans/ISRAEL_ILS_CASH_LIFECYCLE_PLAN-2026-07-25.md`.
- M3 and strict-source Step 1 are complete historically, but the native Journal cutover leaves current ordinary Actual writing/parsing JPY-only.
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
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
- The usable Israel ILS vertical slice is complete: ordinary supported-currency Journal append, one explicitly selected Actual + plan + budget context, and selected-domain balances work for public-synthetic ILS while omitted-currency JPY behavior remains compatible.
- The non-JPY single-currency characterization and test-only admission proof are complete. Public-synthetic ILS and USD witnesses share one registry-driven domain, precision, account-currency, normalization, balance, and structural-trace boundary while production Journal routes remain unchanged.
- The multi-currency Journal container contract and test-only proof are complete. One public-synthetic Journal admits separate JPY and ILS ordinary transactions, a JPY and USD witness proves generality, every transaction retains its own domain and scale, and mixed-domain ordinary transactions fail closed.
- The production complete-source admission boundary is complete. It returns per-transaction domains, scales, normalized posting evidence, account-currency proof, identity, metadata, and source provenance without a Journal-wide money domain or total.
- The Stage 2A currency-proof carrier is complete. It emits separate `currency_proof_rows` with domain and exact scale attached, while the existing untyped 16-field `delta` Posting IR and all consumers remain unchanged.
- The generic projection and valuation foundation remains an active backlog, not implementation authorization.
- Detailed completion history through the previous checkpoint is in `docs/archive/TODO_HISTORY-2026-07-24.md`.

---

## Active work

**No finite implementation slice is currently selected.**

Completed current finite work:

- `src_next/selected_domain_context.bqn`
- supported-currency `src_edit/journal_block_add_cmd.bqn` / `tools/edit journal add --currency CODE`
- selected-domain `src_next/balances.bqn` read model
- `tests/test_src_next_selected_domain_context.bqn`
- `checks/check-israel-ils-usable-vertical-slice.sh`

The selected-domain boundary reuses production complete-source admission and Stage 2A `currency_proof_rows`, validates all Actual and non-Actual evidence before selecting one registry-supported currency, normalizes only that domain to one context-local exact scale, and returns no partial context on failure. JPY, ILS, and USD use this same path without currency-literal control branches. A declaration-only Journal is a valid empty Actual source; selected plan/budget can still form the context, and a fully empty selected domain returns a normal empty context. It does not alter the existing 16-field untyped `delta` contract or add a Currency axis.

The ordinary-add writer now accepts one explicit registry-supported transaction currency, preserves omitted-currency JPY behavior, and rejects unsupported currency, excessive precision, account mismatch, mixed-domain, zero, malformed, missing, and unbalanced postings before safe append. The synthetic rehearsal writes JPY, ILS, and USD expenses through the registry-driven writer and selected-domain read boundaries, verifies domain isolation, and displays cumulative expense with the same section structure for all three currencies. JPY append, selected balances, and full-report compatibility remain checked.

Travel metadata admission is complete as a separate finite slice: CLI `trip_id` renders to native `trip-id`, `payment` admits only `cash|card|debit`, both round-trip exactly through generic Transaction IR metadata, and neither changes account selection, currency, arithmetic, or reports. Mixed-currency aggregation, FX, valuation, reporting currency, reverse exchange, friend finalization, and Wise automatic-conversion semantics remain unimplemented.

The latest AI working feedback remains evidence only and does not authorize additional work.

---

## Next candidates

### Multi-currency native Journal container continuation

Status: admission, Stage 2A carriage, selected-domain composition, ordinary-add widening, and selected balances complete / remaining continuation slices independently unselected.

Current evidence and contract:

- `docs/archive/audits/NATIVE_JOURNAL_NON_JPY_SINGLE_CURRENCY_ADMISSION_CHARACTERIZATION-2026-07-25.md`
- `src_next/journal_supported_single_currency_admission_for_test.bqn`
- `tests/test_journal_supported_single_currency_admission_proof.bqn`
- `docs/archive/active-plans/MULTI_CURRENCY_JOURNAL_CONTAINER_CONTRACT-2026-07-25.md`
- `src_next/journal_multi_currency_container_admission_for_test.bqn`
- `tests/test_journal_multi_currency_container_admission_proof.bqn`
- `src_next/journal_supported_single_currency_admission.bqn`
- `src_next/journal_complete_source_admission.bqn`
- `tests/test_journal_complete_source_admission.bqn`
- `src_next/journal_currency_proof_carrier_stage2a.bqn`
- `tests/test_journal_currency_proof_carrier_stage2a.bqn`
- `src_next/selected_domain_context.bqn`
- `tests/test_src_next_selected_domain_context.bqn`
- `checks/check-israel-ils-usable-vertical-slice.sh`

Recommended candidate order:

1. **Per-domain consumer and formatting verification beyond selected balances** — review one immediate consumer at a time; never produce combined multi-currency totals.
2. **Explicit exchange-in-Journal design** — independently decide whether a typed cross-currency exchange transaction should join the current separate exchange event rail.

Both candidates remain unselected. Full-report routing, FX, valuation, exchange, and later travel work remain unselected.

Selection rules:

- select at most one candidate;
- treat completed admission and carrier rows as production evidence, not authorization to feed unlike currencies into current context or Cube;
- ILS and USD are witnesses, not generic module branch conditions;
- the Journal container may be multi-currency while every ordinary transaction remains single-domain;
- do not bundle a future consumer with travel metadata, reverse exchange, friend finalization, Wise semantics, or broad report conversion;
- never add amounts from different currency domains;
- reject mixed-domain ordinary transactions until an explicit typed exchange contract is selected;
- do not use private production data to determine policy;
- do not create accounts automatically;
- do not add FX, valuation, a reporting currency, a Currency axis, or mixed-currency aggregation automatically.

### Israel 2026 travel funding and settlement continuation

Status: usable ordinary ILS expense → selected ILS context → selected ILS balance vertical slice complete; later travel continuation slices remain independently unselected.

Canonical lifecycle plan:

- `docs/archive/active-plans/ISRAEL_ILS_CASH_LIFECYCLE_PLAN-2026-07-25.md`

Current ownership audit:

- `docs/archive/audits/ISRAEL_TRAVEL_RAIL_OWNERSHIP_CHARACTERIZATION-2026-07-25.md`

Recommended travel order after the completed minimal vertical slice:

1. **Bidirectional account-explicit exchange** — widen the existing safe JPY→ILS event rail to admit ILS→JPY without inferring physical cash versus Wise from account names.
2. **Friend atomic JPY finalization writer** — durable finalization/status/index ownership plus exactly one Journal expense/liability append and recovery.
3. **Wise card evidence characterization** — distinguish existing-ILS-balance spending from purchase-time automatic conversion using public synthetic or user-supplied redacted statement shapes.
4. **Narrow semantic position and obligation read models beyond currency-selected account balances** — physical ILS cash, Wise ILS balance, friend JPY liability, and confirmed own-card JPY spending kept separate.
5. **Synthetic whole-trip rehearsal** — prove no duplicated expense and zero-or-explained balances.
6. **Human-controlled production readiness checkpoint**.

Selection rules:

- select at most one candidate;
- do not bundle supported-currency Journal work with metadata, reverse exchange, friend finalization, Wise semantics, or reports;
- never add JPY and ILS;
- do not use private production data to determine policy;
- do not create accounts automatically;
- do not treat exchange as expense or friend repayment as another expense.

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

Status: unselected / parked Israel continuation candidate.

- Current source-event semantics: `docs/archive/active-plans/FRIEND_TRAVEL_SOURCE_EVENT_JPY_FINALIZATION_PLAN-2026-07-13.md`.
- Reusable atomic-write proposal: `docs/archive/active-plans/FRIEND_TRAVEL_ATOMIC_FINALIZATION_WRITE_DESIGN-2026-07-13.md`.
- Pending source-event storage and safe append are already implemented.
- Finalization status/index persistence, atomic Journal append, production use, strict-source Steps 2–5, and M4 remain independently unselected.

### Mixed-ledger daily-use continuation

Status: usable ordinary supported-currency append and selected-domain context/balance slice complete; broader consumers remain unselected.

- Current broad plan: `docs/archive/active-plans/CURRENCY_MIXED_JPY_ILS_DAILY_USE_PLAN-2026-07-12.md`.
- Israel lifecycle plan: `docs/archive/active-plans/ISRAEL_ILS_CASH_LIFECYCLE_PLAN-2026-07-25.md`.
- The public synthetic path now appends ordinary ILS spending, composes ILS Actual + plan + budget only, and displays ILS account balances and cumulative expense without admitting JPY or USD into that context.
- Omitted-currency ordinary append and explicitly selected JPY balance compatibility remain checked; USD proves the writer is registry-driven.
- strict-source Steps 2–5 beyond this narrow selected route and M4 remain unselected and do not auto-start.
- mixed-currency aggregation, FX, valuation, metadata, reverse exchange, friend finalization, and Wise semantics remain unavailable.

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

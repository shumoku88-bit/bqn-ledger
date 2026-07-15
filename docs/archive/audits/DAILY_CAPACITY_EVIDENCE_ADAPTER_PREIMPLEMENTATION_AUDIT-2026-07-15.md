# Daily Capacity evidence adapter pre-implementation audit — 2026-07-15

Status: audit snapshot
Owner: report / ledger policy / envelope / config
Canonical: no; current contract: `../../DAILY_CAPACITY_MINIMAL_INPUT_RESULT_CONTRACT.md`
Exit: retain as current-main evidence until one adapter characterization slice is separately selected or a later audit supersedes these findings

## Purpose

Identify current repository fact owners and policy owners for the five-part input to the unconnected pure boundary:

```text
BuildDailyCapacityFromEvidence
  ⟨observation, horizon, arithmetic_domain, asset_scope, obligation_scope⟩
```

This audit compares at most three adapter boundaries. It does not select or implement one.

## Scope and inspected current-main surfaces

The audit used current `main` code as implementation truth and inspected at least:

- `src_next/context.bqn`, `outlook.bqn`, `report.bqn`, `summary.bqn`, and `config.bqn`;
- `src_next/cycle.bqn`, `docs/CYCLE.md`, `docs/TIME_AS_AXIS.md`, and `docs/OUTLOOK_TEMPORAL_CURRENT.md`;
- `src_next/account_key.bqn`, `actual_snapshot.bqn`, `tbds.bqn`, and the TBDS contract;
- `src_next/envelope_computation.bqn` and current funding-base / execution-plan policies;
- `src_next/plan_evidence.bqn`, `plan_rows.bqn`, `planned_payments.bqn`, and `plan_journal_overlap.bqn`;
- `src_next/currency_arithmetic.bqn`, `currency_selection.bqn`, and `context.ResolveArithmeticCurrencyProof`;
- `config/meta_schema.tsv` and `docs/JOURNAL_META.md`;
- the `POLICY_RISK_STYLE` decision, the prior consumer/input-evidence audit, the Daily Capacity contract/amendment, runtime seam, and 31-case characterization.

No private or production data was accessed.

## Executive result

The repository has reusable facts for all five carriers, but it cannot currently construct a resolved Daily Capacity input without additional explicit owner decisions.

```text
observation
  explicit current owner exists at the report / BuildAt boundary

horizon
  resolved current-cycle facts exist in ctx.cy
  Daily Capacity use of that cycle still needs an explicit caller decision/provenance

arithmetic_domain
  a checked snapshot-wide proof already exists in ctx.arithmetic_currency_proof
  reuse is valid only when asset and obligation evidence remains tied to that proof input

asset_scope
  account descriptors and balances exist
  owner admission and basis selection do not

obligation_scope
  plan identity/completion signals and metadata candidates exist
  canonical obligation admission and per-obligation reservation provenance do not
```

Therefore neither current `POLICY_RISK_STYLE`, all `role=asset type=liquid` accounts, all open plan rows, nor aggregate execution-envelope coverage can be treated as the missing policy owner.

## Classification vocabulary

This audit uses four classes:

```text
mechanical fact
  reproducible from admitted source or an existing checked projection

explicit owner policy
  a household choice that must be supplied with decision provenance

current implicit inference
  behavior current runtime performs, but which is not target owner evidence

no current owner
  a required target fact or policy for which no canonical repository carrier exists
```

## Carrier ownership matrix

| Carrier | Candidate evidence owner | Candidate policy owner | Existing fields / projections | Missing evidence | Buildable without inference? | Explicit adapter input |
|---|---|---|---|---|---|---|
| `observation` | `src_next/report.bqn` supplies `O`; `outlook.BuildAt(ctx,O)` consumes it | caller / report adapter | explicit `--outlook-as-of`, `report_today`, `BuildAt` argument | normalized `source` provenance is not carried by current `BuildAt` | **Yes**, when `O` and source are explicit; **no** from `L` | `{date, source}` |
| `horizon` | `cycle.ReadCycle`; carrier `ctx.cy` | ledger owner selects cycle rules in `cycle.tsv`; Daily Capacity caller must explicitly select the resolved cycle as this calculation's horizon | `mode`, `start`, `end_exclusive`, `day_count` | contract `state`, `kind`, `source_ref`; explicit Daily Capacity horizon decision; stronger resolver diagnostics | **Yes**, from a resolved `ctx.cy` plus explicit `kind=cycle` decision/provenance | resolved cycle evidence + `horizon_policy_ref` / selection |
| `arithmetic_domain` | `currency_arithmetic.bqn` plus `context.ResolveArithmeticCurrencyProof`; carrier `ctx.arithmetic_currency_proof` | normally none: proof is fact; a selected domain in a partitioned/mixed path would be caller policy | proof `state`, `domain`, `amount_scale`, `basis`, `message`; source-row evidence | contract field rename `domain -> currency`; proof-to-admitted-evidence relationship when downstream modules reread source | **Yes**, only from a proven proof tied to the same supplied evidence snapshot | proven proof; if partitioned, explicit selected currency and selection provenance |
| `asset_scope` | descriptors: `account_key.Resolve`; balances: `actual_snapshot.BuildAt` or a future O-bounded fold of checked `ctx.posting_rows`; pool facts: `envelope_computation` | **no current owner** for Daily Capacity account/pool admission or basis selection | account key/currency/role/type; parallel balance vector; envelope `remaining`, role, sources, backing diagnostics | explicit include/exclude decisions, `scope_id`, `policy_ref`, basis choice, stable source refs, same-snapshot O-bounded balances; O-relative pool semantics | **No** for resolved scope | basis choice + per-asset decisions + decision provenance |
| `obligation_scope` | plan source; `plan_evidence` / `plan_rows`; ambiguity diagnostics in `plan_journal_overlap`; row currency evidence in context | **no current owner** for Daily Capacity obligation admission | source date/endpoints/amount, `plan_id`, completion mask, actual amount, temporal status; metadata candidates `due_on`, `cashflow`; expense `spend_class` | canonical due coordinate, identity quality, settlement proof, per-row currency/scale linkage, include/exclude decisions, reservation state/ref/amount | **No** for resolved scope | per-obligation decision + decision basis + accepted settlement evidence + reservation evidence |

## 1. Observation

### Mechanical facts

The current human report already has the correct ownership shape:

```text
explicit --outlook-as-of
  or report entry reads Today once
    -> outlook.BuildAt(ctx, O)
```

`O` is independent of recorded frontier `L`. Current checks prove that changing Outlook `O` does not redefine snapshot or Daily Trend observation.

### Policy and current inference

The caller chooses `O`; the Daily Capacity adapter must not choose it. `outlook.Build(ctx)` remains a compatibility path that substitutes local recorded frontier `L`. That is current implicit behavior, not canonical Daily Capacity observation policy.

### Missing carrier evidence

`BuildAt` receives only date text. The Daily Capacity carrier also requires inspectable source provenance such as `explicit_argument`, `report_today`, or `synthetic_test`.

### Conclusion

Observation can be built without inference if the adapter requires both date and source. It must reject an attempt to derive `O` from `ctx.as_of`, cycle start, or latest journal date unless the caller explicitly labels a compatibility source.

## 2. Horizon

### Mechanical facts

`cycle.ReadCycle` resolves the current period and `BuildContext` carries it as:

```text
ctx.cy = {mode, start, end_exclusive, day_count}
```

The resolver supports fixed, income-anchor, and calendar-month shapes. These all produce the same half-open interval form required by the first Daily Capacity consumer.

### Policy owner

`cycle.tsv` owns the ledger's current cycle rule. That makes the resolved cycle a strong candidate fact, but not a universal Daily Capacity policy. The adapter still needs an explicit decision that this calculation uses the current resolved cycle horizon.

### Current implicit behavior and gaps

- `BuildContext` and cycle compatibility defaults may derive dates from journal/plan frontiers or system today.
- `cycle.bqn` represents unavailable as `mode/start/end_exclusive="unavailable"` and `day_count=0`, not the contract's explicit state carrier.
- the current cycle namespace has no source reference or policy reference;
- fixed/calendar resolution does not itself provide the full structured diagnostic vocabulary expected by Daily Capacity.

### Conclusion

A horizon adapter can mechanically normalize a supplied resolved cycle, but it must also require explicit `kind=cycle` selection and provenance. It must not infer a monthly horizon or income cadence.

## 3. Arithmetic domain

### Mechanical facts and owner

The current checked path already has the correct ownership split:

```text
context
  builds source-row evidence from one posting snapshot
currency_arithmetic
  proves one domain and amount scale
context.ResolveArithmeticCurrencyProof
  carries state/domain/amount_scale/basis/message
projection
  authorizes naked-delta construction
ctx.arithmetic_currency_proof
  carries the result
```

The Daily Capacity adapter can normalize `proof.domain` to carrier field `currency` without inventing a domain.

### Important linkage gap

The proof is valid for evidence derived from the same checked snapshot. `actual_snapshot.BuildAt` currently rereads `journal.tsv`, while `plan_rows` rereads plan/journal sources. A future adapter must not attach `ctx.arithmetic_currency_proof` to independently reread values as if same-snapshot provenance were proven.

`account_key.currency`, an AccountKey suffix, a config declaration, or a report-selected display currency is not arithmetic-domain proof.

### Conclusion

The arithmetic carrier is mechanically constructible from a proven context proof only when the adapter also receives facts derived from the corresponding checked evidence. Mixed-domain selection remains a separate explicit caller decision; no conversion is available.

## 4. Asset scope

### Mechanical account-balance facts

Existing account descriptors expose:

```text
accounts
account_keys
currencies
roles
types
budgets
budget_groups
spend_classes
kinds
envelope_roles
```

`actual_snapshot.BuildAt(ctx,O)` exposes an O-bounded parallel amount vector, entries, and a liquid breakdown. It is the current report fact producer, but it reparses journal source and integer amounts rather than consuming the context's checked posting snapshot.

`TBDS` provides checked actual closing rows with account identity, currency, role/type, and provenance-friendly indices, but its current closing is the selected period end, not arbitrary Outlook `O`. It cannot silently substitute for an O-bounded balance.

A future fact adapter could mechanically fold `ctx.posting_rows` where `layer=actual` and `date<=O`; no current focused owner exposes that exact view yet.

### Mechanical pool facts

`envelope_computation` exposes per-envelope:

```text
account_index / account_name / label
envelope_role
allocated / actual_spent / remaining
```

and backing evidence:

```text
funding_base
allocated_total
cash_backed_unassigned
funding_sources
active_sources
budget movements
```

These prove that current envelopes are budget-layer claims over an actual funding base. They do not prove owner admission into Daily Capacity. Current envelope timing is primarily cycle/local-frontier based, not a proven arbitrary-O pool snapshot.

### Current implicit inferences

Current Outlook and envelope backing use:

```text
role=asset AND type=liquid
```

Current Outlook additionally chooses displayed life envelopes through configured group labels. These are current compatibility/display policies, not Daily Capacity owner admission.

`PolicyBudgetStyle`, `HOUSEHOLD_GROUP_*`, `envelope_role`, and `EXECUTION_PLANNED_PAYMENTS_ENVELOPE` must not be reinterpreted as asset-scope policy.

### No current owner

No current field or config structure owns:

- `basis_kind=account_balance|pool_remaining` for Daily Capacity;
- explicit included/excluded account or pool identities;
- a Daily Capacity `scope_id` / `policy_ref`;
- an owner decision to exclude an emergency/restricted balance that remains technically liquid.

### Conclusion

A resolved asset scope cannot currently be built without explicit supplied policy. `role/type` may generate candidates only. Account names, prefixes, envelope labels, and aggregate backing values are prohibited admission heuristics.

## 5. Obligation scope

### Mechanical plan and settlement facts

The strongest current chain is:

```text
plan source row
  -> plan_evidence / plan_rows
  -> plan_id (or compatibility five-field fallback)
  -> journal plan_id match
  -> completed_mask / actual amount / temporal status
```

`plan_journal_overlap` additionally distinguishes one-to-one strong overlap from ambiguous matches. This is relevant because `plan_rows.completed_mask` alone uses any matching identity and does not carry identity provenance or ambiguity into each row.

Current source metadata provides candidate facts:

```text
plan_id
due_on
cashflow=fixed_obligation
```

Account metadata provides `spend_class=fixed|variable`. These meanings are not interchangeable:

- plan date or `due_on` may provide a due coordinate;
- `cashflow=fixed_obligation` is an explicit classification signal for a row;
- `spend_class=fixed` classifies an expense account, not an individual unpaid obligation;
- `plan_id` supports settlement linkage, not obligation admission policy.

### Current implicit inference

Current Outlook daily arithmetic admits all remaining raw-plan negative liquid deltas in `[O,C)`, subject to anchor activation. It does not require shared completion evidence or obligation classification. A liquid-to-non-liquid transfer can therefore enter its reserve bucket.

The separate next-cycle display uses a `liabilities:` prefix on one boundary date. This is a compatibility display heuristic, not an obligation owner.

### Settlement gaps

Before a future source-backed adapter can claim `settlement_state`, it must resolve at least:

- explicit ID versus five-field fallback provenance;
- duplicate plan IDs or multiple matching journal rows;
- partial/mismatched actual amounts;
- whether journal evidence outside the current cycle may settle an obligation;
- a canonical due coordinate when source date and `due_on` differ;
- currency and exact scale tied to the admitted row evidence.

A raw unmatched plan is useful candidate evidence, but absence of a match is not automatically a complete proof of an open obligation under every malformed/ambiguous identity state.

### Reservation provenance

Current execution coverage compares one envelope remaining amount with the aggregate unfinished planned total. It has plan rows and IDs, but no per-obligation allocation identity or exact reserved amount.

Therefore it cannot produce:

```text
reservation_state=proven
reservation_ref=<unique exact allocation link>
excluded_from_asset_basis=<exact amount>
```

Aggregate equality, an execution envelope name, budget group, or matching totals is insufficient. For an account-balance basis, virtual envelopes remain inside those account balances and do not mechanically justify positive exclusion. For a pool basis, the relationship may be ambiguous and must fail unavailable unless exact linkage is supplied.

### No current owner

No current repository carrier owns:

- per-obligation `decision=include|exclude` for Daily Capacity;
- `decision_basis` / obligation policy reference;
- exact per-obligation reservation linkage for open obligations;
- a complete normalized obligation row combining identity, due date, currency, settlement, decision, and reservation evidence.

Open issue amounts are not obligation authority.

### Conclusion

Obligation candidates can be produced mechanically, but a resolved obligation scope cannot. Owner decisions and reservation evidence must be explicit adapter inputs.

## Asset and obligation classification summary

| Category | Asset scope | Obligation scope |
|---|---|---|
| Mechanical source facts | account identity/currency/role/type; checked postings; current O-balance and envelope remaining views | plan row/date/endpoints/amount; metadata tokens; plan/journal identity matches; temporal status |
| Explicit owner policy required | basis kind; include/exclude each account/pool; scope/policy reference | include/exclude each candidate; decision basis; accepted horizon/due semantics |
| Current implicit inference | all `role=asset type=liquid`; configured life-group envelope display; liquid funding-base fallback | all remaining negative liquid plan deltas; anchor activation; `liabilities:` prefix display |
| No current owner | Daily Capacity asset admission carrier; O-relative pool fact owner | canonical obligation admission; complete settlement proof carrier; per-obligation reservation provenance |

## Config ownership result

`src_next/config.bqn` owns validation of existing keys only. None is a Daily Capacity owner:

- `POLICY_RISK_STYLE` remains a compatibility switch for `liq_safe_daily`;
- `POLICY_BUDGET_STYLE` enables/disables envelope behavior;
- `HOUSEHOLD_GROUP_*` groups display/policy diagnostics;
- `EXECUTION_PLANNED_PAYMENTS_ENVELOPE` selects one aggregate coverage diagnostic;
- `POLICY_INCOME_CADENCE` must not define horizon implicitly.

No existing key may be renamed or reinterpreted to fill the missing decisions in an adapter characterization.

## Candidate adapter boundaries

### Candidate A — resolved-evidence assembler

```text
AssembleDailyCapacityInputFromResolvedEvidence request
  -> {
       state,
       input,        # empty or five-part Daily Capacity carrier
       diagnostics
     }
```

Explicit request parts:

```text
observation_with_source
resolved_cycle_evidence + explicit horizon selection
proven arithmetic_currency_proof
asset_basis_evidence + explicit asset decisions
obligation_candidates + explicit obligation decisions
settlement evidence
per-obligation reservation evidence
```

- **Existing modules read inside:** none. It consumes already-built values. Upstream candidate owners are `context`, `cycle`, `account_key`, a future checked O-balance view, `plan_rows`/overlap diagnostics, and currency proof.
- **New config/metadata/schema:** none for synthetic characterization.
- **Synthetic while unconnected:** yes; dependency-free in-memory cases can cover ownership missing/ambiguous/error states.
- **Policy inference risk:** low, because unresolved decisions remain unavailable rather than being generated from role/type/name.
- **Minimality:** highest. It characterizes the seam between fact producers/policy inputs and the existing calculator without selecting source loading or storage.

### Candidate B — checked account-balance context adapter

```text
BuildAccountBalanceDailyCapacityInput
  ⟨observation, resolved_cycle, arithmetic_proof,
    resolved_accounts, checked_posting_rows,
    explicit_account_decisions,
    normalized_plan_settlement_evidence,
    explicit_obligation_decisions,
    reservation_evidence⟩
  -> adapter result
```

- **Existing modules used:** context checked posting rows/proof, account-key descriptors, date/cycle helpers, and normalized plan settlement evidence.
- **Explicit inputs:** selected account identities, obligation decisions, reservation states, and policy references.
- **New config/metadata/schema:** none for synthetic tests; later runtime persistence remains a separate decision.
- **Synthetic while unconnected:** yes, using forged checked rows/descriptors.
- **Policy inference risk:** medium-low if decisions are mandatory; high if it falls back to all liquid accounts or all plans.
- **Minimality:** medium. It additionally owns an O-bounded Posting-IR balance projection and settlement normalization, overlapping the separately planned Outlook/actual-snapshot numeric-owner alignment.

### Candidate C — pool-remaining / envelope adapter

```text
BuildPoolRemainingDailyCapacityInput
  ⟨observation, resolved_cycle, arithmetic_proof,
    envelope_view, explicit_pool_decisions,
    normalized_obligations, explicit_obligation_decisions,
    exact_reservation_links⟩
  -> adapter result
```

- **Existing modules used:** envelope computation/backing evidence plus shared plan evidence.
- **Explicit inputs:** selected pool identities and exact per-obligation reservation links.
- **New config/metadata/schema:** none for a synthetic characterization, but current runtime has no source carrier for exact open-obligation reservation links.
- **Synthetic while unconnected:** yes.
- **Policy inference risk:** high if group labels, execution-envelope name, or aggregate equality are used as links.
- **Minimality:** lowest now. Current envelope remaining is not proven at arbitrary `O`, and aggregate execution coverage cannot supply the required provenance.

## Comparison

| Criterion | A: resolved assembler | B: account-balance context | C: pool/envelope |
|---|---:|---:|---:|
| No source/config read in candidate | yes | yes if supplied checked rows/views | yes if supplied view |
| Requires explicit owner policy | yes | yes | yes |
| New config/metadata/schema for characterization | no | no | no |
| Synthetic characterization before Outlook wiring | yes | yes | yes |
| Reuses current facts directly | through supplied values | strong | partial / blocked |
| Hidden inference risk | low | medium | high |
| New arithmetic/projection ownership | none | O-balance + settlement normalization | O-pool + linkage normalization |
| Current readiness | ready to characterize | requires narrower subcontracts | blocked by missing O/linkage facts |

## Recommendation, not selection

Candidate A is the safest next candidate for a separately selected test-only slice.

It should characterize only adapter assembly and diagnostics over explicit in-memory facts and decisions. In particular:

```text
missing asset decision
  -> asset_scope.state=unavailable

missing obligation decision
  -> obligation_scope.state=unavailable

ambiguous pool/obligation relationship
  -> reservation_state=ambiguous

unproven arithmetic domain
  -> adapter error; no plausible carrier
```

It must not calculate balances from source, resolve owner choices, call Outlook, or add persistence. Candidate B can be reconsidered only after Candidate A fixes the exact normalized fact/policy input shape. Candidate C should remain blocked until arbitrary-O pool evidence and per-obligation reservation linkage exist.

This recommendation is evidence only. It does not select an implementation or characterization slice.

## Non-goals retained

This audit does not authorize or change:

- runtime adapter code or tests;
- config keys or interpretation;
- account/plan metadata or TSV schemas;
- Outlook, report, summary, JSON, CLI, UI, or editor paths;
- `POLICY_RISK_STYLE`, `liq_daily`, or `liq_safe_daily`;
- private or production data;
- currency conversion or mixed-currency arithmetic;
- automatic account, obligation, or reservation inference;
- the next slice.

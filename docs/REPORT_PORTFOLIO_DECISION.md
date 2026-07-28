# Report portfolio reset decision

Status: approved direction
Decision date: 2026-07-28
Decision owner: moko
Implementation owner: ledger kernel / report
Supersedes: the destination requirement to preserve all 15 current report sections

## Decision

The canonical ledger/accounting architecture is the durable product. Current report sections are not.

The migration will preserve useful accounting questions and operational capabilities, but it may rebuild, merge, relocate, or delete current reports and output surfaces. We will not carry old report complexity into the destination solely to obtain 15-section parity.

Current production remains unchanged until an atomic cutover. This decision authorizes destination portfolio redesign; it does not authorize partial production routing, forwarding aliases, private-data inspection, or household-data modification.

## Minimum destination portfolio

### Core statement and Lists

| concept | required question | natural result |
|---|---|---|
| Envelope & Backing | What remains in each envelope, and which admitted assets, allocations, Actual spend, and open Plans support it? | policy-heavy Statement: summary Cards plus evidence Matrix/List |
| Account Balances | What is the latest exact balance of every Account in one explicit currency domain? | Matrix/List by Account |
| Recent Journal | What was recorded recently, in source order, with exact lanes and durable provenance? | Transaction List |
| Planned Payments | Which Plans are open/due/overdue/completed, and what Actual evidence fulfilled them? | Plan List plus exact total |
| Issues | Which explicit source issues remain open? | Issue List |

### Account Matrix family

| concept | required question | initial matrix direction |
|---|---|---|
| Current-cycle Accounts | How did each Account move through the resolved cycle? | Account × opening/debit/credit/movement/closing |
| Cycle comparison | How does current-cycle Account activity compare with the previous cycle? | Account × current/previous/difference, with an explicit full-cycle or aligned-observation policy |
| Monthly Accounts | How do Account movement and/or closing state change month by month? | Month × Account or Account × Month under one explicit measure contract |

These are concrete report questions, not permission to build a textual query DSL or one universal three-axis report record. Shared Matrix operations are extracted only after the concrete builders agree.

### Special projection

| concept | required question | natural result |
|---|---|---|
| Daily Target | Given an explicit target date, balances, backing, open Plans, expected income, and reserve policy, what daily amount is safe? | Card/Projection with evidence |

Daily Target and Issues are intentionally not forced into MatrixResult. Recent Journal and Planned Payments remain Lists. Envelope & Backing may combine summary Cards with bounded tabular evidence because its policy question is not a plain balance Pivot.

## Current 15-section disposition

This is a destination disposition, not an immediate production deletion.

| current section | destination direction |
|---|---|
| `snapshot` | decompose into Account Balances, Envelope & Backing, and Daily Target; no obligation to retain a snapshot section |
| `issues` | rebuild as the retained Issues List |
| `ytd` | replace with a bounded Monthly Accounts/year-to-date preset if still useful |
| `balances` | rebuild as retained Account Balances |
| `cycle` | decompose into Current-cycle Accounts and Daily Target |
| `trial-balance` | retain its Account-period capability; expose as Current-cycle Accounts or developer accounting evidence rather than preserving the old section automatically |
| `envelopes` | rebuild as the central Envelope & Backing statement |
| `planned` | retain the destination Planned Payments List already proved |
| `recent` | rebuild as retained Recent Journal |
| `check` | move readiness/validation to an operational command; not a normal report |
| `outlook` | replace with the narrower Daily Target projection and backing evidence |
| `daily-trend` | replace with Account Matrix and/or Daily Target capabilities; do not preserve automatically |
| `daily-flow` | its sparse Group/Pivot proof remains useful; the current section may be removed unless a concrete category-flow question is retained |
| `actual-comparison` | replace with explicit Cycle Comparison Matrix semantics |
| `debug` | move to developer inspection/diagnostic commands; not a production report |

## What remains durable from completed work

- canonical Transaction/Posting Facts and Source/Domain/Account/Layer coordinates;
- strict Actual/Plan/Budget/config/cycle admission;
- exact coefficient/scale arithmetic;
- source-qualified Transaction/Posting provenance;
- Account-period opening/movement/closing capability;
- sparse Group/Pivot and dense MatrixResult;
- pure cycle resolution;
- durable Plan completion Join;
- the destination Planned Payments result/renderers;
- Trial Balance and Daily Flow as architectural proofs, even if their final section names/bodies are not retained.

Deleting a report does not imply deleting a generally useful proved capability. Conversely, a proof module is removable if it has no retained consumer after the portfolio is implemented.

## Output and cutover policy

- The old 15 keys, order, metadata rows, cache files, compact blocks, and JSON surfaces are current-runtime inventory, not destination requirements.
- Exact output contracts will be defined only for retained destination reports.
- A removed/merged report is an intentional break: route, metadata, cache entry, compact key, query consumer, tests, and stale docs are removed together.
- No old/new alias period and no dual compact keys are allowed.
- Full-report composition iterates the retained static portfolio without constructing one all-report semantic record.
- Unsupported old JSON or compact surfaces may disappear when their owning report is removed.
- Production remains `tools/report -> src_next/report.bqn` until the revised portfolio and source-readiness cutover gate pass.

## Contract checkpoint completed

Portfolio Contract P1 is recorded in:

- `REPORT_PORTFOLIO_CONTRACT.md` — final keys/surfaces, three Account Matrix contracts, Envelope & Backing terms, Daily Target semantics, and implementation order;
- `REPORT_SURFACE_RETIREMENT_MAP.md` — tracked consumer families and per-old-section atomic migration/removal actions.

Implementation proceeds by retained question and dependency order. It does not resume mechanical 15-section migration.

## Private-data boundary

Portfolio and contract design use repository code, documents, and public synthetic evidence. Whether a report is useful can be decided by moko without exposing household rows. Any private-source audit, output comparison, readiness preview, or source migration still requires separate explicit direction.

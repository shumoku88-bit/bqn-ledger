# Ledger Observatory long-term plan

Status: active long-term plan
Owner: observability / projection / learning
Canonical: yes; canonical path: `docs/archive/active-plans/LEDGER_OBSERVATORY_LONG_TERM_PLAN-2026-07-13.md`
Exit: archive only after the program is either explicitly completed, superseded, or declined. Individual slices may close independently without closing this plan.

## Purpose

This plan explores `bqn-ledger` as an observatory for derived accounting arrays, not only as a household report generator.

The program connects six related directions:

1. evidence trace from source TSV rows through Posting IR, Cube, TBDS, and report consumers;
2. ephemeral scenario overlays that compare a baseline with hypothetical postings without changing source TSV;
3. Cube Theatre views that expose selected axes, slices, masks, and transpositions through plain structured output;
4. BQN Ledger Kata exercises built from repository fixtures and verified outputs;
5. a later Projection Workbench extracted only from repeated concrete projection needs;
6. repository-as-AI-laboratory observations about how documentation, fixtures, checks, and finite slices affect AI-assisted maintenance.

The goal is not to build a universal analytics framework, visual application, or event-sourcing rewrite. The goal is to make existing transformations inspectable, comparable, learnable, and easier to verify.

## Program shape

```text
source TSV
  -> validated source snapshot
  -> Posting IR
  -> Canonical Daily Cube / TBDS
  -> report consumers

        | evidence trace
        | ephemeral scenario delta
        | axis-oriented Cube views
        | fixture-based kata
        | repeated projection seams
        | AI-work observations
```

The six directions share data and evidence, but they are not authorized as one broad implementation campaign. Every implementation must be selected as a separate finite slice with its own consumer, inputs, outputs, exclusions, fixtures, and checks.

## Principles

### Source data remains protected

- `journal.tsv`, `plan.tsv`, `budget_alloc.tsv`, `accounts.tsv`, `cycle.tsv`, and `issues.tsv` remain source data under their current contracts.
- Observatory work is read-only unless a later independently selected writer plan says otherwise.
- Scenario inputs are ephemeral and must not silently become journal or plan source rows.
- No observatory consumer may mutate production source, infer approval, or bypass the BQN editor safety boundary.

### Existing accounting meaning remains authoritative

- Posting direction, account resolution, currency admission, exact arithmetic, Cube construction, and TBDS remain owned by their current modules.
- Observatory code must reuse validated carriers and must not duplicate accounting logic in shell, UI, teaching material, or AI adapters.
- A trace explains current computation. It does not redefine that computation.

### BQN owns meaning; presentation remains outside

- BQN may emit plain text, TSV, JSON, structured coordinates, semantic status words, and evidence descriptors.
- ANSI styling, cursor control, interactive expansion, graphical layout, and terminal-specific display remain presentation-layer responsibilities.
- Cube Theatre begins as structured or plain output, not as a rich TUI requirement.

### Concrete consumers precede abstraction

- Projection Workbench is intentionally deferred.
- No generic projection DSL, dataframe layer, query language, or universal axis framework is authorized by this plan.
- Shared helpers may be extracted only after at least two independent consumers demonstrate the same contract and shape.

### Learning artifacts do not bend production contracts

- Kata uses public synthetic fixtures, small copied descriptors, or dedicated teaching fixtures.
- Production modules must not be simplified, renamed, or widened solely to make exercises easier.
- A kata may explain shape, axis, mask, projection, and evidence, but its expected answer remains grounded in executable repository behavior.

### AI observation is evidence, not automatic backlog

- AI misunderstandings, repeated rereads, CI-only failures, missing fixture coverage, and stale documentation may be recorded.
- An observation does not automatically become an implementation task.
- Promotion into `TODO.md` requires a concrete repeated signal and a separately selected finite response.

## Direction A: Evidence trace

### Question

For a selected source row, posting, Cube cell, TBDS movement, or report value, what validated evidence contributed to the result?

### Desired boundary

A trace should be able to describe some or all of:

- source file kind and privacy-safe row identity;
- parsed source descriptors;
- generated Posting IR rows and signed deltas;
- resolved account keys;
- date ordinal / dense day coordinate;
- Cube coordinates `(day, account, layer)` and contributions;
- TBDS period, opening, movement, and closing contributions;
- consuming report section or ViewModel field when a concrete consumer exists.

### Non-goals

- no source mutation;
- no alternate accounting calculation;
- no promise that every report field is immediately traceable;
- no broad provenance graph database;
- no exposing private memo, party, receipt, or amount content in public diagnostics by default;
- no UI integration in the first slice.

### Candidate first finite slice

The preferred first implementation candidate is a pure, fixture-only source-row-to-Cube trace.

Inputs:

- supplied validated synthetic account lines;
- one supplied synthetic journal-like row or a supplied validated posting snapshot;
- an explicit row index or stable synthetic row descriptor;
- explicit layer selection, initially `actual` only.

Output:

- structured accepted/rejected result;
- exactly the selected row evidence;
- generated postings;
- resolved account indexes;
- exact Cube coordinates and signed contributions;
- privacy-safe diagnostics;
- no file I/O and no report/UI wiring.

The first slice must not include TBDS, report-field tracing, production source reads, CLI design, or generic tracing infrastructure unless separately selected.

## Direction B: Ephemeral scenario overlays

### Question

How would a supplied hypothetical posting or small posting set change a selected derived view, without becoming source data?

### Desired boundary

```text
validated baseline snapshot
  + validated ephemeral scenario postings
  -> independently derived scenario result
  -> explicit baseline / scenario / diff carrier
```

A scenario must have a visible identity and provenance such as `ephemeral_input`; it must never masquerade as `actual`, `plan`, or committed `forecast` source.

### Candidate consumers

- one hypothetical expense and its selected balance difference;
- next-cycle or next-income-date runway difference;
- envelope coverage difference;
- comparison of two explicitly supplied alternatives.

### Non-goals

- no scenario source file in the first slices;
- no automatic recommendation or approval;
- no Monte Carlo forecasting;
- no solver, optimizer, or budget generator;
- no source write, plan promotion, or journal commit;
- no arbitrary number of scenario axes until a concrete consumer requires it.

### First implementation rule

Scenario work begins only after the trace carrier or equivalent validated posting evidence is available for reuse. The first selected scenario slice should accept exactly one hypothetical journal-like posting and return one narrow baseline/scenario/diff consumer.

## Direction C: Cube Theatre

### Question

What becomes visible when the same derived array is sliced, masked, transposed, or presented with different axes in front?

### Desired boundary

Cube Theatre is a read-only presentation consumer over existing derived arrays. BQN owns axis selection, data meaning, labels, and structured output. External presentation may later add layout or interaction.

Candidate views include:

- `Day × Account` for one layer;
- `Account × Layer` for one period or observation date;
- `Day × Layer` for one selected account group;
- baseline versus scenario deltas after a scenario consumer exists;
- selected masks such as expense-role accounts or non-zero cells.

### Non-goals

- no rich TUI requirement;
- no ANSI or cursor control in BQN;
- no direct editing from a Cube cell;
- no unbounded pivot-table product;
- no generic charting framework;
- no new canonical axis merely for display convenience.

### First implementation rule

The first Cube Theatre slice should expose one already-existing array in one alternate orientation with a fixed, documented shape contract and fixture. It should not wait for a general Workbench.

## Direction D: BQN Ledger Kata

### Question

Can repository fixtures and observatory evidence become small executable exercises about shape, axes, masks, projection, and accounting meaning?

### Desired form

Each kata should contain:

- one narrow question;
- explicit input fixture or supplied small value;
- expected shape and axis interpretation;
- expected semantic result;
- one executable check or reference output;
- a short explanation of why the result follows from the accounting contract.

Candidate early kata:

- identify which Cube cells receive one journal row;
- select expense accounts with a mask;
- compare `actual` and `plan` for one account or period;
- transpose an `Account × Layer` view and explain what changed and what did not;
- apply one ephemeral posting and inspect the resulting difference.

### Non-goals

- no requirement to teach the whole BQN language;
- no production-code rewrite for pedagogy;
- no broad tutorial campaign before one useful exercise is reviewed;
- no private operational data.

### First implementation rule

The first kata should reuse the first accepted evidence-trace fixture and expected result. It may be a separate docs/test slice after the trace slice is complete.

## Direction E: Projection Workbench

### Question

After concrete consumers exist, which projection operations genuinely repeat and deserve a shared internal carrier or helper?

Possible repeated operations include:

- select a validated source or derived carrier;
- apply an explicit mask;
- choose or reorder axes;
- aggregate over one documented axis;
- attach labels;
- emit structured plain output.

### Admission rule

Projection Workbench remains `hold / later` until at least two independent observatory consumers expose materially identical operations and shape contracts. Similar-looking code is insufficient if the semantic owners differ.

### Explicit exclusions

- no external DSL;
- no query parser;
- no user-authored arbitrary expressions;
- no dataframe compatibility layer;
- no attempt to replace `context.bqn`, `cube.bqn`, `tbds.bqn`, or report-specific ViewModels;
- no abstraction justified only by anticipated future consumers.

## Direction F: Repository as AI laboratory

### Question

Which repository structures make AI-assisted work safer, more accurate, less repetitive, and easier to verify?

Candidate observation fields:

- task / PR identifier;
- selected finite slice and declared exclusions;
- documents read or missed;
- contract misunderstood;
- local-only versus CI-exposed defect;
- fixture or check that caught the defect;
- repeated reread or navigation friction;
- documentation drift found;
- whether the observation warrants no action, docs clarification, fixture work, or a separately selected finite task.

### Storage boundary

Use the existing AI working feedback intake or a small dedicated observation document if a repeated concrete need appears. Do not create a source-of-truth telemetry system, token accounting framework, or automatic task queue under this plan.

### Non-goals

- no employee-style performance score for AI agents;
- no ranking of model vendors from anecdotal samples;
- no automatic TODO creation;
- no collection of private ledger values;
- no broad CI instrumentation without a concrete debugging consumer.

## Suggested long-term sequence

This sequence is directional, not authorization.

### Phase 0: contract map

- document existing source snapshot, Posting IR, Cube, TBDS, report, JSON, and presentation boundaries;
- identify privacy-safe row identity options for synthetic traces;
- select the first finite evidence-trace slice separately.

### Phase 1: one evidence specimen

- implement and verify one pure source-row-to-Cube trace on synthetic input;
- keep output structured and small;
- review whether the carrier is understandable enough to support one kata.

### Phase 2: one learning specimen

- add one kata reusing the trace fixture;
- include shape and axis explanation;
- record any AI or human misunderstanding revealed by the exercise.

### Phase 3: one scenario specimen

- select one ephemeral posting consumer;
- produce baseline, scenario, and difference without source writes;
- reuse validated posting / trace carriers where appropriate.

### Phase 4: one alternate Cube view

- expose one fixed-axis Cube Theatre view;
- optionally display scenario differences only if the scenario contract already exists;
- keep presentation outside BQN.

### Phase 5: abstraction review

- compare the completed consumers;
- list truly repeated projection operations and semantic differences;
- either extract one small shared helper or explicitly decline Projection Workbench.

### Phase 6: long-term observation

- continue recording concrete AI-work friction through existing maintenance lanes;
- promote only repeated, evidenced problems into separate finite work.

## Slice selection checklist

Before any implementation slice is selected, answer all of:

1. What exact human, debugging, teaching, UI, or AI consumer needs the output?
2. What supplied carrier or source snapshot is authoritative?
3. Which existing module owns each accounting meaning?
4. What is the exact input and output shape?
5. How are source row identity and private fields protected?
6. What source files and runtime entrypoints remain untouched?
7. What synthetic fixture proves the accepted path?
8. What rejected cases fail closed with zero partial output?
9. Is this a concrete consumer or premature Workbench infrastructure?
10. Which documentation and check become canonical for this slice?

## Program-level non-goals

- replacing the current TSV source model with a universal event log;
- converting `bqn-ledger` into a general array database;
- making every internal value traceable before a consumer exists;
- adding a Scenario axis to the Canonical Daily Cube by default;
- adding a new canonical Currency axis through observatory work;
- building a full TUI, GUI, web application, notebook platform, or visualization framework;
- teaching all of BQN;
- performing AI-generated source writes;
- broad refactoring of current report modules merely to make the architecture look uniform;
- automatically beginning later phases when an earlier phase closes.

## Initial routing decision

This plan is created as a docs-only long-term direction. It selects no runtime implementation by itself.

The next eligible finite design candidate is:

> Evidence trace Step 1: define a pure synthetic source-row-to-Cube trace contract, privacy-safe identity, exact carrier shape, rejection behavior, and focused fixture/test boundary.

Selecting that candidate requires a separate explicit TODO change or design PR. Scenario overlays, Cube Theatre, Kata, Projection Workbench, and new AI-observation infrastructure remain unselected.

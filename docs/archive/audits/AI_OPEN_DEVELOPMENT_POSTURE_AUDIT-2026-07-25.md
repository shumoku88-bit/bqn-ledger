# AI open development posture audit — 2026-07-25

Status: audit snapshot
Owner: docs / workflow
Canonical: no; proposed current targets: `AGENTS.md`, `README.md`, `docs/README.md`, `docs/AI_WORKING_FEEDBACK_PROCESS.md`, `TODO.md`
Exit: supersede with an approved open-development posture and the first docs-only rewrite slice

Baseline: `main` at `f88d61d460ee180c8fb8f7bbcc8c1916249a67ba`

## 1. Purpose

This audit observes whether the current repository documentation helps AI participate as a development partner who can:

- notice patterns and inconsistencies during ordinary work;
- question existing assumptions and module boundaries;
- compare alternatives and state an opinion;
- surface unexpected discoveries to moko;
- try small reversible improvements that support the active goal;
- preserve canonical data, privacy, and accounting correctness while doing so.

The desired culture is not unrestricted mutation. It is a repository where the protected center is explicit and the surrounding design space is open to observation, judgment, and revision.

## 2. Scope and method

This first pass combined:

1. close reading of the current authority chain:
   - `README.md`
   - `AGENTS.md`
   - `TODO.md`
   - `docs/README.md`
   - `docs/QUALITY_BAR.md`
   - `docs/SAFETY_PROFILE.md`
   - `docs/DOCS_LIFECYCLE_CONTRACT.md`
   - `docs/AI_WORKING_FEEDBACK_PROCESS.md`
   - `docs/archive/active-plans/AI_WORKING_FEEDBACK_LOG.md`
2. repository-wide indexed searches for prohibitive language such as `must not`, `do not`, and `してはいけ`;
3. classification of each pattern by purpose rather than by vocabulary alone.

This document does not mechanically rewrite every matching sentence. It identifies the current authority points and the recurring language patterns that shape agent behavior. Archive documents are treated as historical evidence, except where current routing explicitly sends agents back into them.

## 3. Executive finding

The repository already has several ingredients for open development:

- reversible changes are valued;
- AI feedback has a dedicated intake path;
- historical documents are formally separated from current contracts;
- source data and private data boundaries are explicit;
- documentation ownership is carefully recorded.

However, the current authority chain converts those strengths into a permission-heavy workflow.

The dominant message received by an AI is currently:

```text
read the selected route
choose one finite candidate
avoid adjacent changes
record discoveries without acting on them
wait for classification
wait for an approved plan
implement only the approved slice
```

This encourages reliable execution, but it also teaches the AI that independent judgment is a scope risk. Discovery becomes an intake artifact instead of part of development. A new idea must pass through several documents before even a small reversible experiment becomes legitimate.

The central problem is therefore not the presence of safety rules. It is the use of the same restrictive language for three very different things:

1. canonical-data and privacy protection;
2. accounting and arithmetic invariants;
3. ordinary development scope and intellectual initiative.

The first two deserve strong boundaries. The third should become an invitation to think.

## 4. Main structural findings

### 4.1 The first impression is prohibition-oriented

`README.md` currently describes `AGENTS.md` as the entry point for work and prohibitions. It also introduces the design principle `AI must not touch source data by default` before giving an affirmative description of what AI is encouraged to do.

The data boundary is valuable. The framing is narrower than the intended culture.

Recommended direction:

```text
AGENTS.md: development entry, protected boundaries, and room for exploration
```

```text
AI works freely on code, docs, tests, fixtures, and synthetic examples.
Canonical user data changes use explicit user approval and an approved editor or migration path.
```

This keeps the protected boundary while making the open area visible first.

### 4.2 `AGENTS.md` routes every task through a controlled finite-work model

The mandatory path is `AI_CODEMAP -> TODO -> QUALITY_BAR`. The task rules then repeatedly require one purpose, one finite candidate, current-main revalidation, narrow scope, and separate handling of newly found friction.

These practices are useful for high-risk migrations. As universal instructions, they teach agents to optimize for minimum surface area rather than repository coherence.

The current document contains strong absolute language for source-data protection, but the same section also controls module choice, metadata evolution, fixture updates, active-plan interpretation, report routing, UI ownership, feedback handling, and handoff behavior.

Recommended structural split:

- **Protected boundaries**: private data, canonical source data, destructive migration, secrets, accounting arithmetic.
- **Development posture**: curiosity, judgment, structural questions, related discoveries, reversible experiments.
- **Working agreements**: tests, docs synchronization, diff review, public fixture use.
- **Reference routes**: files to read when relevant.

The development posture should appear before the detailed routing tables.

### 4.3 `TODO.md` acts as an authorization gate rather than a navigation aid

`TODO.md` is marked canonical and is repeatedly described as the source of implementation authority. Its current candidate sections use patterns such as:

- no finite slice selected;
- later slices independently unselected;
- must not be implemented automatically;
- select at most one candidate;
- do not bundle;
- do not auto-start;
- require a separate decision before any continuation.

Some of these statements protect real accounting boundaries, especially mixed-currency arithmetic. Others only prevent an agent from following a coherent design observation across nearby files.

Recommended role:

> `TODO.md` shows the current direction, available continuations, and recent discoveries. It helps choose work; it does not define the full extent of what an AI is allowed to notice, discuss, or improve within the user’s active goal.

Recommended language shift:

| Current pattern | Open-development replacement |
|---|---|
| select at most one candidate | keep each change coherent and reviewable |
| do not bundle adjacent work | combine directly related changes when separation would hide the real boundary |
| candidate remains unselected | candidate remains available for later selection |
| do not auto-start | begin work when it directly advances the active user goal |
| evidence is not authorization | use evidence as design input after checking it against current `main` |

### 4.4 The AI feedback process preserves discoveries but removes agency from them

`docs/AI_WORKING_FEEDBACK_PROCESS.md` currently establishes:

1. feedback is not an implementation request;
2. classification is not an implementation backlog;
3. only an approved plan authorizes implementation;
4. newly discovered friction returns to intake instead of being improved during the active task;
5. AI is not given an autonomous improvement mandate.

This protects against uncontrolled expansion, but it also directly conflicts with the desired culture. The repository invites AI to notice friction, then instructs it not to exercise judgment about that friction.

Recommended two-lane process:

#### Lane A: immediate development judgment

An AI may:

- explain a discovery immediately;
- include a tightly related reversible correction in the current change;
- improve nearby documentation when it prevents the same misunderstanding;
- add a focused fixture or test that reveals the discovered property;
- present alternatives and recommend one;
- stop and ask for an explicit decision only when the choice changes canonical data, user policy, public compatibility, or irreversible structure.

#### Lane B: larger independent follow-up

Use intake, classification, and planning when the discovery:

- opens a separate program of work;
- changes user policy or accounting meaning;
- requires destructive migration;
- needs private production evidence;
- introduces a new long-lived subsystem;
- is valuable but unrelated to the active goal.

This preserves the feedback system without forcing every small insight through a five-stage customs office.

### 4.5 Lifecycle metadata is useful, but lifecycle prose is defensive

`docs/DOCS_LIFECYCLE_CONTRACT.md` successfully separates current, active, historical, completed, superseded, and audit documents. This is one of the strongest foundations for opening the repository because it lets experiments exist without pretending to be current truth.

Its prose nevertheless relies heavily on `Do not`, `Non-goals`, and authorization language. The same meaning can be expressed as placement and reading guidance.

Examples:

| Current form | Positive form |
|---|---|
| Do not just write a document. | Give each document a home, an owner, a current role, and an exit path. |
| Do not turn archive notes into current specs. | Read archive notes as history and route current meaning through the canonical path. |
| parked: Do not implement directly. | parked: promote through the current work route when it becomes relevant. |
| Do not silently leave it in the current path. | Mark its new lifecycle state and route readers to the current path. |
| Non-goals | Current focus and deferred possibilities |

The lifecycle system should be retained and rewritten as a map rather than a barricade.

### 4.6 Archive separation is incomplete in practice

The lifecycle contract says archive material is evidence rather than current authority. However, `AGENTS.md` and `docs/README.md` route agents into many active-plan, completed-plan, and audit files for ordinary tasks.

This means archived restrictive language can re-enter the active instruction chain even when its status says historical or evidential.

Recommended change:

- current routing should point first to one short current contract;
- archive links should appear under `History and rationale` or `Evidence when needed`;
- archived plans should not be mandatory reading for ordinary implementation;
- active plans should explain what question they help answer, not merely what work they prohibit.

## 5. Expression inventory by function

The useful distinction is not positive words versus negative words. It is whether a sentence protects a real boundary or suppresses development judgment.

### A. Canonical-data and privacy boundaries

Examples:

- AI editing private production source data without explicit instruction;
- publishing private amounts, account names, report bodies, or personal records;
- destructive source migration without preview, backup, and recovery evidence;
- treating caches or derived files as canonical data.

Disposition: **retain the substance and rewrite as an explicit safe path.**

Preferred form:

```text
Canonical user data changes require explicit user approval, a reviewable preview,
and an editor or migration path with backup and recovery evidence.
```

### B. Accounting and arithmetic invariants

Examples:

- adding amounts from different currency domains;
- accepting unknown accounts as valid;
- hiding invalid input behind a plausible report;
- changing the Canonical Daily Cube contract incidentally;
- losing exact source evidence or provenance.

Disposition: **retain direct technical language.** A mathematical rejection rule is not a cultural prohibition.

Preferred form:

```text
Each total is computed inside one explicit currency domain.
Cross-domain valuation requires a separately typed valuation or exchange contract.
```

### C. High-risk change gates

Examples:

- source-schema migration;
- default-route switch;
- destructive cleanup;
- private-data inspection;
- compatibility removal;
- new automatic advice or writes.

Disposition: **retain explicit human decision points, but scope them to the risk.**

Preferred form:

```text
High-impact changes begin with an explicit decision, migration path, and rollback evidence.
```

### D. Ordinary development constraints

Examples:

- only an approved plan authorizes implementation;
- every idea must first be classified;
- select at most one candidate;
- do not improve adjacent files;
- newly found friction must be deferred;
- archive evidence cannot inform implementation without a separate promotion ritual.

Disposition: **replace with coherence, reversibility, and transparency.**

Preferred form:

```text
Use judgment to keep the change coherent. Include related reversible improvements
when they make the design clearer, and explain discoveries that extend beyond the diff.
```

### E. Scope descriptions and non-goals

Examples:

- not a general accounting system;
- not a SaaS product;
- not a universal Cube;
- not a new mathematical claim;
- not an implementation backlog.

Disposition: **describe the present focus and future possibility instead.**

Preferred forms:

```text
The current implementation focuses on a personal household accounting workbench.
```

```text
This document records observations and candidate directions; implementation can grow from them when they become relevant.
```

### F. Historical migration constraints

Examples:

- old Stage boundaries;
- retired TSV fallback routes;
- temporary parser prerequisites;
- one-time cutover gates;
- completed plan restrictions.

Disposition: **keep as history, reduce current routing into them, and remove present-tense authority.**

## 6. Priority inventory of current files

| Priority | File | Current effect on agent behavior | Recommended disposition |
|---|---|---|---|
| 1 | `AGENTS.md` | Defines the repository’s development personality; mixes safety, routing, prohibition, and implementation authorization | Add an open development posture first; split protected boundaries from working agreements; replace blanket permission gates |
| 1 | `TODO.md` | Acts as canonical implementation authorization and repeats unselected / do-not-start language | Recast as direction and navigation; keep hard accounting boundaries in their owning contracts |
| 1 | `docs/AI_WORKING_FEEDBACK_PROCESS.md` | Explicitly removes autonomous improvement agency | Introduce immediate-judgment and larger-follow-up lanes |
| 1 | `README.md` | First impression describes AGENTS as prohibitions and AI mainly through a restriction | Describe the open work area before the protected data path |
| 1 | `docs/README.md` | Routes ordinary work through TODO and a large archive graph | Shorten current routes; demote archive links to optional history/evidence |
| 2 | `docs/DOCS_LIFECYCLE_CONTRACT.md` | Strong lifecycle model expressed as negative instructions | Keep model; rewrite as placement, ownership, and transition guidance |
| 2 | `docs/QUALITY_BAR.md` | Useful safety and reversibility principles, but begins with repeated negation and a `非目標` frame | Reframe as current focus; retain quality rules |
| 2 | `docs/SAFETY_PROFILE.md` | Owns real safety invariants but sometimes frames AI as a hazard category | Express safe paths and responsibilities; keep technical fail-closed rules |
| 2 | `docs/ARCHITECTURE.md` and core contracts | Indexed prohibitive phrases mix technical invariants with design closure | Review only cultural or accidental prohibitions; retain exact contracts |
| 3 | active plans and backlogs | Repeated `do not auto-start`, `unselected`, and narrow authorization language | Rewrite when touched; stop routing every ordinary task through them |
| 3 | completed plans, audits, migration history | Large volume of historical restriction language | Preserve as evidence; clarify non-current status and reduce mandatory links |

## 7. Proposed open development posture

The following is a candidate core statement for `AGENTS.md`:

```text
bqn-ledger welcomes AI as a development participant, not only as an executor.

AI may notice patterns, question assumptions, compare designs, identify stale boundaries,
and explain discoveries to moko. Useful unexpected findings are part of the work rather
than scope leakage.

Code structure, documentation, tests, fixtures, reports, and reversible experiments are
open to inquiry and revision. Related changes may be included when they make the result
more coherent and remain reviewable.

Canonical user data, private information, accounting meaning, public compatibility, and
destructive migrations have explicit decision paths. These protected boundaries make the
surrounding development space safer to explore.

When uncertainty can be resolved with a small synthetic experiment, prefer observing the
result. When a choice changes user policy, canonical data, or an irreversible contract,
surface the alternatives and ask for an explicit decision.
```

## 8. Proposed AI freedoms

The next current policy should explicitly say that AI may:

1. state an opinion about architecture, naming, module size, data shape, documentation, and development process;
2. report discoveries that were not named in the original task;
3. question current contracts and explain why they may no longer fit;
4. compare multiple approaches before choosing one;
5. create small synthetic experiments, fixtures, or prototypes to resolve uncertainty;
6. improve related docs, tests, and naming when they are part of one coherent change;
7. propose deletion, consolidation, or replacement of obsolete code and metadata;
8. identify when a historical constraint is still controlling present work;
9. recommend a broader or different direction than the current TODO candidate;
10. leave a clear observation even when the discovery is not implemented immediately.

These freedoms do not include silent changes to private production data, user policy, destructive migrations, secrets, or cross-domain accounting semantics.

## 9. Rewrite principles

### 9.1 Say what to do

Prefer:

```text
Use public synthetic fixtures for verification.
```

instead of:

```text
Do not use private production data.
```

### 9.2 Name the protected object

Prefer:

```text
Canonical source data changes use the approved editor path.
```

instead of:

```text
AI must not edit files.
```

### 9.3 Make risk proportional to process

A docs wording improvement should not require the same authorization pipeline as a currency-domain contract or source migration.

### 9.4 Treat discoveries as output

A task may produce:

- the requested change;
- an unexpected finding;
- a recommendation;
- an experiment result;
- a follow-up question.

The latter four are not failures of scope discipline.

### 9.5 Use time and focus instead of permanent exclusion

Prefer:

- current focus;
- available later;
- outside this change;
- requires a separate user decision;
- historical rationale;
- experimental path.

Avoid using permanent `never`, `only`, or `not authorized` language for ordinary design choices.

## 10. Recommended implementation sequence

### Slice 1: top-level posture pivot

Docs-only. Update:

- `AGENTS.md`
- `README.md`
- `docs/README.md`
- `docs/AI_WORKING_FEEDBACK_PROCESS.md`
- `TODO.md`

Goals:

- place the open development posture before detailed rules;
- separate protected boundaries from normal development freedom;
- allow immediate opinions and related reversible improvements;
- make TODO navigation rather than universal authorization;
- preserve all private-data and canonical-data protections.

### Slice 2: current canonical language pass

Review current canonical docs only. Replace:

- `Non-goals` with `Current focus` or `Deferred possibilities`;
- blanket prohibitions with safe procedures;
- repeated authorization disclaimers with lifecycle metadata;
- AI-as-risk wording with responsibility and capability wording.

Technical rejection rules and arithmetic invariants remain direct.

### Slice 3: routing and archive hygiene

- shorten mandatory reading routes;
- move archive links under optional history/evidence sections;
- stop current docs from re-importing completed migration restrictions;
- add short current summaries where archive reading is currently mandatory.

### Slice 4: observe the changed behavior

After several AI-led tasks, record whether agents:

- surface more useful discoveries;
- give clearer opinions;
- perform coherent related improvements;
- still protect source data and private data;
- require fewer artificial planning documents;
- create fewer stale TODO and active-plan records.

Do not add a vocabulary enforcement gate at the start. The first goal is cultural clarity, not a new prohibition against prohibitions.

## 11. Acceptance criteria for Slice 1

The first rewrite is successful when:

- `AGENTS.md` opens with what AI is encouraged and trusted to do;
- an AI may state unexpected findings without routing them through a separate intake process;
- small related reversible improvements can be included with explanation;
- high-risk and irreversible changes still have explicit human decision paths;
- private and canonical source data protections remain at least as clear as before;
- `TODO.md` helps choose direction without claiming exclusive authority over thought or discussion;
- archive evidence can inform judgment without becoming an automatic implementation command;
- no runtime code, source schema, or accounting behavior changes.

## 12. Conclusion

`bqn-ledger` does not need less care. It needs care expressed as capability.

The repository has built a strong protected center: source truth, exact arithmetic, provenance, privacy, recovery, and explicit contracts. The next step is to make that center support exploration rather than radiate prohibition into every surrounding activity.

A healthy target is:

```text
protect canonical data strongly
observe the system freely
state discoveries openly
experiment reversibly
change coherently
ask for decisions where the choice truly belongs to moko
```

That posture gives AI room to discover something on moko’s behalf while keeping the ledger itself trustworthy.

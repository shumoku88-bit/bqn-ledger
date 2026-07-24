# Priority Sequence and Generic Projection Resumption Gate — 2026-07-25

Status: active routing gate / stacked after the document-governance decision intake
Owner: workflow
Canonical: yes for the temporary priority order ahead of PR #354
Exit: archive after the Israel cash lifecycle and document-governance outcomes are recorded and PR #354 is merged, closed, or superseded through a fresh review

## Purpose

Record an intentional priority change before continuing the generic projection ownership work currently parked in Draft PR #354.

The new order is:

1. establish the Israel 2026 physical ILS cash lifecycle, including return exchange and remaining-cash visibility;
2. decide how document representation, BQN auditing, and cold archive separation should interact;
3. only then reassess whether PR #354 remains the right next generic projection step.

This is not a claim that generic projection work is unimportant. It is a decision to put two concrete ownership problems ahead of a broader abstraction investigation.

## Current parked PR

PR #354, `docs: inventory generic projection ownership`, is intentionally Draft and paused. Its current scope is docs-only and its own handoff forbids continuing to A1 or runtime implementation on that branch.

The PR remains useful evidence, but it is not current implementation authority and is not the selected next work item while this gate is active.

## Gate 1 — Israel ILS cash lifecycle outcome

The Israel work is not considered complete merely because its plan is merged. Before PR #354 may be selected again, the repository must have recorded an outcome for the minimum physical-cash consumer:

- the outbound JPY-to-ILS exchange meaning remains verified;
- the return-home ILS-to-JPY exchange direction has an explicit accepted or rejected contract;
- the ILS cash-position read model has an accepted design and ownership boundary;
- a synthetic round trip can explain acquisition, cash spending, return exchange, and remaining or explicitly explained ILS;
- no JPY/ILS addition, market valuation, or duplicate expense is introduced.

The outcome may be implementation and verification, or an explicit decision to use a simpler external/manual operating procedure. It must not remain an ambiguous unselected need before departure and return use.

Canonical route:

- `docs/archive/active-plans/ISRAEL_ILS_CASH_LIFECYCLE_PLAN-2026-07-25.md`

## Gate 2 — document-governance outcome

Before PR #354 resumes, the repository must record a decision outcome for the three document-governance layers:

- OKF or a compatible/no-adoption representation choice;
- BQN consumer scope or explicit rejection/deferment;
- in-repository archive versus separate cold archive boundary.

At minimum, the decision work must produce:

- a current-authority inventory;
- an explicit mapping or rejection of OKF compatibility;
- a narrow BQN consumer boundary or a reason not to build it;
- a measured estimate of what cold archive separation would remove from the main reading surface;
- one smallest reversible pilot, or a deliberate decision to change nothing.

The gate does not require a complete 413-file conversion, a finished archive migration, or a permanent CI check.

Canonical route:

- `docs/archive/active-plans/DOCUMENT_GOVERNANCE_OKF_BQN_ARCHIVE_DECISION-2026-07-25.md`

## PR #354 resumption review

After Gates 1 and 2 have recorded outcomes, do not simply mark PR #354 Ready. Perform a fresh review against current `main`:

1. confirm PR #354 remains open and Draft;
2. confirm its exact head, base, changed files, and latest CI result;
3. compare its branch against current `main`, including changes merged while paused;
4. re-read its ownership inventory in light of the concrete ILS cash-position consumer;
5. decide whether the new document-governance boundary changes where the inventory should live;
6. check whether the proposed exact sparse grouping characterization still answers an observed repeated need;
7. choose exactly one outcome:
   - mark Ready and merge the docs-only inventory unchanged;
   - revise the inventory on the same branch without adding runtime work;
   - close it as superseded and preserve the useful evidence elsewhere.

No A1, runtime primitive, module extraction, Cube refactor, TBDS refactor, valuation work, or projection DSL may begin during this resumption review.

## Why the concrete consumer comes first

The ILS cash-position requirement supplies a real test of projection ownership:

- multiple source kinds contribute to one same-currency asset position;
- exchange events and Journal postings have different semantic owners;
- totals must remain traceable to contributor evidence;
- JPY legs must remain provenance without entering ILS arithmetic;
- return exchange tests whether a proposed generic grouping abstraction preserves direction and source meaning.

Reviewing generic projection after this consumer exists reduces the risk of extracting an abstraction from only existing report shapes.

## Why document governance comes before resuming a docs-heavy PR

PR #354 is itself a large docs-only ownership inventory. The repository should first decide whether such inventories remain in the main repository, become structured knowledge concepts, are consumed by a BQN audit, or eventually move to a cold archive after completion.

This avoids creating more permanent document surface before deciding how that surface is governed.

## Non-goals

- Do not merge or close PR #354 automatically.
- Do not retarget PR #354 inside this routing PR.
- Do not authorize runtime work from any docs-only inventory.
- Do not combine Israel accounting implementation with document-governance tooling.
- Do not require complete document migration before useful ledger work continues.
- Do not use age, file count, or lack of incoming links alone as proof that a document is stale.
- Do not turn this gate into a permanent program-management layer.

## Exit outcomes

This gate exits when:

- the Israel cash-lifecycle minimum outcome is recorded;
- the document-governance decision outcome is recorded;
- PR #354 receives a fresh current-main review;
- PR #354 is then merged, revised, closed, or superseded explicitly;
- `TODO.md` is updated to select at most one new finite slice.

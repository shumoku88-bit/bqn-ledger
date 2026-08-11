# Ledger Phase 2 review closeout — 2026-08-12

## Final state

The dense-array review of every production BQN owner listed under Phase 2 `src/ledger/` is complete.

Final runtime main: `8aeda703afcf31968d45e81edcc1345ba0ed4190`.
Merged-main CI #2803: SUCCESS.

The phase now contains three intentionally different outcomes rather than one mechanical refactor style:

1. live canonical owners whose traversal/relation structure became more explicit BQN arrays;
2. live owners already narrow enough that only bounded local state or publication guards remain;
3. legacy/qualification seams classified for coherent retirement rather than polished locally.

## Major relation transformations

Across the phase, repeated file-wide state and rescans were replaced where the domain already supplied a useful axis or coordinate.

Examples include:

- Account Journal blocks: source classification -> Scan/Group segments -> local Account admission;
- Budget policy tables: logical-row header classification -> Scan/Group segments plus aligned Account coordinates;
- complete/single-domain Journal: source/Posting relations, transaction-local exact completion, structural evidence alignment;
- Journal transaction structure: body result cells plus one semantic metadata coordinate vector;
- Report policy: physical section headers -> Scan/Group source segments;
- Facts: Transaction Domain/Layer and Posting Account coordinates classified once;
- Transaction rows: Posting transaction coordinates -> one Group -> Transaction-aligned Posting cells.

The result is not simply shorter code. The semantic axes visible in the source now more closely match the admitted accounting relations.

## Exactness, identity, provenance, and diagnostics

The review deliberately did not trade correctness boundaries for array compactness.

Retained laws include:

- exact decimal parsing and checked normalization/summation;
- complete Journal balancing and supported-domain admission;
- durable and fallback Transaction identity;
- Plan durable-relation identity;
- Posting identity and physical source coordinates;
- writer/source authority boundaries;
- public diagnostic order, line ownership, and aggregate diagnostic frontiers;
- fail-closed publication after rejected admission/evidence.

Where a guard represented a dependent parse, exact operation, identity choice, or publication boundary, it remained local even if mutation-like syntax survived.

## Legacy/qualification seams

Several owners were reviewed as retirement surfaces rather than array-refactor targets:

- `account_admission.bqn` — historical `accounts.tsv` admission;
- `companion_admission.bqn` — fixed-width companion TSV admission;
- `config_admission.bqn` — aggregate legacy `config.tsv` admission;
- `cycle_admission.bqn` — legacy `cycle.tsv` admission;
- `plan_snapshot.bqn` — `plan.tsv` qualification Snapshot over `companion_admission`.

The live Snapshot review also removed legacy Account admission from the production Snapshot dependency graph. Historical `accounts.tsv` fixture convenience now lives under `tests/legacy_snapshot_fixture.bqn` until broader legacy retirement removes it.

These seams remain tracked by the repository-wide migration/reachability closeout. Their classification is intentional and should not be mistaken for unfinished local beautification.

## Final six-owner closeout

The queue had lagged behind runtime work for the final ledger owners. Their final decisions are:

### `journal_transaction_structure.bqn`

PR #678 replaced shared body traversal accumulation with body-local result cells, kept metadata and Posting axes independently ordered, and replaced seven semantic metadata rescans with one `⊐ -> ⊏` coordinate relation.

Merged main: `dc815fe98a7ff029a1e64a1d58bc7920960faf99`.
Merged-main CI #2750: SUCCESS.

### `plan_journal_admission.bqn`

PR #679 made Plan-id missing/invalid diagnostics transaction-local while retaining whole-source uniqueness and explicit Plan durable-relation identity remapping.

Merged main: `05094b357705558feaa64eeb72ca6daefc3cd7c9`.
Merged-main CI #2754: SUCCESS.

### `plan_snapshot.bqn`

Reviewed as a legacy/qualification `plan.tsv` seam with no canonical application consumer. No local array refactor selected.

Decision: `docs/PLAN_SNAPSHOT_REVIEW_OBSERVATION-2026-08-12.md`.

### `report_policy_admission.bqn`

PR #680 replaced mutable section ownership (`active/current/Finalize`) with physical header classification, prefix Scan, Grouped source segments, and local segment admission while keeping named Report-policy semantics intact.

Merged main: `06e12a24fd181b1e5af7092726a3bd3886f2fb27`.
Merged-main CI #2760: SUCCESS.

### `snapshot.bqn`

PR #681 removed the production dependency on legacy `account_admission.bqn` and the legacy public `Build` entry point. Production now accepts already-admitted canonical Accounts through `BuildFromAccounts`; old fixture convenience moved under tests.

Merged main: `fbbfbaf8be1a3c8b20ecdba189a5fec61dd84cea`.
Merged-main CI #2798: SUCCESS.

### `transaction_rows.bqn`

PR #682 grouped Posting indices once by canonical `transaction_index`, then mapped typed Posting cells directly into Transaction rows. It removed per-Transaction whole-Posting rescans and mutable row append while preserving arbitrary multi-Posting Transactions.

Merged main: `8aeda703afcf31968d45e81edcc1345ba0ed4190`.
Merged-main CI #2803: SUCCESS.

## Phase boundary

Phase 2 is complete.

The next normal review cursor is the first Phase 3 semantic result owner:

```text
src/sections/account_balances.bqn
```

Section owners should not be forced through the same transformation pattern as admission owners. The next phase begins by asking whether each Section is already a thin semantic publication owner, whether formatting still carries incidental traversal machinery, and whether any Section duplicates accounting/report responsibility.

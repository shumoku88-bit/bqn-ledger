# Israel Predeparture Editor Capture Completion — 2026-07-13

Status: completed
Owner: editor / travel capture
Canonical: no; completed execution record
Exit: archived; reopen only through a separately selected finite slice in `TODO.md`.

## Completion record

The integrated synthetic rehearsal completed with `journal=2`, `friend=1`, and `exchange=1`. All four public commands exited 0 with journal `--post-check lint`; dry-runs preserved bytes, duplicate source IDs were rejected, stale writer checks passed, and injected journal post-check failure restored exact original bytes.

| Work | PR | Merge commit |
|---|---:|---|
| Program selection (Phase 0) | #217 | `5c1f6c6386299a49953edb4812562a73ea61eed3` |
| Ordinary metadata readiness (Phase 1) | #218 | `8f744188df6dd4e93d32ef875d7db28df349d995` |
| Friend pending capture (Phase 2) | #220 | `d521d0dbe16593affc1ecba206e09d5fec5a5f2a` |
| Exchange pure contract (Phase 3) | #221 | `2f617445e21bd0a482465e938828e0b78ea4ebb5` |
| Exchange safe append (Phase 4) | #222 | `c345c53841c49a6ad72d5d13523b2bd47ae8142e` |
| Post-check prerequisite selection | #223 | `7cae0448088cdc49b47332428907a78c890a9045` |
| Mixed journal lint and rollback recovery | #224 | `f0b9875eb87ce1610a3d7b5093dbc44d513e6174` |
| Integrated rehearsal and closure (Phase 5) | #225 | this completed-record PR; final merge commit is recorded in PR #225 metadata and the final report |

Public entries:

```text
tools/edit journal add
tools/edit travel friend add
tools/edit travel exchange add
```

Dedicated sources are headerless `friend_travel_events.tsv` (nine columns) and `travel_exchange_events.tsv` (ten columns). No actual `LEDGER_DATA_DIR` was read, no real source TSV or account was created or changed, and repository `data/` was not used as production data. Candidate 6 remains parked. Finalization, router, cash view, strict-source Steps 2–5, and M4 remain unselected.

## Purpose

Before departure, complete safe editor capture for four Israel travel-day paths:

1. the user's ILS cash expense;
2. the user's card expense recorded only at the confirmed JPY amount;
3. a friend-paid ILS pending source event; and
4. an exchange event preserving the JPY handed over and ILS cash received.

The public entry points are intended to remain narrow:

```text
tools/edit journal add ...
tools/edit travel friend add ...
tools/edit travel exchange add ...
```

There is no selected integrated travel router. The ordinary journal remains the semantic owner for cash and card expenses. Friend and exchange capture each receive a dedicated source-event owner and must not be mixed into the journal.

## Ordered independent phases

Each phase is a separate PR. A phase begins only after the preceding PR has passed CI and merged.

1. **Ordinary journal metadata synthetic readiness** — prove existing ILS cash and confirmed-JPY card paths preserve `trip_id=israel-2026` and `payment=cash|card` without changing the journal editor or metadata schema.
2. **Friend-paid pending source-event storage and safe append** — add dedicated pending-event capture only; do not add JPY finalization.
3. **Exchange-event pure validation and preview** — preserve both observed amounts in an I/O-free structured contract.
4. **Exchange-event safe append and recovery** — add dedicated checked source-event persistence without journal projection.
5. **Integrated four-path synthetic rehearsal and closure** — exercise all public entries in one temporary synthetic base, finish usage docs, and archive this plan.

Completion of one phase does not authorize skipping its review or combining it with the next PR.

## Progress

- Phase 1 verifies on a synthetic base that the unchanged ordinary journal path preserves ordered `trip_id=israel-2026` and `payment=cash|card` metadata for ILS cash and confirmed-JPY card rows. The generic `key=value` path is sufficient, so `config/meta_schema.tsv` remains unchanged.
- Phase 2 adds `tools/edit travel friend add` and headerless `friend_travel_events.tsv`. Blank/comment lines follow the existing loader convention; every data row is the fixed nine-column pending contract. BQN owns full-source validation and identity uniqueness; shell owns exclusive first-file creation, checked append, dedicated post-check, and checked rollback. No journal or finalization write is added.
- Phase 3 adds the I/O-free `src_next/travel_exchange_event.bqn` contract. It requires existing JPY/ILS account descriptors, positive integer JPY source text, positive ILS target text with at most two fractional digits, unique safe exchange identity, and `trip_id=israel-2026`. Its exact structured preview retains both amount texts and exposes no rate, valuation, journal row, or storage behavior.
- Phase 4 adds `tools/edit travel exchange add` and headerless fixed-ten-column `travel_exchange_events.tsv`. The BQN owner validates account currency and every existing/candidate row; shell transports the protocol and owns exclusive first-write, checked append, dedicated post-check, and checked rollback. No journal projection, balance mutation, rate, fee, or account creation is added.

## Phase 5 pause and prerequisite recovery slice

The first integrated synthetic rehearsal ran exchange, then ILS cash journal append, then confirmed-JPY card journal append. Both journal rows were appended, but the second command's default `lint` invoked the single-domain full report, exited 1 with `mixed_currency_domains`, and did not restore its backup. The synthetic journal therefore retained two rows despite command failure.

No production or actual `LEDGER_DATA_DIR` was read. The stopped branch was clean after its unfinished rehearsal file was removed. Phase 0 through Phase 4 remain merged and unchanged.

Phase 5 is paused while the selected prerequisite makes ordinary journal `lint` a mixed-safe source-integrity check and adds checked automatic rollback. The prerequisite must preserve per-row date, exact amount, metadata, account existence, account/row currency, ILS precision, and legacy missing-currency compatibility checks. It must refuse rollback if a later writer changed the post-write target. It must not change full report, strict-source Steps 2–5, candidate 6, friend/exchange writers, M4, or cash views.

The prerequisite implements `src_edit/journal_source_integrity.bqn` plus the journal CLI check owner. Ordinary journal `lint` now validates mixed JPY/ILS source row integrity without report arithmetic. Journal post-check failure performs digest-guarded rollback to exact original bytes; later-writer mutation refuses rollback with recovery-required evidence. `full` remains the separate broad check mode and report contracts remain unchanged.

After the prerequisite PR passes CI and merges, Phase 5 resumes through the public commands without `--post-check none`.

## Ownership and exclusions

- Existing ordinary journal behavior owns ILS cash expenses and confirmed-JPY card expenses.
- A dedicated friend source-event contract owns friend-paid pending ILS observations.
- A dedicated exchange source-event contract owns the two observed JPY/ILS amounts.
- JPY and ILS are never added.
- Exchange is neither expense nor income and is not projected automatically into the journal.
- Friend pending events are not ordinary ILS journal entries.
- The card issuer's confirmed JPY amount is recorded once; the displayed ILS amount is not duplicated.
- No account is auto-created.
- Return-home friend finalization, status/index mutation, and the candidate 6 atomic writer are excluded and remain parked.
- A travel router, cash-remaining view, M4, strict-source Steps 2–5, and Ledger Observatory work are excluded.
- Market FX, external APIs, conversion, valuation, fees, and gain/loss are excluded.

## Validation boundary

All implementation and rehearsal work is synthetic-only:

- use committed synthetic fixtures or a `mktemp -d` base directory;
- run validation with `LEDGER_DATA_DIR` unset;
- do not inspect private account names, amounts, paths, or production source TSV;
- do not treat the repository `data/` directory as production data;
- preserve the ordinary journal's first five columns;
- require dry-run and rejected operations to leave bytes unchanged;
- retain fail-closed duplicate, malformed-source, stale-write, post-check, and rollback evidence where applicable.

No phase may read or change actual production data. Any need for actual account names or production source setup stops the program for review.

## Exit conditions

This program is complete only when:

- the four public capture paths pass one integrated synthetic rehearsal;
- short travel-day usage documentation contains exact public command examples and honest limitations;
- the journal contains only the synthetic cash and card rows;
- friend and exchange events each remain in their dedicated source file;
- duplicate, stale-write, and rollback safety tests pass for the new writers;
- candidate 6 remains parked;
- finalization, projection, router, and cash view remain unselected;
- production data and real accounts remain unchanged; and
- this plan is moved to `docs/archive/completed-plans/` with the Phase 1–5 PR and merge evidence recorded.

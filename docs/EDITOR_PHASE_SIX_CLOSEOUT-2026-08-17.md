# Editor Phase 6 closeout — 2026-08-17

## Status

Phase 6 of the production BQN-native review is complete.

Reviewed scope:

```text
src/editor/
src_edit/
```

The phase began with travel/event semantic owners and moved through Account, Actual/Budget, Issue, Journal, Plan, shared rendering, Travel command leaves, and validation.

The closeout does not claim that all shell/UI architecture is final. Selector/UI adapters, experiments, and repository-wide reachability remain cross-cutting work after the production BQN inventory. It means every current production BQN owner in the Phase 6 scope has now been reviewed under the repository's dense-array policy.

## What Phase 6 established

The editor layer now has a clearer recurring architecture:

```text
canonical admitted observation
  -> bounded owner-local semantic selection/construction
  -> explicit candidate or intent
  -> independent safe publication / post-write validation
```

The review repeatedly distinguished regular relation construction from mutation that protects a real evaluation, provenance, or fail-closed boundary.

It did not pursue mutation count as a metric.

## Journal result

The Journal family is now split cleanly among current responsibilities:

- canonical/source admission;
- candidate construction and exact re-admission;
- Canonical Surface observation/rewrite/publication;
- current cleanup planning/apply/verify;
- privacy-safe identity inventory;
- read-only list and inverse intent;
- mandatory written-candidate validation.

The completed 2026-07-24 Reconstructible Identity Cleanup was retired as an executable runtime because its 390-count gate, prefix exceptions, and historical publication procedure described one completed migration epoch rather than a standing Journal capability.

Its completion record and Git history remain as historical evidence.

## Plan result

The canonical Plan family now keeps semantic differences visible rather than hiding them behind a generic command framework:

- Add maps metadata and block construction, then re-admits the complete candidate;
- Edit rewrites only admitted physical coordinates and re-admits the complete candidate;
- Finish observes one open Plan and emits an Actual completion intent;
- List/Related remain read-only projections;
- Plan identity generation observes the current admitted Plan + completion identity universe;
- narrow Plan and completion validators remain independent leaves.

Dead TSV Plan-ID readers were removed. Multi-currency display now retains Commodity in the human display without widening stable selector TSV field counts.

## Render tail

`src_edit/render.bqn` previously combined:

```text
Account TSV renderer
Journal TSV renderer
Issue 8-column renderer
Issue 9-column renderer
Issue 10-column renderer
```

Reachability showed that the Account and Journal renderers had no production consumers. They were kept alive only by unit tests and old review evidence.

They are removed rather than cosmetically refactored.

The live Issue renderers remain because `issue_add_cmd.bqn` uses them to preserve bounded physical compatibility with admitted 8/9/10-column Issue shapes.

The renderer module is therefore no longer a generic editor TSV bag. It is the small live Issue physical-row presentation owner it actually is.

## Validation tail

Before closeout, `src_edit/validate.bqn` described itself as pure while importing `editor_currency.bqn` and executing:

```text
editorCurrency.Load @
```

at module import time.

That meant even validation functions unrelated to currency inherited registry/source setup as an eager effect boundary.

The review removes that hidden ownership.

### Current pure validation surface

The module now contains only live, effect-free validators for:

- calendar dates;
- Issue integer amount text;
- exact decimal amount text against a caller-supplied admitted currency policy;
- tab/newline-free fields;
- metadata token shape;
- metadata collections;
- prohibition of caller-owned currency metadata.

The exact amount validator no longer discovers policy. Its input contains:

```text
currency
admitted policy
amount text
```

Budget Add and canonical Plan Add/Edit/Finish already own the currency registry observation required by their larger admission paths, so they pass the policy they already observe.

This restores one authority:

```text
application/editor command owns policy observation
validate.bqn owns pure lexical/policy predicate
```

### Retired validation residue

Reachability showed no production consumers for the old validation APIs that modeled retired generic editor/TSV contracts, including Account/Currency combined validation and generic Journal-like Add helpers.

Those APIs and their tests are removed rather than left as a second compatibility shell.

The unit test now covers the live pure validation surface, live Issue renderers, and current Plan identity logic.

### Boundary guard

`checks/check-editor-runtime-boundary.sh` now rejects `editor_currency`, `source_io`, and direct effect/process/clock operations inside `src_edit/validate.bqn`.

Purity is therefore a repository law rather than a comment.

## Travel command leaves

`src_edit/travel_exchange_add_cmd.bqn` and `src_edit/travel_friend_add_cmd.bqn` are production-unchanged after law review.

Both already have the desired shape:

```text
CLI args
  -> source read where required
  -> src/editor semantic owner validation
  -> narrow machine protocol output
```

The exchange command delegates row meaning to `src/editor/travel_exchange_event.bqn` and emits an admitted Event/Posting protocol.

The friend-travel command delegates source-event admission to `src/editor/friend_travel_source_event.bqn` and emits only the corresponding append intent.

Neither command justifies a generic Travel Add abstraction. Their semantic owners and effect shapes differ.

## Tests and characterization

Phase 6 deliberately stopped treating tests as production reachability.

A tests-only consumer can preserve useful law evidence, but it does not by itself justify retaining a production compatibility API. This distinction was used to retire:

- the completed Journal identity migration runtime;
- dead TSV Plan-ID readers;
- dead Account/Journal TSV renderers;
- dead combined Account/Currency/editor validation APIs.

Current tests are kept where they guard live source/writer/admission laws.

## Cross-cutting work not closed here

Phase 6 completion does not close the repository-wide audit inventory. Still separate:

- selector/input duplication and UI change locality;
- shell writer/effect ownership across all active surfaces;
- report/application CLI reachability;
- experiments and `tui/` reachability;
- stale operational/documentation residue outside the reviewed production owners;
- classification of checks as law guards, characterization evidence, or obsolete topology assumptions.

These are intentionally not forced into editor owner refactors.

## Phase 7 cursor

The production BQN inventory now advances to the remaining BQN owners outside the reviewed semantic/application/editor phases:

```text
src/text/parse.bqn
tools/bqn-dump.bqn
```

Normal next cursor:

```text
src/text/parse.bqn
```

After those owners are reviewed, the production BQN inventory itself can close and the remaining selector/UI/reachability audits can be treated as cross-cutting repository work rather than semantic-owner review.
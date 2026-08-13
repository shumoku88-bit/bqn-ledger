# `src/editor/` Phase 6 review observation — 2026-08-12

## Scope

Phase 6 begins with the three production owners under `src/editor/`:

- `friend_travel_source_event.bqn`
- `journal_profile.bqn`
- `travel_exchange_event.bqn`

The review asked where mutation hides a regular BQN data shape and where mutation instead protects evaluation order, source admission, or fail-closed publication.

## Travel semantic owners

The two travel owners already have an appropriate boundary: they are I/O-free semantic admission/preview owners and do not own shell selection or physical publication.

A useful regular shape appears in local validation. Independent checks each produce either an empty diagnostic vector or one fixed diagnostic. Where those checks have no interleaved derived-state/evaluation dependency, the natural BQN representation is an ordered vector of optional diagnostic vectors followed by Join fold:

```bqn
∾´ ⟨
  AddIf ⟨conditionA, diagnosticA⟩,
  AddIf ⟨conditionB, diagnosticB⟩,
  AddIf ⟨conditionC, diagnosticC⟩
⟩
```

PR #734 applies this only where the relation is genuinely regular:

- all ten event-local checks in `friend_travel_source_event.ValidateEvent`;
- the three account-local checks in `travel_exchange_event.AccountDiagnostics`.

Diagnostic text, ordering, exact decimal/date behavior, identity checks, privacy-safe failures, and fail-closed publication remain unchanged.

## Mutation retained deliberately

The review also disproved the simpler rule that every `↩` should disappear.

Existing TSV rows are jagged until their physical column-count gate succeeds. `Event fields` / `RequestFromFields` must therefore remain behind the 9/10-column row-local gate. Turning that stage into an eager whole-array projection would evaluate semantic field selection on malformed physical rows and weaken the current lazy validity boundary.

Likewise, `travel_exchange_event.ValidateExtracted` interleaves diagnostic accumulation with direction/precision calculations and observations over existing exchange IDs. Moving those calculations merely to form one large diagnostic vector can change evaluation/failure order for malformed inputs even when ordinary characterization tests remain green. Its sequential staging is therefore retained.

Preview/result publication is also intentionally lazy. A candidate row/event is constructed only after diagnostics prove admission success.

The resulting rule is narrower than "avoid mutation":

> expose regular semantic collections as arrays; retain local mutation when it is the clearest guard for evaluation order, jagged physical admission, provenance-sensitive construction, or fail-closed publication.

## `journal_profile.bqn`

`journal_profile.bqn` is not the same kind of owner as the two travel validators. It is an editor-owned historical Journal parser whose current surface includes:

- paragraph grouping with physical source line coordinates;
- declaration and commodity/account admission;
- account and transaction metadata parsing;
- posting parsing and exact integer deltas;
- transaction IR construction and posting identity;
- cross-transaction plan/budget/actual link validation;
- historical profile selection;
- default-envelope resolution;
- event-by-account matrix projection.

Its mutable staging is frequently tied to parser construction, source-line provenance, shape-dependent publication, or ordered cross-link diagnostics. File size and mutation count alone do not establish a coherent reason to rewrite this parser. No production change is justified in this pass.

A future change should begin from a concrete consumer or correctness/performance defect, not from a generic desire to make the parser shorter.

## Result

The three `src/editor/` owners are reviewed.

- `friend_travel_source_event.bqn`: regular event validation folded in #734.
- `journal_profile.bqn`: law review complete; production unchanged.
- `travel_exchange_event.bqn`: regular account validation folded in #734; interleaved/source-boundary staging deliberately retained.

The normal Phase 6 cursor can move to `src_edit/account_add_cmd.bqn`.

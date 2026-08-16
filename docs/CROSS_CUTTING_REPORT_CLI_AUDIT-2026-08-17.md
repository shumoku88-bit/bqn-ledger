# Cross-cutting report/application CLI audit — 2026-08-17

## Scope

This audit follows the writer/effect ownership pass and traces the current report path from canonical request metadata to terminal presentation and preview caching.

The boundary under review is:

```text
report catalog / request / route / composition meaning
                 BQN
                  |
                  v
request/batch/metadata protocol
                  |
                  v
shell transport / cache / presentation
```

The goal is to find shell-owned report semantics or effect/protocol duplication that survived the Phase 4/5 BQN review.

## Current report entrypoints

### `tools/report`

`tools/report` is a thin single-report process adapter.

It accepts the public command shape, resolves the canonical base path, and delegates one admitted report request to `src/application/report_destination_cli.bqn`.

It does not own the report catalog, route coordinates, evidence selection, accounting composition, or rendering semantics.

### `tools/report-all`

`tools/report-all` obtains the current request set from `current_report_profile_cli.bqn` and renders the complete set through `current_report_batch_cli.bqn`.

The shell does not maintain a twelve-key report table. Request order and surface membership come from the BQN catalog/request owners.

### `tools/report-section-metadata`

This is a source-independent leaf over `report_metadata_cli.bqn`. It is the current key/label/domain/placement publication used by report frontends.

### `tools/report-summary`

This is a compact-surface alias over `tools/report-all`. It owns no independent summary schema.

### `tools/query`

`tools/query` observes the compact report summary and performs exact `ledger_*` key lookup only.

It deliberately provides no retired-key translation, regex query language, heading parsing, or separate request manifest.

### `tools/report-cache`

`tools/report-cache` obtains the current human request relation from `current_report_profile_cli.bqn`, validates its order against `report_selection_cli.bqn`, renders one framed batch through `current_report_batch_cli.bqn`, stages complete cache files, and publishes the cache set under a lock.

The cache does not own report keys or composition.

### `tools/main-ui.sh`

`main-ui.sh` owns report browsing/presentation:

- canonical base/domain observation through application CLIs;
- presentation policy observation;
- dynamically generated section list from `report-section-metadata`;
- optional fzf/gum/plain selection;
- wide-report pager behavior;
- preview cache lifecycle.

Direct section execution is resolved from the current request relation produced by `current_report_profile_cli.bqn`; arbitrary shell keys do not bypass that relation.

## Concrete defect: cache invalidation duplicated semantic source knowledge

Before this audit, `main-ui.sh` decided whether its preview cache was current from a hand-maintained shell list:

```text
accounts.journal
actual.journal
plan.journal
budget.journal
budget.toml
household.toml
report.toml
issues.tsv
src/*.bqn
config/report_labels.tsv
```

That list was already incomplete. The report application path reads the repository currency registry from `config/currencies.tsv`, but changing only that registry did not advance the shell generation token.

A preview cache could therefore be considered current after report-relevant configuration had changed.

More importantly, maintaining a canonical dependency list in the report frontend recreated source-topology knowledge that belongs to the application/source owners.

## Fix: conservative physical invalidation

`main-ui.sh` no longer enumerates semantic report dependencies.

It computes the cache generation token from the maximum physical mtime across:

```text
all files below the selected Household base
all files below repository src/
all files below repository config/
```

This is intentionally conservative.

An unrelated file may cause an extra preview refresh. That is acceptable for a cache. Missing a newly introduced report dependency is not.

The frontend therefore observes physical change without becoming a second owner of the canonical Household/report source set.

`check-report-cache-invalidation.sh` guards both sides:

- the `prepare_cache` body must not regain the old hand-maintained semantic filename list;
- changing only `config/currencies.tsv` mtime must advance the preview-cache generation token.

The test restores the registry timestamp and does not alter registry contents.

## Current preview cache helpers

`tools/command-hub-cache-refresh` and `tools/command-hub-preview` remain reachable from `main-ui.sh`.

Their names are historical residue from the older Command Hub, but they are not dead runtime surfaces:

- cache refresh stages and validates the current report cache before live preview publication;
- preview is a file/status-only fzf preview reader and never starts the report engine.

Renaming or retiring them is therefore a repository naming/dead-surface question, not a report semantic fix. This audit does not remove a live helper merely because its name predates the Calendar-first frontend.

## Result

No duplicated report catalog, route, request, composition, or rendering owner was found in the current shell report entrypoints.

The concrete duplication was cache dependency knowledge, and that has been removed.

The current report boundary is:

```text
BQN catalog/request/route/evidence/composition/rendering
                         |
                         v
               machine/read protocols
                         |
                         v
shell process lifetime / cache / selector / pager
```

## Next cursor

The next cross-cutting lane is repository-wide dead-surface and reachability cleanup.

Known evidence to re-check there includes:

```text
legacy safe-write API definitions with no callers
historically named but live command-hub cache/preview helpers
other retained wrappers whose names or comments may describe retired topology
```

Do not equate an old name with dead reachability; classify current consumers first.

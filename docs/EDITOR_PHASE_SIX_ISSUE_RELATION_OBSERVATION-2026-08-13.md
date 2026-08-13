# Phase 6 Issue editor relation observation — 2026-08-13

## Scope

This review advances the normal Phase 6 cursor through the four Issue editor owners:

- `src_edit/issue_add_cmd.bqn`;
- `src_edit/issue_close_cmd.bqn`;
- `src_edit/issue_list_cmd.bqn`;
- `src_edit/issue_validate_cmd.bqn`.

The main question is not whether every branch or mutation can disappear. It is whether semantic Issue meaning is being parsed twice, and which remaining physical source operations are required to preserve historical 8/9/10-column shape safely.

## Canonical semantic owner

`src/ledger/issue_admission.bqn` already owns the bounded Issue source contract:

- exact legacy eight-column, due-aware nine-column, and closed-aware ten-column headers;
- compatibility normalization into one semantic relation;
- strict Issue identity, status, date, due, close lifecycle, category/title, amount/currency, registry precision, and duplicate-ID admission;
- normalized due/closed meaning;
- exact amount coefficient/scale;
- physical `source_row` and canonical `source_ref` evidence.

That relation is therefore the correct semantic input for read-only selection and close-target selection. Repeating those laws inside each command creates a second Issue parser and makes future lifecycle changes multiply across surfaces.

## Issue List

Before this review, `issue_list_cmd.bqn` independently:

- recognized all three headers;
- checked row widths;
- normalized legacy/due/closed shapes;
- revalidated due and closed dates;
- revalidated status/closed lifecycle;
- rebuilt row records;
- then filtered `status=open`.

The refactor removes that semantic parser. List now:

1. reads physical lines only so physical coordinates remain observable;
2. preserves the historical missing/empty/comment-only source behavior as an empty list without opening the currency registry;
3. admits a nonempty Issue source once through the canonical Issue owner;
4. filters the admitted `status` axis with a BQN mask;
5. uses admitted date/title/details/due/exact amount axes for output;
6. uses admitted `source_row` for the existing human `line N` contract.

The selector output shape remains unchanged. Exact amount text is rendered from admitted coefficient/scale rather than reusing unvalidated source text, so admitted source precision remains visible.

## Issue Close

Close has two different responsibilities and they must stay visibly different.

### Semantic responsibility

Open-Issue selection, source-row identity, recorded date, title, details, due/closed validity, lifecycle validity, amount/currency validity, header meaning, and duplicate identity now come from the admitted Issue relation.

The command no longer owns a second header/row-normalization/date/lifecycle parser.

### Physical writer responsibility

The target source may still be one of three admitted historical physical shapes. Close must preserve that shape when replacing one row.

Because admission already proves the exact supported header, the writer no longer compares header names itself. It observes only whether the admitted physical header has ten columns, which is the one physical fact needed to know whether a `closed` field exists.

The writer deliberately retains:

- physical source-line classification to locate the admitted header row;
- ten-column versus non-ten-column physical capability;
- the raw selected TSV row at admitted `source_row`;
- status-field replacement;
- close-date insertion only for the ten-column shape;
- final-details replacement with the appended decision text;
- exact old/new row publication for the shell safe-replace boundary.

This raw-field work is not a second semantic Issue parser. It is source-shape-preserving writer machinery over an already-admitted semantic target.

The existing rule also remains: a ten-column source requires a strict close date, while eight-/nine-column historical shapes cannot represent one.

## Issue Add

Issue Add retains its existing request validation and schema-specific render owners.

The only BQN-native cleanup is the regular schema/renderer relation:

```text
legacy -> RenderIssueRow
due    -> RenderIssueRowWithDue
closed -> RenderIssueRowWithClosed
```

One schema index selects the renderer through BQN Choose (`◶`) instead of mutating a row variable through three conditional assignments. No new renderer abstraction or Issue schema registry is introduced.

The source-observing shell still supplies the target physical schema. Add does not gain authority to reinterpret the source itself.

## Issue Validate

`issue_validate_cmd.bqn` remains production-unchanged.

It is the mandatory semantic post-write leaf:

- loads the canonical currency registry;
- admits `issues.tsv` through the canonical Issue owner;
- preserves diagnostic codes on failure;
- publishes only the small success protocol.

The shell owns backup/append/replace/rollback; BQN owns semantic re-observation. Generalizing this leaf would hide that writer-safety boundary.

## Source-coordinate witness

Comments, blank lines, and backslash source notes are physical evidence but not Issue rows. Because Issue admission retains physical `source_row`, List and Close can now share semantic meaning without losing physical coordinates.

The existing Issue compatibility check is extended with a source containing comments, a backslash note, a blank line, and both open/closed Issues. It proves:

- List still reports the open Issue as physical `line 4`;
- Close publishes `REPLACE\t4` for the same admitted target;
- no command-local lifecycle parser is required to recover that coordinate.

## Cross-cutting validation/effect observation

`issue_add_cmd.bqn` and `issue_close_cmd.bqn` still import the broad `src_edit/validate.bqn` request-validation surface. That module currently loads editor currency setup at import time.

Close now also needs the currency registry for canonical Issue admission, so the same process can observe registry setup more than once. Budget/Plan owners already expose the same pressure.

Do not solve this with Issue-local copies of date/text validation. The repeated effect is now clear cross-cutting evidence for the later `validate.bqn` owner review, where pure request validation and registry-dependent exact-currency validation can be separated only if the existing diagnostic/evaluation contracts permit it.

## Decision

All four Issue editor owners are reviewed.

- `issue_add_cmd.bqn`: regular schema/renderer selection; existing validation/render ownership retained.
- `issue_list_cmd.bqn`: command-local semantic parser retired in favor of canonical admitted relation.
- `issue_close_cmd.bqn`: semantic parser retired; minimal physical shape-preserving rewrite retained.
- `issue_validate_cmd.bqn`: law review; mandatory post-write leaf unchanged.

The normal Phase 6 cursor can advance to:

`src_edit/journal_block_add_cmd.bqn`

# Journal Native Multi-Posting Append Editor Plan

Status: selected finite production-adjacent explicit-path writer plan
Owner: journal source migration / editor
Canonical: no; canonical routing remains `TODO.md`
Exit: focused implementation, review, completion archive, deletion of this current-path plan, and explicit return to no selected Journal slice; no later slice may be selected automatically
Date: 2026-07-22

## Owner selection and finite question

The owner selected **native multi-posting Journal entry** as the next finite Journal goal.

Canonical finite question:

> TSVの既存`journal add`経路、production report routing、およびTSV source truthを変更せず、明示指定された既存のMinimal BQN Journalファイルへ、一つのactual-layer取引を複数の明示的postingを持つnative Journalブロックとしてpreview・検証・atomic appendし、stale write、重複event-id、不均衡、未知勘定、無効日付・金額、および追記後検証失敗をfail-closedで拒否できる、独立したeditor経路を定義できるか。

This docs-only slice selects and defines a future implementation. It does not implement a writer, validator, test, fixture, or production route.

## Current boundary and why the command is separate

The current production and daily-write contract remains unchanged:

- `journal.tsv`, `plan.tsv`, `budget_alloc.tsv`, and `accounts.tsv` remain production source truth.
- `tools/edit journal add` remains the existing TSV `date / memo / from / to / amount` writer.
- `src_next/context.bqn`, `src_next/report.bqn`, and `src_next/main.bqn` continue to route production reports from TSV.
- The existing A-1 `txn_id` policy remains the TSV-era compatibility policy; this explicit native-Journal path does not reinterpret the TSV five-column contract.

Overloading `tools/edit journal add` would make one stable command select two different source formats and targets. The future command must therefore be a separate, explicit-path command:

```bash
tools/edit --base DIR journal-block add \
  --journal-file FILE \
  --date YYYY-MM-DD \
  --description DESCRIPTION \
  --event-id EVENT_ID \
  --posting ACCOUNT=SIGNED_INTEGER \
  --posting ACCOUNT=SIGNED_INTEGER \
  [--posting ACCOUNT=SIGNED_INTEGER ...] \
  [--dry-run] \
  [--yes] \
  [--post-check none|lint|full]
```

`journal-block` is deliberately distinct from the existing `journal` command group. It does not silently derive a target from `DEFAULT_JOURNAL_FILE` and never targets `journal.tsv`.

## Explicit target-file contract

The future command must require `--journal-file FILE` and enforce all of the following before preview or write:

- `FILE` is a relative path resolved against the selected `--base`.
- Absolute paths are rejected.
- Any `..` path component is rejected rather than normalized away.
- The lexical path has a `.journal` suffix.
- `--base` already exists and resolves to a directory.
- The resolved target already exists and is a regular file.
- The target's canonical resolved path remains inside the canonical base directory; symlink escape is rejected.
- No parent directory or Journal file is created.
- No default filename is substituted.
- `journal.tsv` is never selected.
- Backup and temporary-file operations remain on the target filesystem and no target write occurs outside the selected base.

Path containment and byte movement belong to the shell/filesystem safety boundary; account, commodity, transaction, and posting meaning remain in BQN. A later implementation must not weaken containment merely because the selected relative filename exists.

The existing target must already contain a compatible `commodity JPY` declaration and declarations for every posting account. The command does not add or modify declarations.

## Selected input contract

The first finite writer slice accepts exactly one candidate transaction with this contract:

- layer is fixed to `actual`;
- status marker is fixed to `*`;
- commodity is fixed to `JPY`;
- `--date` is a real calendar date in exact `YYYY-MM-DD` form;
- `--description` is nonempty (not whitespace-only) and cannot contain CR/LF source injection;
- durable `--event-id` is required, nonempty, single-line, and is not generated;
- at least two `--posting` occurrences are required;
- each posting argument has exactly one nonempty `ACCOUNT=SIGNED_INTEGER` pair;
- each amount is an explicit base-10 exact integer, may carry `-`, is nonzero, and is neither decimal nor implicit;
- posting deltas sum exactly to zero;
- posting order is preserved exactly as supplied;
- every account is declared in the target Journal;
- every account resolves exactly in `<base>/accounts.tsv` through `src_next/account_key.bqn` and is compatible with JPY;
- the durable event ID is unique across the full existing Journal;
- no automatic balancing posting, account creation, event-ID generation, TSV row generation, or synchronization occurs.

The semantic owner must reject line-breaking/control input that could change the rendered Journal structure. Shell parses option occurrence and transports values only; it must not infer account roles, signs, balance, registry membership, or Journal meaning.

Not selected: plan layer, budget layer, envelope companions, posting metadata, costs/lots, implicit amounts, multiple commodities, aliases/fuzzy account resolution, or account creation.

## Exact rendered block and preview

For these arguments, the BQN renderer produces exactly one native Journal transaction block shaped as follows:

```journal
2026-07-22 * スーパー
    ; event-id: purchase-20260722-001
    ; layer: actual
    expenses:food:daily    1200 JPY
    expenses:household      500 JPY
    assets:cash           -1700 JPY
```

The renderer owns spacing and line order. The order of posting lines must equal the order of `--posting` options. Preview must display the exact complete candidate block, without elision, normalization, reordering, or an inferred balancing line.

A paragraph-separator newline needed to join the block to existing raw text is transport framing, not part of the transaction block. The proposed-full-file builder must compute the exact separator from the existing final bytes, and the safe append must produce byte-for-byte the same proposed full Journal that was parsed before confirmation. The preview must clearly show the exact block and target path; it must not conceal any candidate line.

## Selected validation and rendering flow

```text
CLI arguments
  -> syntax-only shell parsing and explicit-path safety guards
  -> pre-preview target snapshot (SHA256 / size / mtime)
  -> BQN semantic input validation and exact block rendering
  -> read existing Journal raw text
  -> parse existing Journal with journal_profile_stage1
  -> reject duplicate durable event-id and incompatible declarations
  -> construct exact proposed full Journal in memory
  -> parse proposed full Journal with existing Stage 1 parser
  -> validate proposed Transaction / Posting IR against resolved accounts.tsv registry
  -> exact block preview
  -> confirmation
  -> stale-checked backup-producing atomic block append
  -> mandatory native Journal post-write validation
  -> guarded rollback on post-check failure
```

The future implementation should reuse, without duplicating the parser:

- `src_next/journal_profile_stage1.bqn` for declarations, full-file parsing, durable-ID uniqueness, explicit exact-integer postings, and transaction balance;
- `src_next/journal_posting_ir_stage2a.bqn` for checked Posting IR assembly;
- `src_next/journal_read_only_source_carrier.bqn` where its checked carrier result is useful;
- `src_next/journal_shadow_context.bqn` only where its explicit-path read contract is reusable without introducing report routing;
- `src_next/account_key.bqn` for the resolved `accounts.tsv` registry;
- `tools/lib/safe-write.sh` for stale-checked backup and atomic replacement;
- `tools/lib/edit-bqn-common.sh` for syntax-only protocol, preview, confirmation, and guarded rollback orchestration where compatible.

`src_edit/journal_block_add_cmd.bqn` is the likely BQN owner for candidate validation, exact rendering, existing/proposed full-file checks, and a machine-readable block-append protocol. Shell must not duplicate these Journal semantics.

## Existing and proposed full-file checks

Before preview, the future command must prove both states:

1. **Existing target**: full raw Journal parses successfully under the supported Minimal BQN Journal profile. Unsupported syntax already present fails closed; the command does not repair or normalize it.
2. **Proposed target**: the exact full bytes that safe append would produce parse successfully, contain the candidate durable event exactly once, and produce successful checked Posting IR against the resolved registry.

The candidate validation must additionally prove fixed `actual`, fixed `*`, JPY-only, at least two ordered postings, nonzero exact integers, and a zero delta sum even where Stage 1's broader read profile permits other values.

No parser implementation is copied into `src_edit`. If existing Stage 1 or Stage 2A cannot satisfy the selected writer contract without modification, implementation must stop and propose a separate parser/Posting-IR slice rather than widening this writer slice.

## Atomicity, stale detection, and rollback

The future writer retains this sequence:

1. Capture a pre-preview snapshot containing target path, SHA256, byte size, and mtime.
2. Validate existing and proposed content from that snapshot.
3. Preview and obtain confirmation (unless `--yes`; `--dry-run` never writes).
4. Recheck SHA256/size/mtime before creating the backup.
5. Create a backup before mutation.
6. Construct a temporary file from the unchanged original bytes plus the exact separator and complete multiline block.
7. Recheck the same snapshot immediately before rename.
8. Publish with same-filesystem atomic rename.
9. Capture the post-write digest.
10. Run mandatory native Journal validation on the written explicit target.
11. If validation fails, restore the backup only when the target still matches the captured post-write digest.
12. If a later writer changed the target, refuse rollback and report recovery required; never overwrite that later writer.
13. After successful rollback, verify that original digest is restored, so no partial block remains.

### `safe_append_checked` feasibility finding

Repository inspection found no proven multiline incompatibility. `safe_append_checked` receives its payload as one quoted shell value and writes it using `printf '%s\n'`, while retaining pre-backup and immediate-pre-rename stale checks, backup creation, temporary-file construction, and atomic rename. It is therefore the first reuse candidate without semantic changes.

The implementation test must still prove exact newline/separator behavior for a multiline block, files both with and without a final newline, stale injection before append, and no partial block. `tools/lib/safe-write.sh` may change only if that focused evidence proves a concrete incompatibility; this plan does not authorize a generic writer framework.

## Native Journal post-check ownership

`src_edit/journal_source_check.bqn` validates the TSV journal source. It must not be invoked or relabeled as a native Journal validator.

The future native owner is `src_edit/journal_native_source_check.bqn`. It receives the explicit `.journal` target and base, reads the full target, routes it through the existing Stage 1 parser and checked Stage 2A Posting IR path, and returns failure without report arithmetic or TSV-source substitution.

Mandatory post-write validation must verify at minimum:

- the complete target parses successfully;
- durable event IDs are unique;
- every transaction is balanced;
- all postings have explicit nonzero exact-integer amounts;
- account declarations, JPY commodity, actual candidate layer, and resolved registry are supported;
- Stage 2A produces successful Posting IR rows against `accounts.tsv`;
- the newly appended durable event is present exactly once;
- its posting order, account keys, signed amounts, commodity, layer, status, description, date, and event ID exactly equal the previewed candidate.

`--post-check` semantics must not permit bypassing this mandatory native validation:

- `none`: run the mandatory native target/candidate validation only; skip optional additional checks;
- `lint`: run the same mandatory native validation (the default mode);
- `full`: run mandatory native validation first, then the repository full check; failure of either triggers the same guarded rollback.

Thus `none` does not mean “trust unvalidated bytes”; it only suppresses checks beyond the command's required native postcondition.

## Failure contract

No target write and no backup side effect may occur for:

- missing target file;
- absolute, traversing, wrong-suffix, or outside-base target path;
- non-regular target;
- invalid date;
- empty/whitespace-only or structurally unsafe description;
- missing/unsafe event ID;
- duplicate durable event ID;
- fewer than two postings;
- malformed posting option;
- zero, decimal, implicit, or otherwise non-integer amount;
- posting sum not exactly zero;
- posting account not declared in the Journal;
- posting account absent from or non-JPY in `accounts.tsv`;
- missing/incompatible JPY commodity declaration;
- unsupported Journal syntax already present;
- proposed-full-file parse or Posting IR failure;
- stale file detected before append or immediately before rename;
- user cancellation.

After rename, any mandatory or selected post-check failure triggers guarded rollback from the backup only when safe. Successful rollback must restore the original digest and leave no partial Journal block. A later concurrent writer is never overwritten.

## Production and migration boundaries

This finite slice must not select or modify:

- production `BuildContext` routing;
- `report.bqn`, `main.bqn`, Cube, or TBDS behavior/shape;
- default source switching;
- `journal.tsv` writer behavior;
- automatic TSV-to-Journal or Journal-to-TSV synchronization;
- dual writes, reverse synchronization, fallback, or conflict resolution;
- account declarations or migration into Journal;
- plan, budget, or envelope migration;
- replacement/editing of existing Journal transactions;
- reversal or correction policy;
- interactive TUI/add-UI integration;
- private ledger data or a production-data trial;
- source cutover, final TSV freeze, or archive policy;
- branch cleanup or selection of a later slice.

TSV remains the sole production source truth and default write path throughout this slice. The native command is production-adjacent only because it safely writes an explicitly selected non-default Journal file through existing checked Journal boundaries.

## Likely future changed-file boundary

Repository inspection supports this narrow likely implementation set:

```text
tools/edit-bqn
src_edit/journal_block_add_cmd.bqn
src_edit/journal_native_source_check.bqn
checks/check-edit-bqn-journal-block-add.sh
fixtures/journal-native-multi-posting-editor/accounts.tsv
fixtures/journal-native-multi-posting-editor/cycle.tsv
fixtures/journal-native-multi-posting-editor/source.journal
docs/archive/completed-plans/JOURNAL_NATIVE_MULTI_POSTING_APPEND_EDITOR_PLAN-2026-07-22.md
TODO.md
NEXT_SESSION.md
docs/README.md
docs/JOURNAL_NATIVE_MULTI_POSTING_APPEND_EDITOR_PLAN.md  # deleted on completion
```

Conditional files, only with demonstrated need:

```text
tools/lib/edit-bqn-common.sh  # native block protocol / explicit post-check owner / rollback wiring only
tools/lib/safe-write.sh       # only if focused multiline evidence proves incompatibility
```

The shell integration check belongs under `checks/`, matching current repository convention for editor command tests. The public fixture remains synthetic. A new BQN pure helper, if introduced rather than kept inside command entry modules, requires a focused `tests/test_*.bqn` unit test under repository policy; this does not authorize broad parser tests.

The future implementation must not modify:

```text
src_next/context.bqn
src_next/report.bqn
src_next/main.bqn
src_next/cube.bqn
src_next/tbds.bqn
src_next/journal_profile_stage1.bqn
src_next/journal_posting_ir_stage2a.bqn
src_next/journal_read_only_source_carrier.bqn
src_next/journal_shadow_context.bqn
tools/to-hledger
production/private data
```

If an existing parser, carrier, shadow context, or Posting IR modification proves necessary, stop and select that incompatibility as a separate finite slice.

## Future focused implementation assertions

The focused implementation check must cover at least:

- exact dry-run block preview and zero writes;
- confirmed/`--yes` append to an explicit existing nested or base-relative `.journal` file;
- unchanged `tools/edit journal add` TSV behavior;
- exact posting order and exact event identity after parse;
- target paths: missing, absolute, `..`, wrong suffix, outside-base symlink, and attempted `journal.tsv` selection;
- existing source errors and incompatible/missing declarations;
- invalid date, description, event ID, posting count/shape/amount/sum;
- duplicate event ID;
- declared-but-unresolved and non-JPY registry accounts;
- exact proposed-full-file parsing before confirmation;
- mandatory post-write candidate equality;
- stale change before append and immediately before rename;
- backup creation and atomic full-block visibility;
- forced post-check failure with successful digest-guarded rollback;
- concurrent later-writer mutation causing rollback refusal;
- no partial block after successful rollback;
- `none`, `lint`, and `full` mode boundaries;
- existing files with and without a final newline;
- no Journal creation, TSV generation, production route change, or private data access.

## Completion and routing

Exit requires all of the following in one focused future implementation/review sequence:

1. implement only the selected explicit-path writer boundary;
2. pass focused and full validation;
3. review intended scope against the complete proposed diff;
4. archive this plan as `docs/archive/completed-plans/JOURNAL_NATIVE_MULTI_POSTING_APPEND_EDITOR_PLAN-2026-07-22.md` with observed evidence;
5. delete this current-path plan in that completion change;
6. update `TODO.md`, `NEXT_SESSION.md`, and `docs/README.md` back to **no selected Journal slice**.

No production source switch and no later Journal slice may be selected automatically.

## Validation for this docs-only selection PR

```bash
git diff --check
bash checks/check-docs-lifecycle.sh
bash checks/check-absolute-links.sh
bash checks/check-repo-index.sh
bash tools/check.sh
git status --short
git diff --name-only origin/main...HEAD
```

Exactly these four docs/routing files may change in this PR:

```text
docs/JOURNAL_NATIVE_MULTI_POSTING_APPEND_EDITOR_PLAN.md
TODO.md
NEXT_SESSION.md
docs/README.md
```
